import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const MaterialApp(home: BrowserApp()));
}

class BrowserApp extends StatefulWidget {
  const BrowserApp({super.key});
  @override
  State<BrowserApp> createState() => _BrowserAppState();
}

class _BrowserAppState extends State<BrowserApp> {
  InAppWebViewController? webViewController;
  final TextEditingController urlController = TextEditingController();
  String currentUrl = "https://www.google.com";
  double progress = 0;
  bool canGoBack = false;
  bool canGoForward = false;

  @override
  void initState() {
    super.initState();
    urlController.text = currentUrl;
  }

  void loadUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("بڕاوسەری من"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              // Progress indicator
              if (progress < 1.0)
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              // URL bar and navigation buttons
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: canGoBack
                          ? () => webViewController?.goBack()
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: canGoForward
                          ? () => webViewController?.goForward()
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => webViewController?.reload(),
                    ),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: urlController,
                          decoration: InputDecoration(
                            hintText: 'ناونیشانی وێب سایت بنووسە',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search, size: 20),
                              onPressed: () => loadUrl(urlController.text),
                            ),
                          ),
                          onSubmitted: loadUrl,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.home),
                      onPressed: () {
                        loadUrl("https://www.google.com");
                        urlController.text = "https://www.google.com";
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(currentUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          databaseEnabled: true,
          allowsInlineMediaPlayback: true,
          mediaPlaybackRequiresUserGesture: false,
          javaScriptCanOpenWindowsAutomatically: true,
          supportMultipleWindows: true,
          useHybridComposition: true,
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: true,
          cacheEnabled: true,
          thirdPartyCookiesEnabled: true,
          // User agent بۆ سەپۆرتی باشتری Google Login و وێب سایتەکانی تر
          userAgent:
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onLoadStart: (controller, url) {
          setState(() {
            currentUrl = url.toString();
            urlController.text = currentUrl;
          });
        },
        onLoadStop: (controller, url) async {
          setState(() {
            currentUrl = url.toString();
            urlController.text = currentUrl;
          });
          
          // Update navigation buttons
          canGoBack = await controller.canGoBack();
          canGoForward = await controller.canGoForward();
          setState(() {});
        },
        onProgressChanged: (controller, progress) {
          setState(() {
            this.progress = progress / 100;
          });
        },
        onCreateWindow: (controller, createWindowAction) async {
          // Handle popup windows (Google Login often uses popups)
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Column(
                    children: [
                      AppBar(
                        title: const Text("پەنجەرەی نوێ"),
                        leading: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Expanded(
                        child: InAppWebView(
                          windowId: createWindowAction.windowId,
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            domStorageEnabled: true,
                            thirdPartyCookiesEnabled: true,
                          ),
                          onCloseWindow: (controller) {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          return true;
        },
        onPermissionRequest: (controller, request) async {
          // Handle permission requests (camera, microphone, etc.)
          return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }
}