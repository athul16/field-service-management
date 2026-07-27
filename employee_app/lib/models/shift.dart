class Shift {
  final String id;
  final String workerId;
  final String siteId;
  final String? siteName;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final String? clockOutPhotoUrl;
  final String status; // IN_PROGRESS | COMPLETED

  const Shift({
    required this.id,
    required this.workerId,
    required this.siteId,
    this.siteName,
    required this.clockInAt,
    this.clockOutAt,
    this.clockOutPhotoUrl,
    required this.status,
  });

  bool get isActive => status == 'IN_PROGRESS';

  Duration? get workedDuration {
    if (clockOutAt == null) return null;
    return clockOutAt!.difference(clockInAt);
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] as String,
      workerId: map['workerId'] as String,
      siteId: map['siteId'] as String,
      siteName: map['siteName'] as String?,
      clockInAt: DateTime.parse(map['clockInAt'] as String),
      clockOutAt: map['clockOutAt'] != null ? DateTime.parse(map['clockOutAt'] as String) : null,
      clockOutPhotoUrl: map['clockOutPhotoUrl'] as String?,
      status: map['status'] as String,
    );
  }
}
