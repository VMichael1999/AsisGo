import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String documentNumber;
  final String assignedBranchId;
  final String shiftStartTime;
  final String shiftEndTime;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.documentNumber,
    required this.assignedBranchId,
    required this.shiftStartTime,
    required this.shiftEndTime,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'documentNumber': documentNumber,
      'assignedBranchId': assignedBranchId,
      'shiftStartTime': shiftStartTime,
      'shiftEndTime': shiftEndTime,
      'avatarUrl': avatarUrl,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      documentNumber: json['documentNumber'] as String,
      assignedBranchId: json['assignedBranchId'] as String,
      shiftStartTime: json['shiftStartTime'] as String,
      shiftEndTime: json['shiftEndTime'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        role,
        documentNumber,
        assignedBranchId,
        shiftStartTime,
        shiftEndTime,
        avatarUrl,
      ];
}
