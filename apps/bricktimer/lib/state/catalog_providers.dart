import 'dart:async';

import 'package:bricktimer/services/catalog_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the LEGO Catalog API service.
final legoCatalogServiceProvider = Provider<CatalogService>((ref) {
  final service = CatalogService.brickTimer();
  unawaited(service.warmUp());
  return service;
});
