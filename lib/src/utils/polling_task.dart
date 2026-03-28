import 'package:async/async.dart';

class PollingTask {
  PollingTask.fromAction(Future<bool> Function() action) {
    _isCancel = false;

    _pollingTask = CancelableOperation<void>.fromFuture(
      run(action),
      onCancel: _onCancel,
    );
  }

  CancelableOperation<void>? _pollingTask;
  bool _isCancel = false;

  Future<void> stop() async {
    final task = _pollingTask;
    if (task == null) {
      return;
    }

    await task.cancel();

    await task.valueOrCancellation();
  }

  Future<void> run(Future<bool> Function() action) async {
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
