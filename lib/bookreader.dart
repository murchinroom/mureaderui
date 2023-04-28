import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

class BookReader extends StatefulWidget {
  @override
  _BookReaderState createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> {
  TextStyle textStyle = TextStyle(fontSize: 20.0);
  String bookText = '';
  PageController pageController = PageController();
  int currentPage = 0;
  List<String> pages = ["Book Title"];
  bool pagenated = false;
  final scaffoldState = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _readBook();
  }

  void _readBook() {
    String bookPath = 'assets/h2g2.txt';
    // File bookFile = File(bookPath);
    // String bookText = bookFile.readAsStringSync();
    DefaultAssetBundle.of(context).loadString(bookPath).then((String value) {
      setState(() {
        bookText = value;
      });
    });
    // bookText = "Hello World\nThis is a test\nThis is only a test";

    setState(() {
      currentPage = currentPage;
      pageController = pageController;
    });
  }

  void bookToPages() {
    // split the book text into pages: By CharsPerPage()
    // int charsPerPage = CharsPerPage(
    //     textStyle, context.size?.width ?? 0, context.size?.height ?? 0);
    // print("charsPerPage = $charsPerPage");
    pages.addAll(splitText(bookText));
  }

  List<String> splitText(String text) {
    var width = context.size?.width ?? 0;
    var height = context.size?.height ?? 0;

    print("paging: width = $width, height = $height");

    final TextPainter textPainter1 = TextPainter(
      text: TextSpan(
        text: '十',
        style: textStyle,
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: width);

    print(
        "paging: textPainter1.width = ${textPainter1.width} textPainter1.height = ${textPainter1.height}");

    // MAGIC! DO NOT TOUCH!
    final charWidth = max(textPainter1.width, textPainter1.height);
    final charHeight = charWidth * 1.5;

    print("paging: charWidth = $charWidth, charHeight = $charHeight");

    final int charsPerLine = (width / charWidth).floor();
    final int linesPerPage = (height / charHeight).floor();

    print("paging: charsPerLine = $charsPerLine, linesPerPage = $linesPerPage");

    List<String> pages = [];
    String page = '';
    int charsLeftInLine = charsPerLine;
    int linesLeftInPage = linesPerPage;
    for (int i = 0; i < text.length;) {
      // case 0: new page
      if (linesLeftInPage == 0) {
        pages.add(page);
        linesLeftInPage = linesPerPage;
        charsLeftInLine = charsPerLine;
        page = '';
        continue;
      }
      // case 1: new line (enter)
      if (charsLeftInLine == 0) {
        linesLeftInPage--;
        charsLeftInLine = charsPerLine;
        // page += '\n';
        continue;
      }
      // case 2: new paragraph -> append & enter
      if (text[i] == '\n') {
        page += text[i];
        charsLeftInLine = 0;
        i++;
        continue;
      }
      // case 3: normal char -> append
      page += text[i];
      charsLeftInLine--;
      i++;
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Reader'),
      ),
      body: GestureDetector(
        onTapDown: (details) {
          if (!pagenated) {
            bookToPages();
            pagenated = true;
          }
          final x = details.globalPosition.dx;
          final width = context.size?.width ?? 0;
          print('x = $x, width = $width');

          if (x > (width / 2)) {
            if (currentPage < pages.length - 1) {
              currentPage++;
              // pageController.animateToPage(currentPage,
              //     duration: const Duration(milliseconds: 500),
              //     curve: Curves.easeIn);
              pageController.jumpToPage(currentPage);
            } else {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const Library()),
              // );
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('End of Book'),
                    content: Text('You have reached the end of the book.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          } else {
            if (currentPage > 0) {
              currentPage--;

              // pageController.animateToPage(currentPage,
              //     duration: const Duration(milliseconds: 500),
              //     curve: Curves.easeIn);
              pageController.jumpToPage(currentPage);
            } else {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const Library()),
              // );
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Beginning of Book'),
                    content:
                        Text('You have reached the beginning of the book.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          }
        },
        child: PageView.builder(
          controller: pageController,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(getPageText(index), style: textStyle),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return const Center(
                  child: ControlPanel(),
                ).clipRRect(all: 16);
              });
        },
        child: const Icon(Icons.subject),
        // backgroundColor: Colors.green,
      ),
    );
  }

  String getPageText(int index) {
    if (index < pages.length) {
      return pages[index];
    } else {
      return '[EOF]';
    }
  }
}

class ControlPanel extends StatefulWidget {
  const ControlPanel({Key? key}) : super(key: key);

  @override
  _ControlPanelState createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Music Card
        Row(children: [
          Image.network("https://picsum.photos/200/200",
                  width: 150, height: 150, fit: BoxFit.contain)
              .clipRRect(topLeft: 16, bottomLeft: 16)
              .padding(right: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hunch Gray", style: Theme.of(context).textTheme.labelLarge),
              Text("ZUTOMAYO", style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const Spacer(),
          Row(children: [
            IconButton(
                icon: const Icon(Icons.pause_rounded),
                onPressed: () => {simpleAlert(context, "TODO", "pause")},
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Theme.of(context)
                        .buttonTheme
                        .colorScheme
                        ?.onSecondary))),
            const SizedBox(width: 8),
            IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: () => {simpleAlert(context, "TODO", "next")},
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Theme.of(context)
                        .buttonTheme
                        .colorScheme
                        ?.onSecondary))),
          ]).padding(horizontal: 8),
        ])
            .card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)))
            .padding(horizontal: 16, top: 16, bottom: 8),

        // Search in the book
        // InputChip(label: Text("Search in the book")),
        TextField(
          decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).buttonTheme.colorScheme?.onSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              suffixIcon: Icon(Icons.search),
              labelText: 'Search in the book',
              labelStyle: Theme.of(context).textTheme.labelMedium),
        ).padding(horizontal: 16, vertical: 8),

        // Reader Theme
        TextButton(
            child: Row(children: [
              Text("Font & Theme",
                  style: Theme.of(context).textTheme.labelMedium),
              Spacer(),
              Icon(Icons.text_fields),
            ]).padding(all: 8),
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                    Theme.of(context).buttonTheme.colorScheme?.onSecondary)),
            // 太优雅了吧！设置个破颜色，简直就是工业奇迹！
            onPressed: () => {
                  simpleAlert(context, "TODO", "Theme")
                }).padding(horizontal: 16, vertical: 8),

        // Buttons
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TextButton(
              onPressed: () => {simpleAlert(context, "TODO", "share")},
              child: Icon(Icons.share).padding(horizontal: 32, vertical: 8),
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      Theme.of(context).buttonTheme.colorScheme?.onSecondary))),
          TextButton(
              onPressed: () => {simpleAlert(context, "TODO", "info")},
              child: Icon(Icons.info).padding(horizontal: 32, vertical: 8),
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      Theme.of(context).buttonTheme.colorScheme?.onSecondary))),
          TextButton(
              onPressed: () => {simpleAlert(context, "TODO", "bookmark")},
              child: Icon(Icons.bookmark).padding(horizontal: 32, vertical: 8),
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      Theme.of(context).buttonTheme.colorScheme?.onSecondary)))
        ]).padding(horizontal: 16, top: 8, bottom: 16)
      ],
    ).padding(all: 16);
  }
}

void simpleAlert(BuildContext context, String title, String? content) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(title: Text(title), content: Text(content ?? ""));
    },
  );
}
