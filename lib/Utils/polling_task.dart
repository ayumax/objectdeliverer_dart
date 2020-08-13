// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.

import 'package:async/async.dart';

class PollingTask {
  PollingTask.fromAction(Future<bool> Function() action) {
    _isCancel = false;

    _pollingTask = CancelableOperation<void>.fromFuture(runAsync(action),
        onCancel: _onCancel);
  }

  CancelableOperation<void> _pollingTask;
  bool _isCancel = false;

  Future<void> disposeAsync() async {
    if (_pollingTask == null) {
      return;
    }

    _pollingTask.cancel();

    return _pollingTask.value;
  }

  Future<void> runAsync(Future<bool> Function() action) async {
    while (_isCancel == false) {
      if (await action() == false) {
        break;
      }

      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  void _onCancel() {
    _isCancel = true;
  }
}
