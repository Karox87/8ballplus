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
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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
  bool _isMenuOpen = false;

  // --- Aim Tool State ---
  Offset _pivotPoint = const Offset(100, 600); 
  Offset _middlePoint = const Offset(180, 520); 
  double _lineLength = 280.0; 
  double _circleSize = 35.0;
  double _pathWidth = 65.0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // KEY FIX: Use a more "trusted" User Agent that mimics a real mobile Chrome browser
      ..setUserAgent(
        "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/119.0.6045.193 Mobile Safari/537.36"
      )
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            print('📱 Started: $url');
          },
          onPageFinished: (url) async {
            setState(() => _isLoading = false);
            print('✅ Finished: $url');
            
            // Fix Firebase/Google Auth session storage issues
            await _controller.runJavaScript('''
              (function() {
                try {
                  // Enable session storage
                  if (typeof(Storage) !== "undefined") {
                    console.log("Storage is available");
                  }
                  
                  // Fix for Firebase auth
                  if (window.location.href.includes('oneperson.store')) {
                    // Clear any auth errors
                    var errors = document.querySelectorAll('[role="alert"]');
                    errors.forEach(e => e.remove());
                  }
                  
                  // Make navigator appear legitimate
                  Object.defineProperty(navigator, 'webdriver', {
                    get: () => false
                  });
                  
                  // Fix storage access
                  if (!window.sessionStorage) {
                    console.error("Session storage not available");
                  }
                  
                } catch(e) {
                  console.error("Init error:", e);
                }
              })();
            ''');
            
            // If we see the Firebase error, try to reload once
            if (url.contains('oneperson.store')) {
              // Check for error message
              final hasError = await _controller.runJavaScriptReturningResult(
                'document.body.innerText.includes("missing initial state")'
              );
              
              if (hasError.toString() == 'true') {
                print('⚠️ Detected Firebase error, reloading...');
                Future.delayed(const Duration(seconds: 1), () {
                  _controller.reload();
                });
              }
            }
          },
          onWebResourceError: (error) {
            print('❌ Error: ${error.description}');
          },
          onNavigationRequest: (request) {
            print('🔗 Navigation: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://oneperson.store'));

    // Android specific settings - CRITICAL for Google login
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController = _controller.platform as AndroidWebViewController;
      
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double dx = _middlePoint.dx - _pivotPoint.dx;
    double dy = _middlePoint.dy - _pivotPoint.dy;
    double angle = math.atan2(dy, dx);
    
    Offset endPoint = Offset(
      _pivotPoint.dx + math.cos(angle) * _lineLength,
      _pivotPoint.dy + math.sin(angle) * _lineLength,
    );

    return Scaffold(
      body: Stack(
        children: [
          // 1. WEBVIEW
          WebViewWidget(controller: _controller),
          
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.red)),

          // 2. AIM VISUALS
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ProAimPainter(
                  pivot: _pivotPoint,
                  middle: _middlePoint,
                  end: endPoint,
                  radius: _circleSize,
                  pathWidth: _pathWidth,
                ),
              ),
            ),
          ),

          // 3. TOUCH HANDLES
          _buildHandle(_pivotPoint, _circleSize, (d) {
            setState(() { _pivotPoint += d; _middlePoint += d; });
          }),
          _buildHandle(_middlePoint, 20, (d) => setState(() => _middlePoint += d)),
          _buildHandle(endPoint, _circleSize, (d) {
            setState(() {
              Offset newEnd = endPoint + d;
              _lineLength = (newEnd - _pivotPoint).distance;
            });
          }),

          // 4. FLOATING BUTTONS
          Positioned(
            right: 20, top: 50,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'refresh',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.refresh, color: Colors.black),
                  onPressed: () => _controller.reload(),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'browser',
                  backgroundColor: Colors.purple,
                  child: const Icon(Icons.open_in_new, color: Colors.white),
                  onPressed: () {
                    // Show instructions to login in Chrome first
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Login Issue?'),
                        content: const Text(
                          'If login is not working:\n\n'
                          '1. Open Chrome browser\n'
                          '2. Go to oneperson.store\n'
                          '3. Login with Google there\n'
                          '4. Come back to this app\n'
                          '5. Press the green Home button\n\n'
                          'Your session should work then!'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                FloatingActionButton.small(
                  heroTag: 'settings',
                  backgroundColor: Colors.cyanAccent,
                  child: Icon(_isMenuOpen ? Icons.close : Icons.tune, color: Colors.black),
                  onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'back',
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () async {
                    if (await _controller.canGoBack()) {
                      _controller.goBack();
                    }
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'home',
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.home, color: Colors.white),
                  onPressed: () => _controller.loadRequest(Uri.parse('https://oneperson.store')),
                ),
              ],
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
        child: Container(width: (r + 15) * 2, height: (r + 15) * 2, color: Colors.transparent),
      ),
    );
  }

  Widget _buildSettings() {
    return Center(
      child: Container(
        width: 280, 
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black87, 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyanAccent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "TOOL DESIGN", 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
                color: Colors.cyanAccent,
              )
            ),
            const SizedBox(height: 10),
            _slider("Circle Size", _circleSize / 80, (v) => setState(() => _circleSize = v * 80)),
            _slider("Path Width", _pathWidth / 120, (v) => setState(() => _pathWidth = v * 120)),
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),
            const Text(
              "💡 Tip: Use orange button to go back during login",
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () => setState(() => _isMenuOpen = false), 
              child: const Text("CLOSE"),
            ),
          ],
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
          min: 0.1, 
          max: 1.0, 
          activeColor: Colors.cyanAccent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class ProAimPainter extends CustomPainter {
  final Offset pivot, middle, end;
  final double radius, pathWidth;

  ProAimPainter({
    required this.pivot, 
    required this.middle, 
    required this.end, 
    required this.radius, 
    required this.pathWidth
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    final redLine = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double angle = math.atan2(end.dy - pivot.dy, end.dx - pivot.dx);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.drawRect(
      Rect.fromLTWH(0, -pathWidth / 2, (end - pivot).distance, pathWidth), 
      shadowPaint
    );
    canvas.restore();

    canvas.drawLine(pivot, end, redLine);
    _drawDashedCircle(canvas, pivot, radius);
    _drawDashedCircle(canvas, middle, 18);
    _drawDashedCircle(canvas, end, radius);
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double r) {
    final p = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 20; i++) {
      double angle = (2 * math.pi / 20) * i;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r), 
        angle, 
        math.pi / 20, 
        false, 
        p
      );
    }
  }

  @override 
  bool shouldRepaint(covariant CustomPainter old) => true;
}