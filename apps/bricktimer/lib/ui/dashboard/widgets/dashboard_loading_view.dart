import 'package:flutter/material.dart';

/// Skeleton loading view displayed while dashboard data is loading.
class DashboardLoadingView extends StatelessWidget {
  /// Creates a new [DashboardLoadingView].
  const DashboardLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: const [
        _LoadingHeader(),
        SizedBox(height: 16),
        _StatusCardSkeleton(),
        SizedBox(height: 16),
        _LoadingHeroCard(),
        SizedBox(height: 20),
        _LoadingSectionHeader(),
        SizedBox(height: 12),
        _LoadingRecentRow(),
        SizedBox(height: 10),
        _LoadingRecentRow(),
        SizedBox(height: 10),
        _LoadingRecentRow(),
      ],
    );
  }
}

class _StatusCardSkeleton extends StatelessWidget {
  const _StatusCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          height: 76,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0x22222222),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LoadingBar(width: 180, height: 34),
        SizedBox(height: 10),
        _LoadingBar(width: 260, height: 18),
        SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _LoadingPill(width: 84),
            _LoadingPill(width: 96),
          ],
        ),
      ],
    );
  }
}

class _LoadingHeroCard extends StatelessWidget {
  const _LoadingHeroCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LoadingBar(width: 120, height: 16),
            SizedBox(height: 12),
            _LoadingBar(width: double.infinity, height: 26),
            SizedBox(height: 8),
            _LoadingBar(width: 180, height: 18),
            SizedBox(height: 18),
            Center(child: _LoadingBar(width: 220, height: 54)),
            SizedBox(height: 16),
            _LoadingBar(width: double.infinity, height: 52),
          ],
        ),
      ),
    );
  }
}

class _LoadingSectionHeader extends StatelessWidget {
  const _LoadingSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LoadingBar(width: 140, height: 22),
        SizedBox(height: 6),
        _LoadingBar(width: 240, height: 16),
      ],
    );
  }
}

class _LoadingRecentRow extends StatelessWidget {
  const _LoadingRecentRow();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            _LoadingAvatar(),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LoadingBar(width: 160, height: 18),
                  SizedBox(height: 8),
                  _LoadingBar(width: 220, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingAvatar extends StatelessWidget {
  const _LoadingAvatar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 56,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0x22222222),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return _LoadingBar(width: width, height: 30, radius: 999);
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width == double.infinity ? null : width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
