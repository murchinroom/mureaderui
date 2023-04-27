import 'package:html/parser.dart' show parse;
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:epub_view/epub_view.dart';

class MyEpubReader extends StatefulWidget {
  @override
  _MyEpubReaderState createState() => _MyEpubReaderState();
}

class _MyEpubReaderState extends State<MyEpubReader> {
  late EpubController _epubController;

  @override
  void initState() {
    super.initState();
    _epubController = EpubController(
      // Load document
      document: EpubDocument.openAsset('assets/h2g2.epub'),
      // Set start point
      // epubCfi: 'epubcfi(/6/6[chapter-2]!/4/2/1612)',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Show actual chapter name
        title: EpubViewActualChapter(
            controller: _epubController,
            builder: (chapterValue) => Text(
                  'Chapter: ' +
                      (chapterValue?.chapter?.Title
                              ?.replaceAll('\n', '')
                              .trim() ??
                          ''),
                  textAlign: TextAlign.start,
                )),
      ),
      // Show table of contents
      drawer: Drawer(
        child: EpubViewTableOfContents(
          controller: _epubController,
        ),
      ),
      // Show epub document
      body: EpubView(
        controller: _epubController,
        onChapterChanged: (value) {
          print('chapter changed: '
              '${value?.chapterNumber}::${value?.paragraphNumber}::${value?.progress}::${value?.position}');
          var document = value?.chapter?.HtmlContent;
          var html = parse(document);
          var paragraph = html.body?.children[value!.paragraphNumber];
          print(paragraph?.text);
        },
      ),
      floatingActionButton: FloatingActionButton.small(onPressed: () {
        var epubCfi = _epubController.generateEpubCfi() ?? '';
        print(epubCfi);
        _epubController.jumpTo(index: _epubController.currentValue?.position.index ?? 0 + 1, );
      }),
    );
    // return EpubView(controller: _epubController);
  }
}
