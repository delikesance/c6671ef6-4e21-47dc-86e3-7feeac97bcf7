import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

class EmbedWidget extends StatefulWidget {
  final Function(EmbedBuilder) onChange; // Callback for changes

  const EmbedWidget({super.key, required this.onChange});

  @override
  EmbedWidgetState createState() => EmbedWidgetState();
}

class EmbedWidgetState extends State<EmbedWidget> {
  final embed = EmbedBuilder();

  void _updateEmbed() {
    // Notify the parent widget of changes
    widget.onChange(embed);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: context.tr.embed_label_title,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  embed.title = value;
                  _updateEmbed(); // Trigger the callback
                });
              },
              maxLength: 256,
              maxLines: 1,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).nextFocus();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: context.tr.common_description,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  embed.description = value;
                  _updateEmbed(); // Trigger the callback
                });
              },
              onFieldSubmitted: (value) => FocusScope.of(context).nextFocus(),
              maxLength: 2000,
              maxLines: 5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: context.tr.common_url,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  embed.url = Uri.tryParse(value);
                  _updateEmbed(); // Trigger the callback
                });
              },
              validator:
                  (value) =>
                      value != null && !Uri.tryParse(value)!.isAbsolute
                          ? context.tr.action_provide_valid_url
                          : null,
            ),
          ),
        ],
      ),
    );
  }
}
