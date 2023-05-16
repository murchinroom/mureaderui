import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mureaderui/api.dart';
import 'package:mureaderui/model.dart';
import 'package:mureaderui/storage.dart';
import 'package:styled_widget/styled_widget.dart';

class BookReader extends StatefulWidget {
  final Reading reading;

  const BookReader({super.key, required this.reading});

  @override
  _BookReaderState createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> {
  TextStyle textStyle = TextStyle(fontSize: 20.0);
  PageController pageController = PageController();

  // Size? pageSize;
  // TextStyle? pageTextStyle;

  bool pagenated = false;
  final scaffoldState = GlobalKey<ScaffoldState>();

  final player = AudioPlayer();
  Music? playingMusic;

  @override
  void initState() {
    super.initState();
    _initPageController();
    _initPlayer();
  }

  void _initPageController() {
    // 依据 pageController 的 page 变化来自动
    // update reading.currentPage in storage
    pageController.addListener(() {
      if (pageController.page != null) {
        final pg = pageController.page;
        final round = pageController.page!.round();

        if (pg == round /* 是个整数 */) {
          print("$pageController: ${pageController.page}: update reading page");
          widget.reading.currentPage = pageController.page!.round();
          updateReadingStorage();
        }
      }
    });

    // pageController = pageController;

    // Cannot get size during build.
    // widget.reading.repaginate(Pagination.fromUI(widget.reading.book.file ?? "",
    //     context.size?.width ?? 0, context.size?.height ?? 0, textStyle));
    // updateReadingStorage();
    // pageController.jumpToPage(widget.reading.currentPage ?? 0);
  }

  void _initPlayer() {
    player.onPlayerComplete.listen((_) async {
      await playNextSong();
    });
    // TODO: first song
    // player.play(UrlSource(exampleMusic[0]));
    playNextSong();
  }

  void updateReadingStorage() {
    getReadingStorage().updateReading(widget.reading.ID, widget.reading);
  }

  void paginate(Size size, TextStyle textStyle) {
    widget.reading.repaginate(Pagination.fromUI(
        widget.reading.book.file ?? "", size.width, size.height, textStyle));
    updateReadingStorage();
  }

  /// _recommendNextSong 用 currentPage 及其前 2、后 3 页的文本内容作为参数，
  /// 调用 api.murecom 推荐下一首音乐。
  Future<Music?> _recommendNextSong() async {
    final currentPage = widget.reading.currentPage;

    List<String> prevPages;
    if ((currentPage ?? 0) > 2) {
      prevPages = widget.reading.pagination?.pages
              ?.sublist(currentPage! - 2, currentPage + 0) ??
          [];
    } else {
      prevPages = [];
    }

    List<String> currentPages;
    if (currentPage != null) {
      currentPages = [widget.reading.pagination?.pages?[currentPage] ?? ""];
    } else {
      currentPages = [];
    }

    List<String> nextPages;
    final length = widget.reading.pagination?.pages?.length ?? 0;
    if (length - (currentPage ?? length) > 3) {
      nextPages = widget.reading.pagination?.pages
              ?.sublist(currentPage! + 1, currentPage + 4) ??
          [];
    } else {
      nextPages = [];
    }

    final resp =
        await murecom(MurecomRequest(prevPages, currentPages, nextPages));
    return resp.music;
  }

  /// playNextSong = _recommendNextSong + player.play + playingMusic 状态维护
  Future<void> playNextSong() async {
    var nextSong = await _recommendNextSong();
    if (nextSong == null || nextSong.sourceUrl == null) {
      // unexpected: just in case.
      nextSong = exampleMusics[0];
    }
    player.play(UrlSource(nextSong.sourceUrl!));
    playingMusic = nextSong;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reading.book.title ?? 'Book Reader'),
      ),
      body: GestureDetector(
        onTapDown: (details) {
          if (!pagenated) {
            paginate(context.size ?? Size(100, 100), textStyle);
            pageController.jumpToPage(widget.reading.currentPage ?? 0);
            pagenated = true;
            return;
          }

          final x = details.globalPosition.dx;
          final width = context.size?.width ?? 0;
          // print('x = $x, width = $width');

          var currentPage = widget.reading.currentPage ?? 0;

          // 点击翻页：左 1/3 前页，右 1/3 后页
          if (x > (width * 2 / 3)) {
            final maxPage = widget.reading.pagination?.pages?.length ?? 1;
            if (currentPage < maxPage - 1) {
              currentPage++;
              // 用 pageController listener 自动更新了
              // widget.reading.currentPage = currentPage;
              // updateReadingStorage();

              // pageController.animateToPage(currentPage,
              //     duration: const Duration(milliseconds: 500),
              //     curve: Curves.easeIn);
              pageController.jumpToPage(currentPage);
            } else {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const Library()),
              // );
              simpleAlert(context, "End of Book",
                  "You have reached the end of the book.");
            }
          } else if (x < (width * 1 / 3)) {
            if (currentPage > 0) {
              currentPage--;

              // 用 pageController listener 自动更新了
              // widget.reading.currentPage = currentPage;
              // updateReadingStorage();

              // pageController.animateToPage(currentPage,
              //     duration: const Duration(milliseconds: 500),
              //     curve: Curves.easeIn);
              pageController.jumpToPage(currentPage);
            } else {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const Library()),
              // );
              simpleAlert(context, "Beginning of Book",
                  "You have reached the beginning of the book.");
            }
          }
        },
        child: LayoutBuilder(builder: (context, constraints) {
          return PageView.builder(
            controller: pageController,
            itemBuilder: (context, index) {
              // Text(getPageText(index), style: textStyle)
              return LayoutBuilder(builder: (context, constraints) {
                // if ((pageSize != constraints.biggest) ||
                //     (pageTextStyle != textStyle)) {
                //   // screen size or font changed: re-paginate.
                //   pageSize = constraints.biggest;
                //   pageTextStyle = textStyle;
                //
                //   paginate(pageSize!, pageTextStyle!);
                //   print(
                //       "pageSize=$pageSize, pageTextStyle=$pageTextStyle, pageController=$pageController, widget.reading.currentPage=${widget.reading.currentPage}");
                //
                //   try {
                //     widget.reading.currentPage =
                //         (widget.reading.currentPage ?? 1) - 1;
                //     updateReadingStorage();
                //
                //     pageController.jumpToPage(widget.reading.currentPage ?? 0);
                //   } catch (e) {
                //     print(e);
                //   }
                // }
                return Text(getPageText(index), style: textStyle);
              }).padding(all: 16);
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Center(
                  child: ControlPanel(bookReader: this),
                ).clipRRect(all: 16);
              });
        },
        child: const Icon(Icons.subject),
        // backgroundColor: Colors.green,
      ),
    );
  }

  String getPageText(int index) {
    if (index == 0) {
      // 初始进入阅读时，加载分页之前的临时页面。
      return "\n\n　　又来看书啦？"
          "\n\n　　这本「${widget.reading.book.title ?? 'untitled book'}」，"
          "你已经阅读了 {TODO}，"
          "上次看到第 ${widget.reading.currentPage} 页。"
          "\n\n　　点击继续阅读 📖"
          "\n\n\n\n　　（其实这个页面的目的是，你必须点一下我才能确认页面构建完成了、屏幕尺寸确定了、可以重新计算分页了哈哈。。）";
    }
    final pagesLength = widget.reading.pagination?.pages?.length ?? 0;
    if (index < pagesLength) {
      return widget.reading.pagination?.pages?[index] ?? "[ErrGetPageText]";
    } else {
      return '[EOF]';
    }
  }
}

class ControlPanel extends StatefulWidget {
  final _BookReaderState bookReader;

  const ControlPanel({Key? key, required this.bookReader}) : super(key: key);

  @override
  _ControlPanelState createState() => _ControlPanelState(this.bookReader);
}

class _ControlPanelState extends State<ControlPanel> {
  final _BookReaderState bookReader;

  _ControlPanelState(this.bookReader);

  @override
  Widget build(BuildContext context) {
    // context.size.width => cannot get size during build ... you can use LayoutBuilder
    return LayoutBuilder(builder: (context, constraints) {
      Size size = constraints.biggest;
      final musicImageWidth = min(size.width / 4, 150.0);
      final buttonsHPadding = min(size.width / 16, 32.0);

      return Column(
        children: [
          // Music Card
          Row(children: [
            Image.network("https://picsum.photos/200/200",
                    width: musicImageWidth,
                    height: musicImageWidth,
                    fit: BoxFit.contain)
                .clipRRect(topLeft: 16, bottomLeft: 16)
                .padding(right: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bookReader.playingMusic?.title ?? "Hunch Gray",
                    style: Theme.of(context).textTheme.labelLarge),
                Text(bookReader.playingMusic?.artist ?? "ZUTOMAYO",
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            ).width(musicImageWidth),
            const Spacer(),
            Row(children: [
              IconButton(
                  icon: const Icon(Icons.pause_rounded),
                  onPressed: () => {
                        // simpleAlert(context, "TODO", "pause"),
                        bookReader.player.pause()
                      },
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          Theme.of(context)
                              .buttonTheme
                              .colorScheme
                              ?.onSecondary))),
              const SizedBox(width: 8),
              IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: () {
                    setState(() {  // setState: force ui update: music card
                      bookReader.playNextSong();
                    });
                  },
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          Theme.of(context)
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
                fillColor:
                    Theme.of(context).buttonTheme.colorScheme?.onSecondary,
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
                child: Icon(Icons.share)
                    .padding(horizontal: buttonsHPadding, vertical: 8),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Theme.of(context)
                        .buttonTheme
                        .colorScheme
                        ?.onSecondary))),
            TextButton(
                onPressed: () => {simpleAlert(context, "TODO", "info")},
                child: Icon(Icons.info)
                    .padding(horizontal: buttonsHPadding, vertical: 8),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Theme.of(context)
                        .buttonTheme
                        .colorScheme
                        ?.onSecondary))),
            TextButton(
                onPressed: () => {simpleAlert(context, "TODO", "bookmark")},
                child: Icon(Icons.bookmark)
                    .padding(horizontal: buttonsHPadding, vertical: 8),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Theme.of(context)
                        .buttonTheme
                        .colorScheme
                        ?.onSecondary)))
          ]).padding(horizontal: 16, top: 8, bottom: 16)
        ],
      ).padding(all: 16);
    });
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

const exampleMusic = [
  "https://upload.wikimedia.org/wikipedia/commons/8/83/Auferstehung_Hannover_Orgel_BWV_532.ogg",
  "https://upload.wikimedia.org/wikipedia/commons/9/97/Bach%2C_Johann_Sebastian_-_Suite_No.2_in_B_Minor_-_X._Badinerie.ogg"
];
