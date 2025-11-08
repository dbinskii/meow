class AppAssets {
  const AppAssets._();

  static const backgrounds = BackgroundAssets._();
  static const icons = IconAssets._();
}

class BackgroundAssets {
  const BackgroundAssets._();

  String get topBlueComponent => 'assets/backgrounds/top_blue_companent.webp';
  String get bottomBlueComponent =>
      'assets/backgrounds/buttom_blue_companent.webp';
  String get orangeComponent => 'assets/backgrounds/orange_companent.webp';
}

class IconAssets {
  const IconAssets._();

  String get mainLogo => 'assets/icons/logo/main_logo.png';
  String get secondaryLogo => 'assets/icons/logo/second_logo.svg';
}
