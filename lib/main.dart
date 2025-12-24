import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:math' as math;
import 'dart:io' show Platform;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: BrowserApp()));
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
  
  // Aim Assist State
  bool _isMenuOpen = false;
  bool _showAimAssist = true;
  bool _showAppBar = true;
  bool _isMobileMode = false;
  Offset _pivotPoint = const Offset(150, 500);
  double _lineLength = 100.0;
  double _allCircleSize = 20.0;
  double _pathOpacity = 0.5;
  Color _activeColor = Colors.white;
  double _currentAngle = -0.8;

  // User Agents
  final String mobileUA = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1";
  final String desktopUA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

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

  // Settings گونجاو بۆ Android و iOS
  InAppWebViewSettings _getWebViewSettings() {
    return InAppWebViewSettings(
      javaScriptEnabled: true,
      domStorageEnabled: true,
      databaseEnabled: true,
      allowsInlineMediaPlayback: true,
      mediaPlaybackRequiresUserGesture: false,
      javaScriptCanOpenWindowsAutomatically: true,
      supportMultipleWindows: true,
      cacheEnabled: true,
      clearCache: false,
      thirdPartyCookiesEnabled: true,
      userAgent: _isMobileMode ? mobileUA : desktopUA,
      applicationNameForUserAgent: "",
      useShouldOverrideUrlLoading: true,
      geolocationEnabled: true,
      transparentBackground: false,
      
      // Android specific
      useHybridComposition: Platform.isAndroid,
      mixedContentMode: Platform.isAndroid 
          ? MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW 
          : null,
      
      // iOS specific
      limitsNavigationsToAppBoundDomains: Platform.isIOS ? false : null,
      allowsBackForwardNavigationGestures: Platform.isIOS ? false : null,
      suppressesIncrementalRendering: Platform.isIOS ? false : null,
      allowsLinkPreview: Platform.isIOS ? false : null,
      sharedCookiesEnabled: Platform.isIOS ? true : null,
      
      // بۆ Gmail و OAuth چارەسەر
      allowFileAccessFromFileURLs: true,
      allowUniversalAccessFromFileURLs: true,
    );
  }

  @override
  Widget build(BuildContext context) {
// 1. Set the Middle Point as the absolute anchor (stored in _pivotPoint)
    Offset middlePoint = _pivotPoint; 
    
    // 2. Pivot is FIXED next to the middle (gap distance)
    double gap = _allCircleSize * 2.1;
    Offset pivotPoint = middlePoint + Offset.fromDirection(_currentAngle + math.pi, gap);
    
    // 3. End point is STRETCHABLE (uses _lineLength)
    Offset endPoint = middlePoint + Offset.fromDirection(_currentAngle, _lineLength);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showAppBar ? AppBar(
        backgroundColor: Colors.black87,
        title: const Text("بڕاوسەر + Aim Assist", style: TextStyle(color: Colors.white, fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              if (progress < 1.0)
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(_activeColor),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: canGoBack ? () => webViewController?.goBack() : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      onPressed: canGoForward ? () => webViewController?.goForward() : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                      onPressed: () => webViewController?.reload(),
                    ),
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextField(
                          controller: urlController,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'URL بنووسە',
                            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search, size: 18, color: Colors.white70),
                              onPressed: () => loadUrl(urlController.text),
                            ),
                          ),
                          onSubmitted: loadUrl,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.home, color: Colors.white, size: 20),
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
      ) : null,
      body: Stack(
        children: [
          // BROWSER LAYER
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(currentUrl)),
            initialSettings: _getWebViewSettings(),
            onWebViewCreated: (controller) async {
              webViewController = controller;
              
              // JavaScript injection بۆ شاردنەوەی WebView
              await controller.evaluateJavascript(source: """
                (function() {
                  delete window._flutter_inappwebview;
                  delete window.flutter_inappwebview;
                  delete window.flutter;
                  
                  Object.defineProperty(navigator, 'webdriver', {
                    get: () => false
                  });
                  
                  window.chrome = {
                    runtime: {},
                    loadTimes: function() {},
                    csi: function() {},
                    app: {}
                  };
                  
                  Object.defineProperty(navigator, 'languages', {
                    get: () => ['en-US', 'en', 'ku', 'ar']
                  });
                  
                  Object.defineProperty(navigator, 'plugins', {
                    get: () => [
                      {name: 'Chrome PDF Plugin'},
                      {name: 'Chrome PDF Viewer'},
                      {name: 'Native Client'}
                    ]
                  });
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
              await controller.evaluateJavascript(source: """
                (function() {
                  delete window._flutter_inappwebview;
                  delete window.flutter_inappwebview;
                  delete window.flutter;
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
              try {
                if (!mounted) return false;
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return PopScope(
                      canPop: true,
                      child: Dialog(
                        backgroundColor: Colors.black,
                        insetPadding: const EdgeInsets.all(10),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.95,
                          height: MediaQuery.of(context).size.height * 0.85,
                          child: Column(
                            children: [
                              Container(
                                color: Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () {
                                        if (context.mounted) Navigator.pop(context);
                                      },
                                    ),
                                    const Expanded(
                                      child: Text(
                                        "Login / Popup",
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(width: 48),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: InAppWebView(
                                  windowId: createWindowAction.windowId,
                                  initialSettings: _getWebViewSettings(),
                                  onLoadError: (controller, url, code, message) {
                                    debugPrint("Popup Load Error: $message");
                                  },
                                  onWebViewCreated: (popupController) async {
                                    await popupController.evaluateJavascript(source: """
                                      (function() {
                                        delete window._flutter_inappwebview;
                                        delete window.flutter_inappwebview;
                                        delete window.flutter;
                                      })();
                                    """);
                                  },
                                  onLoadStop: (popupController, url) async {
                                    // چێککردنی ئەگەر login تەواوبوو
                                    final urlString = url.toString().toLowerCase();
                                    if (urlString.contains('oauth') || 
                                        urlString.contains('callback') ||
                                        urlString.contains('success') ||
                                        urlString.contains('accounts.google.com/signin/oauth/consent')) {
                                      await Future.delayed(const Duration(milliseconds: 1500));
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                                  onCloseWindow: (controller) {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                                    // بۆ Gmail OAuth - ڕێگە بدە بە هەموو navigation ەکان
                                    return NavigationActionPolicy.ALLOW;
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
                  },
                );
                return true;
              } catch (e) {
                debugPrint("Error opening popup: $e");
                return false;
              }
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri == null) return NavigationActionPolicy.ALLOW;
              
              final urlString = uri.toString();
              
              // بۆ Gmail و OAuth - هەموو لینکەکان ڕێگەپێبدە
              if (urlString.contains('accounts.google.com') ||
                  urlString.contains('mail.google.com') ||
                  urlString.contains('oauth') ||
                  urlString.contains('signin')) {
                return NavigationActionPolicy.ALLOW;
              }
              
              return NavigationActionPolicy.ALLOW;
            },
            onPermissionRequest: (controller, request) async {
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              );
            },
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              // بۆ SSL certificates
              return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
            },
          ),

          // AIM ASSIST LAYER
if (_showAimAssist) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ProAimPainter(
                    pivot: pivotPoint, 
                    middle: middlePoint, // Fixed Anchor
                    end: endPoint,       // Stretchable
                    radius: _allCircleSize,
                    pathWidth: _allCircleSize * 1.9,
                    opacity: _pathOpacity,
                    color: _activeColor,
                  ),
                ),
              ),
            ),

            // MIDDLE HANDLE: Drag this to move the whole UI
            _buildHandle(middlePoint, _allCircleSize, (delta) {
              setState(() => _pivotPoint += delta);
            }),

            // PIVOT HANDLE: Also moves the whole UI (since it's right next to the middle)
            _buildHandle(pivotPoint, _allCircleSize, (delta) {
              setState(() => _pivotPoint += delta);
            }),

            // END HANDLE: This rotates AND stretches/shrinks the line
            _buildHandle(endPoint, _allCircleSize, (delta) {
              setState(() {
                Offset newEnd = endPoint + delta;
                // Calculate the new distance (Stretch)
                _lineLength = (newEnd - middlePoint).distance;
                
                // Calculate the new angle (Rotation)
                _currentAngle = math.atan2(
                  newEnd.dy - middlePoint.dy, 
                  newEnd.dx - middlePoint.dx
                );

                // Minimum length check to prevent the circle from overlapping the middle
                if (_lineLength < gap + 20) _lineLength = gap + 20;
              });
            }),
          ],

          // SETTINGS BUTTON
          Positioned(
            right: 10, 
            top: _showAppBar ? 10 : MediaQuery.of(context).padding.top + 10,
            child: FloatingActionButton.small(
              backgroundColor: _activeColor.withOpacity(0.5),
              child: const Icon(Icons.tune, color: Colors.white, size: 18),
              onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
            ),
          ),

          if (_isMenuOpen) _buildSettings(),
        ],
      ),
    );
  }

  Widget _buildHandle(Offset pos, double r, Function(Offset) onMove) {
    return Positioned(
      left: pos.dx - (r + 15),
      top: pos.dy - (r + 15),
      child: GestureDetector(
        onPanUpdate: (details) => onMove(details.delta),
        child: Container(
          width: (r + 15) * 2,
          height: (r + 15) * 2,
          color: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _activeColor, width: 2),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "ڕێکخستنەکان",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(color: Colors.white24),
              
              // Show/Hide Aim Assist
              SwitchListTile(
                title: const Text("پیشاندانی Aim Assist", style: TextStyle(fontSize: 13, color: Colors.white)),
                value: _showAimAssist,
                activeColor: _activeColor,
                onChanged: (val) => setState(() => _showAimAssist = val),
              ),
              
              // Show/Hide AppBar
              SwitchListTile(
                title: const Text("پیشاندانی Navigation Bar", style: TextStyle(fontSize: 13, color: Colors.white)),
                value: _showAppBar,
                activeColor: _activeColor,
                onChanged: (val) => setState(() => _showAppBar = val),
              ),
              
              // Mobile/Desktop Mode
              SwitchListTile(
                title: Text(
                  _isMobileMode ? "مۆبایل مۆد 📱" : "دێسکتۆپ مۆد 💻",
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
                value: _isMobileMode,
                activeColor: _activeColor,
                onChanged: (val) {
                  setState(() => _isMobileMode = val);
                  webViewController?.setSettings(settings: _getWebViewSettings());
                  webViewController?.reload();
                },
              ),
              
              if (_showAimAssist) ...[
                _slider("قەبارەی گشتی", _allCircleSize / 100, (v) => setState(() => _allCircleSize = v * 100)),
                _slider("ڕوونی ڕێڕەو", _pathOpacity, (v) => setState(() => _pathOpacity = v)),
                const SizedBox(height: 10),
                const Text("ڕەنگ:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Colors.white,
                    Colors.red,
                    Colors.green,
                    Colors.cyan,
                    Colors.yellow,
                    Colors.purple,
                  ].map((c) => GestureDetector(
                    onTap: () => setState(() => _activeColor = c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: _activeColor == c ? 2.5 : 0,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ],
              
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => setState(() => _isMenuOpen = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _activeColor,
                  foregroundColor: Colors.black,
                ),
                child: const Text("داخستن", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, double val, Function(double) onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        Slider(
          value: val,
          min: 0.2,
          max: 1.0,
          activeColor: _activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }
}

class ProAimPainter extends CustomPainter {
  final Offset pivot, middle, end;
  final double radius, pathWidth, opacity;
  final Color color;

  ProAimPainter({
    required this.pivot,
    required this.middle,
    required this.end,
    required this.radius,
    required this.pathWidth,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double angle = math.atan2(end.dy - pivot.dy, end.dx - pivot.dx);
    double dist = (end - pivot).distance;

    // 1. Draw the Background Path (The "Capacity")
    final pathPaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromLTRBR(0, -pathWidth / 2, dist, pathWidth / 2, Radius.circular(radius)),
      pathPaint,
    );

    // 2. Draw the INNER LINE (The different color line inside the capacity)
    final innerLinePaint = Paint()
      ..color = Colors.red // Change this to any color you prefer
      ..strokeWidth = 2.0  // Thickness of the inner line
      ..strokeCap = StrokeCap.round;

    // Drawing the line from 0 to dist inside the rotated canvas
    canvas.drawLine(const Offset(0, 0), Offset(dist, 0), innerLinePaint);
    canvas.restore();

    // 3. Draw the Circles on top
    _drawCircle(canvas, pivot, radius);
    _drawCircle(canvas, middle, radius);
    _drawCircle(canvas, end, radius);
  }

  void _drawCircle(Canvas canvas, Offset center, double r) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, r, p);
    // Tiny center dot for extra precision
    canvas.drawCircle(center, 1, p..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}