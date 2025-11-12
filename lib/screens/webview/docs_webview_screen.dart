import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Simple full-screen WebView used as a fallback when the platform can't open
/// an external browser for the legal/doc pages.
class DocsWebViewScreen extends StatefulWidget {
  final String initialUrl;

  const DocsWebViewScreen({super.key, required this.initialUrl});

  @override
  State<DocsWebViewScreen> createState() => _DocsWebViewScreenState();
}

class _DocsWebViewScreenState extends State<DocsWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
