import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

part 'mill.g.dart';


@JsonSerializable()
class Mill {
  final String name;
  final String image;
  final String credits;
  final Map<String, String> meta;
  final String? history;

  Mill(this.name, this.image, this.credits, this.meta, this.history);

  factory Mill.fromJson(Map<String, dynamic> json) => _$MillFromJson(json);
}

Future<List<Mill>> getMills() async {
  final data = json.decode(
      await rootBundle.loadString("assets/files/mill_info.json")
  );
  return data.where((mill) => mill["name"] != null).map<Mill>((mill) => Mill.fromJson(mill)).toList();
}