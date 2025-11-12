import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Full-screen WebView with progress and error handling. Shows a loader while
/// the page is loading and a retry UI if the page fails to load.
class DocsWebViewScreen extends StatefulWidget {
  final String initialUrl;

  const DocsWebViewScreen({super.key, required this.initialUrl});

  @override
  State<DocsWebViewScreen> createState() => _DocsWebViewScreenState();
}

class _DocsWebViewScreenState extends State<DocsWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          debugPrint('WebView: started $url');
          setState(() {
            _loading = true;
            _errorMessage = null;
          });
        },
        onPageFinished: (url) {
          debugPrint('WebView: finished $url');
          setState(() {
            _loading = false;
          });
        },
        onWebResourceError: (err) {
          debugPrint('WebView error: ${err.description}');
          setState(() {
            _loading = false;
            _errorMessage = err.description;
          });
        },
      ))
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  void _reload() {
    setState(() {
      _errorMessage = null;
      _loading = true;
    });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load page',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: _reload,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
