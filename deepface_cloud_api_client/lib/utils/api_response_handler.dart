import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:convert';

class ApiResponseHandler {
  Map reply;
  BuildContext context;

  static const String _successStatus = 'success';
  static const String identifyFail = 'idFail';

  ApiResponseHandler(this.reply, this.context);

  String handleApiResponse(String service) {
    String message = '';

    // Select the correct response handler
    if (service.contains('detect')) {
      _handleDetectRequestResponse();
    } else if (service.contains('identify')) {
      message = _handleIndentifyRequestResponse();
    } else if (service.contains('verify')) {
      _handleVerifyRequestResponse();
    } else if (service.contains('represent')) {
      _handleRepresentRequestResponse();
    }

    return message;
  }

  /// This method is used to spcify what action perform, if detect service
  /// is selected, according to the the reply sent from the web API
  void _handleDetectRequestResponse() {
    // If the response contains this value, the operation is successful
    reply['status'] == _successStatus
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
            duration: Duration(seconds: 2, microseconds: 500)));
  }

  /// This method is used to spcify what action perform, if identify service
  /// is selected, according to the the reply sent from the web API
  String _handleIndentifyRequestResponse() {
    String message;

    if (reply['status'] == _successStatus) {
      message = 'Identità trovate:\n';

      List foundedIds = reply['founded_ids'];
      log(foundedIds.length);

      for (String id in foundedIds) {
        message += '• $id\n';
      }
    } else {
      message = 'idFail';
    }

    return message;
  }

  /// This method is used to spcify what action perform, if verify service
  /// is selected, according to the the reply sent from the web API
  void _handleVerifyRequestResponse() {
    Color snackBarColor = Colors.green;
    String snackBarMessage = '';

    // Deterimines scaffold properties
    if (reply['status'] == _successStatus) {
      if (reply['message'] == 'True') {
        snackBarColor = Colors.green;
        snackBarMessage = 'Identità confermata';
      } else if (reply['message'] == 'False') {
        snackBarColor = Colors.red;
        snackBarMessage = 'Identità NON confermata';
      }
    } else {
      snackBarColor = Colors.red;
      snackBarMessage =
          'Errori nell\'invio della richiesta. Controllare che l\'immagine contenga volti';
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: snackBarColor,
        content: Text(snackBarMessage),
        duration: const Duration(seconds: 2, microseconds: 500)));
  }

  /// This method is used to spcify what action perform, if verify service
  /// is selected, according to the the reply sent from the web API
  void _handleRepresentRequestResponse() {
    Color snackBarColor;
    String snackBarMessage;

    if (reply['status'] == _successStatus) {
      snackBarColor = Colors.green;
      snackBarMessage = 'Identità registrata';
    } else {
      snackBarColor = Colors.red;
      snackBarMessage = 'Identità NON registrata: volti multipli rilevati';
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: snackBarColor,
        content: Text(snackBarMessage),
        duration: const Duration(seconds: 2, microseconds: 500)));
  }
}
