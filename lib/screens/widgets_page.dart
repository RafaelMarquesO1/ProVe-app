import 'package:flutter/material.dart';

class WidgetsPage extends StatelessWidget {
  const WidgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widgets'),
      ),
      body: const Center(
        child: Text('Página de Widgets'),
      ),
    );
  }
}
