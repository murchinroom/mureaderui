import 'dart:math';

import 'package:mureaderui/model.dart';

Future<MurecomResponse> murecom(MurecomRequest request) async {
  print('murecom: ${request.prevPages.length}-${request.currentPages.length}-${request.nextPages.length}: ${request.currentPages}');
  // final music = exampleMusics[Random().nextInt(exampleMusics.length)];
  final music = exampleMusics[1];
  return MurecomResponse(music: music);
}
