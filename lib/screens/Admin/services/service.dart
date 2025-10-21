class Service {
  final String id;
  final String name;
  final String description;
  final String price;
  final String popular;
  final String imgurl;
  final String rooms;
  final String additional;

  Service({
    this.id = '',
    required this.name,
    required this.description,
    required this.price,
    required this.popular,
    required this.imgurl,
    required this.rooms,
    required this.additional,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] ?? '',
      popular: map['popular'] ?? '',
      imgurl: map['imgurl'] ?? '',
      rooms: map['rooms'] ?? '',
      additional: map['additional'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'popular': popular,
      'imgurl': imgurl,
      'rooms': rooms,
      'additional': additional,
    };
  }
}