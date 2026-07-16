class BazarList {
  int? id;
  String name;
  bool isArchived;
  DateTime createdAt;

  BazarList({
    this.id,
    required this.name,
    this.isArchived = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isArchived': isArchived ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BazarList.fromJson(Map<String, dynamic> json) {
    return BazarList(
      id: json['id'],
      name: json['name'],
      isArchived: json['isArchived'] == 1 || json['isArchived'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
