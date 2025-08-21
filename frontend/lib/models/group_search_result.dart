class GroupSearchResult {
  final int id;
  final String name;
  final String ownerId;

  GroupSearchResult({
    required this.id,
    required this.name,
    required this.ownerId,
  });

  factory GroupSearchResult.fromJson(Map<String, dynamic> json) => GroupSearchResult(
        id: json['id'],
        name: json['name'],
        ownerId: json['owner_id'],
      );
}
