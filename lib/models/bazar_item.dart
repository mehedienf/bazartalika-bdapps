import 'category.dart';

class BazarItem {
  int? id;
  final String name;
  double? price;
  Category? category;
  bool isBought;
  bool isArchived;
  DateTime createdAt;
  final DateTime originalCreatedAt;

  BazarItem({
    this.id,
    required this.name,
    this.price,
    this.category,
    this.isBought = false,
    this.isArchived = false,
    DateTime? createdAt,
    DateTime? originalCreatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       originalCreatedAt = originalCreatedAt ?? createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'category': category?.toJson(),
    'isBought': isBought ? 1 : 0,
    'isArchived': isArchived ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
    'originalCreatedAt': originalCreatedAt.toIso8601String(),
  };

  factory BazarItem.fromJson(Map<String, dynamic> json) {
    return BazarItem(
      id: json['id'],
      name: json['name'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      isBought: json['isBought'] == 1 || json['isBought'] == true,
      isArchived: json['isArchived'] == 1 || json['isArchived'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      originalCreatedAt: json['originalCreatedAt'] != null
          ? DateTime.parse(json['originalCreatedAt'])
          : null,
    );
  }
}
