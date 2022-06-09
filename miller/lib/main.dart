import 'package:flutter/material.dart';

import 'guess_page.dart';
import 'mill.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GuessPage(),
    );
  }
}