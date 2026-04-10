import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';

import '../home/home_layout_shell.dart';
import '../navigation/app_routes.dart';
import '../home/home_walkthrough_providers.dart';
import 'onboarding_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.receipt_long,
      title: 'onboarding.slide1.title',
      description: 'onboarding.slide1.description',
    ),
    _OnboardingSlide(
      icon: Icons.analytics,
      title: 'onboarding.slide2.title',
      description: 'onboarding.slide2.description',
    ),
    _OnboardingSlide(
      icon: Icons.account_balance_wallet,
      title: 'onboarding.slide3.title',
      description: 'onboarding.slide3.description',
    ),
    _OnboardingSlide(
      icon: Icons.credit_card,
      title: 'onboarding.slide4.title',
      description: 'onboarding.slide4.description',
    ),
    _OnboardingSlide(
      icon: Icons.cloud_upload,
      title: 'onboarding.slide5.title',
      description: 'onboarding.slide5.description',
    ),
    _OnboardingSlide(
      icon: Icons.security,
      title: 'onboarding.slide6.title',
      description: 'onboarding.slide6.description',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _SlideContent(slide: _slides[index]);
                },
              ),
            ),
            _PageIndicator(
              currentPage: _currentPage,
              totalPages: _slides.length,
            ),
            Padding(
              padding: const EdgeInsets.all(HomeLayoutSpacing.s24),
              child: _currentPage == _slides.length - 1
                  ? FilledButton(
                      onPressed: () => _completeOnboarding(showHomeTour: true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(tr('onboarding.start')),
                    )
                      .animate()
                      .fadeIn(
                          delay: 180.ms,
                          duration: 240.ms,
                          curve: Curves.easeOutCubic)
                      .slideY(
                          begin: 0.12,
                          end: 0,
                          delay: 180.ms,
                          duration: 260.ms,
                          curve: Curves.easeOutCubic)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(tr('onboarding.skip')),
                        )
                            .animate()
                            .fadeIn(
                                delay: 120.ms,
                                duration: 200.ms,
                                curve: Curves.easeOutCubic),
                        FilledButton(
                          onPressed: _nextPage,
                          child: Text(tr('onboarding.next')),
                        )
                            .animate()
                            .fadeIn(
                                delay: 120.ms,
                                duration: 200.ms,
                                curve: Curves.easeOutCubic)
                            .scale(
                                delay: 120.ms,
                                duration: 220.ms,
                                curve: Curves.easeOutCubic,
                                begin: const Offset(0.94, 0.94),
                                end: const Offset(1, 1)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding({bool showHomeTour = false}) async {
    await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    if (showHomeTour) {
      await ref.read(homeWalkthroughPendingProvider.notifier).markPending();
    }
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(HomeLayoutSpacing.s32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.12),
                  cs.primaryContainer.withValues(alpha: 0.25),
                ],
              ),
            ),
            child: Icon(
              slide.icon,
              size: 52,
              color: cs.primary,
            ),
          )
              .animate()
              .scale(
                  delay: 120.ms,
                  duration: 320.ms,
                  curve: Curves.easeOutCubic,
                  begin: const Offset(0.82, 0.82),
                  end: const Offset(1, 1))
              .fadeIn(
                  delay: 120.ms,
                  duration: 240.ms,
                  curve: Curves.easeOutCubic),
          SizedBox(height: HomeLayoutSpacing.s32 + HomeLayoutSpacing.s16),
          Text(
            tr(slide.title),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(
                  delay: 220.ms,
                  duration: 260.ms,
                  curve: Curves.easeOutCubic)
              .slideY(
                  begin: 0.1,
                  end: 0,
                  delay: 220.ms,
                  duration: 280.ms,
                  curve: Curves.easeOutCubic),
          SizedBox(height: HomeLayoutSpacing.s24),
          Text(
            tr(slide.description),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(
                  delay: 320.ms,
                  duration: 260.ms,
                  curve: Curves.easeOutCubic)
              .slideY(
                  begin: 0.1,
                  end: 0,
                  delay: 320.ms,
                  duration: 280.ms,
                  curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentPage
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
          ),
        )
            .animate()
            .scale(
                delay: AppMotion.staggerInterval * index,
                duration: AppMotion.standard,
                curve: AppMotion.curve,
                begin: const Offset(0, 0),
                end: const Offset(1, 1))
            .fadeIn(
                delay: AppMotion.staggerInterval * index,
                duration: AppMotion.standard,
                curve: AppMotion.curve),
      ),
    );
  }
}

