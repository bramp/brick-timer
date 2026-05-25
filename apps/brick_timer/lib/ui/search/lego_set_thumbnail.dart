import 'package:brick_timer/services/lego_set_image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Renders a LEGO set thumbnail with local disk caching.
// TODO(bramp): Create a lego themed loading animation.
class LegoSetThumbnail extends StatelessWidget {
  /// Creates a set thumbnail that uses local image caching.
  const LegoSetThumbnail({
    required this.imageUrl,
    this.cacheManager,
    this.size = 56,
    super.key,
  });

  /// Source image URL for the set thumbnail.
  final String? imageUrl;

  /// Optional cache manager override, mostly used in tests.
  final BaseCacheManager? cacheManager;

  /// Width and height of the square thumbnail.
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const Icon(Icons.category_outlined),
      );
    }

    if (kIsWeb) {
      // Use an HTML <img> element on web to avoid CORS-blocked fetches from
      // image CDNs that do not send Access-Control-Allow-Origin headers.
      return SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.contain,
          width: size,
          height: size,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, _, _) => SizedBox(
            width: size,
            height: size,
            child: const Icon(Icons.image_not_supported_outlined),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        cacheManager: cacheManager ?? LegoSetImageCacheManager.instance,
        fit: BoxFit.contain,
        imageBuilder: (context, imageProvider) => Image(
          image: imageProvider,
          fit: BoxFit.contain,
          width: size,
          height: size,
        ),
        placeholder: (_, _) => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, _, _) => SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      ),
    );
  }
}
