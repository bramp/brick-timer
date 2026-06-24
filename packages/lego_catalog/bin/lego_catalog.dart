import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dio/dio.dart';
import 'package:lego_catalog/lego_catalog.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('lego_catalog');

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this usage information.',
    )
    ..addOption(
      'log-level',
      defaultsTo: _defaultLogLevelName,
      allowed: _supportedLogLevels,
      help: 'Logging level.',
    )
    ..addOption(
      'backend',
      defaultsTo: _rebrickableBackend,
      allowed: _supportedBackends,
      help: 'Catalog backend to query.',
    )
    ..addOption(
      'api-key',
      help:
          'API key for the selected backend. '
          'Defaults to REBRICKABLE_API_KEY when omitted.',
    )
    ..addOption('base-url', help: 'Optional backend base URL override.')
    ..addOption('connect-timeout-ms', defaultsTo: '10000')
    ..addOption('receive-timeout-ms', defaultsTo: '10000')
    ..addOption('send-timeout-ms', defaultsTo: '10000')
    ..addOption('retries', defaultsTo: '3')
    ..addOption('initial-retry-delay-ms', defaultsTo: '250')
    ..addCommand('search')
    ..addCommand('details');

  parser.commands['search']!
    ..addOption('page-size', defaultsTo: '20')
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage for search command.',
    );

  parser.commands['details']!.addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Show usage for details command.',
  );

  late ArgResults parsed;
  try {
    parsed = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(_usage(parser));
    exitCode = 64;
    return;
  }

  if (parsed['help'] as bool) {
    stdout.writeln(_usage(parser));
    return;
  }

  final parsedLogLevel =
      (parsed['log-level'] as String?) ?? _defaultLogLevelName;
  final envLogLevel = (Platform.environment['LOG_LEVEL'] ?? '').trim();
  final resolvedLogLevel = parsed.wasParsed('log-level')
      ? parsedLogLevel
      : (envLogLevel.isNotEmpty ? envLogLevel : parsedLogLevel);

  _configureLogging(resolvedLogLevel);

  final command = parsed.command;
  if (command == null) {
    stdout.writeln(_usage(parser));
    return;
  }

  if (command['help'] as bool) {
    stdout.writeln(_commandUsage(parser, command));
    return;
  }

  try {
    final backendName = (parsed['backend'] as String?)?.trim() ?? '';
    _log.info('Command: ${command.name}');
    final backend = _buildBackend(parsed);

    if (command.name == 'search') {
      final query = command.rest.join(' ').trim();
      if (query.isEmpty) {
        throw const FormatException('Missing required <query> argument.');
      }

      final pageSize = int.parse(command['page-size'] as String);
      _log.info(
        'Starting search: backend=$backendName, pageSize=$pageSize, '
        'query="$query"',
      );
      final result = await backend.searchSets(
        query,
        pageSize: pageSize,
      );
      _log.info('Search completed: ${result.length} result(s)');
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(
          result.map((set) => set.toJson()).toList(),
        ),
      );
      return;
    }

    if (command.name == 'details') {
      final setNumber = command.rest.join(' ').trim();
      if (setNumber.isEmpty) {
        throw const FormatException(
          'Missing required <set-number> argument.',
        );
      }

      _log.info(
        'Starting details lookup: backend=$backendName, setNumber=$setNumber',
      );

      final result = await backend.getSetDetails(setNumber);
      _log.info(
        'Details lookup completed: ${result == null ? 'not found' : 'found'}',
      );
      if (result == null) {
        stdout.writeln('null');
      } else {
        stdout.writeln(
          const JsonEncoder.withIndent('  ').convert(result.toJson()),
        );
      }
      return;
    }

    throw FormatException('Unsupported command: ${command.name}');
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  } on Exception catch (error) {
    stderr.writeln(error.toString());
    exitCode = 1;
  }
}

LegoCatalogBackend _buildBackend(ArgResults root) {
  final backendName = (root['backend'] as String?)?.trim() ?? '';
  final dio = _createCliDio();
  final baseUrl = (root['base-url'] as String?)?.trim();
  final httpConfig = CatalogHttpConfig(
    connectTimeout: Duration(
      milliseconds: int.parse(root['connect-timeout-ms'] as String),
    ),
    receiveTimeout: Duration(
      milliseconds: int.parse(root['receive-timeout-ms'] as String),
    ),
    sendTimeout: Duration(
      milliseconds: int.parse(root['send-timeout-ms'] as String),
    ),
    retries: int.parse(root['retries'] as String),
    initialRetryDelay: Duration(
      milliseconds: int.parse(root['initial-retry-delay-ms'] as String),
    ),
  );

  switch (backendName) {
    case _rebrickableBackend:
      final apiKeyFromFlag = (root['api-key'] as String?)?.trim() ?? '';
      final apiKeyFromEnv = (Platform.environment['REBRICKABLE_API_KEY'] ?? '')
          .trim();
      final apiKey = apiKeyFromFlag.isNotEmpty ? apiKeyFromFlag : apiKeyFromEnv;
      if (apiKey.isEmpty) {
        throw const FormatException(
          'Missing API key. Provide --api-key or set REBRICKABLE_API_KEY.',
        );
      }

      return RebrickableBackend(
        apiKey: apiKey,
        dio: dio,
        baseUrl: (baseUrl == null || baseUrl.isEmpty)
            ? 'https://rebrickable.com/api/v3/lego'
            : baseUrl,
        httpConfig: httpConfig,
      );
    case _bricktimerBackend:
      final resolvedBaseUrl =
          baseUrl ?? (Platform.environment['BRICKTIMER_BASE_URL'] ?? '').trim();
      if (resolvedBaseUrl.isEmpty) {
        throw const FormatException(
          'Missing Brick Timer base URL. Provide --base-url or set '
          'BRICKTIMER_BASE_URL.',
        );
      }

      return BrickTimerBackend(
        baseUrl: resolvedBaseUrl,
        dio: dio,
        httpConfig: httpConfig,
      );
    default:
      throw FormatException(
        'Unsupported backend: $backendName. '
        'Supported backends: ${_supportedBackends.join(', ')}',
      );
  }
}

Dio _createCliDio() {
  final dio = Dio();
  dio.interceptors.add(
    LogInterceptor(
      responseHeader: false,
      logPrint: (obj) {
        Logger('lego_catalog').finer(obj.toString());
      },
    ),
  );
  return dio;
}

void _configureLogging(String levelName) {
  Logger.root.level = _parseLogLevel(levelName);
  hierarchicalLoggingEnabled = true;

  Logger.root.onRecord.listen((record) {
    final timestamp = record.time.toIso8601String();
    final message =
        '$timestamp ${record.level.name.padRight(7)} '
        '${record.loggerName}: ${record.message}';

    stderr.writeln(message);
    if (record.error != null) {
      stderr.writeln('  error: ${record.error}');
    }
    if (record.stackTrace != null) {
      stderr.writeln(record.stackTrace);
    }
  });
}

Level _parseLogLevel(String value) {
  switch (value.toLowerCase()) {
    case 'all':
      return Level.ALL;
    case 'finest':
      return Level.FINEST;
    case 'finer':
      return Level.FINER;
    case 'fine':
      return Level.FINE;
    case 'info':
      return Level.INFO;
    case 'warning':
      return Level.WARNING;
    case 'severe':
      return Level.SEVERE;
    case 'shout':
      return Level.SHOUT;
    case 'off':
      return Level.OFF;
    default:
      return Level.INFO;
  }
}

const String _rebrickableBackend = 'rebrickable';
const String _bricktimerBackend = 'bricktimer';
const List<String> _supportedBackends = <String>[
  _rebrickableBackend,
  _bricktimerBackend,
];
const String _defaultLogLevelName = 'info';
const List<String> _supportedLogLevels = <String>[
  'all',
  'finest',
  'finer',
  'fine',
  'info',
  'warning',
  'severe',
  'shout',
  'off',
];

String _usage(ArgParser parser) {
  final searchUsage = parser.commands['search']?.usage ?? '';
  final detailsUsage = parser.commands['details']?.usage ?? '';

  return 'Usage: dart run lego_catalog [global options] <command> '
      '[command options] <arg>\n'
      '\n'
      'Commands:\n'
      '  search <query>             Search sets by query.\n'
      '  details <set-number>       Fetch details for one set number.\n'
      '\n'
      'Search options:\n'
      '$searchUsage\n'
      '\n'
      'Details options:\n'
      '$detailsUsage\n'
      '\n'
      'Tip: Use `dart run lego_catalog <command> -h` for '
      'command-specific help.\n'
      '\n'
      '${parser.usage}';
}

String _commandUsage(ArgParser parser, ArgResults command) {
  if (command.name == 'search') {
    return 'Usage: dart run lego_catalog [global options] search [options] '
        '<query>\n'
        '\n'
        '${parser.commands['search']?.usage ?? ''}';
  }

  if (command.name == 'details') {
    return 'Usage: dart run lego_catalog [global options] details [options] '
        '<set-number>\n'
        '\n'
        '${parser.commands['details']?.usage ?? ''}';
  }

  return 'Usage: dart run lego_catalog <command> [options] <arg>';
}
