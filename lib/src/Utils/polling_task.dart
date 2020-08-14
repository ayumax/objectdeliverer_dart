import 'package:async/async.dart';

class PollingTask {
  PollingTask.fromAction(Future<bool> Function() action) {
    _isCancel = false;

    _pollingTask = CancelableOperation<void>.fromFuture(runAsync(action),
        onCancel: _onCancel);
  }

  CancelableOperation<void> _pollingTask;
  bool _isCancel = false;

  Future<void> stopAsync() async {
    if (_pollingTask == null) {
      return;
    }

    await _pollingTask.cancel();

    await _pollingTask.value;
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
