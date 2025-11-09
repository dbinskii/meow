import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';
import 'package:url_launcher/url_launcher.dart';

mixin CatViewMixin<T extends StatefulWidget> on State<T> {
  Future<void> openCatInBrowser(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      showOpenInBrowserError();
      return;
    }

    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success) {
        showOpenInBrowserError();
      }
    } on Exception {
      showOpenInBrowserError();
    }
  }

  void showOpenInBrowserError() {
    if (!mounted) {
      return;
    }

    final localizations = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.todayCatOpenInBrowserError)),
    );
  }
}
