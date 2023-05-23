import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

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
  final String url = "https://deepfacecloudapiunibatesi.azurewebsites.net/";
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String requestURL = 'https://deepfacecloudapiunibatesi.azurewebsites.net/';

  // The state of the widget
  int _selectedIndex = 0;

  // The selected chip
  int _selectedChip = 0;

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
  void _buildJsonRequestMap(List<String> keys, List<String> values) {
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
    switch (_selectedChip) {
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

  /// This mthod is used to handle the api request to REST api
  Future<void> apiRequest(String url, Map jsonMap) async {
    log("Request started at url: $url");

    if (_selectedChip != -1) {
      HttpClient httpClient = HttpClient();
      HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
      request.headers.set('content-type', 'application/json');
      request.add(utf8.encode(json.encode(jsonMap)));
      HttpClientResponse response = await request.close();
      // todo - you should check the response.statusCode
      String reply = await response.transform(utf8.decoder).join();
      httpClient.close();
      Map jsonReply = jsonDecode(reply);
      handleApiResponse(jsonReply, url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.red,
        content: Text(
            'Selezionare il task da eseguire prima di inviare la richiesta'),
        duration: Duration(seconds: 1, microseconds: 500),
      ));
    }
  }

  void handleApiResponse(Map reply, String url) {
    if (url.contains('detect')) {
      // TODO: alert dialog before display result
      showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              child: Image.memory(base64.decode(reply['img_b64'])),
            );
          });
    } else if (url.contains('find')) {
      // TODO: full screen dialog with the results of the operation
      // TODO: handle not represented user
    } else if (url.contains('verify')) {
      // TODO: show snackbar with the result of the operation
    } else if (url.contains('represent')) {
      // TODO: show snackbar with the result of the operation
    }
  }

  /// Used to display the request dialog
  void _sendAction() {
    log("Chip index $_selectedChip");
    if (_selectedChip == 1 || _selectedChip == 3) {
      _addEntriesOnChipBased();
      showDialog(
          context: context,
          builder: (context) => JsonRequestDialog(
                fields: entries,
                id: _selectedChip,
                onRequestSendCallback: (inputFields, id) async {
                  List<String> keys = [];

                  if (id == 1) {
                    keys = ['username', 'info'];
                  } else if (id == 3) {
                    keys = ['identity'];
                  }

                  _buildJsonRequestMap(keys, inputFields);
                  apiRequest(requestURL, widget.jsonRequest);

                  // Let the user start a new request
                  _imagePicked = false;

                  // ignore: use_build_context_synchronously
                  Navigator.pop(context); // Close the Dialog
                },
              ));
    } else {
      apiRequest(requestURL, widget.jsonRequest);
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
      body: Center(
          child: HomeWidget(
        onChipSelectedCallback: (index, name) {
          _selectedChip = index;

          // Add the nested services if detect is select
          if (index == 0) {
            name += "/faceboxes";
          } else if (index == 2) {
            name = 'find';
          }

          // Build the url that will be used to perform the request
          requestURL = widget.url + name.toLowerCase();

          log("Actual Url: $requestURL");
        },

        // The callback is used to process the base 64 encoded image
        imagePickedCallback: (b64Image) {
          _imagePicked = true;
          log("String b64 length: ${b64Image.length}");
          log("Number of bytes b64 decoded image: ${base64.decode(b64Image).length}");
          _buildJsonRequestMap(['img'], [b64Image]);
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
                    backgroundColor: Colors.red,
                    content: Text(
                        'Impossibile inviare una richiesta senza prima aver selezionato un immagine.'),
                    duration: Duration(seconds: 1, microseconds: 500),
                  ))
                : _sendAction(); // if the image is picked display the dialog
          }),
    );
  }
}
