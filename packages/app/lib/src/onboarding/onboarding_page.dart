import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
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
              padding: const EdgeInsets.all(24),
              child: _currentPage == _slides.length - 1
                  ? FilledButton(
                      onPressed: _completeOnboarding,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(tr('onboarding.start')),
                    )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 400.ms)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(tr('onboarding.skip')),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 300.ms),
                        FilledButton(
                          onPressed: _nextPage,
                          child: Text(tr('onboarding.next')),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 300.ms)
                            .scale(delay: 200.ms, duration: 300.ms, begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/expenses');
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            slide.icon,
            size: 120,
            color: Theme.of(context).colorScheme.primary,
          )
              .animate()
              .scale(delay: 200.ms, duration: 600.ms, begin: const Offset(0.5, 0.5), end: const Offset(1, 1))
              .fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 48),
          Text(
            tr(slide.title),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 500.ms),
          const SizedBox(height: 24),
          Text(
            tr(slide.description),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0, delay: 600.ms, duration: 500.ms),
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
                : Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        )
            .animate()
            .scale(delay: (index * 50).ms, duration: 300.ms, begin: const Offset(0, 0), end: const Offset(1, 1))
            .fadeIn(delay: (index * 50).ms, duration: 300.ms),
      ),
    );
  }
}

