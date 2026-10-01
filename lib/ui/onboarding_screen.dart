// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/inklus_colors.dart';
import 'theme/tokens.dart';

/// Pantalla de onboarding que se muestra la primera vez que se abre la app.
///
/// Muestra 4 páginas (cómo usar la app) con ilustraciones.
/// Se guarda en SharedPreferences que ya se vio, para no mostrar de nuevo.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onDone});

  /// Callback cuando se completa el onboarding (debe navegar a la biblioteca).
  final VoidCallback? onDone;

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_seen') ?? true;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', false);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  List<_OnboardingPage> _pages(BuildContext context) {
    final l10n = context.l10n;
    return [
      _OnboardingPage(icon: Icons.edit_outlined, title: l10n.onb1Title, description: l10n.onb1Body),
      _OnboardingPage(icon: Icons.pan_tool_outlined, title: l10n.onb2Title, description: l10n.onb2Body),
      _OnboardingPage(icon: Icons.construction_outlined, title: l10n.onb3Title, description: l10n.onb3Body),
      _OnboardingPage(icon: Icons.lock_outline, title: l10n.onb4Title, description: l10n.onb4Body),
    ];
  }

  /// Color de cada página y su color de texto encima (roles del tema:
  /// funciona en claro y oscuro).
  (Color, Color) _accentPair(BuildContext context, int i) => switch (i) {
        0 => (context.colors.primary, context.colors.onPrimary),
        1 => (context.colors.tertiary, context.colors.onTertiary),
        2 => (context.colors.secondary, context.colors.onSecondary),
        _ => (context.inklus.success, context.colors.onPrimary),
      };

  Color _accent(BuildContext context, int i) => _accentPair(context, i).$1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages(context).length - 1) {
      _controller.nextPage(duration: Motion.slow, curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _finish() async {
    await OnboardingScreen.markSeen();
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.sizeOf(context).height < 600;
    final accent = _accent(context, _page);
    final last = _page == _pages(context).length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, Spacing.sm, Spacing.lg, 0),
                child: TextButton(onPressed: _finish, child: Text(context.l10n.onbSkip)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages(context).length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages(context)[i];
                  final color = _accent(context, i);
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          children: [
                            Container(
                              width: isSmall ? 100 : 140,
                              height: isSmall ? 100 : 140,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: context.isDark ? 0.2 : 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(p.icon, size: isSmall ? 48 : 64, color: color),
                            ),
                            SizedBox(height: isSmall ? Spacing.xl : Spacing.xxxl),
                            Text(
                              p.title,
                              textAlign: TextAlign.center,
                              style: isSmall
                                  ? context.text.headlineSmall
                                  : context.text.headlineMedium,
                            ),
                            const SizedBox(height: Spacing.md),
                            Text(
                              p.description,
                              textAlign: TextAlign.center,
                              style: context.text.bodyLarge
                                  ?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  Spacing.xxl, 0, Spacing.xxl, isSmall ? Spacing.lg : Spacing.xxl),
              child: Row(
                children: [
                  for (var i = 0; i < _pages(context).length; i++)
                    AnimatedContainer(
                      duration: Motion.normal,
                      margin: const EdgeInsets.only(right: Spacing.sm),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? accent : context.colors.outlineVariant,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: _accentPair(context, _page).$2,
                      minimumSize: const Size(0, Sizes.minTouch),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: Icon(last ? Icons.check : Icons.arrow_forward),
                    label: Text(last ? context.l10n.onbStart : context.l10n.createNext),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
