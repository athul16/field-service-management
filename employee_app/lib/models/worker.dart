class Worker {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String role;

  const Worker({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.role,
  });

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      role: map['role'] as String,
    );
  }
}
