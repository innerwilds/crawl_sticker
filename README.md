Create a crawl sticker indicator for your lists.

## Getting started
Install it via your favourite tool or:
```shell
dart pub add crawl_sticker
```

## Usage

```dart
final decoration = BoxDecoration(
  color: Colors.red,
);
Widget build(BuildContext context) {
  // Wrap [StickerWidget]s in [CrawlStickerSurface]
  // and change [StickerWidget.show] to crawl sticker on that surface like a worm.
  return CrawlStickerSurface(
    sticksCount: sticksCount,
    // Size available only when stick is building for crawling.
    stickBuilder: (context, StickType type, Size? size) {
      return Container(
        width: size?.width,
        height: size?.height,
        decoration: stickDecoration,
      );
    },
    // Reactive this
    selected: 2,
    child: Column(
      children: [
        SizedBox(
          width: 4,
          height: 4,
          // Stick itself uses stickBuilder from CrawlStickerSurface
          // so we wrap it with SizedBox to pass fixed constraints and make it all same sizes
          child: Stick(index: 0),
        ),
        SizedBox(
          width: 4,
          height: 4,
          child: Stick(index: 1),
        ),
        SizedBox(
          width: 4,
          height: 4,
          child: Stick(index: 2),
        ),
      ],
    ),
  );
}
```