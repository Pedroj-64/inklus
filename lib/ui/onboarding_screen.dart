import '../constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_colors.dart';

/// Pantalla de onboarding que se muestra la primera vez que se abre la app.
///
/// Muestra 4 páginas explicativas con ilustraciones y permite saltar al final.
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

  static const _pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.edit_note,
      color: kAccentColor,
      title: 'Escribe con naturalidad',
      description:
          'Inklus detecta tu stylus y rechaza la palma de la mano. '
          'Escribe, dibuja o subraya como en un cuaderno real.',
    ),
    _OnboardingPage(
      icon: Icons.dashboard_customize_outlined,
      color: Color(0xFF8B5CF6),
      title: 'Plantillas ilimitadas',
      description:
          'Rayas, cuadrícula, pentagrama, agenda o crea tu propia plantilla. '
          'Los lienzos infinitos se alargan conforme escribes.',
    ),
    _OnboardingPage(
      icon: Icons.cloud_upload_outlined,
      color: Color(0xFF10B981),
      title: 'Respaldo en la nube',
      description:
          'Inicia sesión con Google Drive para respaldar tus cuadernos '
          'automáticamente. Tus datos nunca se pierden.',
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome,
      color: Color(0xFFF59E0B),
      title: 'Herramientas mágicas',
      description:
          'Lazo, figuras, buckets, capas, OCR y exporta a PNG, PDF o SVG. '
          'Todo lo que necesitas, gratis y sin límites.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  void _finish() async {
    await OnboardingScreen.markSeen();
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Botón saltar
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Saltar',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Páginas
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ilustración circular
                        Container(
                          width: isSmall ? 100 : 140,
                          height: isSmall ? 100 : 140,
                          decoration: BoxDecoration(
                            color: p.color.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            p.icon,
                            size: isSmall ? 50 : 64,
                            color: p.color,
                          ),
                        ),
                        SizedBox(height: isSmall ? 24 : 40),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmall ? 22 : 26,
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.of(context).textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmall ? 13 : 15,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicadores de página + botón siguiente
            Padding(
              padding: EdgeInsets.fromLTRB(
                32,
                0,
                32,
                isSmall ? 20 : 32,
              ),
              child: Row(
                children: [
                  // Dots indicadores
                  ...List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? _pages[_page].color
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Botón siguiente / empezar
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: _pages[_page].color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _page == _pages.length - 1
                              ? 'Empezar'
                              : 'Siguiente',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _page == _pages.length - 1
                              ? Icons.check
                              : Icons.arrow_forward_ios,
                          size: 16,
                        ),
                      ],
                    ),
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
  final Color color;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
