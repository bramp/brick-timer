import 'package:brick_timer/main.dart'; // for ledgerRepository
import 'package:brick_timer/state/active_session_notifier.dart';
import 'package:brick_timer/state/search_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for searching and adding new LEGO sets from Rebrickable.
class RebrickableSearchScreen extends ConsumerWidget {
  /// Creates a new [RebrickableSearchScreen].
  const RebrickableSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search LEGO Sets'),
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
      body: searchResults.when(
        data: (results) {
          if (results.isEmpty) {
            final query = ref.read(searchQueryProvider);
            if (query.trim().isNotEmpty) {
              return const Center(child: Text('No sets found.'));
            }
            return const Center(
              child: Text('Type a set number or name to search.'),
            );
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final setCompanion = results[index];
              return ListTile(
                leading:
                    setCompanion.imageUrl.present &&
                        setCompanion.imageUrl.value != null
                    ? Image.network(
                        setCompanion.imageUrl.value!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.category, size: 50),
                title: Text(setCompanion.name.value),
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
                  final savedSet = await ledgerRepository.getLegoSet(setId);
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
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
