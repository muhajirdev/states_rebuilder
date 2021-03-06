// Copyright 2018 The Flutter Architecture Sample Authors. All rights reserved.
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:ex_009_1_3_ca_todo_mvc_with_state_persistence_user_auth/ui/injected/injected_todo.dart';
import 'package:flutter/material.dart';

import 'todo_item.dart';

class TodoList extends StatelessWidget {
  const TodoList();
  @override
  Widget build(BuildContext context) {
    return todosFiltered.rebuilder(
      () {
        final todos = todosFiltered.state;
        return ListView.builder(
          itemCount: todos.length,
          itemBuilder: (BuildContext context, int index) {
            return todoItem.inherited(
              key: Key('${todos[index].id}'),
              stateOverride: () {
                return todosFiltered.state[index];
              },
              builder: (_) => const TodoItem(),
              // debugPrintWhenNotifiedPreMessage: 'todo $index',
            );
          },
        );
      },
      shouldRebuild: () => todosFiltered.hasData || todosFiltered.hasError,
    );
  }
}
