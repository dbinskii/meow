import 'package:flutter/material.dart';

class CatView extends StatelessWidget {
  const CatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SafeArea(
        child: Center(child: Text('''Today's cat will be here''')),
      ),
    );
  }
}
