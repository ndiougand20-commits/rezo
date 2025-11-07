import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoFadeAnimation;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  late AnimationController _shadowController;
  late Animation<double> _shadowFadeAnimation;

  late AnimationController _fadeOutController;
  late Animation<double> _fadeOutAnimation;

  bool _showShadow = false;

  @override
  void initState() {
    super.initState();

    // 🎬 1. Animation d'apparition du logo (slide + fade)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack, // effet de rebond léger
    ));
    _logoFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeIn,
      ),
    );

    // 🔍 2. Animation de zoom progressif (scale)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutExpo,
      ),
    );

    // 🌫️ 3. Animation d'apparition de l’ombre
    _shadowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _shadowFadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_shadowController);

    // 🌙 4. Animation de fade out
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeOutAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _fadeOutController,
        curve: Curves.easeInOut,
      ),
    );

    // Démarre la séquence d'animation
    scheduleAnimations();
  }

  void scheduleAnimations() async {
    // 0.0s -> 0.3s : écran blanc (plus court pour plus d'impact)
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    // 1.5s -> démarrage du zoom (plus rapide)
    await Future.delayed(const Duration(milliseconds: 1200));
    _scaleController.forward();

    // 2.8s -> apparition de l’ombre (plus rapide)
    await Future.delayed(const Duration(milliseconds: 1300));
    setState(() {
      _showShadow = true;
    });
    _shadowController.forward();

    // 4.0s -> 4.1s : pause stable (encore plus courte)
    await Future.delayed(const Duration(milliseconds: 100));

    // 4.1s -> fade out animation then navigation
    _fadeOutController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _scaleController.dispose();
    _shadowController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: FadeTransition(
        opacity: _fadeOutAnimation,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1200),
              decoration: BoxDecoration(
                boxShadow: [
                  if (_showShadow)
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(_shadowFadeAnimation.value * 0.10),
                      blurRadius: 30,
                      spreadRadius: 3,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: SlideTransition(
                position: _logoSlideAnimation,
                child: FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: Image.asset(
                    'assets/images/Rezo logo.png',
                    height: 400,
                    width: 400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
