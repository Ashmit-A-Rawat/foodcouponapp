// lib/screens/qr_scanner_screen.dart
//
// USER scans the QR code displayed by the CANTEEN to confirm order collection.
// Flow:
//   1. Canteen shows QR for a ready order (CanteenOrdersScreen "Show QR" button)
//   2. User opens this screen from MyOrdersScreen or HomeScreen
//   3. User scans the QR → POST /api/orders/verify-qr { qrToken }
//   4. Backend marks order as "completed"
//   5. Success dialog shown, returns to previous screen

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:ui';
import '../services/api_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  final ApiService _apiService = ApiService();

  bool _isProcessing = false;
  bool _hasScanned = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _hasScanned) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _handleScan(code);
  }

  Future<void> _handleScan(String qrToken) async {
    setState(() {
      _isProcessing = true;
      _hasScanned = true;
    });
    _controller.stop();
    _pulseController.stop();

    final result = await _apiService.verifyQRAndCompleteOrder(qrToken);

    if (!mounted) return;

    if (result['success'] == true) {
      await _showSuccessDialog(result);
    } else {
      await _showErrorDialog(result['message'] ?? 'Invalid or expired QR code');
    }
  }

  Future<void> _showSuccessDialog(Map<String, dynamic> result) async {
    final orderNumber = result['order']?['orderNumber']?.toString() ?? '';
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        success: true,
        title: 'Order Collected!',
        subtitle: orderNumber.isNotEmpty ? 'Order #$orderNumber' : '',
        message: 'Your order has been marked as collected. Enjoy your meal!',
        buttonLabel: 'Done',
        onPressed: () {
          Navigator.pop(context);       // close dialog
          Navigator.pop(context, true); // return to caller with success=true
        },
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
      context: context,
      builder: (_) => _ResultDialog(
        success: false,
        title: 'Scan Failed',
        subtitle: '',
        message: message,
        buttonLabel: 'Try Again',
        onPressed: () {
          Navigator.pop(context);
          setState(() {
            _isProcessing = false;
            _hasScanned = false;
          });
          _pulseController.repeat(reverse: true);
          _controller.start();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Dark overlay with transparent cutout
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _OverlayPainter(),
          ),

          // Top header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _GlassButton(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'Scan Order QR Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Animated scanning frame
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) => Opacity(
                opacity:
                    _isProcessing ? 1.0 : _pulseAnimation.value,
                child: SizedBox(
                  width: 270,
                  height: 270,
                  child: Stack(children: [
                    // Border
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isProcessing
                              ? Colors.white
                              : const Color(0xFF6366F1),
                          width: 3,
                        ),
                      ),
                    ),
                    // Corners
                    _FrameCorner(top: -3, left: -3,
                        isProcessing: _isProcessing,
                        radius: const BorderRadius.only(
                            topLeft: Radius.circular(24))),
                    _FrameCorner(top: -3, right: -3,
                        isProcessing: _isProcessing,
                        radius: const BorderRadius.only(
                            topRight: Radius.circular(24))),
                    _FrameCorner(bottom: -3, left: -3,
                        isProcessing: _isProcessing,
                        radius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24))),
                    _FrameCorner(bottom: -3, right: -3,
                        isProcessing: _isProcessing,
                        radius: const BorderRadius.only(
                            bottomRight: Radius.circular(24))),
                  ]),
                ),
              ),
            ),
          ),

          // Bottom instruction
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 56, top: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter:
                          ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF6366F1).withOpacity(0.35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded,
                                color: Colors.white, size: 22),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Scan QR shown by canteen',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Point camera at canteen's screen",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter:
                        ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                          SizedBox(height: 20),
                          Text('Verifying...',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _FrameCorner extends StatelessWidget {
  final double? top, bottom, left, right;
  final bool isProcessing;
  final BorderRadius radius;
  const _FrameCorner(
      {this.top,
      this.bottom,
      this.left,
      this.right,
      required this.isProcessing,
      required this.radius});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isProcessing ? Colors.white : const Color(0xFF6366F1),
          borderRadius: radius,
        ),
      ),
    );
  }
}

// ── Dark overlay with transparent scanning cutout ─────────────────────────────
class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    const frameSize = 270.0;
    const radius = 24.0;
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2;
    final cutout = RRect.fromLTRBR(
      left, top, left + frameSize, top + frameSize,
      const Radius.circular(radius),
    );
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutout)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => false;
}

// ── Animated result dialog ────────────────────────────────────────────────────
class _ResultDialog extends StatefulWidget {
  final bool success;
  final String title;
  final String subtitle;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _ResultDialog({
    required this.success,
    required this.title,
    required this.subtitle,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.success
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final icon = widget.success
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.9), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 72),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          Text(widget.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937))),
                          if (widget.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(widget.subtitle,
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(widget.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                  height: 1.4)),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16)),
                              ),
                              child: Text(widget.buttonLabel,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}