import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isIOS) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const BrowserApp(),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
  ));
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
  bool isSecure = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    urlController.text = currentUrl;
  }

  void loadUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    setState(() {
      isLoading = true;
    });
    webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Navigation Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Progress Bar
                  if (progress < 1.0 && isLoading)
                    SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                      ),
                    ),
                  
                  // URL Bar
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Back Button
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: canGoBack
                                ? Colors.blue
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                          onPressed: canGoBack
                              ? () => webViewController?.goBack()
                              : null,
                        ),
                        
                        // Forward Button
                        IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: canGoForward
                                ? Colors.blue
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                          onPressed: canGoForward
                              ? () => webViewController?.goForward()
                              : null,
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // URL TextField
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Icon(
                                    isSecure
                                        ? Icons.lock
                                        : Icons.info_outline,
                                    size: 16,
                                    color: isSecure
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: urlController,
                                    decoration: const InputDecoration(
                                      hintText: 'گەڕان یان ناونیشان',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                    onSubmitted: loadUrl,
                                  ),
                                ),
                                if (isLoading)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.refresh, size: 20),
                                    onPressed: () =>
                                        webViewController?.reload(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Home Button
                        IconButton(
                          icon: const Icon(
                            Icons.home,
                            color: Colors.blue,
                            size: 26,
                          ),
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
            
            // WebView
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(currentUrl),
                ),
                initialSettings: InAppWebViewSettings(
                  // بنەڕەتی
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  
                  // Media
                  allowsInlineMediaPlayback: true,
                  mediaPlaybackRequiresUserGesture: false,
                  
                  // Windows & Popups
                  javaScriptCanOpenWindowsAutomatically: true,
                  supportMultipleWindows: true,
                  
                  // Cache
                  cacheEnabled: true,
                  clearCache: false,
                  
                  // iOS تایبەت
                  allowsLinkPreview: true,
                  allowsBackForwardNavigationGestures: true,
                  isFraudulentWebsiteWarningEnabled: false,
                  sharedCookiesEnabled: true,
                  
                  // User Agent - iOS 16 Safari
                  userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1",
                  
                  // Security
                  useShouldOverrideUrlLoading: false,
                  allowFileAccessFromFileURLs: false,
                  allowUniversalAccessFromFileURLs: false,
                  
                  // Cookies
                  thirdPartyCookiesEnabled: true,
                  
                  // سەرنجدان
                  incognito: false,
                  
                  // Viewport
                  useWideViewPort: true,
                  loadWithOverviewMode: true,
                  
                  // Zoom
                  supportZoom: true,
                  builtInZoomControls: false,
                  displayZoomControls: false,
                  
                  // SSL
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                ),
                
                onWebViewCreated: (controller) {
                  webViewController = controller;
                  print("WebView Created Successfully!");
                },
                
                onLoadStart: (controller, url) {
                  print("Load Start: $url");
                  setState(() {
                    currentUrl = url.toString();
                    urlController.text = currentUrl;
                    isSecure = url.toString().startsWith('https://');
                    isLoading = true;
                  });
                },
                
                onLoadStop: (controller, url) async {
                  print("Load Stop: $url");
                  setState(() {
                    currentUrl = url.toString();
                    urlController.text = currentUrl;
                    isSecure = url.toString().startsWith('https://');
                    isLoading = false;
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
                  print("Create Window: ${createWindowAction.request.url}");
                  
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.9,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'لۆگین - Sign In',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          
                          // WebView
                          Expanded(
                            child: InAppWebView(
                              windowId: createWindowAction.windowId,
                              initialSettings: InAppWebViewSettings(
                                javaScriptEnabled: true,
                                domStorageEnabled: true,
                                thirdPartyCookiesEnabled: true,
                                sharedCookiesEnabled: true,
                                userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1",
                              ),
                              onCloseWindow: (controller) {
                                Navigator.pop(context);
                              },
                              onLoadStop: (controller, url) {
                                print("Popup loaded: $url");
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  
                  return true;
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
                
                onConsoleMessage: (controller, consoleMessage) {
                  print("Console: ${consoleMessage.message}");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }
}