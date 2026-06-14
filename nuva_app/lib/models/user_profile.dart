import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only user profile (Phase: prototype). Persisted to shared_preferences.
/// Phase 1: move to Supabase `profiles` (role, full_name, age, gender, mbti, bio,
/// avatar_url) — documented in docs/epics/EPIC_3.md.

enum UserRole { seeker, psychologist }

extension UserRoleX on UserRole {
  String get storage => this == UserRole.psychologist ? 'psychologist' : 'seeker';
  static UserRole parse(String? v) =>
      v == 'psychologist' ? UserRole.psychologist : UserRole.seeker;
}

/// The 16 MBTI types (used for the profile selector + onboarding).
const mbtiTypes = <String>[
  'INTJ', 'INTP', 'ENTJ', 'ENTP',
  'INFJ', 'INFP', 'ENFJ', 'ENFP',
  'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
  'ISTP', 'ISFP', 'ESTP', 'ESFP',
];

const genderOptions = <String>['Женский', 'Мужской', 'Другое', 'Не указывать'];

@immutable
class UserProfile {
  final UserRole role;
  final String name;
  final int? age;
  final String? gender;
  final String? mbti;
  final String bio;
  final bool onboarded;

  const UserProfile({
    this.role = UserRole.seeker,
    this.name = 'Аноним',
    this.age,
    this.gender,
    this.mbti,
    this.bio = '',
    this.onboarded = false,
  });

  String get initials =>
      name.trim().isEmpty ? 'А' : name.trim().characters.first.toUpperCase();

  UserProfile copyWith({
    UserRole? role,
    String? name,
    int? age,
    String? gender,
    String? mbti,
    String? bio,
    bool? onboarded,
  }) =>
      UserProfile(
        role: role ?? this.role,
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        mbti: mbti ?? this.mbti,
        bio: bio ?? this.bio,
        onboarded: onboarded ?? this.onboarded,
      );

  Map<String, dynamic> toJson() => {
        'role': role.storage,
        'name': name,
        'age': age,
        'gender': gender,
        'mbti': mbti,
        'bio': bio,
        'onboarded': onboarded,
      };

  factory UserProfile.fromJson(Map<String, dynamic> m) => UserProfile(
        role: UserRoleX.parse(m['role'] as String?),
        name: (m['name'] ?? 'Аноним') as String,
        age: (m['age'] as num?)?.toInt(),
        gender: m['gender'] as String?,
        mbti: m['mbti'] as String?,
        bio: (m['bio'] ?? '') as String,
        onboarded: (m['onboarded'] as bool?) ?? false,
      );
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(const UserProfile()) {
    _load();
  }

  static const _key = 'user_profile_v1';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        state = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      // keep defaults
    }
  }

  Future<void> save(UserProfile p) async {
    state = p;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(p.toJson()));
    } catch (_) {
      // non-fatal in prototype
    }
  }

  Future<void> update({
    UserRole? role,
    String? name,
    int? age,
    String? gender,
    String? mbti,
    String? bio,
    bool? onboarded,
  }) =>
      save(state.copyWith(
        role: role,
        name: name,
        age: age,
        gender: gender,
        mbti: mbti,
        bio: bio,
        onboarded: onboarded,
      ));
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>(
        (_) => UserProfileNotifier());
