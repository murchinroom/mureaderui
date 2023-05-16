import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:mureaderui/model.dart';

const String murecomServer = "https://mureader.murchinroom.fun/murecom4reader/";

Uri murecomUri() {
  return Uri.parse("${murecomServer}murecom");
}

Future<MurecomResponse> murecom(MurecomRequest request) async {
  final response = await http.post(murecomUri(), body: jsonEncode(request.toJson()));

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    print("murecom response: $json");
    return MurecomResponse.fromJson(json);
  } else {
    print("murecom failed: ${response.statusCode}: ${response.body}");
    throw Exception("murecom failed: ${response.statusCode}: ${response.body}");
  }
}
