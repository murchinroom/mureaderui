import 'package:get_storage/get_storage.dart';
import 'package:mureaderui/model.dart';

class ReadingStorage {
  Map<int, Reading>? readings;
  final storage = GetStorage("ReadingStorage");

  // ******** storage ops ********

  void readStorage() {
    readings = storage.read("readings");
  }

  void writeStorage() {
    storage.write("readings", readings);
  }

  // ******** readingList crud ********

  // addReading 添加阅读一本新书
  void addReading(Book book) {
    readStorage();

    final newReading = Reading(book);

    if (readings == null) {
      readings = {newReading.ID: newReading};
    } else {
      readings![newReading.ID] = newReading;
    }

    writeStorage();
  }

  Reading? getReading(int ID) {
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

    switch (sortReadingBy) {
      case SortReadingBy.title:
        readingList.sort((a, b) => a.book.title!.compareTo(b.book.title!));
        break;
      case SortReadingBy.author:
        readingList.sort((a, b) => a.book.author!.compareTo(b.book.author!));
        break;
      case SortReadingBy.lastRead:
        readingList.sort(
            (a, b) => a.history!.lastRead!.compareTo(b.history!.lastRead!));
        break;
    }

    return readingList;
  }

  void updateReading(int ID, Reading updated) {
    readStorage();

    if (readings == null) {
      return;
    }

    readings![ID] = updated;

    writeStorage();
  }

  void removeReading(int ID) {
    readStorage();

    if (readings == null) {
      return;
    }

    readings!.remove(ID);

    writeStorage();
  }
}

enum SortReadingBy {
  title,
  author,
  lastRead,
}
