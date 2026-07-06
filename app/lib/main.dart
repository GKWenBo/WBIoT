import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/connection/connection_page.dart';

void main() {
  runApp(const ProviderScope(child: WbiotApp()));
}

class WbiotApp extends StatelessWidget {
  const WbiotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WBIoT',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const ConnectionPage(),
    );
  }
}
