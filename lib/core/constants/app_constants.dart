class AppConstants {
  static const String appName = 'FarmaJá';
  static const String appTagline = 'Farmácias e Medicamentos em Angola';
  
  // Supabase Configuration from Environment Variables
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzkjghfklqw.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5emtqZ2hma2xxdyIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzEzMDA0ODAwLCJleHAiOjIwMjg1ODA4MDB9.testKey',
  );

  // Angola Provinces
  static const List<String> angolaProvinces = [
    'Luanda',
    'Benguela',
    'Huambo',
    'Huíla',
    'Cabinda',
    'Cuanza Sul',
    'Cuanza Norte',
    'Uíge',
    'Malanje',
    'Namibe',
    'Lunda Norte',
    'Lunda Sul',
    'Zaire',
    'Bengo',
    'Bié',
    'Cuando Cubango',
    'Cunene',
    'Moxico',
  ];

  // Angola Municipalities by Province
  static const Map<String, List<String>> angolaMunicipalities = {
    'Luanda': ['Todos os Municípios', 'Talatona', 'Maianga', 'Ingombota', 'Belas', 'Viana', 'Cazenga', 'Kilamba Kiaxi', 'Cacuaco'],
    'Benguela': ['Todos os Municípios', 'Benguela Centro', 'Lobito', 'Catumbela', 'Baía Farta'],
    'Huambo': ['Todos os Municípios', 'Huambo Centro', 'Caála', 'Bailundo'],
    'Huíla': ['Todos os Municípios', 'Lubango', 'Humpata', 'Chibia'],
    'Cabinda': ['Todos os Municípios', 'Cabinda Centro', 'Buco-Zau', 'Lândana'],
  };

  // Primary Currency
  static const String currencySymbol = 'Kz';
}
