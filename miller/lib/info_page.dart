import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'mill.dart';


class InfoPage extends StatelessWidget {
  final Mill mill;

  const InfoPage({Key? key, required this.mill}) : super(key: key);

  Widget makeTitle(String text) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18
          )
        )
      )
    );
  }

  Widget makeMeta(String key, String value) {
    return ListTile(
      title: Text(key),
      subtitle: Text(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: makeTitle(mill.name)
              ),
              Center(
                child: CachedNetworkImage(
                  imageUrl: mill.image,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child:
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    mill.credits,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey
                    ),
                  ),
                ),
              ),

              if (mill.history != null)
                makeTitle("Geschiedenis"),
              if (mill.history != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    mill.history!,
                    softWrap: true,
                  ),
                ),
              makeTitle("Gegevens"),
              for (var entry in mill.meta.entries)
                makeMeta(entry.key, entry.value)
            ],
          )
        )
      ),
      floatingActionButton: ElevatedButton(
        child: const Text("Terug"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
