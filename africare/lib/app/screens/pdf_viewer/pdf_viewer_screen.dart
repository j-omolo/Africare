import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';

class PDFViewerScreen extends StatelessWidget {
  final String filePath;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.shareFiles([filePath]),
          ),
        ],
      ),
      body: SfPdfViewer.file(File(filePath)),
    );
  }
}
