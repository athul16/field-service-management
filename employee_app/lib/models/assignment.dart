class Assignment {
  final String id;
  final String projectId;
  final String projectName;
  final String siteId;
  final String siteName;
  final String siteAddress;

  const Assignment({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.siteId,
    required this.siteName,
    required this.siteAddress,
  });

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      projectName: map['projectName'] as String,
      siteId: map['siteId'] as String,
      siteName: map['siteName'] as String,
      siteAddress: map['siteAddress'] as String,
    );
  }
}
