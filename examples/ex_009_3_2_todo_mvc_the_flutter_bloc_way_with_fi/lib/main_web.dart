import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:key_value_store_web/key_value_store_web.dart';
import 'package:todo_mvc_the_flutter_bloc_way/run_app.dart';
import 'package:todos_repository_local_storage/todos_repository_local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runBlocLibraryApp(LocalStorageRepository(
    localStorage: KeyValueStorage(
      'bloc_library',
      WebKeyValueStore(window.localStorage),
    ),
  ));
}
