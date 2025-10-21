import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../FastTranslationService.dart';
import 'PdfInvoiceService.dart';


class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  translatedtranslatedText('Invoice Preview')),
      body: PdfPreview(
        build: (format) async {
          final document = await PdfInvoiceService.generateInvoice();
          return await document.save();
        },
      ),
    );
  }
}