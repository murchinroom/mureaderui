import 'dart:math';

import 'package:mureaderui/model.dart';

Future<MurecomResponse> murecom(MurecomRequest request) async {
  print(request);
  final music = exampleMusics[Random().nextInt(exampleMusics.length)];
  return MurecomResponse(music: music);
}
