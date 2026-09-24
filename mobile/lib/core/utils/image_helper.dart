import 'dart:convert';
import 'package:flutter/material.dart';

ImageProvider? getAvatarImageProvider(String source) {
  if (source.isEmpty) return null;
  if (source.startsWith('http')) {
    return NetworkImage(source);
  }
  if (source.startsWith('data:image')) {
    final base64String = source.split(',').last;
    return MemoryImage(base64Decode(base64String));
  }
  return null;
}

Widget buildAvatar(String source, {double fontSize = 32}) {
  final provider = getAvatarImageProvider(source);
  if (provider != null) {
    return const SizedBox.shrink(); // Use backgroundImage in CircleAvatar instead
  }
  return Text(source, style: TextStyle(fontSize: fontSize));
}

ImageProvider? getBannerImageProvider(String source) {
  if (source.isEmpty) return null;
  if (source.startsWith('http')) {
    return NetworkImage(source);
  }
  if (source.startsWith('data:image')) {
    final base64String = source.split(',').last;
    return MemoryImage(base64Decode(base64String));
  }
  return null;
}
