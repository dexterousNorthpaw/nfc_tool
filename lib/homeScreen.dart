import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

ValueNotifier<dynamic> result = ValueNotifier(null);
ValueNotifier<dynamic> result2 = ValueNotifier(null);
final TextEditingController writeValue = TextEditingController();
final TextEditingController writeValue2 = TextEditingController();
bool isSessionActive = false;

// String data = '';

class NfcHome extends StatefulWidget {
  const NfcHome({super.key});

  @override
  State<NfcHome> createState() => _NfcHomeState();
}

class _NfcHomeState extends State<NfcHome> {
  // final ValueNotifier<dynamic> result = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("NFC Test"),
        ),
        body: FutureBuilder(
            future: NfcManager.instance.isAvailable(),
            builder: (context, ss) {
              return ss.data != true
                  ? Center(
                      child: Text("NFC not availbale"),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                              child: Container(
                                  height: 52,
                                  width: 352,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey), // Border color
                                    borderRadius: BorderRadius.circular(
                                        10), // Border radius
                                  ),
                                  child: TextFormField(
                                      controller: writeValue,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10),
                                        border: InputBorder
                                            .none, // Remove default border
                                        hintText: 'Enter text',
                                      )))),
                          // Center(
                          //     child: Container(
                          //         height: 52,
                          //         width: 352,
                          //         decoration: BoxDecoration(
                          //           border: Border.all(
                          //               color: Colors.grey), // Border color
                          //           borderRadius: BorderRadius.circular(
                          //               10), // Border radius
                          //         ),
                          //         child: TextFormField(
                          //             controller: writeValue2,
                          //             decoration: InputDecoration(
                          //               contentPadding: EdgeInsets.symmetric(
                          //                   horizontal: 10),
                          //               border: InputBorder
                          //                   .none, // Remove default border
                          //               hintText: 'Enter text',
                          //             )))),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton(
                                  onPressed: () {
                                    _ndefWrite(context);
                                  },
                                  child: Text("Write")),
                              TextButton(
                                  onPressed: _startNFCReading,
                                  child: Text("Read")),
                              TextButton(onPressed: () {}, child: Text("Del")),
                            ],
                          ),
                          SizedBox(
                            height: 50,
                          ),
                          ValueListenableBuilder(
                              valueListenable: result,
                              builder: (context, value, _) {
                                return Text("${value ?? ''}");
                              })
                        ],
                      ),
                    );
            }));
  }
}

// void _tagRead() {
//   print("reading");
//   NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
//     result.value = tag.data;
//     NfcManager.instance.stopSession();
//   });
//   print("Done reading");
// }

void _startNFCReading() async {
  try {
    bool isAvailable = await NfcManager.instance.isAvailable();
    print("NFC Availability: $isAvailable");
    print("started");
    //We first check if NFC is available on the device.
    if (isAvailable) {
      print("available");
      //If NFC is available, start an NFC session and listen for NFC tags to be discovered.
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          // result.value = tag.data;
          // Process NFC tag, When an NFC tag is discovered, print its data to the console.
          debugPrint('NFC Tag Detected: ${tag.data}');
          print("tag");
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            debugPrint('NDEF not supported');
          } else {
            final cachedMessage = ndef.cachedMessage;
            if (cachedMessage != null) {
              for (var record in cachedMessage.records) {
                debugPrint('Record: ${record.payload}');
                final payload = String.fromCharCodes(record.payload);
                result.value = payload;

                print("NFC tag is : ${payload}");
              }
            }
            NfcManager.instance.stopSession();
          }
        },
      );
      // await Future.delayed(Duration(seconds: 1));
      // NfcManager.instance.stopSession();

      // print("done");
    } else {
      debugPrint('NFC not available.');
    }
  } catch (e) {
    debugPrint('Error reading NFC: $e');
  }
}

void _ndefWrite(BuildContext context) {
  if (isSessionActive) {
    print('Session is already active');
    return;
  }
  print("write");
  isSessionActive = true;
  NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
    var ndef = Ndef.from(tag);
    if (ndef == null || !ndef.isWritable) {
      result.value = 'Tag is not ndef writable';
      NfcManager.instance.stopSession(errorMessage: result.value);
      return;
    }

    NdefMessage message = NdefMessage([
      // NdefRecord.createText('Hello World!'),
      // NdefRecord.createUri(Uri.parse('https://flutter.dev')),
      NdefRecord.createMime(
          writeValue.text, Uint8List.fromList(writeValue.text.codeUnits)),
      // NdefRecord.createMime(
      //     writeValue2.text, Uint8List.fromList(writeValue2.text.codeUnits)),
      // NdefRecord.createExternal(
      //     'com.example', 'mytype', Uint8List.fromList('mydata'.codeUnits)),
    ]);

    try {
      await ndef.write(message);
      result.value = 'Successfully written';
      await Future.delayed(Duration(milliseconds: 600));
      NfcManager.instance.stopSession();
    } catch (e) {
      result.value = e;
      NfcManager.instance.stopSession(errorMessage: result.value.toString());
    } finally {
      isSessionActive = false;
    }
    writeValue.clear();
    // writeValue2.clear();
    FocusScope.of(context).unfocus();
    NfcManager.instance.stopSession();
  });
}
