import 'package:flutter/foundation.dart';

/// Registers the Nunito font license so it appears in Flutter's
/// license page list.
void registerNunitoLicense() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      <String>['Nunito Font Family'],
      '''
Nunito Font Family

Copyright 2014 The Nunito Project Authors
(https://github.com/googlefonts/nunito)

This Font Software is licensed under the SIL Open Font License,
Version 1.1.

You may obtain a copy of the license at:
https://openfontlicense.org/open-font-license-official-text/
''',
    );
  });
}
