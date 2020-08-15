import 'package:async/async.dart';

class PollingTask {
  PollingTask.fromAction(Future<bool> Function() action) {
    _isCancel = false;

    _pollingTask = CancelableOperation<void>.fromFuture(runAsync(action),
        onCancel: _onCancel);
  }

  CancelableOperation<void> _pollingTask;
  bool _isCancel = false;

  Future stopAsync() async {
    if (_pollingTask == null) {
      return;
    }

    await _pollingTask.cancel();

    await _pollingTask.valueOrCancellation();
  }

  Future runAsync(Future<bool> Function() action) async {
    while (_isCancel == false) {
      if (await action() == false) {
        break;
      }

      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  void _onCancel() {
    _isCancel = true;
  }
}
