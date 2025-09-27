class TransferCategory {
  final String? id;
  final String name;
  final String? description;
  final String color;
  final String icon;
  final bool isActive;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TransferCategory({
    this.id,
    required this.name,
    this.description,
    this.color = '#6B7280',
    this.icon = 'exchange',
    this.isActive = true,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory TransferCategory.fromMap(Map<String, dynamic> map) {
    return TransferCategory(
      id: map['_id']?.toString() ?? map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      color: map['color']?.toString() ?? '#6B7280',
      icon: map['icon']?.toString() ?? 'exchange',
      isActive: map['isActive'] ?? true,
      userId: map['user']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'isActive': isActive,
    };
  }

  TransferCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    bool? isActive,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransferCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TransferCategory(id: $id, name: $name, description: $description, color: $color, icon: $icon, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransferCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
