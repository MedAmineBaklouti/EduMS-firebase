import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/database_service.dart';
import '../../data/models/announcement_model.dart';
import '../../modules/announcement/views/announcement_detail_view.dart';

class DashboardAnnouncements extends StatefulWidget {
  const DashboardAnnouncements({
    super.key,
    this.audience,
    this.onShowAll,
  });

  final String? audience;
  final VoidCallback? onShowAll;

  @override
  State<DashboardAnnouncements> createState() => _DashboardAnnouncementsState();
}

class _DashboardAnnouncementsState extends State<DashboardAnnouncements> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  Timer? _autoScrollResumeTimer;
  int _autoScrollItemCount = 0;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _autoScrollResumeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = Get.find<DatabaseService>();

    return StreamBuilder<List<AnnouncementModel>>(
      stream: database.streamAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'Unable to load announcements',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        final announcements = _filterAnnouncements(snapshot.data ?? []);
        _configureAutoScroll(announcements.length);

        if (announcements.isEmpty) {
          return SizedBox(
            height: 180,
            child: _EmptyAnnouncements(onShowAll: widget.onShowAll),
          );
        }

        if (_currentPage >= announcements.length) {
          _currentPage = 0;
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        }

        return SizedBox(
          height: 220,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _isUserInteracting = true;
                _pauseAutoScroll();
              } else if (notification is ScrollEndNotification) {
                if (_isUserInteracting) {
                  _isUserInteracting = false;
                  _scheduleAutoScrollResume();
                }
              }
              return false;
            },
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: announcements.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    return _AnnouncementSlide(
                      announcement: announcement,
                      onShowAll: widget.onShowAll,
                    );
                  },
                ),
                if (announcements.length > 1)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.65),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: AnimatedBuilder(
                                animation: _pageController,
                                builder: (context, child) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      announcements.length,
                                      (dotIndex) {
                                        final isActive =
                                            dotIndex == _currentPage;
                                        return AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          height: 6,
                                          width: isActive ? 18 : 6,
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _configureAutoScroll(int itemCount) {
    _autoScrollItemCount = itemCount;

    if (itemCount <= 1) {
      _pauseAutoScroll(cancelResume: true);
      return;
    }

    if (_isUserInteracting) {
      return;
    }

    if (_autoScrollTimer?.isActive == true) {
      return;
    }

    _startAutoScrollTimer();
  }

  void _startAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _autoScrollResumeTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients || _autoScrollItemCount <= 1) {
        return;
      }
      final nextPage = (_currentPage + 1) % _autoScrollItemCount;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseAutoScroll({bool cancelResume = false}) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (cancelResume) {
      _autoScrollResumeTimer?.cancel();
      _autoScrollResumeTimer = null;
    }
  }

  void _scheduleAutoScrollResume() {
    _autoScrollResumeTimer?.cancel();
    _autoScrollResumeTimer = Timer(const Duration(seconds: 8), () {
      if (_autoScrollItemCount > 1 && !_isUserInteracting) {
        _startAutoScrollTimer();
      }
    });
  }

  List<AnnouncementModel> _filterAnnouncements(List<AnnouncementModel> items) {
    if (widget.audience == null) {
      return items;
    }

    final audience = widget.audience!.toLowerCase();
    return items.where((announcement) {
      if (announcement.audience.isEmpty) {
        return true;
      }
      final lowered = announcement.audience.map((item) => item.toLowerCase()).toList();
      return lowered.contains(audience) || lowered.contains('all');
    }).toList();
  }

}

class _AnnouncementSlide extends StatelessWidget {
  const _AnnouncementSlide({
    required this.announcement,
    this.onShowAll,
  });

  final AnnouncementModel announcement;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTitle = announcement.title.trim().isEmpty
        ? 'Announcement'
        : announcement.title.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: () {
          Get.to(() => AnnouncementDetailView(announcement: announcement));
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              resolvedTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onPrimary
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.onPrimary
                                    .withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              'NEW',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onShowAll != null) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: onShowAll,
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Show all'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    announcement.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacity(0.9),
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDate(announcement.createdAt),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary
                              .withOpacity(0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _EmptyAnnouncements extends StatelessWidget {
  const _EmptyAnnouncements({this.onShowAll});

  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Announcements',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onShowAll != null)
                  TextButton.icon(
                    onPressed: onShowAll,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Show all'),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              'No announcements right now.\nCheck back soon for updates.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
