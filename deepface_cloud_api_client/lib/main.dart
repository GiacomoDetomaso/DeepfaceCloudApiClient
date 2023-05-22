import 'dart:collection';

import 'package:deepface_cloud_api_client/widgets/dialog_form_generator.dart';
import 'package:flutter/material.dart';
import 'widgets/home_layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Deepface client'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final Map<String, String> jsonRequest = {};
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // The state of the widget
  int _selectedIndex = 0;

  // Indicates if the image is picked from the storage
  bool _imagePicked = false;

  // A map used to build the dialog to send the request to the web server
  // through the JsonRequestDialog
  LinkedHashMap<String, IconData> entries = LinkedHashMap();

  /// Determines the index of the BottomNavigationViewItem tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Used to build the json request
  void _buildJsonRequest(List<String> keys, List<String> values) {
    if (keys.length != values.length) {
      throw Exception("Keys and values must have the same size");
    }

    for (int i = 0; i < keys.length; i++) {
      widget.jsonRequest.putIfAbsent(keys[i], () => values[i]);
    }
  }

  /// Used to add the correct entries to the map based on the operation choice
  void _addEntriesOnChipBased() {
    entries.clear();
    switch (_selectedIndex) {
      case 1:
        entries.addAll(
          {'Username': Icons.account_circle, 'Info': Icons.info},
        );
        break;
      case 3:
        entries.addAll({'Usermane': Icons.account_circle});
        break;
    }
  }

  /// Used to display the request dialog
  void _displayDialog() {
    if (_selectedIndex != 0 && _selectedIndex != 2) {
      _addEntriesOnChipBased();
      showDialog(
          context: context,
          builder: (context) => JsonRequestDialog(
                fields: entries,
                onRequestSendCallback: (inputFields) => {
                  // TODO: setup the user's input into the request
                },
              ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Ciao"),
        duration: Duration(microseconds: 900),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      // The body of this material app is composed by a custom HomeWidget used
      // to select the operation's type from a ChipGroup.
      // An ImagePicker callback is provided in order to manage the selected
      // image that will be processed by the API request previously defined
      // by the user. The Widget is then wrapped by a Center.
      body: Center(child: HomeWidget(
        imagePickedCallback: (b64Image) {
          // TODO: setup the image into the request
        },
      )),

      // Setup the BottomNavigationBar and its items, defining also the
      // behavior when an item is tapped by the user.
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Impostazioni',
            ),
          ]),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.send),
          // Define the onPressed by showing a dialog to send the request
          // to the web server
          onPressed: () {
            !_imagePicked // If the image is not picked show a snackbar
                ? ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Impossibile inviare una richiesta senza prima aver selezionato un immagine.'),
                    duration: Duration(seconds: 1, microseconds: 500),
                  ))
                : _displayDialog(); // if the image is picked display the dialog
          }),
    );
  }
}
