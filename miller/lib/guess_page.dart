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

  @override
  void initState() {
    super.initState();
    chooseMill();
  }

  Future<void> loadMills() async {
    // load all mills from json and generate sequence
    allMills ??= await getMills();
    sequence = List.from(allMills!);
    sequence!.shuffle();
    setState(() { });
  }

  void chooseMill() {
    // choose mill if sequence is generated
    choices = null;
    if (sequence == null) {
      // load sequence then try again
      loadMills().then((_) { chooseMill(); });
    }
    else {
      setState(() {
        // choose mill and select 3 other choices for easy mode
        mill = sequence!.removeLast();
        choices = [
          mill!.name,
          for (int i = 0; i < 3; i++)
            sequence![i].name
        ];
        // shuffle choices and sequence
        // so that the next mill is not guaranteed to be one of the choices
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
    // show animation text "Correct" or "Wrong" and open info window
    showGeneralDialog(
      context: context,
      transitionBuilder: (context, a1, a2, widget) {
        // don't allow back button to be pressed
        // this would mess up the navigator stack
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
        // after one second, open the info window
        Future.delayed(const Duration(seconds: 1), () {
          final infoPage = InfoPage(mill: mill!);
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => infoPage)
          );
          chooseMill();
        });

        // message to be displayed before window is opened
        return AlertDialog(
          shape: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Center(child: correct ? const Text("Goed") : const Text("Fout")),
          backgroundColor: correct ? Colors.green : Colors.red,
        );
      }
    );
  }

  Widget makeEasyOptionButton(BuildContext context, String text) {
    // a single easy mode option button
    assert(mill != null);

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

    // 2x2 grid of easy option buttons
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
    // autocomplete field with all mill names as options
    assert(mill != null);

    String selected = "";

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        children: [
          Row(
            children: [
              // only show back button if textbox is selected
              if (hardFocused)
                IconButton(
                  onPressed: () { setState(() { hardFocused = false; }); },
                  icon: const Icon(Icons.arrow_back_outlined),
                  splashRadius: 20,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),

                  // hide image on tap to give more room for the suggestions
                  child: GestureDetector(
                    behavior: hardFocused ? HitTestBehavior.translucent : HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        hardFocused = true;
                      });
                    },

                    // block clicks on textfield when image is shown
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
                  hardFocused = false;
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
    // single difficulty button
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
    // difficulty buttons
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

            // hide image when hard text entry is focused
            if (!hardFocused)
              Expanded(
                flex: 8,
                child: Stack(
                  children: [
                    Center(
                      child: CachedNetworkImage(
                        imageUrl: mill!.image,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.error,
                              color: Colors.grey,
                            ),
                            Text(
                              "Afbeelding laden mislukt",
                              style: TextStyle(
                                  color: Colors.grey
                              )
                            ),
                          ]
                        )
                      ),
                    ),

                    // skip button
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