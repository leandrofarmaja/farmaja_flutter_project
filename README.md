# FarmaJá Angola 🇦🇴 • Aplicação Flutter Clean Architecture

Aplicação mobile oficial do **FarmaJá Angola** desenvolvida em **Flutter 3.20+** com **Material Design 3**, **Riverpod**, **GoRouter** e integração **Supabase**.

## 📱 Estrutura do Projecto (Clean Architecture)

```
/
├── pubspec.yaml               # Dependências do Flutter (Riverpod, GoRouter, Supabase)
├── analysis_options.yaml      # Regras de Linting Dart
├── lib/
│   ├── main.dart              # Ponto de Entrada (ProviderScope + Supabase Init)
│   ├── core/
│   │   ├── constants/         # Cores do Sistema & Constantes de Angola
│   │   ├── router/            # Rotas GoRouter com NavigationBar MD3
│   │   ├── services/          # Cliente Supabase
│   │   └── theme/             # Tema Material Design 3 (Claro & Escuro)
│   └── features/
│       ├── ai_assistant/      # Assistente Farmacêutico IA
│       ├── auth/              # Autenticação, Login, Registo & Splash
│       ├── medicines/         # Pesquisa de Medicamentos, Stock e Detalhes
│       ├── pharmacies/        # Lista de Farmácias em Angola & Emergência 24H
│       ├── profile/           # Perfil do Utilizador & Validação de Receitas
│       └── reservations/      # Gestão e Histórico de Reservas com Código
├── android/                   # Projecto Android Nativo (AndroidManifest.xml)
└── ios/                       # Projecto iOS Nativo (Info.plist)
```

## 🚀 Como Executar em Dispositivo / Emulador Nativo

1. Certifique-se de ter o Flutter 3.20+ instalado:
   ```bash
   flutter doctor
   ```
2. Instalar todas as dependências:
   ```bash
   flutter pub get
   ```
3. Executar na Web / Android / iOS:
   ```bash
   flutter run -d chrome # Ou -d android / -d ios
   ```

## 🛠️ Tecnologias Utilizadas
- **Flutter 3.20+ / Dart 3**
- **Material Design 3** (ColorScheme.fromSeed com tom Emerald #16A34A)
- **Flutter Riverpod 2.5** (StateNotifier, FutureProvider)
- **GoRouter 14** (Navegação declarativa com ShellRoute)
- **Supabase Flutter 2.5** (Autenticação e Base de Dados)
