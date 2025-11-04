import 'package:flutter/material.dart';
import '../features/cat/presentation/views/cat_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Meow', home: const CatView());
  }
}
