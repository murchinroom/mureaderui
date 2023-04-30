import 'package:flutter/material.dart';
import 'package:mureaderui/model.dart';
import 'package:mureaderui/storage.dart';
import 'package:styled_widget/styled_widget.dart';

import 'bookreader.dart';

class Library extends StatelessWidget {
  Library({super.key});

  final readingList = getReadingStorage().getReadings(SortReadingBy.lastRead);

  @override
  Widget build(BuildContext context) {
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
}

class BookItem extends StatelessWidget {
  // Reading instead of Book: to modify the history!
  final Reading reading;
  final Book book;

  BookItem({super.key, required this.reading}) : book = reading.book;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Image.network("https://picsum.photos/200/300")
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
        Image.network("https://picsum.photos/200/200",
                width: 40, height: 200, fit: BoxFit.fitHeight)
            .padding(right: 5),
        Image.network("https://picsum.photos/200/200",
                width: 40, height: 200, fit: BoxFit.fitHeight)
            .padding(right: 5),
        Image.network("https://picsum.photos/200/200",
                width: 40, height: 200, fit: BoxFit.fitHeight)
            .padding(right: 5),
        Image.network("https://picsum.photos/200/200",
            width: 40, height: 200, fit: BoxFit.fitHeight)
      ],
    );
  }
}
