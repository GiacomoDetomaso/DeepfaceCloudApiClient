import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class HomeWidget extends StatefulWidget {
  // This calback is used to handle the image picked from the gallery.
  // The input is the base64 encode of the picked image. If the process
  // is unsuccessful the input is empty.
  final Function(String) imagePickedCallback;

  // This callback is used to identify what action is
  // selected from the ChipGroup
  final Function(int, String) onChipSelectedCallback;

  // Indicates if the circluar progress bar need to be showing
  final bool isCircularProgressIndicatorShowing;

  // A text to display if some operations from the parent
  // widgets are successful
  final String successMessage;

  const HomeWidget(
      {super.key,
      required this.isCircularProgressIndicatorShowing,
      required this.successMessage,
      required this.imagePickedCallback,
      required this.onChipSelectedCallback});

  @override
  State<StatefulWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  // Used to select the correct chip
  int? _value = -1;

  // Used to store the bytes of the read image
  Uint8List? _imageBytes;

  // The list of the categories of the chip
  final List _choiceChipCategories = [
    "Detect",
    "Represent",
    "Identify",
    "Verify"
  ];

  // 4. compress Uint8List and get another Uint8List.
  Future<Uint8List> compressUint8List(Uint8List list) async {
    var result = await FlutterImageCompress.compressWithList(list, quality: 15);

    log("Before compressing: ${list.length}");
    log("After compressing: ${result.length}");

    return result;
  }

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
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: Wrap(
                    spacing: 10.0,
                    children: List<Widget>.generate(
                      4,
                      (int index) {
                        return ChoiceChip(
                          label: Text(_choiceChipCategories[index]),
                          selected: _value == index,
                          onSelected: (bool selected) {
                            setState(() {
                              _value = selected ? index : null;

                              if (_value != null) {
                                widget.onChipSelectedCallback(
                                    _value!, _choiceChipCategories[_value!]);
                              }
                            });
                          },
                        );
                      },
                    ).toList(),
                  ))),

          // The following section is used to display the picked image.
          // It is visible only if the image is picked and automatically
          // disappears when the request is completed
          if (_imageBytes != null)
            Container(
              padding: const EdgeInsets.only(top: 30.0),
              alignment: Alignment.center,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        alignment: Alignment.center,
                        image: MemoryImage(_imageBytes!),
                        fit: BoxFit.cover),
                    shape: BoxShape.rectangle),
              ),
            ),
          if (widget.successMessage.isNotEmpty)
            Container(
                padding: const EdgeInsets.only(top: 20),
                alignment: Alignment.center,
                child: Text(widget.successMessage)),

          // This section contains an OutlinedButton that will perform
          // the pick action of the ImagePicker. The image will be
          // then converted into base64 format, and sent to the parent
          // widget whose responsible to handle the json request
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Center(
                child: OutlinedButton(
              onPressed: () async {
                // Retrieve the image from the gallery using the ImagePicker
                final XFile? imageFile =
                    await ImagePicker().pickImage(source: ImageSource.gallery);

                // Retrieve the image bytes from the file
                Uint8List? imageBytes = await imageFile?.readAsBytes();

                Uint8List imageBytesCompressed =
                    await compressUint8List(imageBytes!);

                // Encode image bytes using the dart:convert module's base64Encode
                String encodedBytes =
                    base64.encode(imageBytesCompressed.toList());
                // Send the encoded String to the parent via callback
                widget.imagePickedCallback(encodedBytes);
                // Change the state of the widget according to the picked image
                setState(() {
                  _imageBytes = imageBytes;
                });
              },
              child: const Text('Seleziona immagine'),
            )),
          ),
          Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Visibility(
                  visible: widget.isCircularProgressIndicatorShowing,
                  child: const Center(child: CircularProgressIndicator()))),
        ]);
  }
}
