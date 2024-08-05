library crawl_sticker;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum StickType {
  visible,
  hidden,
  worm,
}

typedef StickBuilder = Widget Function(BuildContext, StickType, Size?);

/// The surface on which the crawl animation will be performed.
///
/// To use it wrap your entire list of items (or whatever it need to be emphasized)
/// with [CrawlStickSurface]:
/// ```dart
/// CrawlStickSurface(
///   duration: const Duration(milliseconds: 200),
///   curve: Curves.ease,
///   child: ListView(...),
/// )
/// ```
/// next, for every item in list add a [Stick], but be sure they are
/// positioned in same axis (horizontal or vertical) with a tolerance of one degree
/// on both sides:
/// ```dart
/// children: List.generate(100, (i) => Row(
///   crossAxisAlignment: CrossAxisAlignment.center,
///   children: [
///     // StickWidget is a filler so you need to pass finite constraints
///     SizedBox(
///       width: 4,
///       height: 10,
///       child: StickWidget(decoration: myDecoration, show: i == selected),
///     ),
///     TextButton(
///       onPressed: () => setState(() => selected = i),
///       child: Text('Select')
///     ),
///   ]
/// ))
/// ```
class CrawlStickSurface extends StatefulWidget {
  const CrawlStickSurface({
    super.key,
    required this.child,
    required this.animationDuration,
    required this.animationCurve,
    required this.sticksCount,
    required this.stickBuilder,
    required this.selected,
  });

  /// The child in which the [Stick]s must be placed anywhere to create
  /// sticks transition.
  ///
  /// The [Stick]s widgets must be located on the same axis, and this
  /// axis must coincide with [axis].
  final Widget child;

  /// The transition curve.
  final Curve animationCurve;

  /// The transition duration.
  final Duration animationDuration;

  /// The sticks count
  final int sticksCount;

  /// Selected stick index
  final int selected;

  /// Stick builder with next arguments: context, visibility, size.
  /// When size is not null the stick must use the size.
  final StickBuilder stickBuilder;

  static InheritedSticksSurface of(BuildContext context) {
    final InheritedSticksSurface? result =
        context.dependOnInheritedWidgetOfExactType<InheritedSticksSurface>();
    assert(result != null, 'No _SticksCollector found in context');
    return result!;
  }

  @override
  State<CrawlStickSurface> createState() => CrawlStickSurfaceState();
}

class CrawlStickSurfaceState extends State<CrawlStickSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<Size?>? _size;
  Animation<Alignment?>? _alignment;

  final List<GlobalKey> __sticksKeys = [];
  List<GlobalKey> get _sticksKeys {
    if (__sticksKeys.length != widget.sticksCount) {
      final diff = widget.sticksCount - __sticksKeys.length;
      if (diff > 0) {
        // add missing ones
        __sticksKeys.addAll(List.generate(diff, (_) => GlobalKey()));
      } else {
        __sticksKeys.length = widget.sticksCount;
      }
    }
    return __sticksKeys;
  }

  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
  }

  @override
  void didUpdateWidget(covariant CrawlStickSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.animationDuration;

    if (oldWidget.selected != widget.selected) {
      _selectedChanged(oldWidget.selected, widget.selected);
    }
  }

  static Axis _getAxis(Offset p1, Offset p2) {
    final angle =
        math.atan2(p2.dy - p1.dy, p2.dx - p1.dx).abs() * 180 / math.pi;

    assert(
        angle > 89 && angle < 91 ||
            angle > 179 && angle < 181 ||
            angle > -1 && angle < 1,
        '''
      StickWidgets must be placed in same axis each within same nearest SticksSurface.
      Some of your sticks are not. The angle between sticks centers was $angle
    ''');

    if (angle > 89 && angle < 91) {
      return Axis.vertical;
    }

    return Axis.horizontal;
  }

  void _selectedChanged(int oldIndex, int newIndex) {
    final fromContext = _sticksKeys[oldIndex].currentContext;
    final toContext = _sticksKeys[newIndex].currentContext;

    final from = fromContext?.getContextBoundingBox(context);
    final to = toContext?.getContextBoundingBox(context);

    /// If [from] or [to] are not available, then it just shows the indicator
    /// without animation. They may not be available when using [ListView], where
    /// the widget element is not built, if it is not visible, and therefore
    /// its context is not available.

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (from != null && to != null) {
        setState(() => _selected = -1);
        await _animate(from, to);
      }

      setState(() => _selected = widget.selected);
    });
  }

  Future _animate(Rect begin, Rect end) async {
    if (_controller.isAnimating) {
      await _controller.fling(velocity: 2);
    }

    final axis = _getAxis(begin.center, end.center);
    final expanded = begin.expandToInclude(end);
    final firstHalfFinalSize = axis == Axis.vertical
        ? Size(begin.width, expanded.height)
        : Size(expanded.width, begin.height);

    _size = TweenSequence([
      TweenSequenceItem(
          tween: SizeTween(
            begin: begin.size,
            end: firstHalfFinalSize,
          ),
          weight: 50),
      TweenSequenceItem(
          tween: SizeTween(
            begin: firstHalfFinalSize,
            end: end.size,
          ),
          weight: 100),
    ]).animate(
        CurvedAnimation(curve: widget.animationCurve, parent: _controller));

    _alignment = TweenSequence([
      TweenSequenceItem(
          tween: AlignmentTween(
            begin: begin.center.toAlignment(),
            end: expanded.center.toAlignment(),
          ),
          weight: 50),
      TweenSequenceItem(
          tween: AlignmentTween(
            begin: expanded.center.toAlignment(),
            end: end.center.toAlignment(),
          ),
          weight: 100),
    ]).animate(
        CurvedAnimation(curve: widget.animationCurve, parent: _controller));

    try {
      await _controller.forward(from: 0);
    } on TickerCanceled {
      // The animation got canceled, probably because it was disposed of.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InheritedSticksSurface(
          sticksKeys: _sticksKeys,
          stickBuilder: widget.stickBuilder,
          selected: _selected,
          child: widget.child,
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isCompleted ||
                _controller.isDismissed ||
                !_controller.isAnimating) {
              return const SizedBox.shrink();
            }

            final width = _size!.value!.width;
            final height = _size!.value!.height;
            final child = widget.stickBuilder(
                context, StickType.worm, Size(width, height));

            return Positioned(
              left: _alignment!.value!.x - (width / 2),
              top: _alignment!.value!.y - (height / 2),
              child: child,
            );
          },
        )
      ],
    );
  }
}

/// Used to contact with [CrawlStickSurface] from [Stick]
/// when [Stick.show] changed.
class InheritedSticksSurface extends InheritedWidget {
  const InheritedSticksSurface({
    super.key,
    required super.child,
    required this.sticksKeys,
    required this.selected,
    required this.stickBuilder,
  });

  final List<GlobalKey> sticksKeys;
  final StickBuilder stickBuilder;
  final int selected;

  @override
  bool updateShouldNotify(InheritedSticksSurface oldWidget) {
    return !listEquals(sticksKeys, oldWidget.sticksKeys) ||
        selected != oldWidget.selected ||
        stickBuilder != oldWidget.stickBuilder;
  }
}

class Stick extends StatelessWidget {
  const Stick({
    super.key,
    required this.index,
  }) : assert(index >= 0, 'Stick index must be greater or equal to 0');

  final int index;

  @override
  Widget build(BuildContext context) {
    final surface = CrawlStickSurface.of(context);
    final visible = surface.selected == index;

    assert(index < surface.sticksKeys.length,
        'Stick index was out of range for neares CrawlStickSurface with sticksCount set to ${surface.sticksKeys.length}');

    return KeyedSubtree(
      key: surface.sticksKeys[index],
      child: surface.stickBuilder(
          context, visible ? StickType.visible : StickType.hidden, null),
    );
  }
}

extension on BuildContext {
  Rect getContextBoundingBox(BuildContext surfaceContext) {
    final box = findRenderObject() as RenderBox;
    final globalPosition = box.localToGlobal(Offset.zero);
    final surfaceBox = surfaceContext.findRenderObject() as RenderBox;
    final onSurfacePosition = surfaceBox.globalToLocal(globalPosition);
    final size = box.size;
    final stickGeometry = onSurfacePosition & size;

    return stickGeometry;
  }
}

extension on Offset {
  Alignment toAlignment() => Alignment(dx, dy);
}
