library crawl_sticker;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

extension on Completer {
  void safeComplete() => isCompleted ? Future.value() : complete();
}

extension on Offset {
  Alignment toAlignment() => Alignment(dx, dy);
}

typedef SameStickBuilder = Widget Function(double width, double height);

class CrawlStickSurface extends StatefulWidget {
  const CrawlStickSurface({
    super.key,
    required this.child,
    required this.duration,
    required this.curve,
  });

  /// The child in which the [StickWidget]s must be placed anywhere to create
  /// sticks transition.
  ///
  /// The [StickWidget]s widgets must be located on the same axis, and this
  /// axis must coincide with [axis].
  final Widget child;

  /// The transition curve.
  final Curve curve;

  /// The transition duration.
  final Duration duration;

  static InheritedSticksSurface of(BuildContext context) {
    final InheritedSticksSurface? result = context.dependOnInheritedWidgetOfExactType<InheritedSticksSurface>();
    assert(result != null, 'No _SticksCollector found in context');
    return result!;
  }

  @override
  State<CrawlStickSurface> createState() => CrawlStickSurfaceState();
}

class CrawlStickSurfaceState extends State<CrawlStickSurface> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<Size?>? _size;
  Animation<Alignment?>? _alignment;
  late SameStickBuilder _sameStickBuilder;

  Completer? _built;
  Rect? _begin, _end;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = widget.duration;
  }

  static Axis _getAxis(Offset p1, Offset p2) {
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx).abs() * 180 / math.pi;

    assert(angle > 89 && angle < 91 || angle > 179 && angle < 181 || angle > -1 && angle < 1, '''
      StickWidgets must be placed in same axis each within same nearest SticksSurface.
      Some of your sticks are not. The angle between sticks centers was $angle
    ''');

    if (angle > 89 && angle < 91) {
      return Axis.vertical;
    }

    return Axis.horizontal;
  }

  Future _animate(Rect begin, Rect end) async {
    if (_controller.isAnimating) {
      await _controller.fling(velocity: 2);
    }

    final axis = _getAxis(begin.center, end.center);
    final expanded = begin.expandToInclude(end);
    final firstHalfFinalSize = axis == Axis.vertical ? Size(begin.width, expanded.height) : Size(expanded.width, begin.height);

    _size = TweenSequence([
      TweenSequenceItem(
          tween: SizeTween(
            begin: begin.size,
            end: firstHalfFinalSize,
          ),
          weight: 50
      ),
      TweenSequenceItem(
          tween: SizeTween(
            begin: firstHalfFinalSize,
            end: end.size,
          ),
          weight: 100
      ),
    ]).animate(CurvedAnimation(
        curve: widget.curve,
        parent: _controller
    ));

    _alignment = TweenSequence([
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: begin.center.toAlignment(),
          end: expanded.center.toAlignment(),
        ),
        weight: 50
      ),
      TweenSequenceItem(
          tween: AlignmentTween(
            begin: expanded.center.toAlignment(),
            end: end.center.toAlignment(),
          ),
          weight: 100
      ),
    ]).animate(CurvedAnimation(
        curve: widget.curve,
        parent: _controller
    ));

    try {
      await _controller.forward(from: 0);
    } on TickerCanceled {
      // The animation got canceled, probably because it was disposed of.
    }
  }

  Future handleStickShowChanged(Rect route, bool isDestination, SameStickBuilder sameStickBuilder) async {
    _sameStickBuilder = sameStickBuilder;
    if (isDestination) {
      _end = route;
    }
    else {
      _begin = route;
    }
    if (_end != null && _begin != null) {
      _built?.safeComplete();
      await _animate(_begin!, _end!);
      _begin = _end = null;
    }
    else {
      _built?.safeComplete();
      _built = Completer();
      await _built?.future;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InheritedSticksSurface(
          onShowChanged: handleStickShowChanged,
          animationDuration: widget.duration,
          child: widget.child,
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isCompleted || _controller.isDismissed || !_controller.isAnimating) {
              return const SizedBox.shrink();
            }

            final width = _size!.value!.width;
            final height = _size!.value!.height;
            final child = _sameStickBuilder(width, height);

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

/// Used to contact with [CrawlStickSurface] from [StickWidget]
/// when [StickWidget.show] changed.
class InheritedSticksSurface extends InheritedWidget {
  const InheritedSticksSurface({
    super.key,
    required super.child,
    required this.animationDuration,
    required this.onShowChanged,
  });

  /// The amount of needed to 'stick' from previously showed [StickWidget]
  /// to newly one.
  final Duration animationDuration;

  /// Passes a stick geometry, new [StickWidget.show] value and stick widget
  /// builder to a [CrawlStickSurface].
  /// The builder must return the same widget that it returns from build method.
  final Future Function(Rect, bool, SameStickBuilder) onShowChanged;

  @override
  bool updateShouldNotify(InheritedSticksSurface oldWidget) {
    return oldWidget.animationDuration != animationDuration &&
        oldWidget.onShowChanged != onShowChanged;
  }
}

class StickWidget extends StatefulWidget {
  const StickWidget({
    super.key,
    required this.show,
    required this.decoration,
  });

  final BoxDecoration decoration;
  final bool show;

  @override
  State<StickWidget> createState() => _StickWidgetState();
}

mixin CrawlStickGeometryEmitter<T extends StatefulWidget> on State<T> {
  bool _show = false;

  bool get statedShow;
  bool get show => _show;

  Widget buildSized(double width, double height);

  void emitShowChanged() async {
    final box = context.findRenderObject() as RenderBox;
    final globalPosition = box.localToGlobal(Offset.zero);
    final surface = context.findAncestorStateOfType<CrawlStickSurfaceState>();
    assert(surface != null, 'You must wrap any StickWidget into SticksSurface at any level deep');
    final surfaceBox = surface!.context.findRenderObject() as RenderBox;
    final onSurfacePosition = surfaceBox.globalToLocal(globalPosition);
    final size = box.size;
    final surfaceInhWidget = CrawlStickSurface.of(context);
    final stick = onSurfacePosition & size;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!statedShow) {
        setState(() => _show = statedShow);
      }

      await surfaceInhWidget.onShowChanged(stick, statedShow, buildSized);

      if (mounted) {
        setState(() => _show = statedShow);
      }
      else {
        _show = statedShow;
      }
    });
  }
}

class _StickWidgetState extends State<StickWidget> with CrawlStickGeometryEmitter {
  @override
  bool get statedShow => widget.show;

  @override
  void initState() {
    super.initState();
    _show = widget.show;
  }

  @override
  void didUpdateWidget(covariant StickWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.show != widget.show) {
      emitShowChanged();
    }
  }

  @override
  Widget buildSized(double width, double height) => Container(
    width: width,
    height: height,
    decoration: widget.decoration,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: show ? widget.decoration : null,
    );
  }
}