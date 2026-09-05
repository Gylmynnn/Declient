class FolderModel {
  final String id;
  final String collectionId;
  final String parentId;
  final String name;
  final String description;

  FolderModel({
    required this.id,
    required this.collectionId,
    this.parentId = '',
    required this.name,
    this.description = '',
  });

  FolderModel copyWith({String? name, String? description, String? parentId}) {
    return FolderModel(
      id: id,
      collectionId: collectionId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collectionId': collectionId,
        'parentId': parentId,
        'name': name,
        'description': description,
      };

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String? ?? '',
      collectionId: json['collectionId'] as String? ?? '',
      parentId: json['parentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
