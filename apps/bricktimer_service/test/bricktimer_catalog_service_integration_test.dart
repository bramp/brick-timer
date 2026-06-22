import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('bricktimer_service runtime integration', () {
    test(
      'returns functions manifest when FUNCTIONS_CONTROL_API is enabled',
      () async {
        final port = await _reservePort();
        final server = await _startServiceServer(
          port: port,
          environment: const {'FUNCTIONS_CONTROL_API': 'true'},
        );
        addTearDown(server.stop);

        final response = await _get(
          port,
          '/__/functions.yaml',
        );

        expect(response.statusCode, 200);
        expect(response.body, contains('bricktimer-catalog:'));
        expect(response.body, contains('invoker:'));
        expect(response.body, contains('- public'));
      },
    );

    test('serves runtime health endpoint', () async {
      final port = await _reservePort();
      final server = await _startServiceServer(port: port);
      addTearDown(server.stop);

      final response = await _get(
        port,
        '/__/health',
      );

      expect(response.statusCode, 200);
      expect(response.body, 'OK');
    });

    test('returns app check error JSON when token is missing', () async {
      final port = await _reservePort();
      final server = await _startServiceServer(port: port);
      addTearDown(server.stop);

      final response = await _get(
        port,
        '/bricktimer-catalog',
      );

      expect(response.statusCode, 401);
      expect(response.body, contains('app_check_required'));
    });
  });
}

class _ServiceServer {
  _ServiceServer(this._process);

  final Process _process;

  Future<void> stop() async {
    _process.kill();
    await _process.exitCode.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        _process.kill(ProcessSignal.sigkill);
        return _process.exitCode;
      },
    );
  }
}

Future<_ServiceServer> _startServiceServer({
  required int port,
  Map<String, String> environment = const {},
}) async {
  final process = await Process.start(
    'dart',
    const ['run', 'bin/server.dart'],
    workingDirectory: Directory.current.path,
    environment: {
      ...Platform.environment,
      'PORT': '$port',
      'FIREBASE_PROJECT': 'demo-bricktimer',
      ...environment,
    },
  );

  final stdoutDone = process.stdout.transform(utf8.decoder).join();
  final stderrDone = process.stderr.transform(utf8.decoder).join();

  final ready = await _waitForServerReady(port);
  if (!ready) {
    final exitCode = await process.exitCode.timeout(
      const Duration(milliseconds: 100),
      onTimeout: () => -1,
    );
    final stdoutText = await stdoutDone;
    final stderrText = await stderrDone;
    throw StateError(
      'Service failed to start on port $port (exit: $exitCode).\n'
      'stdout:\n$stdoutText\n'
      'stderr:\n$stderrText',
    );
  }

  return _ServiceServer(process);
}

Future<bool> _waitForServerReady(int port) async {
  final deadline = DateTime.now().add(const Duration(seconds: 12));

  while (DateTime.now().isBefore(deadline)) {
    try {
      final response = await _get(port, '/__/health');
      if (response.statusCode == 200) {
        return true;
      }
    } on SocketException {
      // Keep polling until the server starts listening.
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  return false;
}

Future<int> _reservePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<_HttpResult> _get(int port, String path) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:$port$path'),
    );
    final response = await request.close();
    final body = await utf8.decodeStream(response);
    return _HttpResult(response.statusCode, body);
  } finally {
    client.close();
  }
}

class _HttpResult {
  const _HttpResult(this.statusCode, this.body);

  final int statusCode;
  final String body;
}
