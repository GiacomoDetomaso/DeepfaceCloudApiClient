import 'dart:collection';

import 'package:flutter/material.dart';

class JsonRequestDialog extends StatelessWidget {
  // The fields of the dialog. The map contains:
  // field name and associated icon
  final LinkedHashMap<String, IconData> fields;

  // The controller to obtain the dialog's input
  final List<TextEditingController> _textEditingControllerList = [];

  // This callback is used to let the parent widget of the Dialog obtain its 
  // input List, in order to send the request to the  web server.
  // The List contains the inputs, inserted in the same order as they
  // appear in the JsonRequestDialog.
  final Function(List<String>) onRequestSendCallback;

  void _initControllersList() {
    // Used to add a controller for every TextField
    for (int i = 0; i < fields.length; i++) {
      _textEditingControllerList.add(TextEditingController());
    }
  }

  JsonRequestDialog(
      {super.key, required this.fields, required this.onRequestSendCallback}) {
    _initControllersList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // Specify a column which will hold the dialog elements
      child: Column(
          // Specify the minimum possible size for the dialog
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Adds the title of the Dialog, using material 3 paddings
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                "Inserimento richiesta",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),

            // Adds a diveder using the material 3 guidelines
            const Padding(
                padding: EdgeInsets.only(left: 8, right: 8, bottom: 4),
                child: Divider()),

            // This wrap section is used to generate n TextField based on
            // the _fields map size. The information stored into the map
            // are accessed using the index provided by the generate callback.
            // The controller defined in _initControllersList is binded too.
            Wrap(
                children: List<Widget>.generate(
                    fields.length,
                    (index) => Padding(
                          padding: const EdgeInsets.all(15),
                          child: SizedBox(
                            child: TextField(
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  prefixIcon:
                                      Icon(fields.values.elementAt(index)),
                                  labelText: fields.keys.elementAt(index)),
                              controller: _textEditingControllerList[index],
                            ),
                          ),
                        )).toList()),

            // Adds a diveder using the material 3 guidelines
            const Padding(
                padding: EdgeInsets.only(left: 8, right: 8, top: 4),
                child: Divider()),

            // Adds a row with the two buttons of the dialog.
            // The first button is used to close the dialog, while the second
            // will be used to submit the input data and send them back
            // to the module that will handle the json request.
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Chiudi")),
                TextButton(
                    onPressed: () {
                      List inputs = [];
                      int controllersLength = _textEditingControllerList.length;

                      for (int i = 0; i < controllersLength; i++) {
                        String text = _textEditingControllerList[i].text;

                        text.isNotEmpty
                            ? inputs.add(text)
                            : ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                            content: Text(
                                "Il campo ${fields.values.elementAt(i)} è vuoto")));
                      }
                    },
                    child: const Text("Invia"))
              ]),
            ),
          ]),
    );
  }
}
