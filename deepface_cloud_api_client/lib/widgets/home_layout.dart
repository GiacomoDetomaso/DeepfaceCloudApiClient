import 'package:flutter/material.dart';

class HomeWidget extends StatefulWidget {
  // This calback is used to handle the image picked from the gallery. 
  // The input is the base64 encode of the picked image. If the process
  // is unsuccessful the input is empty.
  final Function(String) imagePickedCallback;

  const HomeWidget({super.key, required this.imagePickedCallback});

  @override
  State<StatefulWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  int _selectedIndex = 0;

  final List _choiceChipCategories = [
    "Detect",
    "Represent",
    "Identify",
    "Verify"
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 15.0),
          Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              child: const Text(
                "Seleziona un'operazione",
              )),
          const SizedBox(height: 10.0),
          Container(
            alignment: Alignment.center,
            child: Wrap(
                spacing: 5.0,
                children: List<Widget>.generate(
                    4,
                    (index) => ChoiceChip(
                          label: Text(_choiceChipCategories[index]),
                          selected: _selectedIndex == index,
                          onSelected: (value) => setState(() {
                            _selectedIndex = (value ? index : null)!;
                          }),
                        )).toList()),
          ),
          Expanded(
            child: Center(
                child: OutlinedButton(
              onPressed: () {
                widget.imagePickedCallback("Ciao qui passo l'immagine base64");
              },
              child: const Text('Seleziona immagine'),
            )),
          )
        ]);
  }
}
