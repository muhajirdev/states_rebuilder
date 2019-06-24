import 'package:flutter/material.dart';
import '../states_rebuilder.dart';

class Injector<T extends StatesRebuilder> extends StatefulWidget {
  final Widget Function(BuildContext, T) builder;
  final List<Function()> models;
  Injector(
      {this.builder,
      this.models,
      this.initState,
      this.dispose,
      this.appLifeCycle,
      this.disposeModels = false})
      : assert(models != null && builder != null);

  final Function(T) initState;
  final Function(T) dispose;
  final Function(T, AppLifecycleState) appLifeCycle;

  final bool disposeModels;

  // Inject the same singleton
  static T get<T>([String name]) => _InjectorState._get<T>(false, name);

  /// Inject a new instance
  static T getNew<T>([String name]) => _InjectorState._get<T>(true, name);

  @override
  State<Injector<T>> createState() {
    if (appLifeCycle == null) {
      return _InjectorState<T>();
    } else {
      return _InjectorStateAppLifeCycle<T>();
    }
  }
}

class _InjectorState<T extends StatesRebuilder> extends State<Injector<T>> {
  _InjectorState();

  final vm = new Map<String, List<_Model>>();
  List<_Model> _modelInstanceList = [];
  @override
  void initState() {
    super.initState();
    widget.models.forEach((m) {
      String _modelName;
      Function creationFunction;
      var instance;
      var element = m();
      if (element is List) {
        if (element.length != 2 ||
            // !(element[0] is Function) ||
            !(element[1] is String)) {
          throw FlutterError(
              "The list length must be 2, and the first element must be a Function and the second a String");
        } else {
          instance = element[0];
          _modelName = "${instance.runtimeType}-" + element[1];
          creationFunction = () => m()[0];
        }
      } else {
        instance = element;
        _modelName = "${instance.runtimeType}";
        creationFunction = m;
      }
      final _modelInstance =
          _Model(creationFunction: creationFunction, instance: instance);
      _modelInstanceList.add(_modelInstance);
      vm[_modelName] = _modelsMap[_modelName] ?? [];
      vm[_modelName].add(_modelInstance);

      _modelsMap.addAll(vm);
    });
  }

  @override
  void dispose() {
    if (widget.disposeModels) {
      vm.forEach((k, v) {
        try {
          v.last.instance?.dispose();
        } catch (e) {
          if ('$e'.contains(
              "AnimationController.dispose() called more than once")) {
            print(e);
          } else {
            print(
                "You have set the parameter `disposeModels` of Injector to true.\n"
                "Your model must have a dispose() method\n"
                "If you are registering many models, and you want only a set of them to be disposed,\n"
                "wrap them inside another nested Injector widget and set  the parameter `disposeModels` to true\n");
            rethrow;
          }
        }
      });
    }
    vm.forEach((k, v) {
      _modelInstanceList.forEach((m) {
        _modelsMap[k].remove(m);
      });
      if (_modelsMap[k].isEmpty) {
        _modelsMap.remove(k);
      }
    });
    super.dispose();
  }

  static final _modelsMap = new Map<String, List<_Model>>();

  static T _get<T>(bool getNew, [String name]) {
    _Model _model;
    if (name != null) {
      name = "$T-$name";
      _model = _modelsMap[name]?.last;
    } else {
      name = "$T";
      _model = _modelsMap[name]?.last;
    }

    if (_model == null) {
      var _models = _modelsMap.keys;
      print("Model of type '$name 'is not registered yet.\n"
          "You have to register the model before calling it.\n"
          "To register the model use the `Injector` widget.\n"
          "The list of registered models is : $_models");
      return null;
    }

    if (getNew) {
      return _model.creationFunction() as T;
    }
    return _model.instance as T;
  }

  @override
  Widget build(BuildContext context) {
    final model = T != StatesRebuilder ? Injector.get<T>() : null;
    return StateBuilder(
      viewModels: [model],
      initState: (_, __) {
        if (widget.initState != null) {
          widget.initState(model);
        }
      },
      dispose: (_, __) {
        if (widget.dispose != null) {
          widget.dispose(model);
        }
      },
      builder: (context, _) => widget.builder(context, model),
    );
  }
}

class _InjectorStateAppLifeCycle<T extends StatesRebuilder>
    extends _InjectorState<T> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final model = T != StatesRebuilder ? Injector.get<T>() : null;
    widget.appLifeCycle(model, state);
  }
}

class _Model {
  final Function() creationFunction;
  final instance;

  _Model({this.creationFunction, this.instance});
}
