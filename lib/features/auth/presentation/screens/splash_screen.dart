import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart' show Iconsax;

import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const String _healthImage =
      'assets/images/Ilustração_3d_saude.jpg';

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user != null) {
      if (user.role == 'pharmacy') {
        context.go('/pharmacy-dashboard');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    return Theme(
      data: base.copyWith(
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FBF8),
        body: SafeArea(
          child: Stack(
            children: [
              // Ilustração 3D discreta no fundo. Se faltar, não aparece nada.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.12,
                    child: Image.asset(
                      _healthImage,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 700.ms),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 172,
                        height: 172,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(38),
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF173B57)
                                  .withValues(alpha: 0.07),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'FARCLIK_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Iconsax.shop_bold,
                              size: 88,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .scale(
                            begin: const Offset(0.85, 0.85),
                            end: const Offset(1, 1),
                            duration: 550.ms,
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 30),

                      const Text(
                        'FARCLIK',
                        style: TextStyle(
                          color: Color(0xFF173B57),
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      )
                          .animate(delay: 150.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),

                      const SizedBox(height: 10),

                      const Text(
                        'A sua saúde à distância de um clique.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF748091),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      )
                          .animate(delay: 300.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),

                      const SizedBox(height: 48),

                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ).animate(delay: 450.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 16),

                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.activity,
                            size: 14,
                            color: Color(0xFF89949F),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'A preparar a sua experiência...',
                            style: TextStyle(
                              color: Color(0xFF89949F),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                          .animate(delay: 600.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
