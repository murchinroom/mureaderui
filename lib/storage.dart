import 'dart:convert';
import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:mureaderui/model.dart';

class ReadingStorage {
  Map<String, Reading>? readings;
  final storage = GetStorage("ReadingStorage");

  // ******** storage ops ********

  void readStorage() {
    final String? readingsJson = storage.read("readings");
    if (readingsJson != null) {
      final readingsMap = jsonDecode(readingsJson);
      readings = {};
      for (final key in readingsMap.keys) {
        readings![key] = Reading.fromJson(readingsMap[key]);
      }
    }

    // init
    if (readings?.isEmpty ?? true) {
      exampleReadings().then((value) {
        print("store exampleReadings cuz readings=$readings");
        readings = value;
        writeStorage();
      });
    }
  }

  void writeStorage() {
    // final readingsMap = readings?.map((key, value) {
    //   return MapEntry(key, value.toJson());
    // });
    final String readingsJson = json.encode(readings);

    storage.write("readings", readingsJson);
  }

  // ******** readingList crud ********

  // addReading 添加阅读一本新书
  Reading addReading(Book book) {
    readStorage();

    final newReading = Reading(book);

    if (readings == null) {
      readings = {newReading.ID: newReading};
    } else {
      readings![newReading.ID] = newReading;
    }

    writeStorage();

    return newReading;
  }

  Reading? getReading(String ID) {
    readStorage();

    if (readings == null) {
      return null;
    }

    return readings![ID];
  }

  List<Reading> getReadings(SortReadingBy sortReadingBy) {
    readStorage();

    if (readings == null) {
      return [];
    }

    final readingList = readings!.values.toList();

    // Google Bard told me that:
    // the compareTo() method will return 0 if either of the strings are null.
    // Therefore, it is not necessary to check if the fields are null.
    switch (sortReadingBy) {
      case SortReadingBy.title:
        readingList.sort((a, b) => a.book.title?.compareTo(b.book.title!) ?? 0);
        break;
      case SortReadingBy.author:
        readingList
            .sort((a, b) => a.book.author?.compareTo(b.book.author!) ?? 0);
        break;
      case SortReadingBy.lastRead:
        readingList.sort((b, a) => // reverse -> (b, a)
            a.history?.lastRead?.compareTo(b.history!.lastRead!) ?? 0);
        break;
    }

    return readingList;
  }

  void updateReading(String ID, Reading updated) {
    readStorage();

    if (readings == null) {
      return;
    }

    readings![ID] = updated;

    writeStorage();
  }

  void removeReading(String ID) {
    readStorage();

    if (readings == null) {
      return;
    }

    readings!.remove(ID);

    writeStorage();
  }
}

ReadingStorage readingStorage = ReadingStorage();

ReadingStorage getReadingStorage() {
  return readingStorage;
}

enum SortReadingBy {
  title,
  author,
  lastRead,
}
