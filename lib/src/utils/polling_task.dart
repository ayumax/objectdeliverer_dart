import 'package:async/async.dart';

/// Polling processing class
class PollingTask {
  PollingTask.fromAction(Future<bool> Function() action) {
    _isCancel = false;

    _pollingTask =
        CancelableOperation<void>.fromFuture(run(action), onCancel: _onCancel);
  }

  CancelableOperation<void> _pollingTask;
  bool _isCancel = false;

  /// stop the polling
  Future stop() async {
    if (_pollingTask == null) {
      return;
    }

    await _pollingTask.cancel();

    await _pollingTask.valueOrCancellation();
  }

  /// Polling process
  Future run(Future<bool> Function() action) async {
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
