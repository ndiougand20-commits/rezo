import 'package:flutter/material.dart';

import 'features/auth/auth_flow.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.authService, this.tokenStorage});

  final AuthService? authService;
  final TokenStorage? tokenStorage;

  @override
  Widget build(BuildContext context) {
    return RezoApp(authService: authService, tokenStorage: tokenStorage);
  }
}
