import 'dart:io';

import 'package:flutter/foundation.dart';

// ************************ Local Storage ************************

class Book {
  String? title;
  String? author;
  String? file;

  Book({this.title, this.author, this.file});

  int get hashCode => Object.hash(title, author, file);
}

/// Reading a Book.
class Reading {
  int ID;

  Book book;

  // int? currentOffset;  // 可由 currentPage 和 pagination.charsInPages 计算得到
  int? currentPage;

  Pagination? pagination;

  History? history;

  Reading(this.book, {this.currentPage, this.pagination, this.history})
      : ID = book.hashCode;

  int? currentOffset() {
    if (currentPage == null) {
      return null;
    }
    return pagination?.pages
        ?.sublist(0, currentPage! + 1)
        .map((page) => page.length)
        .reduce((sumLen, pageLen) => sumLen + pageLen);
  }
}

class Pagination {
  int? charsPerLine;
  int? linesPerPage;

  List<String>? pages;

  // List<int>? charsInPages;  // 可用 pages.map((p) => p.length) 计算得到

  Pagination({this.charsPerLine, this.linesPerPage, this.pages});
}

class History {
  DateTime? lastRead;
}

// ******************** Remote Procedure Call  ********************

class MurecomRequest {
  List<String> prevPages;
  List<String> currentPages; // 虽然但是真的不是 String? currentPage 嘛 😂
  List<String> nextPages;

  MurecomRequest(this.prevPages, this.currentPages, this.nextPages);
}

class MurecomResponse {
  Music? music;

  MurecomResponse({this.music});
}

class Music {
  String? title;
  String? artist;
  String? coverImage;
  String? sourceUrl;

  Music({this.title, this.artist, this.coverImage, this.sourceUrl});
}

// *********************** Example Instances ***********************

final Book exampleBookH2G2 = Book(
  title: "银河系漫游指南",
  author: "道格拉斯·亚当斯",
  file: File("assets/h2g2.txt").readAsStringSync(),
);

final Book exampleBookTROE = Book(
  title: "安迪密恩的觉醒",
  author: "丹·西蒙斯",
  file: File("assets/troe.txt").readAsStringSync(),
);

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
