import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';

class CatView extends StatelessWidget {
  const CatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.todayCatTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.todayCatSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
