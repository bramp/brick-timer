import 'dart:convert';

import 'package:bricktimer_service/src/bricktimer_catalog_service.dart';
import 'package:firebase_admin_sdk/app_check.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:lego_catalog/lego_catalog.dart';

// TODO(bramp): Rename this constant to lowerCamelCase after a
// firebase_functions release includes:
// https://github.com/firebase/firebase-functions-dart/pull/180
// We currently keep the identifier uppercase to force the generated
// functions.yaml secret name to match REBRICKABLE_API_KEY.
// ignore: constant_identifier_names
const REBRICKABLE_API_KEY = SecretParam('REBRICKABLE_API_KEY', null);

Future<void> main(List<String> args) async {
  await runFunctions((firebase) {
    firebase.https.onRequest(
      name: 'bricktimerCatalog',
      options: const HttpsOptions(
        invoker: Invoker.public(),
        region: Region(SupportedRegion.usCentral1),
        secrets: [REBRICKABLE_API_KEY],
        cors: Option(['*']),
      ),
      (request) async {
        final appCheckToken = request.headers['X-Firebase-AppCheck'];
        if (appCheckToken == null || appCheckToken.trim().isEmpty) {
          return _jsonResponse(
            401,
            {
              'error': 'app_check_required',
              'message': 'A valid Firebase App Check token is required.',
            },
          );
        }

        final firebaseApp = FirebaseApp.apps.isEmpty
            ? FirebaseApp.initializeApp()
            : FirebaseApp.instance;

        try {
          await firebaseApp.appCheck().verifyToken(appCheckToken.trim());
        } on FirebaseAppCheckException {
          return _jsonResponse(
            401,
            {
              'error': 'app_check_invalid',
              'message': 'The Firebase App Check token is invalid.',
            },
          );
        }

        final service = BrickTimerCatalogService(
          backend: RebrickableBackend(
            apiKey: _resolveRebrickableApiKey(),
          ),
        );
        return service.handle(request);
      },
    );
  });
}

String _resolveRebrickableApiKey() {
  final value = REBRICKABLE_API_KEY.value().trim();
  if (value.isEmpty) {
    throw StateError(
      'Missing REBRICKABLE_API_KEY secret value. Set it via Firebase '
      'parameterized configuration.',
    );
  }
  return value;
}

Response _jsonResponse(int statusCode, Object body) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: const {'Content-Type': 'application/json; charset=utf-8'},
  );
}
