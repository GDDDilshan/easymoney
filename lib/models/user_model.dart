import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String currencyPreference;
  final bool notificationsEnabled;
  final bool emailAlerts;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.currencyPreference = 'USD',
    this.notificationsEnabled = true,
    this.emailAlerts = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'currencyPreference': currencyPreference,
      'notificationsEnabled': notificationsEnabled,
      'emailAlerts': emailAlerts,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      currencyPreference: map['currencyPreference'] ?? 'USD',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      emailAlerts: map['emailAlerts'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? displayName,
    String? currencyPreference,
    bool? notificationsEnabled,
    bool? emailAlerts,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      currencyPreference: currencyPreference ?? this.currencyPreference,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailAlerts: emailAlerts ?? this.emailAlerts,
      createdAt: createdAt,
    );
  }
}
