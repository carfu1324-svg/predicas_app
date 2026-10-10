class Predica {
  final int id;
  final String titulo;
  final String fecha;
  final String categoria;
  final String url;
  final bool oculto; // true => la prédica no se muestra en la app
  final List<String> versiculos; // referencias citadas en la prédica (ej. "Juan 3:16")
  bool isFavorito;

  Predica({
    required this.id,
    required this.titulo,
    required this.fecha,
    required this.categoria,
    required this.url,
    this.oculto = false,
    this.versiculos = const [],
    this.isFavorito = false,
  });

  factory Predica.fromJson(Map<String, dynamic> json) {
    return Predica(
      id: json['id'],
      titulo: json['titulo'],
      fecha: json['fecha'],
      categoria: json['categoria'],
      url: json['url'],
      // Acepta "oculto" u "oculta" (true / "true" / 1) para no depender de
      // cómo lo escriba el editor del JSON. Si no viene, la prédica se muestra.
      oculto: _leerBool(json['oculto'] ?? json['oculta']),
      versiculos: _leerLista(json['versiculos']),
      isFavorito: json['isFavorito'] ?? false,
    );
  }

  // Acepta una lista ["Juan 3:16", "Romanos 8:28"] o un solo texto separado
  // por saltos de línea o punto y coma ("Juan 3:16; Romanos 8:28").
  // Si no viene el campo, queda vacío y la app no muestra la sección.
  static List<String> _leerLista(dynamic valor) {
    Iterable<dynamic> items;
    if (valor is List) {
      items = valor;
    } else if (valor is String) {
      items = valor.split(RegExp(r'[;\n]'));
    } else {
      return const [];
    }
    return items
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static bool _leerBool(dynamic valor) {
    if (valor is bool) return valor;
    if (valor is num) return valor != 0;
    if (valor is String) return valor.trim().toLowerCase() == 'true';
    return false;
  }
}