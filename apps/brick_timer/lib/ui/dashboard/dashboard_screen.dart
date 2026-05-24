import 'package:brick_timer/state/dashboard_providers.dart';
import 'package:brick_timer/ui/dashboard/sync_status_widget.dart';
import 'package:brick_timer/ui/search/lego_catalog_search_screen.dart';
import 'package:brick_timer/ui/search/lego_set_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The main dashboard screen displaying in-progress builds and historic stats.
class DashboardScreen extends ConsumerWidget {
  /// Creates a new [DashboardScreen].
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(buildSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brick Timer Dashboard'),
        actions: const [
          SyncStatusWidget(),
          SizedBox(width: 16),
        ],
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text(
                'No builds yet.\nTap + to start a new LEGO set!',
                textAlign: TextAlign.center,
              ),
            );
          }

          final activeSessions = sessions
              .where((s) => !s.session.isCompleted)
              .toList();
          final historicSessions = sessions
              .where((s) => s.session.isCompleted)
              .toList();

          return CustomScrollView(
            slivers: [
              if (activeSessions.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'In-Progress Builds',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sessionWithSet = activeSessions[index];
                      final session = sessionWithSet.session;
                      final set = sessionWithSet.legoSet;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LegoSetThumbnail(
                              imageUrl: set.imageUrl,
                              size: 50,
                            ),
                          ),
                          title: Text(set.name),
                          subtitle: Text(
                            'Set #${set.setNumber} - Started '
                            '${DateFormat.yMMMd().format(session.startDate)}',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // TODO(bramp): Navigate to Active Build Workspace
                          },
                        ),
                      );
                    },
                    childCount: activeSessions.length,
                  ),
                ),
              ],
              if (historicSessions.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Historic Stats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatColumn(
                            title: 'Sets Completed',
                            value: historicSessions.length.toString(),
                          ),
                          // TODO(bramp): calculate pieces and time
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const LegoCatalogSearchScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(title),
      ],
    );
  }
}
