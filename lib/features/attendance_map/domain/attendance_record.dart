import 'package:equatable/equatable.dart';
import 'shift_phase.dart';

class AttendanceRecord extends Equatable {
  final String id;
  final String userId;
  final AttendanceType type;
  final DateTime timestamp;
  final String branchId;
  final String branchName;
  final String? geozoneId;
  final String? geozoneName;
  final double latitude;
  final double longitude;
  final double distanceToGeozone;
  final bool isInsideGeozone;
  final bool isMockedLocation;
  final String? note;
  final String? selfiePath;
  final bool isSynced;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.branchId,
    required this.branchName,
    this.geozoneId,
    this.geozoneName,
    required this.latitude,
    required this.longitude,
    required this.distanceToGeozone,
    required this.isInsideGeozone,
    this.isMockedLocation = false,
    this.note,
    this.selfiePath,
    this.isSynced = true,
  });

  AttendanceRecord copyWith({
    String? id,
    String? userId,
    AttendanceType? type,
    DateTime? timestamp,
    String? branchId,
    String? branchName,
    String? geozoneId,
    String? geozoneName,
    double? latitude,
    double? longitude,
    double? distanceToGeozone,
    bool? isInsideGeozone,
    bool? isMockedLocation,
    String? note,
    String? selfiePath,
    bool? isSynced,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      geozoneId: geozoneId ?? this.geozoneId,
      geozoneName: geozoneName ?? this.geozoneName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceToGeozone: distanceToGeozone ?? this.distanceToGeozone,
      isInsideGeozone: isInsideGeozone ?? this.isInsideGeozone,
      isMockedLocation: isMockedLocation ?? this.isMockedLocation,
      note: note ?? this.note,
      selfiePath: selfiePath ?? this.selfiePath,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'branchId': branchId,
      'branchName': branchName,
      'geozoneId': geozoneId,
      'geozoneName': geozoneName,
      'latitude': latitude,
      'longitude': longitude,
      'distanceToGeozone': distanceToGeozone,
      'isInsideGeozone': isInsideGeozone,
      'isMockedLocation': isMockedLocation,
      'note': note,
      'selfiePath': selfiePath,
      'isSynced': isSynced,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: AttendanceType.values.byName(json['type'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      branchId: json['branchId'] as String,
      branchName: json['branchName'] as String,
      geozoneId: json['geozoneId'] as String?,
      geozoneName: json['geozoneName'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceToGeozone: (json['distanceToGeozone'] as num).toDouble(),
      isInsideGeozone: json['isInsideGeozone'] as bool,
      isMockedLocation: json['isMockedLocation'] as bool? ?? false,
      note: json['note'] as String?,
      selfiePath: json['selfiePath'] as String?,
      isSynced: json['isSynced'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        timestamp,
        branchId,
        branchName,
        geozoneId,
        geozoneName,
        latitude,
        longitude,
        distanceToGeozone,
        isInsideGeozone,
        isMockedLocation,
        note,
        selfiePath,
        isSynced,
      ];
}
