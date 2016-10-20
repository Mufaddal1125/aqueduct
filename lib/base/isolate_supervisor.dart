part of aqueduct;

class IsolateSupervisor {
  static String _MessageStop = "_MessageStop";

  final Isolate isolate;
  final ReceivePort receivePort;
  final int identifier;

  Application supervisingApplication;
  SendPort _serverSendPort;
  Logger logger;
  Completer _launchCompleter;
  Completer _stopCompleter;

  IsolateSupervisor(this.supervisingApplication, this.isolate, this.receivePort, this.identifier, this.logger);

  Future resume() {
    _launchCompleter = new Completer();
    receivePort.listen(listener);

    isolate.setErrorsFatal(false);
    isolate.resume(isolate.pauseCapability);

    return _launchCompleter.future.timeout(new Duration(seconds: 30));
  }

  Future stop() async {
    _stopCompleter = new Completer();
    _serverSendPort.send(_MessageStop);
    await _stopCompleter.future.timeout(new Duration(seconds: 30));

    isolate.kill();
  }

  void listener(dynamic message) {
    if (message is SendPort) {
      _launchCompleter.complete();
      _launchCompleter = null;

      _serverSendPort = message;
    } else if (message == _MessageStop) {
      _stopCompleter?.complete();
      _stopCompleter = null;
    } else if (message is List) {
      var exception = new IsolateSupervisorException(message.first);
      var stacktrace = new StackTrace.fromString(message.last);
      if (_launchCompleter != null) {
        _launchCompleter.completeError(exception, stacktrace);
      } else {
        logger.severe("Uncaught exception in isolate.", exception, stacktrace);
      }
    }
  }

  void _tearDownWithError(String errorMessage, dynamic stackTrace) {
    stop().then((_) {
      _launchCompleter = null;
      _stopCompleter = null;
      supervisingApplication.isolateDidExitWithError(this, errorMessage, stackTrace);
    });
  }

}

class IsolateSupervisorException implements Exception {
  final String message;
  IsolateSupervisorException(this.message);
}