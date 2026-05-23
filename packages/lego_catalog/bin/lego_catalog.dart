import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:lego_catalog/lego_catalog.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this usage information.',
    )
    ..addCommand('search')
    ..addCommand('details');

  parser.commands['search']!
    ..addOption('backend', defaultsTo: 'rebrickable')
    ..addOption(
      'api-key',
      help:
          'API key for the selected backend. '
          'Defaults to REBRICKABLE_API_KEY when omitted.',
    )
    ..addOption('page-size', defaultsTo: '20')
    ..addOption('base-url', help: 'Optional backend base URL override.')
    ..addOption('connect-timeout-ms', defaultsTo: '10000')
    ..addOption('receive-timeout-ms', defaultsTo: '10000')
    ..addOption('send-timeout-ms', defaultsTo: '10000')
    ..addOption('retries', defaultsTo: '3')
    ..addOption('initial-retry-delay-ms', defaultsTo: '250')
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage for search command.',
    );

  parser.commands['details']!
    ..addOption('backend', defaultsTo: 'rebrickable')
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
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage for details command.',
    );

  late ArgResults parsed;
  try {
    parsed = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(_usage(parser));
    exitCode = 64;
    return;
  }

  if (parsed['help'] as bool) {
    stdout.writeln(_usage(parser));
    return;
  }

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
    final backend = _buildBackend(command);

    if (command.name == 'search') {
      final query = command.rest.join(' ').trim();
      if (query.isEmpty) {
        throw const FormatException('Missing required <query> argument.');
      }

      final pageSize = int.parse(command['page-size'] as String);
      final result = await backend.searchSets(query, pageSize: pageSize);
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

      final result = await backend.getSetDetails(setNumber);
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

LegoCatalogBackend _buildBackend(ArgResults command) {
  final backendName = (command['backend'] as String?)?.trim() ?? '';
  if (backendName != 'rebrickable') {
    throw FormatException('Unsupported backend: $backendName');
  }

  final apiKeyFromFlag = (command['api-key'] as String?)?.trim() ?? '';
  final apiKeyFromEnv = (Platform.environment['REBRICKABLE_API_KEY'] ?? '')
      .trim();
  final apiKey = apiKeyFromFlag.isNotEmpty ? apiKeyFromFlag : apiKeyFromEnv;
  if (apiKey.isEmpty) {
    throw const FormatException(
      'Missing API key. Provide --api-key or set REBRICKABLE_API_KEY.',
    );
  }

  final baseUrl = (command['base-url'] as String?)?.trim();

  return RebrickableBackend(
    apiKey: apiKey,
    baseUrl: (baseUrl == null || baseUrl.isEmpty)
        ? 'https://rebrickable.com/api/v3/lego'
        : baseUrl,
    connectTimeout: Duration(
      milliseconds: int.parse(command['connect-timeout-ms'] as String),
    ),
    receiveTimeout: Duration(
      milliseconds: int.parse(command['receive-timeout-ms'] as String),
    ),
    sendTimeout: Duration(
      milliseconds: int.parse(command['send-timeout-ms'] as String),
    ),
    retries: int.parse(command['retries'] as String),
    initialRetryDelay: Duration(
      milliseconds: int.parse(command['initial-retry-delay-ms'] as String),
    ),
  );
}

String _usage(ArgParser parser) {
  return [
    'Usage: dart run lego_catalog <command> [options] <arg>',
    '',
    'Commands:',
    '  search <query>             Search sets by query.',
    '  details <set-number>       Fetch details for one set number.',
    '',
    parser.usage,
  ].join('\n');
}

String _commandUsage(ArgParser parser, ArgResults command) {
  if (command.name == 'search') {
    return [
      'Usage: dart run lego_catalog search [options] <query>',
      '',
      parser.commands['search']?.usage ?? '',
    ].join('\n');
  }

  if (command.name == 'details') {
    return [
      'Usage: dart run lego_catalog details [options] <set-number>',
      '',
      parser.commands['details']?.usage ?? '',
    ].join('\n');
  }

  return 'Usage: dart run lego_catalog <command> [options] <arg>';
}
