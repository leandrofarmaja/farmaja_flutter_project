import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGOTIPO FARCLIK
            Container(
              width: 190,
              height: 190,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 25,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/farclik_logo_hd.png',
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'FARCLIK',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'A sua saúde à distância de um clique.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 45),

            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
