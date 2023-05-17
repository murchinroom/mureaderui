import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mureaderui/model.dart';
import 'package:mureaderui/storage.dart';
import 'package:styled_widget/styled_widget.dart';

import 'bookreader.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

GlobalKey<_LibraryState> libraryKey = GlobalKey<_LibraryState>();

class _LibraryState extends State<Library> with RouteAware {
  // Library({super.key});

  var readingList = getReadingStorage().getReadings(SortReadingBy.lastRead);

  @override
  Widget build(BuildContext context) {
    if (readingList.isEmpty) {
      return const Center(child: CircularProgressIndicator()).padding(all: 32);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reading
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Reading", style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            TextButton(
                onPressed: () => {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const AlertDialog(
                              title: Text("TODO"),
                              content: Text("books library"),
                            );
                          })
                    },
                child: Text("more >"))
          ],
        ),
        // Books
        Row(
                children: readingList
                    .map((reading) => BookItem(reading: reading))
                    .toList())
            .scrollable(scrollDirection: Axis.horizontal),

        // Music
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Music", style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            TextButton(
                onPressed: () => {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const AlertDialog(
                              title: Text("TODO"),
                              content: Text("music library"),
                            );
                          })
                    },
                child: Text("more >"))
          ],
        ),
        MusicOverview(),
      ],
    ).scrollable(scrollDirection: Axis.vertical).padding(all: 8);
  }

  void updateUI() {
    print("Library: updateUI");
    setState(() {
      readingList = getReadingStorage().getReadings(SortReadingBy.lastRead);
    });
  }
}

class BookItem extends StatelessWidget {
  // Reading instead of Book: to modify the history!
  final Reading reading;
  final Book book;

  BookItem({super.key, required this.reading}) : book = reading.book;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Image.network("https://picsum.photos/200/30${Random().nextInt(9)}")
          .clipRRect(topLeft: 8, topRight: 8, bottomLeft: 0, bottomRight: 0)
          .limitedBox(
              maxWidth: 200, maxHeight: 280), // 微信读书 1:1.45, Apple Books 1:1.4
      Text(book.title ?? "Book Title",
              style: Theme.of(context).textTheme.titleSmall)
          .padding(top: 8, bottom: 2, horizontal: 8),
      Text(book.author ?? "Author",
              style: Theme.of(context).textTheme.bodySmall)
          .padding(top: 2, bottom: 8, horizontal: 8),
    ]).alignment(Alignment.center).card().gestures(onTap: () {
      print("book item tapped: ${book.hashCode}");

      reading.history?.lastRead = DateTime.now();
      getReadingStorage().updateReading(reading.ID, reading);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookReader(reading: reading)),
      );
    }).padding(all: 8);
  }
}

class MusicOverview extends StatelessWidget {
  const MusicOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Image.network("https://picsum.photos/200/200")
        //     .clipRRect(topLeft: 8, bottomLeft: 8)
        //     .limitedBox(maxWidth: 200, maxHeight: 200),
        MusicShelf(),
        Column(
          children: [
            Text("murecom for reading",
                    style: Theme.of(context).textTheme.titleSmall)
                .padding(all: 4),
            Text("When you are reading a book, music here will be played to help you focus.")
                .textAlignment(TextAlign.center)
                .padding(vertical: 4),
            Text("Music are recommended based on the emotion of the text you are reading.")
                .textAlignment(TextAlign.center),
          ],
        ).padding(all: 8).expanded(),
      ],
    )
        .card()
        .gestures(
            onTap: () => {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          title: Text("TODO"),
                          content: Text("music library"),
                        );
                      })
                })
        .padding(all: 8);
  }
}

/// 扁平的唱片架拟物：在这里用多张图片（库中音乐封面），竖条形排列 (川) 。
class MusicShelf extends StatelessWidget {
  const MusicShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Image.network("https://picsum.photos/200/200",
                width: 40, height: 200, fit: BoxFit.fitHeight)
            .clipRRect(topLeft: 8, bottomLeft: 8)
            .padding(right: 5),
        Image.network("https://picsum.photos/200/201",
                width: 40, height: 200, fit: BoxFit.fitHeight)
            .padding(right: 5),
        Image.network("https://picsum.photos/200/202",
                width: 40, height: 200, fit: BoxFit.fitHeight)
            .padding(right: 5),
        Image.network("https://picsum.photos/200/203",
                width: 40, height: 200, fit: BoxFit.fitHeight)
            .padding(right: 5),
        Image.network("https://picsum.photos/200/204",
            width: 40, height: 200, fit: BoxFit.fitHeight)
      ],
    );
  }
}

class AddBookView extends StatefulWidget {
  @override
  _AddBookViewState createState() => _AddBookViewState();
}

class _AddBookViewState extends State<AddBookView> {
  // AddBookView({super.key});

  String? _title;
  String? _author;
  String? _filename;
  String? _txtContent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("导入书籍", style: Theme.of(context).textTheme.headlineMedium),
        const Text("添加你喜欢的书开始阅读吧！😉").padding(top: 16, bottom: 32),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).buttonTheme.colorScheme?.onSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            labelText: 'Book Title',
            icon: const Icon(Icons.menu_book_rounded),
          ),
          onChanged: (value) {
            _title = value;
          },
        ).padding(vertical: 16),

        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).buttonTheme.colorScheme?.onSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            labelText: 'Author',
            icon: const Icon(Icons.person),
          ),
          onChanged: (value) {
            _author = value;
          },
        ).padding(vertical: 16),

        // text file: pickup
        if (_filename != null)
          TextField(
            decoration: InputDecoration(
                filled: true,
                fillColor:
                    Theme.of(context).buttonTheme.colorScheme?.onSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                labelText: "Txt File",
                icon: const Icon(Icons.description),
                suffixIcon: const Icon(Icons.done, color: Colors.greenAccent)),
            readOnly: true,
            enabled: false,
            controller: TextEditingController(text: _filename!),
          ).padding(vertical: 16)
        else
          SizedBox(
            width: 120,
            child: FloatingActionButton.extended(
                onPressed: () => _pickFiles(),
                label: Text('Pick file'),
                icon: const Icon(Icons.description)),
          ).padding(vertical: 16),

        ButtonBar(
          alignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => {Navigator.pop(context)},
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                print(
                    "add book submit: $_title, $_author, ${_txtContent?.length}");
                if (_title != null && _author != null && _txtContent != null) {
                  getReadingStorage().addReading(Book(
                    title: _title,
                    author: _author,
                    file: _txtContent,
                  ));

                  _LibraryState? libraryState = libraryKey.currentState;
                  libraryState?.updateUI();
                } else {
                  print("invalid input");
                  showToast(context, "invalid input");
                }
                Navigator.pop(context);
              },
              child: Text('添加'),
            ),
          ],
        ),
      ],
    ).padding(all: 32).card().padding(all: 32);
  }

  _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result == null) {
      return;
    }
    if (result.files.single.extension != "txt") {
      showToast(context, "only support txt file");
      return;
    }

    setState(() {
      _filename = result.files.single.name;
      // _txtContent = result.files.single.bytes.toString();
      _txtContent = utf8.decode(result.files.single.bytes!);
    });
  }
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ),
  );
}
