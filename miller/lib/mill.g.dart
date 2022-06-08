// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mill _$MillFromJson(Map<String, dynamic> json) => Mill(
      json['name'] as String,
      json['image'] as String,
      json['credits'] as String,
      Map<String, String>.from(json['meta'] as Map),
      json['history'] as String?,
    );

Map<String, dynamic> _$MillToJson(Mill instance) => <String, dynamic>{
      'name': instance.name,
      'image': instance.image,
      'credits': instance.credits,
      'meta': instance.meta,
      'history': instance.history,
    };
