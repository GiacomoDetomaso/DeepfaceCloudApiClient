import 'dart:collection';
import 'dart:convert';
import 'dart:developer';

import 'package:deepface_cloud_api_client/utils/api_response_handler.dart';
import 'package:deepface_cloud_api_client/widgets/dialog_form_generator.dart';
import 'package:flutter/material.dart';
import 'widgets/home_layout.dart';
import 'package:http/http.dart' as http;

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

  final Map<String, dynamic> requestMap = {};
  final String title;
  final String url = 'deepfacecloudapiunibatesi.azurewebsites.net';

  // Setting up constant values that correspons to the selected chip
  static const detectId = 0;
  static const representId = 1;
  static const identifyId = 2;
  static const verifyId = 3;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String requestURL = 'deepfacecloudapiunibatesi.azurewebsites.net';
  String serviceName = '';

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
  void _buildRequestMap(List<String> keys, List<String> values, bool clean) {
    if (clean && widget.requestMap.isNotEmpty) {
      widget.requestMap.clear();
    }

    if (keys.length != values.length) {
      throw Exception("Keys and values must have the same size");
    }

    for (int i = 0; i < keys.length; i++) {
      widget.requestMap.putIfAbsent(keys[i], () => values[i]);
    }
  }

  Future<http.MultipartRequest> _buildRequest(
      Uri uri, String method, String path) async {
    var keys = widget.requestMap.keys;
    var values = widget.requestMap.values;
    var request = http.MultipartRequest(method, uri);

    for (int i = 0; i < keys.length; i++) {
      request.fields[keys.elementAt(i)] = values.elementAt(i);
    }

    request.files.add(await http.MultipartFile.fromPath('img', path));

    return request;
  }

  Future<Map<int, String>> sendMultipartRequest(
      String url, String method) async {
    var uri = Uri.http(url, serviceName);

    log("Dim: ${widget.requestMap.length}");
    log(widget.requestMap.values.toString());

    String filePath = widget.requestMap['img'];
    log(filePath);
    http.MultipartRequest request = await _buildRequest(uri, method, filePath);

    http.StreamedResponse streamedResponse = await request.send();
    log("${streamedResponse.statusCode}");

    String response;

    // Determines response value
    streamedResponse.statusCode != 200
        ? response = ''
        : response = await streamedResponse.stream.bytesToString();

    Map<int, String> responseMap = {streamedResponse.statusCode: response};

    return responseMap;
  }

  /// This mthod is used to handle the api request to REST api
  Future<void> menageApiRequest(String url, Map jsonMap, String method) async {
    _updateRequestRunning(true); // Change the state

    log("Request started at url: $url/$serviceName");
    Map<int, String> replyMap = await sendMultipartRequest(url, method);

    if (replyMap.containsKey(200)) {
      Map jsonReply = jsonDecode(replyMap.remove(200)!);
      log(jsonReply.toString());

      if (context.mounted) {
        _updateRequestRunning(false);
        var responseHandler = ApiResponseHandler(jsonReply, context);
        String message = responseHandler.handleApiResponse(serviceName);

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
                            serviceName = 'represent';
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
  }

  /// Used to display the request dialog
  void _sendAction(int injectedSelectedChip) {
    log("Chip index $injectedSelectedChip");

    String method = 'POST';

    if (serviceName == 'detect') {
      method = 'GET';
    }

    if (serviceName.isNotEmpty) {
      log(serviceName);

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
                      keys = ['identity', 'info'];
                    } else if (id == MyHomePage.verifyId) {
                      keys = ['identity'];
                    }

                    _buildRequestMap(keys, inputFields, false);
                    log(widget.requestMap.toString());
                    menageApiRequest(requestURL, widget.requestMap, method);

                    // Let the user start a new request
                    _imagePicked = false;

                    // Close the Dialog
                    Navigator.pop(context);
                  },
                ));
      } else {
        menageApiRequest(requestURL, widget.requestMap, method);
        // Let the user start a new request
        _imagePicked = false;
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
          // Add the nested services if detect is select
          if (index == MyHomePage.detectId) {
            name += "/faceboxes";
          }

          _selectedChip = index;
          _updateSuccessMessage('');

          // Build the url that will be used to perform the request
          //requestURL = widget.url + name.toLowerCase();
          serviceName = name.toLowerCase();

          log("Selected service: $serviceName");
        },

        // The callback is used to process the base 64 encoded image
        imagePickedCallback: (filePath) {
          _imagePicked = true;
          log("Path: $filePath");

          _buildRequestMap(['img'], [filePath], true);
        },
      )),

      // Setup the BottomNavigationBar and its items, defining also the
      // behavior when an item is tapped by the user.
      bottomNavigationBar: Visibility(
        visible: false,
        child: BottomNavigationBar(
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
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.send),
          // Define the onPressed by showing a dialog to send the request
          // to the web server
          onPressed: () async {
            if (!_imagePicked) // If the image is not picked show a snackbar
            {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.red,
                content: Text(
                    'Impossibile inviare una richiesta senza prima aver selezionato un immagine.'),
                duration: Duration(seconds: 1, microseconds: 500),
              ));
            } else {
              log('$_selectedChip');
              _sendAction(_selectedChip);
            }
            // if the image is picked display the dialog
          }),
    );
  }
}
