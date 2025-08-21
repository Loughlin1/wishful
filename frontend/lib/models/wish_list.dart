import 'wish_item.dart';

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
        sharedWith: (json['shared_with'] as List<dynamic>?)?.cast<String>(),
        tag: json['tag'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'owner_id': ownerId,
        'owner_first_name': ownerFirstName,
        'owner_last_name': ownerLastName,
        'items': items.map((item) => item.toJson()).toList(),
        'shared_with': sharedWith,
        'tag': tag,
      };
}
