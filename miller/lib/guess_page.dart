import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'mill.dart';
import 'info_page.dart';

enum Difficulty {
  easy, hard
}


class GuessPage extends StatefulWidget {
  const GuessPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => GuessPageState();
}

class GuessPageState extends State<GuessPage> {
  static List<Mill>? allMills;
  List<Mill>? sequence;
  Difficulty difficulty = Difficulty.easy;
  Mill? mill;
  List<String>? choices;
  bool hardFocused = false;
  late FocusNode hardFocusNode;

  @override
  void initState() {
    super.initState();
    hardFocusNode = FocusNode();
    chooseMill();
  }

  @override
  void dispose() {
    hardFocusNode.dispose();

    super.dispose();
  }

  Future<void> loadMills() async {
    allMills = await getMills();
    sequence = List.from(allMills!);
    sequence!.shuffle();
    setState(() { });
  }

  void chooseMill() {
    choices = null;
    if (sequence == null) {
      loadMills().then((_) { chooseMill(); });
    }
    else {
      setState(() {
        mill = sequence!.removeLast();
        choices = [
          mill!.name,
          for (int i = 0; i < 3; i++)
            sequence![i].name
        ];
        choices!.shuffle();
        sequence!.shuffle();
      });
      if (sequence!.length < 10) {
        sequence = null;
        loadMills();
      }
    }
  }

  void showResult(BuildContext context, bool correct) {
    showGeneralDialog(
      context: context,
      transitionBuilder: (context, a1, a2, widget) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Transform.scale(
            scale: a1.value,
            child: Opacity(
              opacity: a1.value,
              child: Center(child: widget)
            ),
          )
        );
      },
      transitionDuration: const Duration(milliseconds: 100),
      barrierDismissible: false,
      barrierLabel: '',
      pageBuilder: (context, animation1, animation2) {
        Future.delayed(const Duration(seconds: 1), () {
          final infoPage = InfoPage(mill: mill!);
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => infoPage)
          );
          chooseMill();
        });

        return AlertDialog(
          shape: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Center(child: correct ? Text("Goed") : Text("Fout")),
          backgroundColor: correct ? Colors.green : Colors.red,
        );
      }
    );
  }

  Widget makeEasyOptionButton(BuildContext context, String text) {
    return Expanded(
      flex: 1,
      child: InkWell(
        child: Center(child: Text(text)),
        onTap: () {
          showResult(context, text == mill!.name);
        },
      )
    );
  }

  Widget easyOptions(BuildContext context) {
    if (mill == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              makeEasyOptionButton(context, choices![0]),
              makeEasyOptionButton(context, choices![1]),
            ],
          )
        ),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              makeEasyOptionButton(context, choices![2]),
              makeEasyOptionButton(context, choices![3]),
            ],
          )
        ),
      ],
    );
  }

  Widget hardOptions(BuildContext context) {
    String selected = "";

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        children: [
          Row(
            children: [
              if (hardFocused)
                IconButton(
                  onPressed: () { setState(() { hardFocused = false; }); },
                  icon: const Icon(Icons.arrow_back_outlined),
                  splashRadius: 20,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: GestureDetector(
                    behavior: hardFocused ? HitTestBehavior.translucent : HitTestBehavior.opaque,
                    onTap: () {
                      print("tapped");
                      setState(() {
                        hardFocused = true;
                        hardFocusNode.requestFocus();
                      });
                    },
                    child: IgnorePointer(
                      ignoring: !hardFocused,
                      child: Autocomplete(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return const Iterable<String>.empty();
                          }
                          return allMills!.map((mill) => mill.name).where((String name) {
                            return name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          selected = selection;
                        },
                        optionsMaxHeight: 300,
                      )
                    ),
                  ),
                )
              )
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              child: const Text("Bevestig"),
              onPressed: () {
                if (selected.isNotEmpty) {
                  showResult(context, selected == mill!.name);
                }
              },
            ),
          )
        ],
      ),
    );
  }

  Widget options(BuildContext context) {
    switch (difficulty) {
      case Difficulty.easy:
        return easyOptions(context);
      case Difficulty.hard:
        return hardOptions(context);
    }
  }

  Widget makeDifficultyButton(String text, Difficulty value, Color color) {
    return Expanded(
      flex: 1,
      child: InkWell(
        child: Container(
          color: difficulty == value ? color : color.withAlpha(64),
          child: Center(child: Text(
            text,
            style: TextStyle(
              fontWeight: difficulty == value ? FontWeight.bold : FontWeight.normal
            ),
          ))
        ),
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            difficulty = value;
            hardFocused = false;
          });
        },
      ),
    );
  }

  Widget settings(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          makeDifficultyButton("Makkelijk", Difficulty.easy, Colors.green),
          makeDifficultyButton("Moeilijk", Difficulty.hard, Colors.red),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (sequence == null || mill == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            settings(context),
            if (!hardFocused)
              Expanded(
                flex: 8,
                child: Stack(
                  children: [
                    Center(
                      child: CachedNetworkImage(
                        imageUrl: mill!.image,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 30, bottom: 10),
                        child: ElevatedButton(
                          child: const Icon(Icons.fast_forward),
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(15),
                            primary: Colors.blue,
                          ),
                          onPressed: () {
                            setState(() {
                              mill = null;
                              chooseMill();
                            });
                          },
                        )
                      ),
                    )
                  ],
                ),
              ),
            Expanded(
              flex: 4,
              child: options(context),
            )
          ],
        )
      ),
    );
  }
}