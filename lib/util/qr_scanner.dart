import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanner extends StatelessWidget {
  final Function(String) onScan;

  const QRScanner({Key? key, required this.onScan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
            onScan(barcode.rawValue!);
            break;
          }
        }
      },
    );
  }
} 