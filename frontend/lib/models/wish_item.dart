class WishItem {
  final int id;
  final String name;
  final bool reserved;
  final String? reservedBy;
  final String? reservedByName;
  final String? link;

  WishItem({
    required this.id,
    required this.name,
    this.reserved = false,
    this.reservedBy,
    this.reservedByName,
    this.link,
  });

  factory WishItem.fromJson(Map<String, dynamic> json) => WishItem(
        id: json['id'],
        name: json['name'],
        reserved: json['reserved'] ?? false,
        reservedBy: json['reserved_by'],
        reservedByName: json['reserved_by_name'],
        link: json['link'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'reserved': reserved,
        'reserved_by': reservedBy,
        'link': link,
      };
}
