class WishItem {
  final int id;
  final String name;
  final bool reserved;
  final String? reservedBy;

  WishItem({
    required this.id,
    required this.name,
    this.reserved = false,
    this.reservedBy,
  });

  factory WishItem.fromJson(Map<String, dynamic> json) => WishItem(
        id: json['id'],
        name: json['name'],
        reserved: json['reserved'] ?? false,
        reservedBy: json['reserved_by'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'reserved': reserved,
        'reserved_by': reservedBy,
      };
}

class WishList {
  final int id;
  final String name;
  final String ownerId;
  final String? ownerFirstName;
  final String? ownerLastName;
  final List<WishItem> items;
  final List<String>? sharedWith;
  final String? tag;

  WishList({
    required this.id,
    required this.name,
    required this.ownerId,
    this.ownerFirstName,
    this.ownerLastName,
    required this.items,
    this.sharedWith,
    this.tag,
  });

  factory WishList.fromJson(Map<String, dynamic> json) => WishList(
        id: json['id'],
        name: json['name'],
        ownerId: json['owner_id'],
        ownerFirstName: json['owner_first_name'],
        ownerLastName: json['owner_last_name'],
        items: (json['items'] as List<dynamic>? ?? [])
            .map((item) => WishItem.fromJson(item))
            .toList(),
        sharedWith: (json['shared_with'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        tag: json['tag'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'owner_id': ownerId,
        'owner_first_name': ownerFirstName,
        'owner_last_name': ownerLastName,
        'items': items.map((e) => e.toJson()).toList(),
        'shared_with': sharedWith,
        'tag': tag,
      };
}