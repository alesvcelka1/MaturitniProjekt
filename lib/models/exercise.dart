import 'package:cloud_firestore/cloud_firestore.dart';

/// Model pro cvik
/// - Cviky jsou uložené v Firestore databázi
/// - GIF soubory jsou lokální (assets/gifs/)
class Exercise {
  final String id;
  final String name;
  final String gifPath; // Cesta k lokálnímu GIF souboru
  final String bodyPart;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Exercise({
    required this.id,
    required this.name,
    required this.gifPath,
    required this.bodyPart,
    this.createdAt,
    this.updatedAt,
  });

  /// Vytvoří Exercise z Firestore dokumentu
  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      name: data['name'] ?? '',
      gifPath: data['gifPath'] ?? '',
      bodyPart: data['bodyPart'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Vytvoří Exercise z Map
  factory Exercise.fromMap(Map<String, dynamic> map, String id) {
    return Exercise(
      id: id,
      name: map['name'] ?? '',
      gifPath: map['gifPath'] ?? '',
      bodyPart: map['bodyPart'] ?? '',
      createdAt: map['created_at'] is Timestamp 
          ? (map['created_at'] as Timestamp).toDate()
          : null,
      updatedAt: map['updated_at'] is Timestamp
          ? (map['updated_at'] as Timestamp).toDate()
          : null,
    );
  }

  /// Konvertuje Exercise na Map pro Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gifPath': gifPath,
      'bodyPart': bodyPart,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// Konvertuje Exercise na Map (starý formát pro kompatibilitu)
  Map<String, dynamic> toCompatibleMap() {
    return {
      'id': id,
      'name': name,
      'gifPath': gifPath,
      'bodyPart': bodyPart,
    };
  }

  /// Vytvoří kopii s upravenými hodnotami
  Exercise copyWith({
    String? id,
    String? name,
    String? gifPath,
    String? bodyPart,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      gifPath: gifPath ?? this.gifPath,
      bodyPart: bodyPart ?? this.bodyPart,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, bodyPart: $bodyPart, gifPath: $gifPath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Pomocné konstanty pro partie těla
class BodyParts {
  static const String chest = 'chest';
  static const String back = 'back';
  static const String legs = 'legs';
  static const String shoulders = 'shoulders';
  static const String arms = 'arms';
  static const String core = 'core';

  static const List<String> all = [
    chest,
    back,
    legs,
    shoulders,
    arms,
    core,
  ];

  /// Vrátí český překlad partie těla
  static String getCzechName(String bodyPart) {
    switch (bodyPart) {
      case chest:
        return 'Hrudník';
      case back:
        return 'Záda';
      case legs:
        return 'Nohy';
      case shoulders:
        return 'Ramena';
      case arms:
        return 'Paže';
      case core:
        return 'Core/Břicho';
      default:
        return bodyPart;
    }
  }
}
