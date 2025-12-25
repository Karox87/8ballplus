import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io' show Platform;

void main() {
  // بۆ iOS تایبەت پێویستە ئەم ڕێکخستنە
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isIOS) {
    InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  
  runApp(MaterialApp(
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
  
  // بۆ کۆنترۆڵی popup windows
  final List<PopupWebView> _popups = [];

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
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Navigation Bar - iOS Style
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Progress Bar
                  if (progress < 1.0)
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.blue,
                      ),
                      minHeight: 2,
                    ),
                  
                  // URL Bar و Navigation Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Back Button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: canGoBack
                              ? () => webViewController?.goBack()
                              : null,
                          child: Icon(
                            CupertinoIcons.back,
                            color: canGoBack
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey,
                            size: 28,
                          ),
                        ),
                        
                        // Forward Button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: canGoForward
                              ? () => webViewController?.goForward()
                              : null,
                          child: Icon(
                            CupertinoIcons.forward,
                            color: canGoForward
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey,
                            size: 28,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // URL TextField
                        Expanded(
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    isSecure
                                        ? CupertinoIcons.lock_fill
                                        : CupertinoIcons.info_circle,
                                    size: 16,
                                    color: isSecure
                                        ? CupertinoColors.systemGreen
                                        : CupertinoColors.systemGrey,
                                  ),
                                ),
                                Expanded(
                                  child: CupertinoTextField(
                                    controller: urlController,
                                    placeholder: 'گەڕان یان ناونیشانی وێبسایت',
                                    decoration: const BoxDecoration(),
                                    style: const TextStyle(fontSize: 14),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    onSubmitted: loadUrl,
                                    clearButtonMode:
                                        OverlayVisibilityMode.editing,
                                  ),
                                ),
                                CupertinoButton(
                                  padding: const EdgeInsets.only(right: 4),
                                  minSize: 0,
                                  onPressed: () =>
                                      webViewController?.reload(),
                                  child: const Icon(
                                    CupertinoIcons.refresh,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Home Button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            loadUrl("https://www.google.com");
                            urlController.text = "https://www.google.com";
                          },
                          child: const Icon(
                            CupertinoIcons.house_fill,
                            color: CupertinoColors.activeBlue,
                            size: 24,
                          ),
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
                initialUrlRequest: URLRequest(url: WebUri(currentUrl)),
                initialSettings: InAppWebViewSettings(
                  // تایبەتمەندییەکانی بنەڕەتی
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  
                  // تایبەتمەندییەکانی Media
                  allowsInlineMediaPlayback: true,
                  mediaPlaybackRequiresUserGesture: false,
                  
                  // تایبەتمەندییەکانی Window و Popup
                  javaScriptCanOpenWindowsAutomatically: true,
                  supportMultipleWindows: true,
                  
                  // Cache و Cookie
                  cacheEnabled: true,
                  clearCache: false,
                  thirdPartyCookiesEnabled: true,
                  
                  // iOS تایبەتمەندییەکانی تایبەت بە
                  allowsLinkPreview: true,
                  allowsBackForwardNavigationGestures: true,
                  allowsPictureInPictureMediaPlayback: true,
                  isFraudulentWebsiteWarningEnabled: true,
                  limitsNavigationsToAppBoundDomains: false,
                  
                  // User Agent - iPhone 15 Pro
                  userAgent:
                      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
                  applicationNameForUserAgent: "",
                  
                  // Security Settings
                  useShouldOverrideUrlLoading: true,
                  allowFileAccessFromFileURLs: false,
                  allowUniversalAccessFromFileURLs: false,
                  
                  // بۆ Gmail و Google Services پێویستە
                  geolocationEnabled: true,
                  
                  // iOS Specific
                  applePayAPIEnabled: true,
                  sharedCookiesEnabled: true,
                  automaticallyAdjustsScrollIndicatorInsets: true,
                  
                  // Mixed Content
                  mixedContentMode:
                      MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                ),
                onWebViewCreated: (controller) async {
                  webViewController = controller;
                  
                  // JavaScript injection بۆ iOS
                  await controller.evaluateJavascript(source: """
                    (function() {
                      // شاردنەوەی Flutter/WebView نیشانەکان
                      delete window._flutter_inappwebview;
                      delete window.flutter_inappwebview;
                      delete window.flutter;
                      
                      // iOS Safari properties
                      Object.defineProperty(navigator, 'webdriver', {
                        get: () => false
                      });
                      
                      // Platform
                      Object.defineProperty(navigator, 'platform', {
                        get: () => 'iPhone'
                      });
                      
                      // Languages
                      Object.defineProperty(navigator, 'languages', {
                        get: () => ['en-US', 'en', 'ar', 'ku']
                      });
                      
                      // Touch Events بۆ iOS
                      window.ontouchstart = function() {};
                      
                      // Connection
                      Object.defineProperty(navigator, 'connection', {
                        get: () => ({
                          effectiveType: '4g',
                          downlink: 10,
                          rtt: 50,
                          saveData: false
                        })
                      });
                      
                      // Plugins - Safari iOS
                      Object.defineProperty(navigator, 'plugins', {
                        get: () => []
                      });
                      
                      // بۆ Google OAuth
                      window.isNativeApp = false;
                      
                      // DeviceMemory
                      Object.defineProperty(navigator, 'deviceMemory', {
                        get: () => 8
                      });
                      
                      // Hardware Concurrency
                      Object.defineProperty(navigator, 'hardwareConcurrency', {
                        get: () => 6
                      });
                      
                      // Max Touch Points - iPhone
                      Object.defineProperty(navigator, 'maxTouchPoints', {
                        get: () => 5
                      });
                    })();
                  """);
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    currentUrl = url.toString();
                    urlController.text = currentUrl;
                    isSecure = url.toString().startsWith('https://');
                  });
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    currentUrl = url.toString();
                    urlController.text = currentUrl;
                    isSecure = url.toString().startsWith('https://');
                  });

                  canGoBack = await controller.canGoBack();
                  canGoForward = await controller.canGoForward();
                  setState(() {});
                  
                  // JavaScript injection دووبارە
                  await controller.evaluateJavascript(source: """
                    (function() {
                      delete window._flutter_inappwebview;
                      delete window.flutter_inappwebview;
                      delete window.flutter;
                      
                      // WebGL
                      const getParameter = WebGLRenderingContext.prototype.getParameter;
                      WebGLRenderingContext.prototype.getParameter = function(parameter) {
                        if (parameter === 37445) return 'Apple Inc.';
                        if (parameter === 37446) return 'Apple GPU';
                        return getParameter.call(this, parameter);
                      };
                      
                      // Timezone
                      Intl.DateTimeFormat.prototype.resolvedOptions = function() {
                        return {timeZone: 'Asia/Baghdad'};
                      };
                    })();
                  """);
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    this.progress = progress / 100;
                  });
                },
                // Gmail Login بۆ پشتگیری لە - Popup Handler
                onCreateWindow: (controller, createWindowAction) async {
                  final popupWebView = PopupWebView(
                    createWindowAction: createWindowAction,
                    onClose: () {
                      setState(() {
                        _popups.removeWhere(
                          (p) => p.createWindowAction.windowId ==
                              createWindowAction.windowId,
                        );
                      });
                    },
                  );
                  
                  setState(() {
                    _popups.add(popupWebView);
                  });
                  
                  // پیشاندانی Popup بە شێوەی Modal
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) => popupWebView,
                  );
                  
                  return true;
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url.toString();
                  
                  // بۆ Gmail OAuth و Google Services
                  if (url.contains('accounts.google.com') ||
                      url.contains('oauth') ||
                      url.contains('signin')) {
                    return NavigationActionPolicy.ALLOW;
                  }
                  
                  return NavigationActionPolicy.ALLOW;
                },
                onPermissionRequest: (controller, request) async {
                  // هەموو Permissions بدە بۆ Gmail
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                onReceivedError: (controller, request, error) {
                  debugPrint("Error: ${error.description}");
                },
                onReceivedHttpError: (controller, request, errorResponse) {
                  debugPrint("HTTP Error: ${errorResponse.statusCode}");
                },
                onReceivedServerTrustAuthRequest:
                    (controller, challenge) async {
                  // SSL Certificate بۆ Gmail
                  return ServerTrustAuthResponse(
                    action: ServerTrustAuthResponseAction.PROCEED,
                  );
                },
                onReceivedHttpAuthRequest: (controller, challenge) async {
                  // HTTP Authentication
                  return HttpAuthResponse(
                    action: HttpAuthResponseAction.PROCEED,
                  );
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
    webViewController?.dispose();
    super.dispose();
  }
}

// Popup Window بۆ Gmail Login
class PopupWebView extends StatefulWidget {
  final CreateWindowAction createWindowAction;
  final VoidCallback onClose;

  const PopupWebView({
    super.key,
    required this.createWindowAction,
    required this.onClose,
  });

  @override
  State<PopupWebView> createState() => _PopupWebViewState();
}

class _PopupWebViewState extends State<PopupWebView> {
  InAppWebViewController? popupController;
  String currentUrl = "";
  double progress = 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentUrl.isEmpty ? 'چاوەڕوانبە...' : currentUrl,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        widget.onClose();
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: CupertinoColors.systemGrey,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress Bar
              if (progress < 1.0)
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 2,
                ),
              
              // WebView
              Expanded(
                child: InAppWebView(
                  windowId: widget.createWindowAction.windowId,
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
                    allowsInlineMediaPlayback: true,
                    allowsBackForwardNavigationGestures: true,
                    sharedCookiesEnabled: true,
                    userAgent:
                        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
                    applicationNameForUserAgent: "",
                  ),
                  onWebViewCreated: (controller) {
                    popupController = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      currentUrl = url?.toString() ?? "";
                    });
                  },
                  onLoadStop: (controller, url) {
                    setState(() {
                      currentUrl = url?.toString() ?? "";
                    });
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      this.progress = progress / 100;
                    });
                  },
                  onCloseWindow: (controller) {
                    widget.onClose();
                    Navigator.pop(context);
                  },
                  onPermissionRequest: (controller, request) async {
                    return PermissionResponse(
                      resources: request.resources,
                      action: PermissionResponseAction.GRANT,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}