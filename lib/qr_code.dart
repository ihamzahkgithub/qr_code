import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QRScanner extends StatefulWidget {
  @override
  _QRScannerState createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  bool cameraPermission = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _checkCameraPermission(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('QR Code Scanner'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: _buildQrView(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    double size =
        MediaQuery.of(context).size.width * 0.8; // Adjust the size as needed

    return cameraPermission
        ? Center(
            child: SizedBox(
              width: size,
              height: size,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
            ),
          )
        : Center(
            child: ElevatedButton(
              onPressed: () {
                _checkCameraPermission(context);
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                child: Text('Request Camera Permission'),
              ),
            ),
          );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      // Handle the scanned QR code data
      print("Scanned data: ${scanData.code}");

      // Show a dialog with the scanned QR code
      _showScannedQRDialog(context, scanData.code!);
    });
  }

  void _checkCameraPermission(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    var status = await Permission.camera.status;
    Navigator.of(context).pop(); // Close the loading indicator

    if (status == PermissionStatus.granted) {
      setState(() {
        cameraPermission = true;
      });
    } else {
      status = await Permission.camera.request();
      if (status == PermissionStatus.granted) {
        setState(() {
          cameraPermission = true;
        });
      } else {
        setState(() {
          cameraPermission = false;
        });
        _showPermissionErrorDialog(context);
      }
    }
  }

  void _showPermissionErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Error'),
          content: const Text(
              'Camera permission is required to use the QR scanner.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showScannedQRDialog(BuildContext context, String scanData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Scanned QR Code'),
          content: Text('QR Code: $scanData'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _delayedDisposeController(); // Delay disposal after dialog is closed
                _openURLInBrowser(scanData); // Open the URL in the browser
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _delayedDisposeController() {
    Future.delayed(Duration.zero, () {
      controller?.dispose();
    });
  }

  void _openURLInBrowser(String url) async {
    // Check if the scanned data is a valid URL
    if (Uri.parse(url).isAbsolute) {
      try {
        await launch(url, forceSafariVC: false, forceWebView: false);
      } catch (e) {
        print('Error launching URL: $e');
      }
    } else {
      // Handle the case where the scanned data is not a valid URL
      print('Scanned data is not a valid URL: $url');
      // You can show a message or handle it as per your application's requirements.
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
