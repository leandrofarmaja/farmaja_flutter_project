import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Encontre Medicamentos em Angola Rápidamente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Consulte o stock em tempo real de farmácias em Luanda, Benguela, Huambo e reserve os seus remédios sem filas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Entrar na Conta'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/register'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: const Text(
                  'Criar Nova Conta',
                  style: TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'É necessária uma conta real Supabase para aceder à aplicação.',
                  style: TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
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
