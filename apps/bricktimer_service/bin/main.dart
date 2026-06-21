import 'package:bricktimer_service/src/bricktimer_catalog_service.dart';
import 'package:firebase_admin_sdk/app_check.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:lego_catalog/lego_catalog.dart';

const _rebrickableApiKey = SecretParam('REBRICKABLE_API_KEY', null);

Future<void> main(List<String> args) async {
  await runFunctions((firebase) {
    firebase.https.onRequest(
      name: 'bricktimerCatalog',
      options: const HttpsOptions(
        secrets: [_rebrickableApiKey],
        cors: Option(['*']),
      ),
      (request) async {
        final appCheckToken = request.headers['X-Firebase-AppCheck'];
        if (appCheckToken == null || appCheckToken.trim().isEmpty) {
          return Response.unauthorized(
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
          return Response.forbidden(
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
  final value = _rebrickableApiKey.value().trim();
  if (value.isEmpty) {
    throw StateError(
      'Missing REBRICKABLE_API_KEY secret value. Set it via Firebase '
      'parameterized configuration.',
    );
  }
  return value;
}
