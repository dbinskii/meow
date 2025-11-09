abstract class CatEvent {
  const CatEvent();
}

class CatRequested extends CatEvent {
  const CatRequested({this.forceRefresh = false});

  final bool forceRefresh;
}
