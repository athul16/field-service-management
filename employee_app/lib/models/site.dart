class Site {
  final String id;
  final String name;
  final String address;

  const Site({
    required this.id,
    required this.name,
    required this.address,
  });

  factory Site.fromMap(Map<String, dynamic> map) {
    return Site(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
    );
  }
}
