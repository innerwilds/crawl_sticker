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
    child: Column(
      children: [
        StickerWidget(
          decoration: decoration,
          show: false,
        ),
        StickerWidget(
          decoration: decoration,
          show: false,
        ),
        StickerWidget(
          decoration: decoration,
          show: true,
        ),
        StickerWidget(
          decoration: decoration,
          show: false,
        ),
        StickerWidget(
          decoration: decoration,
          show: false,
        ),
      ],
    ),
  );
}
```