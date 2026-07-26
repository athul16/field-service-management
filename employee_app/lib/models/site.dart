class Site {
  final String id;
  final String projectId;
  final String name;
  final String address;
  final String? projectName;

  const Site({
    required this.id,
    required this.projectId,
    required this.name,
    required this.address,
    this.projectName,
  });

  factory Site.fromMap(Map<String, dynamic> map) {
    return Site(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      projectName: (map['projects'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }
}
