import 'dart:async';

import 'package:meow/src/features/cat/domain/bloc/cat_event.dart';
import 'package:meow/src/features/cat/domain/bloc/cat_state.dart';
import 'package:meow/src/features/cat/domain/config/cat_refresh_config.dart';
import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';
import 'package:meow/src/features/cat/domain/repositories/cat_repository.dart';
import 'package:meow/src/features/cat/service/cat_background_service.dart';

class CatBloc {
  CatBloc({
    required CatRepository repository,
    Duration? foregroundRefreshInterval,
  }) : _repository = repository,
       _foregroundRefreshInterval =
           foregroundRefreshInterval ?? CatRefreshConfig.interval {
    _emit(const CatState.initial());
    _eventSubscription = _eventController.stream.listen(
      _handleEvent,
      onError: (Object error, _) => _emitFailure(error),
    );
    _backgroundRefreshSubscription = CatBackgroundService
        .instance
        .onBackgroundRefresh
        .listen((_) => _handleBackgroundRefreshSignal());
  }

  final CatRepository _repository;
  final _controller = StreamController<CatState>.broadcast();
  final _eventController = StreamController<CatEvent>();
  StreamSubscription<CatEvent>? _eventSubscription;
  StreamSubscription<DateTime>? _backgroundRefreshSubscription;
  CatState _state = const CatState.initial();
  final Duration _foregroundRefreshInterval;
  Timer? _foregroundRefreshTimer;
  bool _pendingBackgroundRefresh = false;

  Stream<CatState> get stream => _controller.stream;

  CatState get state => _state;

  void add(CatEvent event) {
    if (_eventController.isClosed) {
      return;
    }
    _eventController.add(event);
  }

  void loadCat({bool forceRefresh = false}) =>
      add(CatRequested(forceRefresh: forceRefresh));

  void dispose() {
    _eventSubscription?.cancel();
    _backgroundRefreshSubscription?.cancel();
    _eventController.close();
    _controller.close();
    _cancelForegroundRefreshTimer();
  }

  void _handleEvent(CatEvent event) {
    if (event is CatRequested) {
      unawaited(_onCatRequested(forceRefresh: event.forceRefresh));
    }
  }

  Future<void> _onCatRequested({required bool forceRefresh}) async {
    _cancelForegroundRefreshTimer();

    var seededCat = _state.cat;
    var seededUpdatedAt = _state.updatedAt;

    if (seededCat == null) {
      seededCat = await _repository.getLastCachedCat();
      seededUpdatedAt = seededCat?.createdAt ?? seededUpdatedAt;
    }

    _emit(
      CatState.loading(
        previousCat: seededCat,
        previousUpdatedAt: seededUpdatedAt,
      ),
    );

    try {
      final cat = await _repository.getRandomCat(forceRefresh: forceRefresh);
      _emit(CatState.success(cat, cat.createdAt));
      unawaited(CatBackgroundService.instance.ensureScheduled());
      CatBackgroundService.instance.registerForegroundUpdate(cat.createdAt);
      _scheduleForegroundRefresh();
    } on Exception catch (error) {
      _emitFailure(
        error,
        previousCat: seededCat,
        previousUpdatedAt: seededUpdatedAt,
      );
      _scheduleForegroundRefresh();
    }
  }

  void _emitFailure(
    Object error, {
    CatEntity? previousCat,
    DateTime? previousUpdatedAt,
  }) {
    _emit(
      CatState.failure(
        error,
        previousCat: previousCat ?? _state.cat,
        previousUpdatedAt: previousUpdatedAt ?? _state.updatedAt,
      ),
    );
  }

  void _emit(CatState state) {
    if (_controller.isClosed) {
      return;
    }
    _state = state;
    _controller.add(state);

    if (!_state.isLoading && _pendingBackgroundRefresh) {
      _pendingBackgroundRefresh = false;
      unawaited(_refreshFromCache());
    }
  }

  void _scheduleForegroundRefresh() {
    if (_foregroundRefreshInterval <= Duration.zero ||
        _eventController.isClosed) {
      return;
    }

    _foregroundRefreshTimer?.cancel();
    _foregroundRefreshTimer = Timer(
      _foregroundRefreshInterval,
      _handleForegroundRefreshTick,
    );
  }

  void _cancelForegroundRefreshTimer() {
    _foregroundRefreshTimer?.cancel();
    _foregroundRefreshTimer = null;
  }

  void _handleForegroundRefreshTick() {
    _foregroundRefreshTimer = null;
    if (_eventController.isClosed) {
      return;
    }
    if (_state.isLoading) {
      _scheduleForegroundRefresh();
      return;
    }
    loadCat(forceRefresh: true);
  }

  Future<void> _refreshFromCache() async {
    final cached = await _repository.getLastCachedCat();
    if (cached == null) {
      loadCat(forceRefresh: true);
      return;
    }
    _emit(CatState.success(cached, cached.createdAt));
    CatBackgroundService.instance.registerForegroundUpdate(cached.createdAt);
  }

  void _handleBackgroundRefreshSignal() {
    if (_state.isLoading) {
      _pendingBackgroundRefresh = true;
      return;
    }
    unawaited(_refreshFromCache());
  }
}
