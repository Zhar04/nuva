import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// The answers a guest gave in the entry quiz, plus the server-assigned lead id
/// (if the lead POST succeeded). Persisted across the register hop so we can
/// link the lead to the new account and seed the profile after sign-up.
///
/// Mental-health answers are special-category data (№94-V) — we keep only what
/// the quiz collected, and we drop the pending capture as soon as it's linked.
class PendingLead {
  final int? leadId; // null when the lead POST failed (offline) — link is skipped
  final List<String> topics;
  final String goal;

  const PendingLead({this.leadId, this.topics = const [], this.goal = ''});

  Map<String, dynamic> toJson() =>
      {'lead_id': leadId, 'topics': topics, 'goal': goal};

  factory PendingLead.fromJson(Map<String, dynamic> m) => PendingLead(
        leadId: (m['lead_id'] as num?)?.toInt(),
        topics: ((m['topics'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        goal: (m['goal'] ?? '') as String,
      );

  /// A short human line for the profile bio (RU) — no raw severity/contact.
  String get bioLine {
    final parts = <String>[];
    if (topics.isNotEmpty) parts.add('Запрос: ${topics.join(', ')}');
    if (goal.isNotEmpty) parts.add('Цель: $goal');
    return parts.join(' · ');
  }
}

const _key = 'pending_lead_v1';

/// Stash the quiz result so the register flow can pick it up.
Future<void> savePendingLead(PendingLead lead) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lead.toJson()));
  } catch (_) {
    // non-fatal — the funnel still works, we just won't auto-link.
  }
}

Future<PendingLead?> readPendingLead() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return PendingLead.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

Future<void> clearPendingLead() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  } catch (_) {/* ignore */}
}

/// After a successful registration, claim the anonymous lead for this account
/// (`/leads/{id}/link`). Best-effort: any failure is swallowed so it never
/// blocks the auth flow. Returns the pending lead (for profile seeding) or null.
Future<PendingLead?> linkPendingLead(ApiClient api, String? token) async {
  final lead = await readPendingLead();
  if (lead == null) return null;
  if (lead.leadId != null && token != null) {
    try {
      await api.post('leads/${lead.leadId}/link/', const {}, token: token);
    } on ApiException {
      // 403 (someone else's lead) / 404 — nothing to do, drop it.
    } catch (_) {/* offline — keep the bio seed, skip the link */}
  }
  await clearPendingLead();
  return lead;
}
