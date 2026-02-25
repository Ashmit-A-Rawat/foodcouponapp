// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import '../services/api_service.dart'; // FIX: import needed for ApiService

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // FIX: create instance so we can call getMe()
  final _apiService = ApiService();

  late AnimationController _animationController;
  late AnimationController _floatController;
  late AnimationController _rotateController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20000),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.elasticOut),
    );

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _rotateAnimation =
        Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_rotateController);

    _animationController.forward();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Minimum splash display time
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (token != null && token.isNotEmpty) {
      // FIX: validate token is still accepted by the server
      final result = await _apiService.getMe();

      if (!mounted) return;

      if (!result['success']) {
        // Token expired or invalid — clear and go to login
        await _apiService.clearData();
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Token valid — navigate by role
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-home');
      } else if (role == 'canteen') {
        Navigator.pushReplacementNamed(context, '/canteen-home');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F7),
        ),
        child: Stack(
          children: [
            // Animated rotating geometric shapes
            ...List.generate(6, (index) {
              return AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  final rotation =
                      _rotateAnimation.value + (index * math.pi / 3);
                  final size = 150.0 + (index * 30.0);
                  final opacity = 0.03 + (index * 0.01);

                  return Positioned(
                    left: MediaQuery.of(context).size.width / 2 - size / 2,
                    top: MediaQuery.of(context).size.height / 2 - size / 2,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                const Color(0xFF6366F1).withOpacity(opacity),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(size / 4),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Floating decorative elements
            Positioned(
              top: 100,
              right: 40,
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              left: 30,
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -_floatAnimation.value),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200,
              left: 50,
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _floatAnimation.value * 0.7),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 250,
              right: 60,
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -_floatAnimation.value * 0.5),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _floatAnimation.value * 0.3),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.9),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1)
                                          .withOpacity(0.15),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    size: 70,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Title
                      const Text(
                        'Metro Food',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.8)),
                            ),
                            child: Text(
                              'Your Monthly Food Wallet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 70),

                      // Loading indicator
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.8)),
                            ),
                            child: const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6366F1)),
                                strokeWidth: 3,
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
          ],
        ),
      ),
    );
  }
}