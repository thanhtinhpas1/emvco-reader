import 'dart:developer';
import 'dart:io';
import 'package:emvqrcode/emvqrcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(const MaterialApp(home: MyHome()));

class MyHome extends StatelessWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emvco Reader')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const QRViewExample(),
            ));
          },
          child: const Text('Scan'),
        ),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  EmvqrModel? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 5,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (result != null)
                    Padding(
                        padding: const EdgeInsets.all(4),
                        child: SizedBox(
                          height: 400,
                          width: 400,
                          child: JsonView.map(
                            result!.toJson(),
                            theme: const JsonViewTheme(
                              errorWidget: Text('error',
                                  style: TextStyle(color: Colors.red)),
                              backgroundColor: Colors.black87,
                              keyStyle: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              doubleStyle: TextStyle(
                                color: Colors.green,
                                fontSize: 16,
                              ),
                              intStyle: TextStyle(
                                color: Colors.yellow,
                                fontSize: 16,
                              ),
                              stringStyle: TextStyle(
                                color: Colors.yellow,
                                fontSize: 16,
                              ),
                              boolStyle: TextStyle(
                                color: Colors.yellow,
                                fontSize: 16,
                              ),
                              closeIcon: Icon(
                                Icons.close,
                                color: Colors.yellow,
                                size: 20,
                              ),
                              openIcon: Icon(
                                Icons.add,
                                color: Colors.yellow,
                                size: 20,
                              ),
                              separator: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Icon(
                                  Icons.arrow_right_alt_outlined,
                                  size: 20,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        ))
                  else
                    const Text(
                      'Scan a code',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(4),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.pauseCamera();
                          },
                          child: const Text('pause',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(4),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.resumeCamera();
                          },
                          child: const Text('resume',
                              style: TextStyle(fontSize: 12)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 400.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      this.controller!.pauseCamera();
      final emvdecode = EMVMPM.decode(scanData.code!);
      if (emvdecode.error != null) {
        showDialog(
            context: context,
            builder: (context) => Center(
                  child: Material(
                    color: Colors.red,
                    child: Text(emvdecode.error?.message!),
                  ),
                ));
        return;
      }
      setState((() {
        result = emvdecode.emvqr;
      }));
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
