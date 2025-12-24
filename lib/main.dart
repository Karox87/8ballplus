import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// These imports are required for the "Pro" webview features
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

  final double _baseHandleRadius = 30.0; // Bigger touch area

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    late final PlatformWebViewControllerCreationParams params;
 // Change this section:
if (WebViewPlatform.instance is WebKitWebViewPlatform) {
  params = WebKitWebViewControllerCreationParams(
    allowsInlineMediaPlayback: true,
    // FIX: Change PlaybackTier to PlaybackMediaTypes
    mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{}, 
  );
} else {
  params = const PlatformWebViewControllerCreationParams();
}

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    // FIX GOOGLE LOGIN: Use a slightly older generic Pixel UserAgent
    // This specific string is very successful at bypassing Google blocks.
    const String proUserAgent = 
        "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36";

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(proUserAgent)
      ..setBackgroundColor(const Color(0xFF121212)) // Black background while loading
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() { _isLoading = true; _hasError = false; });
          },
          onPageFinished: (String url) {
            setState(() { _isLoading = false; });
          },
          onWebResourceError: (WebResourceError error) {
            // Only show error screen for MAJOR errors (like no internet)
            if (error.errorCode == -2 || error.description.contains("NAME_NOT_RESOLVED")) {
               setState(() { _hasError = true; _isLoading = false; });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Always allow navigation so Google Login redirects work
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://onepersone.store'));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

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

  @override
  Widget build(BuildContext context) {
    // Dynamic handle size
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
            
          // Loading Bar (Cyan Neon)
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

          // 3. CONTROLS (TOUCH HANDLES)
          // Double Circle Handle
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

          // Single Circle Handle
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

          // 4. MENU
          _buildFloatingControls(),
        ],
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
              "Could not load website",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "1. Check your internet connection.\n2. Ensure you added <uses-permission> in AndroidManifest.\n3. Try a different URL.",
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
                hintText: "Try google.com",
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _reloadWithUrl(urlController.text.isNotEmpty ? urlController.text : "https://google.com"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
              child: const Text("RELOAD", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      right: 15, top: 50,
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
    required this.pivotPoint, required this.targetPoint,
    required this.color, required this.width,
    required this.pivotScale, required this.targetScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = width..style = PaintingStyle.stroke;
    final fill = Paint()..color = color..style = PaintingStyle.fill;
    
    // Line
    double dx = targetPoint.dx - pivotPoint.dx;
    double dy = targetPoint.dy - pivotPoint.dy;
    double dist = math.sqrt(dx*dx + dy*dy);
    if (dist == 0) dist = 0.1;
    Offset end = Offset(pivotPoint.dx + (dx/dist)*3000, pivotPoint.dy + (dy/dist)*3000);
    canvas.drawLine(pivotPoint, end, paint);

    // Pivot (Double)
    canvas.drawCircle(pivotPoint, 6 * pivotScale, fill);
    canvas.drawCircle(pivotPoint, 18 * pivotScale, paint);

    // Target (Single)
    canvas.drawCircle(targetPoint, 10 * targetScale, fill);
  }

  @override
  bool shouldRepaint(covariant ProAimPainter old) => true;
}