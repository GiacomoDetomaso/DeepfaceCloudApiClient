import 'package:flutter/material.dart';
import 'dart:convert';

class ApiResponseHandler {
  Map reply;
  BuildContext context;

  ApiResponseHandler(this.reply, this.context);

  void handleApiResponse(String url) {
    // Select the correct response handler
    if (url.contains('detect')) {
      _handleDetectRequestResponse();
    } else if (url.contains('find')) {
      _handleIndentifyRequestResponse();
    } else if (url.contains('verify')) {
      _handleVerifyRequestResponse();
    } else if (url.contains('represent')) {
      _handleRepresentRequestResponse();
    }
  }

  /// This method is used to spcify what action perform, if detect service
  /// is selected, according to the the reply sent from the web API
  void _handleDetectRequestResponse() {
    // If the response contains this value, the operation is successful
    reply.keys.contains('img_b64')
        ? showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                child: Image.memory(base64.decode(reply['img_b64'])),
              );
            })
        : ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content:
                Text('Impossibile individuare un volto in questa immagine.'),
            duration: Duration(seconds: 1, microseconds: 800)));
  }

  /// This method is used to spcify what action perform, if identify service
  /// is selected, according to the the reply sent from the web API
  void _handleIndentifyRequestResponse() {
    Color snackBarColor;
    String snackBarMessage;

    if (reply['message'].toString().contains('Success!')) {
      snackBarColor = Colors.green;
      snackBarMessage = reply['founded_ids'].toString();
    } else {
      snackBarColor = Colors.red;
      snackBarMessage = 'Impossibile individuare volti in questa immagine';
    }

    // TODO: ask to register not represented users

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: snackBarColor,
        content: Text(snackBarMessage),
        duration: const Duration(seconds: 3, microseconds: 500)));
  }

  /// This method is used to spcify what action perform, if verify service
  /// is selected, according to the the reply sent from the web API
  void _handleVerifyRequestResponse() {
    Color snackBarColor;
    String snackBarMessage;

    // Deterimines scaffold properties
    if (reply.containsValue('True')) {
      snackBarColor = Colors.green;
      snackBarMessage = 'Identità confermata';
    } else {
      snackBarColor = Colors.red;
      snackBarMessage = 'Identità NON confermata';
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: snackBarColor,
        content: Text(snackBarMessage),
        duration: const Duration(seconds: 1, microseconds: 800)));
  }

  /// This method is used to spcify what action perform, if verify service
  /// is selected, according to the the reply sent from the web API
  void _handleRepresentRequestResponse() {
    Color snackBarColor;
    String snackBarMessage;

    if (reply['message'].toString().contains('Representation generated')) {
      snackBarColor = Colors.green;
      snackBarMessage = 'Identità registrata';
    } else {
      snackBarColor = Colors.red;
      snackBarMessage = 'Identità NON registrata: errori interni';
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: snackBarColor,
        content: Text(snackBarMessage),
        duration: const Duration(seconds: 1, microseconds: 800)));
  }
}
