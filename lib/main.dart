import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import specific platform implementations to fix initialization errors

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
        sliderTheme: const SliderThemeData(
          showValueIndicator: ShowValueIndicator.always,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
        ),
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
  bool _hasError = false; // Controls the error screen
  bool _isControlsOpen = false;

  // --- Aim Assist State ---
  Offset _pivotPoint = const Offset(100, 450); 
  Offset _targetPoint = const Offset(300, 300);
  
  // Customization
  Color _aimColor = Colors.white;
  double _lineWidth = 3.0; 
  double _opacity = 0.8;
  double _pivotScale = 1.0;  // Size of Double Circle
  double _targetScale = 1.0; // Size of Single Circle

  final double _baseHandleRadius = 25.0; 

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // Platform-specific initialization parameters
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
       // mediaTypesRequiringUserAction: const <PlaybackTier>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    // FIX GOOGLE LOGIN: Use a real Android phone UserAgent
    const String proUserAgent = 
        "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36";

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(proUserAgent) 
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
          },
          onWebResourceError: (WebResourceError error) {
            // CRITICAL FIX: Capture ERR_NAME_NOT_RESOLVED
            // We only show the error screen if the Main Frame fails
            if (error.isForMainFrame ?? true) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      // We try the user's URL, but if it fails, the onWebResourceError above handles it.
      ..loadRequest(Uri.parse('https://onepersone.store'));

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
    final double pivotHandleSize = _baseHandleRadius * _pivotScale;
    final double targetHandleSize = _baseHandleRadius * _targetScale;

    return Scaffold(
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          // 1. WEBVIEW LAYER (Only show if no error)
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

          // 2. AIM OVERLAY LAYER
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

          // 3. TOUCH HANDLES (Controls)
          
          // Pivot Handle (Double Circle)
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

          // Target Handle (Single Circle)
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

          // 4. FLOATING MENU
          _buildFloatingControls(),
        ],
      ),
    );
  }

  // --- ERROR SCREEN ---
  Widget _buildErrorScreen() {
    final TextEditingController urlController = TextEditingController();
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 80, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              "Website Not Found",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "The address 'onepersone.store' could not be resolved.\nIt may be offline or typed incorrectly.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black45,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: "Enter a valid URL (e.g. google.com)",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF00E5FF)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _reloadWithUrl(urlController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("TRY AGAIN", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- SETTINGS MENU ---
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
            const SizedBox(height: 12),
            Container(
              width: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xE6121212), // 90% opacity black
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header("VISUALS"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _colorDot(Colors.white),
                      _colorDot(const Color(0xFF00E5FF)), // Cyan
                      _colorDot(Colors.greenAccent),
                      _colorDot(Colors.redAccent),
                      _colorDot(Colors.yellowAccent),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _slider("Line Thickness", _lineWidth, 1, 8, (v) => _lineWidth = v),
                  _slider("Opacity", _opacity, 0.1, 1, (v) => _opacity = v),
                  
                  const SizedBox(height: 15),
                  _header("SIZING (INDEPENDENT)"),
                  _slider("Pivot Size (Double)", _pivotScale, 0.5, 3.0, (v) => _pivotScale = v),
                  _slider("Aim Size (Single)", _targetScale, 0.5, 3.0, (v) => _targetScale = v),
                  
                  const SizedBox(height: 10),
                  // Quick link to reload default if stuck
                  Center(
                    child: TextButton(
                      onPressed: () => _reloadWithUrl("https://www.google.com"),
                      child: const Text("Reset to Google", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ),
                  )
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
    );
  }

  Widget _slider(String label, double val, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        SizedBox(
          height: 30,
          child: Slider(
            value: val, min: min, max: max,
            activeColor: const Color(0xFF00E5FF),
            inactiveColor: Colors.white12,
            onChanged: (v) => setState(() => onChanged(v)),
          ),
        ),
      ],
    );
  }

  Widget _colorDot(Color c) {
    bool isSelected = _aimColor == c;
    return GestureDetector(
      onTap: () => setState(() => _aimColor = c),
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)] : null,
        ),
      ),
    );
  }
}

// --- PAINTER (Graphics) ---
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
    final fill = Paint()..color = color..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, width * 0.4);

    // 1. Aim Line (Infinite)
    double dx = targetPoint.dx - pivotPoint.dx;
    double dy = targetPoint.dy - pivotPoint.dy;
    double dist = math.sqrt(dx*dx + dy*dy);
    if(dist == 0) dist = 1;
    
    // Extrapolate line 3000px outward
    Offset end = Offset(pivotPoint.dx + (dx/dist) * 3000, pivotPoint.dy + (dy/dist) * 3000);
    
    canvas.drawLine(pivotPoint, end, Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round);

    // 2. Pivot (Double Circle)
    canvas.drawCircle(pivotPoint, 5.0 * pivotScale, fill); // Inner
    canvas.drawCircle(pivotPoint, 16.0 * pivotScale, stroke); // Outer

    // 3. Target (Single Circle)
    canvas.drawCircle(targetPoint, 9.0 * targetScale, fill);
  }

  @override
  bool shouldRepaint(covariant ProAimPainter old) => true;
}