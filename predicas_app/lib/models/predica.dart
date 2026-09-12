class Predica {
  final int id;
  final String titulo;
  final String fecha;
  final String categoria;
  final String url;
  bool isFavorito;

  Predica({
    required this.id,
    required this.titulo,
    required this.fecha,
    required this.categoria,
    required this.url,
    this.isFavorito = false,
  });

  factory Predica.fromJson(Map<String, dynamic> json) {
    return Predica(
      id: json['id'],
      titulo: json['titulo'],
      fecha: json['fecha'],
      categoria: json['categoria'],
      url: json['url'],
      isFavorito: json['isFavorito'] ?? false,
    );
  }
}