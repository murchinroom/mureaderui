import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ************************ Local Storage ************************

class Book {
  String? title;
  String? author;
  String? file;

  Book({this.title, this.author, this.file});

  int get hashCode => Object.hash(title, author, file);

  // object is not automatically json encodable:
  //   https://github.com/dart-lang/sdk/issues/18960
  // fix:
  //   https://stackoverflow.com/a/62197836

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'file': file,
      };

  Book.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        author = json['author'],
        file = json['file'];
}

/// Reading a Book.
class Reading {
  String ID; // int cannot be used as a json key

  Book book;

  // int? currentOffset;  // 可由 currentPage 和 pagination.charsInPages 计算得到
  int? currentPage;

  Pagination? _pagination;

  Pagination? get pagination => _pagination;

  set pagination(Pagination? value) {
    repaginate(value);
  }

  History? history;

  Reading(this.book, {this.currentPage, this.history})
      : ID = book.hashCode.toString();

  int? currentOffset() {
    if (currentPage == null) {
      return null;
    }
    return pageToOffset(currentPage!);
  }

  int? pageToOffset(int pageNumber) {
    if (pagination != null && pagination?.pages == null) {
      pagination?.rebuildPages(book.file ?? "");
    }
    return pagination?.pages
        ?.sublist(0, pageNumber)
        // 精妙关系: 切到 pageNumber 则 offsetToPage 里是 if (sumLen > offset)
        // 切到 pageNumber + 1 则 offsetToPage 里是 if (sumLen >= offset)
        .map((page) => page.length)
        .reduce((sumLen, pageLen) => sumLen + pageLen);
  }

  int? offsetToPage(int offset) {
    if (pagination != null && pagination?.pages == null) {
      pagination?.rebuildPages(book.file ?? "");
    }
    int sumLen = 0;
    for (int i = 0; i < pagination!.pages!.length; i++) {
      sumLen += pagination!.pages![i].length;
      // 精妙关系: (sumLen > offset) 则 pageToOffset 切片到 pageNumber
      // (sumLen >= offset) 则 pageToOffset 切片到 pageNumber + 1
      if (sumLen > offset) {
        return i;
      }
    }
    return null;
  }

  /// repaginate 为 Reading 设置新的 Pagination，
  /// 新分页下的 currentPage 保持原来看到的位置（是看到的位置，不是原来的页码）。
  ///
  /// e.g.
  /// 原来一页 100 个字，看到第 6 页（即第 600 字的位置）
  /// 设置新的分页，一页 200 个字，this.currentPage 会更新为 3: 还是第 600 字的位置。
  void repaginate(Pagination? newPagination) {
    if (newPagination == null) {
      return;
    }

    final oldPagination = pagination;

    // new

    if (oldPagination == null) {
      newPagination.rebuildPages(book.file ?? "");
      this._pagination = newPagination;
      this.currentPage = 0;
      return;
    }

    // update

    if (oldPagination.pages == null) {
      oldPagination.rebuildPages(book.file ?? "");
    }

    final offset = currentOffset(); // get offset by old pagination
    this._pagination = newPagination; // use new pagination
    this.currentPage = offsetToPage(offset ?? 0); // offset => new page number
  }

  // object is not automatically json encodable:
  //   https://github.com/dart-lang/sdk/issues/18960
  // fix:
  //   https://stackoverflow.com/a/62197836

  Map<String, dynamic> toJson() => {
        'ID': ID,
        'book': book.toJson(),
        'currentPage': currentPage,
        'pagination': pagination?.toJson(),
        'history': history?.toJson(),
      };

  Reading.fromJson(Map<String, dynamic> json)
      : ID = json['ID'],
        book = Book.fromJson(json['book']),
        currentPage = json['currentPage'],
        _pagination = Pagination.fromJson(json['pagination']),
        history = History.fromJson(json['history']);
}

class Pagination {
  int? charsPerLine;
  int? linesPerPage;

  /// 从索引 1 开始放内容，和现实世界的页码对应: pages[0] is left empty ('').
  List<String>? pages;

  // List<int>? charsInPages;  // 可用 pages.map((p) => p.length) 计算得到

  Pagination({this.charsPerLine, this.linesPerPage, this.pages});

  /// Pagination.fromUI splits text of book (String) into pages (List<String>),
  /// regarding the widget's width, height and textStyle.
  Pagination.fromUI(
      String text, double width, double height, TextStyle textStyle) {
    // print("paging: width = $width, height = $height");

    final TextPainter textPainter1 = TextPainter(
      text: TextSpan(
        text: '十',
        style: textStyle,
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: width);

    // print("paging: textPainter1.width = ${textPainter1.width} textPainter1.height = ${textPainter1.height}");

    // MAGIC! DO NOT TOUCH!
    final charWidth = max(textPainter1.width, textPainter1.height);
    // 就离谱，直接在 widget build 里算就要 * 1.5，挪到这边就刚好不用了。。
    // final charHeight = charWidth * 1.5;
    final charHeight = charWidth * 1.0;

    // print("paging: charWidth = $charWidth, charHeight = $charHeight");

    final int charsPerLine = (width / charWidth).floor();
    final int linesPerPage = (height / charHeight).floor();

    // print("paging: charsPerLine = $charsPerLine, linesPerPage = $linesPerPage");

    final pages = textToPages(text, charsPerLine, linesPerPage);

    // return Pagination(
    //   charsPerLine: charsPerLine,
    //   linesPerPage: linesPerPage,
    //   pages: pages,
    // );
    this.charsPerLine = charsPerLine;
    this.linesPerPage = linesPerPage;
    this.pages = pages;
  }

  /// textToPages splits text of book (String) into pages (List<String>),
  /// regarding charsPerLine and linesPerPage.
  static List<String> textToPages(
      String text, int charsPerLine, int linesPerPage) {
    List<String> pages = ['']; // pages[0] is left.
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

  /// rebuildPages rebuilds pages from text,
  /// regarding its charsPerLine and linesPerPage.
  ///
  /// This should be called after fromJson.
  void rebuildPages(String text) {
    if (charsPerLine == null || linesPerPage == null) {
      return;
    }
    pages = textToPages(text, charsPerLine!, linesPerPage!);
  }

  // object is not automatically json encodable:
  //   https://github.com/dart-lang/sdk/issues/18960
  // fix:
  //   https://stackoverflow.com/a/62197836
  // note:
  //   pages 可由 Book 中存有原始文本和 textToPages 方法重新计算得到，不再冗余存储。

  Map<String, dynamic> toJson() => {
        'charsPerLine': charsPerLine,
        'linesPerPage': linesPerPage,
        // 'pages': pages,
      };

  Pagination.fromJson(Map<String, dynamic>? json)
      : charsPerLine = json?['charsPerLine'],
        linesPerPage = json?['linesPerPage'];
// pages = json?['pages'];
}

class History {
  DateTime? lastRead;

  // object is not automatically json encodable:
  //   https://github.com/dart-lang/sdk/issues/18960
  // fix:
  //   https://stackoverflow.com/a/62197836

  Map<String, dynamic> toJson() => {
        'lastRead': lastRead?.toIso8601String(),
      };

  History.fromJson(Map<String, dynamic>? json)
      : lastRead =
            DateTime.parse(json?['lastRead'] ?? '1969-07-20T20:18:04.000Z');
}

// ******************** Remote Procedure Call  ********************

class MurecomRequest {
  List<String> prevPages;
  List<String> currentPages; // 虽然但是真的不是 String? currentPage 嘛 😂
  List<String> nextPages;

  MurecomRequest(this.prevPages, this.currentPages, this.nextPages);

  // JSON encode / decode

  Map<String, dynamic> toJson() => {
        'prevPages': prevPages,
        'currentPages': currentPages,
        'nextPages': nextPages,
      };

  MurecomRequest.fromJson(Map<String, dynamic>? json)
      : prevPages = json?['prevPages'],
        currentPages = json?['currentPages'],
        nextPages = json?['nextPages'];
}

class MurecomResponse {
  Music? music;

  MurecomResponse({this.music});

  // JSON encode / decode

  Map<String, dynamic> toJson() => {
        'music': music?.toJson(),
      };

  MurecomResponse.fromJson(Map<String, dynamic>? json)
      : music = Music.fromJson(json?['music']);
}

class Music {
  String? title;
  String? artist;
  String? coverImage;
  String? sourceUrl;

  Music({this.title, this.artist, this.coverImage, this.sourceUrl});

  // JSON encode / decode

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'coverImage': coverImage,
        'sourceUrl': sourceUrl,
      };

  Music.fromJson(Map<String, dynamic>? json)
      : title = json?['title'],
        artist = json?['artist'],
        coverImage = json?['coverImage'],
        sourceUrl = json?['sourceUrl'];
}

// *********************** Example Instances ***********************

Future<String> readAssetFile(String path) async {
  return await rootBundle.loadString(path);
}

Future<Book> exampleBookH2G2() async {
  final h2g2 = Book(
    title: "银河系漫游指南",
    author: "道格拉斯·亚当斯",
    // file: File("assets/h2g2.txt").readAsStringSync(),
    file: await readAssetFile("assets/h2g2.txt"),
  );

  return h2g2;
}

Future<Book> exampleBookTROE() async {
  final troe = Book(
    title: "安迪密恩的觉醒",
    author: "丹·西蒙斯",
    file: await readAssetFile("assets/troe.txt"),
  );

  return troe;
}

Future<List<Book>> exampleBooks() async {
  return [await exampleBookH2G2(), await exampleBookTROE()];
}

Future<Map<String, Reading>> exampleReadings() async {
  return {
    for (var e in (await exampleBooks()).map((book) => Reading(book))) e.ID: e
  };
}

final Music exampleMusicBWV532 = Music(
  title: "前奏曲与赋格 BWV 532 前奏曲（节录）",
  artist: "约翰·塞巴斯蒂安·巴赫",
  coverImage: "https://en.wikipedia.org/wiki/File:Johann_Sebastian_Bach.jpg",
  sourceUrl:
      "https://upload.wikimedia.org/wikipedia/commons/8/83/Auferstehung_Hannover_Orgel_BWV_532.ogg",
);

final Music exampleMusicBWV1067 = Music(
  title: "第二号管弦组曲 谐谑曲",
  artist: "约翰·塞巴斯蒂安·巴赫",
  coverImage: "https://zh.wikipedia.org/wiki/File:Bach_Window_Thomaskirche.jpg",
  sourceUrl:
      "https://upload.wikimedia.org/wikipedia/commons/9/97/Bach%2C_Johann_Sebastian_-_Suite_No.2_in_B_Minor_-_X._Badinerie.ogg",
);

final exampleMusics = [exampleMusicBWV532, exampleMusicBWV1067];
