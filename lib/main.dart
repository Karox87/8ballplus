import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:math' as math;

void main() {
  runApp(const BilliardAimApp());
}

class BilliardAimApp extends StatelessWidget {
  const BilliardAimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pro Aim Tool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00E5FF),
      ),
      home: const GameBrowserScreen(),
    );
  }
}

class GameBrowserScreen extends StatefulWidget {
  const GameBrowserScreen({super.key});

  @override
  State<GameBrowserScreen> createState() => _GameBrowserScreenState();
}

class _GameBrowserScreenState extends State<GameBrowserScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isControlsOpen = false;

  // --- Aim Assist State ---
  Offset _pivotPoint = const Offset(100, 450); 
  Offset _targetPoint = const Offset(300, 300);
  
  // Customization
  Color _aimColor = Colors.white;
  double _lineWidth = 3.0; 
  double _opacity = 0.8;
  double _pivotScale = 1.0; 
  double _targetScale = 1.0; 

  final double _baseHandleRadius = 30.0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    late final PlatformWebViewControllerCreationParams params;
    
    // ✅ FIX 1: iOS Configuration - بۆ کردنەوەی وێبسایت و گوگڵ لۆگین
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        // ⭐ iOS-specific settings بۆ باشترکردنی کارکردن
        limitsNavigationsToAppBoundDomains: false,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    // ✅ FIX 2: UserAgent بۆ iOS - دەبێت وەکو Safari بێت بۆ گوگڵ لۆگین
    const String iosUserAgent = 
        "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1";

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(iosUserAgent)
      ..setBackgroundColor(const Color(0xFF121212))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() { 
              _isLoading = true; 
              _hasError = false; 
            });
          },
          onPageFinished: (String url) {
            setState(() { _isLoading = false; });
            
            // ✅ FIX 3: Inject JavaScript بۆ باشترکردنی تاچ ئیڤێنتەکان لە iOS
            controller.runJavaScript('''
              (function() {
                // بەرزکردنەوەی تاچ سێنسیتیڤیتی
                document.addEventListener('touchstart', function(e) {
                  e.stopPropagation();
                }, {passive: true});
                
                // بەرزکردنەوەی viewport بۆ iOS
                var meta = document.querySelector('meta[name="viewport"]');
                if (!meta) {
                  meta = document.createElement('meta');
                  meta.name = 'viewport';
                  document.head.appendChild(meta);
                }
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
              })();
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('⚠️ WebView Error: ${error.errorCode} - ${error.description}');
            // تەنها ئێڕەرە گەورەکان نیشان بدە
            if (error.errorCode == -1009 || // No internet (iOS)
                error.errorCode == -1003 || // Host not found (iOS)
                error.errorCode == -2 ||    // Android equivalent
                error.description.contains('NAME_NOT_RESOLVED')) {
              setState(() { 
                _hasError = true; 
                _isLoading = false; 
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // ✅ FIX 4: ڕێگەدان بە هەموو نێڤیگەیشنێک بۆ گوگڵ OAuth
            debugPrint('🔗 Navigating to: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );

    // ✅ FIX 5: Platform-specific configuration
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    } else if (controller.platform is WebKitWebViewController) {
      // iOS-specific settings
      (controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }

    // ✅ لۆد کردنی وێبسایت
    controller.loadRequest(
      Uri.parse('https://onepersone.store'),
      headers: {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
      },
    );

    _controller = controller;
  }

  void _reloadWithUrl(String url) {
    if (url.isEmpty) return;
    String cleanUrl = url.trim();
    if (!cleanUrl.startsWith('http')) {
      cleanUrl = 'https://$cleanUrl';
    }
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _controller.loadRequest(Uri.parse(cleanUrl));
  }

  // ✅ FIX 6: دوگمەی رێفرێش زیادکردن
  void _refreshWebView() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _controller.reload();
  }

  // ✅ FIX 7: دوگمەکانی navigation
  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  Future<void> _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double pivotHandleSize = _baseHandleRadius * _pivotScale;
    final double targetHandleSize = _baseHandleRadius * _targetScale;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. WEBVIEW LAYER
          if (_hasError) 
            _buildErrorScreen()
          else 
            WebViewWidget(controller: _controller),
            
          // Loading Bar
          if (_isLoading && !_hasError)
            const Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(
                color: Color(0xFF00E5FF), 
                backgroundColor: Colors.transparent,
                minHeight: 4,
              ),
            ),

          // 2. VISUAL OVERLAY
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ProAimPainter(
                  pivotPoint: _pivotPoint,
                  targetPoint: _targetPoint,
                  color: _aimColor.withOpacity(_opacity),
                  width: _lineWidth,
                  pivotScale: _pivotScale,
                  targetScale: _targetScale,
                ),
              ),
            ),
          ),

          // 3. TOUCH HANDLES
          Positioned(
            left: _pivotPoint.dx - pivotHandleSize,
            top: _pivotPoint.dy - pivotHandleSize,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _pivotPoint += details.delta;
                  _targetPoint += details.delta;
                });
              },
              child: Container(
                width: pivotHandleSize * 2,
                height: pivotHandleSize * 2,
                color: Colors.transparent,
              ),
            ),
          ),

          Positioned(
            left: _targetPoint.dx - targetHandleSize,
            top: _targetPoint.dy - targetHandleSize,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _targetPoint += details.delta;
                });
              },
              child: Container(
                width: targetHandleSize * 2,
                height: targetHandleSize * 2,
                color: Colors.transparent,
              ),
            ),
          ),

          // 4. ✅ Navigation Controls (NEW)
          _buildNavigationBar(),

          // 5. MENU
          _buildFloatingControls(),
        ],
      ),
    );
  }

  // ✅ FIX 8: دوگمەکانی Navigation
  Widget _buildNavigationBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _goBack,
              tooltip: 'Back',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              onPressed: _goForward,
              tooltip: 'Forward',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF)),
              onPressed: _refreshWebView,
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    final TextEditingController urlController = TextEditingController();
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.public_off, size: 60, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              "ناتوانرێت وێبسایت بکرێتەوە",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "١. ئینتەرنێتەکەت پشکنین بکە\n٢. دڵنیابە لە پەرمیتەکان لە Info.plist\n٣. URLـێکی دیکە تاقیبکەرەوە",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black45,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                hintText: "google.com تاقیبکەرەوە",
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _reloadWithUrl(
                urlController.text.isNotEmpty ? urlController.text : "https://google.com"
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text(
                "دووبارە تاقیبکەرەوە", 
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      right: 15, 
      top: 50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            backgroundColor: _isControlsOpen ? Colors.redAccent : const Color(0xFF00E5FF),
            child: Icon(_isControlsOpen ? Icons.close : Icons.tune, color: Colors.black),
            onPressed: () => setState(() => _isControlsOpen = !_isControlsOpen),
          ),
          if (_isControlsOpen) ...[
            const SizedBox(height: 10),
            Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  _slider("Line Width", _lineWidth, 1, 6, (v) => _lineWidth = v),
                  _slider("Opacity", _opacity, 0.2, 1, (v) => _opacity = v),
                  const Divider(color: Colors.white24),
                  _slider("Pivot Size", _pivotScale, 0.5, 2.5, (v) => _pivotScale = v),
                  _slider("Target Size", _targetScale, 0.5, 2.5, (v) => _targetScale = v),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _slider(String label, double val, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        SizedBox(
          height: 20,
          child: Slider(
            value: val, min: min, max: max,
            activeColor: const Color(0xFF00E5FF),
            inactiveColor: Colors.white10,
            onChanged: (v) => setState(() => onChanged(v)),
          ),
        ),
      ],
    );
  }
}

class ProAimPainter extends CustomPainter {
  final Offset pivotPoint;
  final Offset targetPoint;
  final Color color;
  final double width;
  final double pivotScale;
  final double targetScale;

  ProAimPainter({
    required this.pivotPoint, 
    required this.targetPoint,
    required this.color, 
    required this.width,
    required this.pivotScale, 
    required this.targetScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Line
    double dx = targetPoint.dx - pivotPoint.dx;
    double dy = targetPoint.dy - pivotPoint.dy;
    double dist = math.sqrt(dx*dx + dy*dy);
    if (dist == 0) dist = 0.1;
    Offset end = Offset(
      pivotPoint.dx + (dx/dist)*3000, 
      pivotPoint.dy + (dy/dist)*3000
    );
    canvas.drawLine(pivotPoint, end, paint);

    // Pivot (Double Circle)
    canvas.drawCircle(pivotPoint, 6 * pivotScale, fill);
    canvas.drawCircle(pivotPoint, 18 * pivotScale, paint);

    // Target (Single Circle)
    canvas.drawCircle(targetPoint, 10 * targetScale, fill);
  }

  @override
  bool shouldRepaint(covariant ProAimPainter old) => true;
}