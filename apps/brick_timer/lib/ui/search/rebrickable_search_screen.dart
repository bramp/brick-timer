import 'package:brick_timer/main.dart'; // for ledgerRepository
import 'package:brick_timer/state/active_session_notifier.dart';
import 'package:brick_timer/state/search_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lego_catalog/lego_catalog.dart';

/// Screen for searching and adding new LEGO sets from Rebrickable.
class RebrickableSearchScreen extends ConsumerStatefulWidget {
  /// Creates a new [RebrickableSearchScreen].
  const RebrickableSearchScreen({super.key});

  @override
  ConsumerState<RebrickableSearchScreen> createState() =>
      _RebrickableSearchScreenState();
}

class _RebrickableSearchScreenState
    extends ConsumerState<RebrickableSearchScreen> {
  bool _showErrorDetails = false;

  Future<void> _refreshSearchResults(WidgetRef ref) async {
    ref.invalidate(searchResultsProvider);
    try {
      await ref.read(searchResultsProvider.future);
    } on Exception {
      // The error state is rendered in the UI; swallow to complete refresh.
    }
  }

  Widget _buildScrollableMessage({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 72),
        Icon(
          icon,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[
          const SizedBox(height: 20),
          Center(child: action),
        ],
      ],
    );
  }

  Widget _buildErrorPanel(BuildContext context, Object error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 56),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 40,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load search results',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _friendlySearchErrorMessage(error),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showErrorDetails = !_showErrorDetails;
                            });
                          },
                          child: Text(
                            _showErrorDetails ? 'Hide details' : 'Advanced',
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _refreshSearchResults(ref),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                    if (_showErrorDetails) ...[
                      const SizedBox(height: 12),
                      Divider(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Technical details',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _friendlySearchErrorMessage(Object error) {
    if (error is CatalogHttpException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'Search is not authorized right now. Please try again later.';
      }
      if (error.statusCode == 429) {
        return 'Too many requests right now. '
            'Please wait a moment and try again.';
      }
      if (error.statusCode != null && error.statusCode! >= 500) {
        return 'The catalog service is temporarily unavailable. '
            'Please try again.';
      }
    }

    return 'We could not load search results. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search LEGO Sets'),
        actions: [
          IconButton(
            tooltip: 'Refresh search results',
            onPressed: query.trim().isEmpty
                ? null
                : () => _refreshSearchResults(ref),
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. 42115 or Lamborghini',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).updateQuery(value);
              },
            ),
          ),
        ),
      ),
      body: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
          },
        ),
        child: RefreshIndicator(
          onRefresh: () => _refreshSearchResults(ref),
          child: searchResults.when(
            data: (results) {
              if (results.isEmpty) {
                if (query.trim().isNotEmpty) {
                  return _buildScrollableMessage(
                    context: context,
                    icon: Icons.search_off,
                    title: 'No sets found',
                    message:
                        'Try another set number or name, '
                        'or pull down to search again.',
                  );
                }
                return _buildScrollableMessage(
                  context: context,
                  icon: Icons.toys_outlined,
                  title: 'Find your next build',
                  message:
                      'Type a set number or name to search Rebrickable. '
                      'You can pull down anytime to refresh.',
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final setCompanion = results[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      leading:
                          setCompanion.imageUrl.present &&
                              setCompanion.imageUrl.value != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                setCompanion.imageUrl.value!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox(
                                  width: 56,
                                  height: 56,
                                  child:
                                      Icon(Icons.image_not_supported_outlined),
                                ),
                              ),
                            )
                          : const SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(Icons.category_outlined),
                            ),
                      title: Text(
                        setCompanion.name.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Set #${setCompanion.setNumber.value} • '
                        '${setCompanion.totalPieces.value} parts',
                      ),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () async {
                        // Save set to local database
                        final setId = await ledgerRepository.saveLegoSet(
                          setCompanion,
                        );
                        if (!context.mounted) return;

                        // Retrieve the saved LegoSet data class
                        final savedSet = await ledgerRepository.getLegoSet(
                          setId,
                        );
                        if (savedSet != null && context.mounted) {
                          // Start a new session
                          await ref
                              .read(activeSessionProvider.notifier)
                              .startNewSession(savedSet);

                          if (!context.mounted) return;
                          // Return to dashboard
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  );
                },
              );
            },
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 160),
                Center(child: CircularProgressIndicator()),
              ],
            ),
            error: (error, _) => _buildErrorPanel(context, error),
          ),
        ),
      ),
    );
  }
}
