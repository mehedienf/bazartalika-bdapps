class Category {
  final String name;

  Category(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  Map<String, dynamic> toJson() => {'name': name};

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(json['name']);
  }
}
