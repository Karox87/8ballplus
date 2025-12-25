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
              if (progress < 1.0)
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
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
          cacheEnabled: true,
          clearCache: false,
          thirdPartyCookiesEnabled: true,
          mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
          // User Agent وەک Chrome ی ڕاستەقینە - تەواو
          userAgent:
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
          applicationNameForUserAgent: "",
          // ڕێکخستنەکانی زیاتر بۆ کۆمپاتیبلیتی باشتر
          useShouldOverrideUrlLoading: true,
          allowFileAccessFromFileURLs: false,
          allowUniversalAccessFromFileURLs: false,
          // سەپۆرتی Geolocation و تایبەتمەندییەکانی تر
          geolocationEnabled: true,
          // Headers زیادکردن
          transparentBackground: false,
        ),
        onWebViewCreated: (controller) async {
          webViewController = controller;
          
          // JavaScript injection بۆ شاردنەوەی هەموو نیشانەکانی WebView
          await controller.evaluateJavascript(source: """
            (function() {
              // شاردنەوەی WebView properties
              delete window._flutter_inappwebview;
              delete window.flutter_inappwebview;
              delete window.flutter;
              
              // Chrome properties زیادکردن
              Object.defineProperty(navigator, 'webdriver', {
                get: () => false
              });
              
              window.chrome = {
                runtime: {},
                loadTimes: function() {},
                csi: function() {},
                app: {}
              };
              
              // Navigator properties تەواوکردن
              Object.defineProperty(navigator, 'languages', {
                get: () => ['en-US', 'en', 'ku']
              });
              
              Object.defineProperty(navigator, 'platform', {
                get: () => 'Win32'
              });
              
              Object.defineProperty(navigator, 'plugins', {
                get: () => [
                  {name: 'Chrome PDF Plugin'},
                  {name: 'Chrome PDF Viewer'},
                  {name: 'Native Client'}
                ]
              });
              
              // Connection API
              Object.defineProperty(navigator, 'connection', {
                get: () => ({
                  effectiveType: '4g',
                  downlink: 10,
                  rtt: 50
                })
              });
              
              // Battery API
              navigator.getBattery = () => Promise.resolve({
                charging: true,
                level: 1,
                chargingTime: 0,
                dischargingTime: Infinity
              });
              
              // Permissions API
              const originalQuery = window.navigator.permissions.query;
              window.navigator.permissions.query = (parameters) => (
                parameters.name === 'notifications' ?
                  Promise.resolve({ state: Notification.permission }) :
                  originalQuery(parameters)
              );
            })();
          """);
        },
        onLoadStart: (controller, url) {
          setState(() {
            currentUrl = url.toString();
            urlController.text = currentUrl;
          });
        },
        onLoadStop: (controller, url) async {
          // JavaScript injection دووبارە دوای باربوونی لاپەڕە
          await controller.evaluateJavascript(source: """
            (function() {
              // شاردنەوەی WebView نیشانەکان
              delete window._flutter_inappwebview;
              delete window.flutter_inappwebview;
              delete window.flutter;
              
              // WebGL Vendor وەک GPU ڕاستەقینە
              const getParameter = WebGLRenderingContext.prototype.getParameter;
              WebGLRenderingContext.prototype.getParameter = function(parameter) {
                if (parameter === 37445) return 'Intel Inc.';
                if (parameter === 37446) return 'Intel Iris OpenGL Engine';
                return getParameter.call(this, parameter);
              };
              
              // Timezone
              Intl.DateTimeFormat.prototype.resolvedOptions = function() {
                return {timeZone: 'Asia/Baghdad'};
              };
            })();
          """);
          
          setState(() {
            currentUrl = url.toString();
            urlController.text = currentUrl;
          });

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
                            databaseEnabled: true,
                            thirdPartyCookiesEnabled: true,
                            cacheEnabled: true,
                            clearCache: false,
                            mediaPlaybackRequiresUserGesture: false,
                            javaScriptCanOpenWindowsAutomatically: true,
                            supportMultipleWindows: true,
                            useHybridComposition: true,
                            userAgent:
                                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
                            applicationNameForUserAgent: "",
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
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          // تەنها بۆ navigation requests
          return NavigationActionPolicy.ALLOW;
        },
        onPermissionRequest: (controller, request) async {
          return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT,
          );
        },
        onReceivedError: (controller, request, error) {
          print("Error: ${error.description}");
        },
        onReceivedHttpError: (controller, request, errorResponse) {
          print("HTTP Error: ${errorResponse.statusCode}");
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