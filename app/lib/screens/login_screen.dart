import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration durationPerChar;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.durationPerChar = const Duration(milliseconds: 30),
  });

  @override
  _TypewriterTextState createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.durationPerChar * widget.text.length,
      vsync: this,
    );
    _animation = IntTween(begin: 0, end: widget.text.length).animate(_controller);
  }

  void startAnimation() {
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        String text = widget.text.substring(0, _animation.value);
        return Text(text, style: widget.style);
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _logoAnimationController;
  late Animation<double> _logoFadeAnimation;
  final GlobalKey<_TypewriterTextState> _welcomeTextKey = GlobalKey();
  final GlobalKey<_TypewriterTextState> _taglineTextKey = GlobalKey();
  final GlobalKey<_TypewriterTextState> _loginTextKey = GlobalKey();
  late AnimationController _emailAnimationController;
  late Animation<double> _emailFadeAnimation;
  late AnimationController _passwordAnimationController;
  late Animation<double> _passwordFadeAnimation;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeIn,
      ),
    );

    // Email animation
    _emailAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _emailFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _emailAnimationController,
        curve: Curves.easeIn,
      ),
    );

    // Password animation
    _passwordAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _passwordFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _passwordAnimationController,
        curve: Curves.easeIn,
      ),
    );

    // Button animation
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeIn,
      ),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Show logo first
    _logoAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // Then show texts with typewriter effect
    _welcomeTextKey.currentState?.startAnimation();
    await Future.delayed(const Duration(milliseconds: 500));
    _taglineTextKey.currentState?.startAnimation();
    await Future.delayed(const Duration(milliseconds: 500));
    _loginTextKey.currentState?.startAnimation();
    await Future.delayed(const Duration(milliseconds: 500));

    // Then show email input
    _emailAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // Then show password input
    _passwordAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // Finally show button
    _buttonAnimationController.forward();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _emailAnimationController.dispose();
    _passwordAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 5), // Much closer spacing
                  // Logo and text stacked (text overlapping logo)
                  SizedBox(
                    height: 320, // Height to accommodate logo + overlapping text
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Logo (animated)
                        FadeTransition(
                          opacity: _logoFadeAnimation,
                          child: Image.asset(
                            'assets/images/Rezo logo.png',
                            height: 280,
                            width: 280,
                          ),
                        ),
                        // Texte de bienvenue (animated) - positioned over logo
                        Positioned(
                          bottom: 20, // Position text from bottom of stack
                          child: Column(
                            children: [
                              TypewriterText(
                                key: _welcomeTextKey,
                                text: 'Bienvenue sur Rezo',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TypewriterText(
                                key: _taglineTextKey,
                                text: 'Votre avenir en un swipe',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black38,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TypewriterText(
                                key: _loginTextKey,
                                text: 'Connexion',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10), // Closer to inputs
                  // Email input (animated)
                  FadeTransition(
                    opacity: _emailFadeAnimation,
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Password input (animated)
                  FadeTransition(
                    opacity: _passwordFadeAnimation,
                    child: TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        labelStyle: const TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Button (animated)
                  FadeTransition(
                    opacity: _buttonFadeAnimation,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Se connecter',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  // Lien vers inscription
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register');
                    },
                    child: const Text(
                      'S\'inscrire',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
