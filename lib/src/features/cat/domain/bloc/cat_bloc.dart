import 'dart:async';

import 'package:meow/src/features/cat/domain/bloc/cat_event.dart';
import 'package:meow/src/features/cat/domain/bloc/cat_state.dart';
import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';
import 'package:meow/src/features/cat/domain/repositories/cat_repository.dart';

class CatBloc {
  CatBloc({required CatRepository repository}) : _repository = repository {
    _emit(const CatState.initial());
    _eventSubscription = _eventController.stream.listen(
      _handleEvent,
      onError: (Object error, _) => _emitFailure(error),
    );
  }

  final CatRepository _repository;
  final _controller = StreamController<CatState>.broadcast();
  final _eventController = StreamController<CatEvent>();
  StreamSubscription<CatEvent>? _eventSubscription;
  CatState _state = const CatState.initial();

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
    _eventController.close();
    _controller.close();
  }

  void _handleEvent(CatEvent event) {
    if (event is CatRequested) {
      unawaited(_onCatRequested(forceRefresh: event.forceRefresh));
    }
  }

  Future<void> _onCatRequested({required bool forceRefresh}) async {
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
    } on Exception catch (error) {
      _emitFailure(
        error,
        previousCat: seededCat,
        previousUpdatedAt: seededUpdatedAt,
      );
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
  }
}
