import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:mureaderui/model.dart';

/// murecomServer is the base url to murecom-gw4reader service
const String murecomServer = "https://mureader.murchinroom.fun/murecom4reader";

Uri murecomUri() {
  return Uri.parse("$murecomServer/murecom");
}

Future<MurecomResponse> murecom(MurecomRequest request) async {
  final response =
      await http.post(murecomUri(), body: jsonEncode(request.toJson()));

  if (response.statusCode != 200) {
    print("murecom failed: ${response.statusCode}: ${response.body}");
    throw Exception("murecom failed: ${response.statusCode}: ${response.body}");
  }

  final json = jsonDecode(response.body);
  print("murecom response: $json");

  var resp = MurecomResponse.fromJson(json);

  // relative url: 视为 proxied: 前面加上 murecom-gw4reader 服务的地址
  if (resp.music?.sourceUrl?.startsWith("/") ?? false) {
    resp.music?.sourceUrl = "$murecomServer${resp.music?.sourceUrl}";
  }

  return resp;
}
