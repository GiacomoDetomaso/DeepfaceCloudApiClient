import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:deepface_cloud_api_client/utils/api_response_handler.dart';
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
  final String url = 'https://deepfacecloudapiunibatesi.azurewebsites.net/';

  // Setting up constant values that correspons to the selected chip
  static const detectId = 0;
  static const representId = 1;
  static const identifyId = 2;
  static const verifyId = 3;

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

  // Indicates if the request is over or not
  bool _requestStatus = false;

  // A success to display if find operation is successful
  String _successMessage = "";

  // A map used to build the dialog to send the request to the web server
  // through the JsonRequestDialog
  LinkedHashMap<String, IconData> entries = LinkedHashMap();

  /// Determines the index of the BottomNavigationViewItem tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Determines the actual status of the request, updating the UI
  void _updateRequestRunning(bool status) {
    setState(() {
      _requestStatus = status;

      // Update the succes message to empty message if a new
      // request is running
      if (_requestStatus) _updateSuccessMessage("");
    });
  }

  void _updateSuccessMessage(String successMessage) {
    setState(() {
      _successMessage = successMessage;
    });
  }

  /// Used to add the correct entries to the map based on the operation choice
  void _addEntriesOnChipBased(int selectedChip) {
    entries.clear();
    switch (selectedChip) {
      case MyHomePage.representId:
        entries.addAll(
          {'username': Icons.account_circle, 'info': Icons.info},
        );
        break;
      case MyHomePage.verifyId:
        entries.addAll({'Username': Icons.account_circle});
        break;
    }
  }

  /// Used to build the json request
  void _buildJsonRequestMap(
      List<String> keys, List<String> values, bool clean) {
    if (clean && widget.jsonRequest.isNotEmpty) {
      widget.jsonRequest.clear();
    }

    if (keys.length != values.length) {
      throw Exception("Keys and values must have the same size");
    }

    for (int i = 0; i < keys.length; i++) {
      widget.jsonRequest.putIfAbsent(keys[i], () => values[i]);
    }
  }

  /// This mthod is used to handle the api request to REST api
  Future<void> sendApiRequest(String url, Map jsonMap) async {
    _updateRequestRunning(true); // Change the state

    log("Request started at url: $url");

    HttpClient httpClient = HttpClient();
    HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
    request.headers.set('content-type', 'application/json');
    request.add(utf8.encode(json.encode(jsonMap)));
    HttpClientResponse response = await request.close();

    String reply = await response.transform(utf8.decoder).join();
    httpClient.close();

    Map jsonReply = jsonDecode(reply);
    log(reply);

    if (context.mounted) {
      _updateRequestRunning(false);
      var responseHandler = ApiResponseHandler(jsonReply, context);
      String message = responseHandler.handleApiResponse(url);

      if (message == ApiResponseHandler.identifyFail) {
        // If the identification fails let the user the possibility
        // to register a representation of the input
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text(
                    'Impossibile verificare idenità',
                    style: TextStyle(fontSize: 20),
                  ),
                  content: const Text(
                      "Impossibile identificare volti in questa immagine. Cliccare su 'Registra identità' "
                      "se si vuole usare la stessa immagine per registrare il volto sconosciuto.\n"
                      "L'operazione è possibile solo in presenza di un singolo volto."),
                  actions: <TextButton>[
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Chiudi')),
                    TextButton(
                        onPressed: () {
                          //Navigator.pop(context);
                          requestURL = '${widget.url}represent';
                          Navigator.pop(context);
                          _sendAction(MyHomePage.representId);
                        },
                        child: const Text('Registra identità'))
                  ],
                  actionsAlignment: MainAxisAlignment.end,
                ));
      } else if (message.isNotEmpty) {
        // The only case in which the message is not empty is when the idenity
        // in identify operations are found. The state of the widget is updated
        // in order to display the success message.
        _updateSuccessMessage(message);
      }
    } else {
      log('Context not mounted');
    }
  }

  /// Used to display the request dialog
  void _sendAction(int injectedSelectedChip) {
    log("Chip index $injectedSelectedChip");

    if (requestURL != widget.url) {
      if (injectedSelectedChip == MyHomePage.representId ||
          injectedSelectedChip == MyHomePage.verifyId) {
        _addEntriesOnChipBased(injectedSelectedChip);
        showDialog(
            context: context,
            builder: (context) => JsonRequestDialog(
                  fields: entries,
                  id: injectedSelectedChip,
                  onRequestSendCallback: (inputFields, id) {
                    List<String> keys = [];

                    if (id == MyHomePage.representId) {
                      keys = ['username', 'info'];
                    } else if (id == MyHomePage.verifyId) {
                      keys = ['identity'];
                    }

                    _buildJsonRequestMap(keys, inputFields, false);
                    log(widget.jsonRequest.toString());
                    sendApiRequest(requestURL, widget.jsonRequest);

                    // Let the user start a new request
                    _imagePicked = false;

                    // Close the Dialog
                    Navigator.pop(context);
                  },
                ));
      } else {
        sendApiRequest(requestURL, widget.jsonRequest);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.red,
        content: Text(
            'Selezionare il task da eseguire prima di inviare la richiesta'),
        duration: Duration(seconds: 1, microseconds: 500),
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
      body: Center(
          child: HomeWidget(
        successMessage: _successMessage,
        isCircularProgressIndicatorShowing: _requestStatus,
        onChipSelectedCallback: (index, name) {
          _selectedChip = index;

          // Add the nested services if detect is select
          if (index == MyHomePage.detectId) {
            name += "/faceboxes";
          } else if (index == MyHomePage.identifyId) {
            name = 'find';
          }

          // Build the url that will be used to perform the request
          requestURL = widget.url + name.toLowerCase();

          log("Selected Url: $requestURL");
        },

        // The callback is used to process the base 64 encoded image
        imagePickedCallback: (b64Image) {
          _imagePicked = true;
          log("String b64 length: ${b64Image.length}");
          log("Number of bytes b64 decoded image: ${base64.decode(b64Image).length}");
          _buildJsonRequestMap(['img'], [b64Image], true);
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
                : _sendAction(
                    _selectedChip); // if the image is picked display the dialog
          }),
    );
  }
}
