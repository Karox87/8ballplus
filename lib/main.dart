import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:math' as math;

void main() {
  runApp(const BilliardAimApp());
}

class BilliardAimApp extends StatelessWidget {
  const BilliardAimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pro Aim Assistant',
      debugShowCheckedModeBanner: false,
      // Dark theme for a professional look
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.tealAccent,
        sliderTheme: const SliderThemeData(
          showValueIndicator: ShowValueIndicator.always,
        )
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
  
  // --- Aim Assist State ---
  Offset _pivotPoint = const Offset(100, 400); // The "Double Circle" (Cue Ball)
  Offset _targetPoint = const Offset(300, 300); // The "Single Circle" (Aim)
  
  // Customization State
  Color _aimColor = Colors.white;
  double _lineWidth = 3.0; 
  double _opacity = 0.8;
  double _circleScale = 1.0; // New: Scale factor for circles (0.5x to 2.5x)
  bool _isControlsOpen = false;

  // Base radius for touch handles, will be multiplied by scale
  final double _baseHandleRadius = 22.0; 

  @override
  void initState() {
    super.initState();
    // Initialize WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() { _isLoading = true; _hasError = false; });
          },
          onPageFinished: (String url) {
            setState(() { _isLoading = false; });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() { _hasError = true; _isLoading = false; });
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      // Using google as default just to show it works, as onepersone.store is down
      ..loadRequest(Uri.parse('https://www.google.com/search?q=play+billiard+online')); 
  }

  void _reloadWithUrl(String url) {
    if (url.isEmpty) return;
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    _controller.loadRequest(Uri.parse(url));
    setState(() { _hasError = false; _isLoading = true;});
  }

  @override
  Widget build(BuildContext context) {
    // Calculate current handle size based on scale scale
    final double currentHandleRadius = _baseHandleRadius * _circleScale;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents webview resize when keyboard opens
      body: Stack(
        children: [
          // 1. WEBVIEW LAYER
          if (_hasError) 
            _buildErrorScreen()
          else 
            WebViewWidget(controller: _controller),
            
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),

          // 2. AIM OVERLAY LAYER
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ProAimPainter(
                  pivotPoint: _pivotPoint,
                  targetPoint: _targetPoint,
                  color: _aimColor.withOpacity(_opacity),
                  width: _lineWidth,
                  circleScale: _circleScale, // Pass scale to painter
                ),
              ),
            ),
          ),

          // 3. GESTURE HANDLES
          
          // -- Handle A: DOUBLE CIRCLE (Pivot) --
          Positioned(
            left: _pivotPoint.dx - currentHandleRadius,
            top: _pivotPoint.dy - currentHandleRadius,
            child: GestureDetector(
              // Using PanUpdate for smooth dragging
              onPanUpdate: (details) {
                setState(() {
                  // Move both points together
                  _pivotPoint += details.delta;
                  _targetPoint += details.delta;
                });
              },
              child: Container(
                width: currentHandleRadius * 2,
                height: currentHandleRadius * 2,
                decoration: const BoxDecoration(
                  color: Colors.transparent, // Invisible touch zone
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // -- Handle B: SINGLE CIRCLE (Rotate) --
          Positioned(
            left: _targetPoint.dx - currentHandleRadius,
            top: _targetPoint.dy - currentHandleRadius,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  // Only move target point
                  _targetPoint += details.delta;
                });
              },
              child: Container(
                width: currentHandleRadius * 2,
                height: currentHandleRadius * 2,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // 4. FLOATING TOOLS MENU
          _buildFloatingControls(),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildErrorScreen() {
    final TextEditingController urlController = TextEditingController();
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              "Website Error",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "The default website could not be loaded. Please enter a valid game URL.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black54,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                labelText: "Enter URL (e.g., google.com)",
                labelStyle: const TextStyle(color: Colors.tealAccent),
                prefixIcon: const Icon(Icons.link, color: Colors.tealAccent),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _reloadWithUrl(urlController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text("Load URL"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      right: 16,
      top: 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Toggle Button
          FloatingActionButton.small(
            backgroundColor: _isControlsOpen ? Colors.redAccent : Colors.tealAccent,
            child: Icon(_isControlsOpen ? Icons.close : Icons.settings, color: Colors.black),
            onPressed: () => setState(() => _isControlsOpen = !_isControlsOpen),
          ),
          
          if (_isControlsOpen) ...[
            const SizedBox(height: 12),
            // Controls Container
            Container(
              width: 220,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black87.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("AIM SETTINGS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
                  const Divider(color: Colors.white24, height: 20),
                  
                  // Color Picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _colorDot(Colors.white),
                      _colorDot(Colors.redAccent),
                      _colorDot(Colors.greenAccent),
                      _colorDot(Colors.cyanAccent),
                      _colorDot(Colors.yellowAccent),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Sliders using custom theme for labels
                  _buildSliderLabel("Line Thickness", _lineWidth.toStringAsFixed(1)),
                  Slider(
                    value: _lineWidth, min: 1.0, max: 8.0,
                    activeColor: Colors.tealAccent, inactiveColor: Colors.white24,
                    label: _lineWidth.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _lineWidth = v),
                  ),

                  _buildSliderLabel("Circle Size", "${(_circleScale * 100).toInt()}%"),
                  Slider(
                    value: _circleScale, min: 0.5, max: 2.5, // Scale from 50% to 250%
                    activeColor: Colors.tealAccent, inactiveColor: Colors.white24,
                    label: "${(_circleScale * 100).toInt()}%",
                    onChanged: (v) => setState(() => _circleScale = v),
                  ),

                  _buildSliderLabel("Opacity", "${(_opacity * 100).toInt()}%"),
                  Slider(
                    value: _opacity, min: 0.1, max: 1.0,
                    activeColor: Colors.tealAccent, inactiveColor: Colors.white24,
                    label: "${(_opacity * 100).toInt()}%",
                    onChanged: (v) => setState(() => _opacity = v),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSliderLabel(String title, String value) {
     return Padding(
       padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0),
       child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
           ),
     );
  }

  Widget _colorDot(Color c) {
    bool isSelected = _aimColor == c;
    return GestureDetector(
      onTap: () => setState(() => _aimColor = c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 28 : 24,
        height: isSelected ? 28 : 24,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.tealAccent : Colors.transparent, width: 2.5),
          boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 8)] : null,
        ),
      ),
    );
  }
}

// --- Professional Aim Painter ---
class ProAimPainter extends CustomPainter {
  final Offset pivotPoint;
  final Offset targetPoint;
  final Color color;
  final double width;
  final double circleScale; // Add scale factor

  // Base radii constants
  static const double _basePivotInner = 5.0;
  static const double _basePivotOuter = 16.0;
  static const double _baseTarget = 9.0;

  ProAimPainter({
    required this.pivotPoint,
    required this.targetPoint,
    required this.color,
    required this.width,
    required this.circleScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, width * 0.3); // Scale stroke slightly with line width

    // 1. Calculate Infinite Line Vector
    double dx = targetPoint.dx - pivotPoint.dx;
    double dy = targetPoint.dy - pivotPoint.dy;
    double distance = math.sqrt(dx * dx + dy * dy);
    
    // Avoid division by zero if points are on top of each other
    if (distance < 1.0) distance = 1.0;
    
    double unitX = dx / distance;
    double unitY = dy / distance;

    // Extend very far
    Offset extendedPoint = Offset(
      pivotPoint.dx + unitX * 3000,
      pivotPoint.dy + unitY * 3000,
    );

    // 2. Draw Aim Line
    canvas.drawLine(pivotPoint, extendedPoint, Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round);

    // 3. Draw "Double Circle" at Pivot (Scaled)
    // Inner Solid
    canvas.drawCircle(pivotPoint, _basePivotInner * circleScale, paintFill); 
    // Outer Ring
    canvas.drawCircle(pivotPoint, _basePivotOuter * circleScale, paintStroke); 

    // 4. Draw "Single Circle" at Target (Scaled)
    canvas.drawCircle(targetPoint, _baseTarget * circleScale, paintFill);
  }

  @override
  bool shouldRepaint(covariant ProAimPainter old) {
    return old.pivotPoint != pivotPoint || 
           old.targetPoint != targetPoint ||
           old.color != color || 
           old.width != width ||
           old.circleScale != circleScale; // Repaint if scale changes
  }
}