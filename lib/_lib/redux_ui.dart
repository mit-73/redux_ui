import 'dart:collection';

import 'package:flutter/foundation.dart'
    show immutable, listEquals, required, nonVirtual, protected, Key;
import 'package:flutter/widgets.dart'
    show hashList, Widget, BuildContext, StatelessWidget;

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

@immutable
class ReduxUI<State> {
  static Reducer<ReduxUIStateModel> createStateModelsReducer() {
    return combineReducers<ReduxUIStateModel>([
      TypedReducer<ReduxUIStateModel, _AddModelAction>(
        (models, action) {
          var a = ReduxUIStateModel(models ?? {})
            ..addAll({action.id: action.stateModel});
          print(a.runtimeType);
          return a;
        },
      ),
      TypedReducer<ReduxUIStateModel, _UpdateModelAction>(
        (models, action) {
          return ReduxUIStateModel(models ?? {})
            ..update(action.id, (v) => action.stateModel);
        },
      ),
      TypedReducer<ReduxUIStateModel, _RemoveModelAction>(
        (models, action) {
          return ReduxUIStateModel(models ?? {})..remove(action.stateModel);
        },
      ),
      TypedReducer<ReduxUIStateModel, _ClearModelsAction>(
        (models, action) {
          return ReduxUIStateModel(models)..clear();
        },
      ),
    ]);
  }
}

// -------------------------------------------- //

@immutable
abstract class ReduxUIModel {
  final List<Object> equals;

  ReduxUIModel({this.equals = const []})
      : assert(_onlyContainFieldsOfAllowedTypes(equals));

  static bool _onlyContainFieldsOfAllowedTypes(List<Object> objects) {
    objects.forEach((Object object) {
      if (object is Function) {
        throw Exception(
            "ReduxUIModel equals has an invalid field of type ${object.runtimeType}.");
      }
    });

    return true;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ hashList(equals);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReduxUIModel &&
        runtimeType == other.runtimeType &&
        listEquals(other.equals, equals);
  }

  @override
  String toString() => "RuntimeType: $runtimeType\nEqual Objects: $equals\n";
}

class ReduxUIViewModel<State, Model extends ReduxUIModel> {
  final int _id;
  final ReduxUIModel _model;
  final ReduxUIStateModel Function(State) _supervisor;
  final Store<State> store;

  ReduxUIViewModel({
    @required BuildContext context,
    @required ReduxUIModel model,
    @required ReduxUIStateModel Function(State) supervisor,
    bool unique = true,
  })  : assert(context != null),
        assert(model != null),
        assert(supervisor != null),
        _model = model,
        _id =
            unique ? model.hashCode : model.hashCode ^ DateTime.now().hashCode,
        _supervisor = supervisor,
        store = StoreProvider.of<State>(context, listen: false) {
    _init();
  }

  @nonVirtual
  Model get model {
    return _supervisor(store.state)[_id];
  }

  void _init() {
    store.dispatch(_AddModelAction(_id, _model));
  }

  @nonVirtual
  void dispose() {
    store.dispatch(_RemoveModelAction(_id, _model));
  }

  @protected
  @nonVirtual
  void update(Model model) {
    store.dispatch(_UpdateModelAction(_id, model));
  }
}

// -------------------------------------------- //

@immutable
class ReduxUIStateModel
    with MapMixin<int, ReduxUIModel>
    implements Map<int, ReduxUIModel> {
  final Map<int, ReduxUIModel> _map;

  const ReduxUIStateModel(Map<int, ReduxUIModel> map) : _map = map;

  factory ReduxUIStateModel.from(Map other) =>
      ReduxUIStateModel(Map.from(other));

  factory ReduxUIStateModel.empty() => ReduxUIStateModel({});

  @override
  ReduxUIModel operator [](Object key) => _map[key];

  @override
  void operator []=(int key, ReduxUIModel value) => _map[key] = value;

  @override
  void clear() => _map.clear();

  @override
  Iterable<int> get keys => _map.keys;

  @override
  ReduxUIModel remove(Object key) => _map.remove(key);
}

@immutable
class _AddModelAction {
  final int id;
  final ReduxUIModel stateModel;

  _AddModelAction(this.id, this.stateModel);
}

@immutable
class _UpdateModelAction {
  final int id;
  final ReduxUIModel stateModel;

  _UpdateModelAction(this.id, this.stateModel);
}

@immutable
class _RemoveModelAction {
  final int id;
  final ReduxUIModel stateModel;

  _RemoveModelAction(this.id, this.stateModel);
}

@immutable
class _ClearModelsAction {}

// -------------------------------------------- //

@immutable
class StoreObserver<State, Model extends ReduxUIModel> extends StatelessWidget {
  final ReduxUIViewModel<State, Model> viewModel;
  final ViewModelBuilder<Model> builder;
  final OnInitCallback<State> onInit;
  final OnDisposeCallback<State> onDispose;
  final bool rebuildOnChange;
  final IgnoreChangeTest<State> ignoreChange;
  final OnWillChangeCallback<Model> onWillChange;
  final OnDidChangeCallback<Model> onDidChange;
  final OnInitialBuildCallback<Model> onInitialBuild;

  const StoreObserver({
    Key key,
    @required this.viewModel,
    @required this.builder,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.ignoreChange,
    this.onWillChange,
    this.onDidChange,
    this.onInitialBuild,
  })  : assert(builder != null),
        assert(viewModel != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<State, Model>(
      builder: builder,
      converter: (_) => viewModel.model,
      distinct: true,
      onInit: onInit,
      onDispose: onDispose,
      rebuildOnChange: rebuildOnChange,
      ignoreChange: ignoreChange,
      onWillChange: onWillChange,
      onDidChange: onDidChange,
      onInitialBuild: onInitialBuild,
    );
  }
}
