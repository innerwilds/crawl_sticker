import 'dart:math';

import 'package:crawl_sticker/crawl_sticker.dart';
import 'package:flutter/material.dart';

final random = Random();
const decoration = BoxDecoration(
  color: Colors.red,
);

int rndc() => random.nextInt(106) + 150;

void main() {
  runApp(const CrawlStickerExampleApp());
}

class CrawlStickerExampleApp extends StatelessWidget {
  const CrawlStickerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    int selected = 0;
    int milliseconds = 200;
    ValueNotifier<Axis> axisNotifier = ValueNotifier(Axis.horizontal);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crawl Sticker Demo',
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Just tap on some item'),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Row(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text('List view axis: '),
                              ValueListenableBuilder(
                                valueListenable: axisNotifier,
                                builder: (context, value, _) {
                                  return SegmentedButton(
                                    onSelectionChanged: (axises) {
                                      axisNotifier.value = axises.first;
                                    },
                                    segments: const [
                                      ButtonSegment(
                                        value: Axis.vertical,
                                        icon: Icon(Icons.arrow_downward),
                                        label: Text('Vertical'),
                                      ),
                                      ButtonSegment(
                                        value: Axis.horizontal,
                                        icon: Icon(Icons.arrow_right_alt),
                                        label: Text('Horizontal'),
                                      ),
                                    ],
                                    selected: {value},
                                    multiSelectionEnabled: false,
                                    emptySelectionAllowed: false,
                                  );
                                },
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 10),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text('Animation duration: '),
                              Slider(
                                min: 50,
                                max: 1000,
                                label: 'Milliseconds',
                                value: milliseconds.toDouble(),
                                onChanged: (double value) {
                                  setState(() => milliseconds = value.toInt());
                                },
                              ),
                              Text('${milliseconds.toInt().toString().padLeft(4, '#')}ms')
                            ],
                          )
                        ],
                      );
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return CrawlStickSurface(
                    sticksCount: 50,
                    selected: selected,

                    animationDuration: Duration(milliseconds: milliseconds.toInt()),
                    animationCurve: Curves.ease,

                    stickBuilder: (BuildContext context, StickType type, Size? size) {
                      const indicatorDecoration = BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        color: Colors.red,
                      );
                      const wormDecoration = BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        color: Colors.green,
                      );
                      return Container(
                        width: size?.width,
                        height: size?.height,
                        decoration: switch (type) {
                          StickType.visible => indicatorDecoration,
                          StickType.worm => wormDecoration,
                          StickType.hidden => null,
                        },
                      );
                    },

                    child: ValueListenableBuilder(
                      valueListenable: axisNotifier,
                      builder: (context, value, _) {
                        final tiles = List.generate(value == Axis.vertical ? 50 : 4, (i) {
                          final stick = Stick(
                            index: i,
                            builder: i % 2 == 0 ? (context, type) {
                              return type == StickType.visible ? const Icon(Icons.adb, size: 16) : const SizedBox.expand();
                            } : null,
                          );
                          return IntrinsicWidth(
                            child: IntrinsicHeight(
                              child: TextButton(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: value == Axis.vertical ? Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: stick,
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                      ),
                                      Text('Item $i'),
                                    ],
                                  ) : Column(
                                    children: [
                                      Text('Item $i'),
                                      const Padding(
                                        padding: EdgeInsets.only(top: 6),
                                      ),
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: stick,
                                      ),
                                    ],
                                  ),
                                ),
                                onPressed: () => setState(() => selected = i),
                              ),
                            ),
                          );
                        });

                        return CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: value == Axis.vertical ?
                                Column(children: tiles, crossAxisAlignment: CrossAxisAlignment.stretch) :
                                Row(children: tiles, mainAxisAlignment: MainAxisAlignment.spaceBetween),
                            )
                          ],
                        );
                      },
                    )
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}