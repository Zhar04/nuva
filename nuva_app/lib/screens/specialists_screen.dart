import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/specialist.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

final _priceFmt =
    NumberFormat.currency(locale: 'ru_KZ', symbol: '₸', decimalDigits: 0);

class SpecialistsScreen extends ConsumerWidget {
  final bool showBack;
  const SpecialistsScreen({super.key, this.showBack = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: t.text, size: 18),
                      ),
                    if (showBack) const SizedBox(width: 4),
                    Text(
                      s.specialists,
                      style: TextStyle(
                        color: t.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ref.watch(specialistsProvider).when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (list) => RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(specialistsProvider);
                          await ref.read(specialistsProvider.future);
                        },
                        color: t.blue,
                        backgroundColor: t.surface,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final sp = list[i];
                            return _SpecialistCard(
                              sp: sp,
                              onTap: () =>
                                  context.push('/specialists/${sp.id}'),
                            );
                          },
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialistCard extends ConsumerWidget {
  final Specialist sp;
  final VoidCallback onTap;
  const _SpecialistCard({required this.sp, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;

    return GlassCard(
      onTap: onTap,
      elevated: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientAvatar(
                initials: sp.initials,
                gradient: sp.avatarGradient,
                size: 56,
                radius: 18,
                fontSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sp.fullName,
                            style: TextStyle(
                              color: t.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.verified_rounded,
                            color: t.blue, size: 14),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(sp.title,
                        style: TextStyle(color: t.textSec, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: t.teal, size: 16),
                      const SizedBox(width: 2),
                      Text('${sp.rating}',
                          style: TextStyle(
                            color: t.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                  Text('${sp.reviewCount}',
                      style: TextStyle(color: t.textTer, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sp.worksWith.map((w) => Tag(label: w)).toList(),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: t.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: t.textTer, size: 14),
              const SizedBox(width: 4),
              Text('${sp.yearsExperience} ${s.yearsExp}',
                  style: TextStyle(color: t.textSec, fontSize: 12)),
              const SizedBox(width: 12),
              Icon(Icons.translate_rounded, color: t.textTer, size: 14),
              const SizedBox(width: 4),
              Text(sp.languages.length.toString(),
                  style: TextStyle(color: t.textSec, fontSize: 12)),
              const Spacer(),
              Text(
                '${s.sessionFrom} ${_priceFmt.format(sp.sessionPriceKzt)}',
                style: TextStyle(
                  color: t.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SpecialistDetailScreen extends ConsumerWidget {
  final String id;
  const SpecialistDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    final detail = ref.watch(specialistDetailProvider(id)).valueOrNull;
    final list =
        ref.watch(specialistsProvider).valueOrNull ?? specialistCatalog;
    final sp = detail ??
        list.firstWhere(
          (e) => e.id == id,
          orElse: () {
            try {
              return specialistCatalog.byId(id);
            } catch (_) {
              return list.isNotEmpty ? list.first : specialistCatalog.first;
            }
          },
        );

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: t.text, size: 18),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.favorite_outline_rounded,
                          color: t.text, size: 20),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.share_outlined,
                          color: t.text, size: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Hero(sp: sp),
                      const SizedBox(height: 18),
                      _StatsRow(sp: sp),
                      const SizedBox(height: 22),
                      SectionLabel(label: s.about),
                      Text(sp.about,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 14,
                            height: 1.5,
                          )),
                      const SizedBox(height: 20),
                      SectionLabel(label: s.works),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sp.worksWith
                            .map((w) => Tag(label: w))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sp.approaches
                            .map((w) => Tag(label: w, color: t.teal))
                            .toList(),
                      ),
                      const SizedBox(height: 22),
                      SectionLabel(label: s.education),
                      ...sp.education.map((e) => _EducationRow(e: e)),
                      const SizedBox(height: 22),
                      SectionLabel(label: s.diplomas),
                      _DiplomasGallery(diplomas: sp.diplomas),
                      const SizedBox(height: 22),
                      _GuaranteeCard(),
                      const SizedBox(height: 22),
                      SectionLabel(
                        label: '${s.reviews} · ${sp.reviewCount}',
                        trailing: TextButton(
                          onPressed: () {},
                          child: Text(s.allReviews,
                              style: TextStyle(
                                color: t.blue,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ),
                      ...sp.reviews.map((r) => _ReviewCard(r: r)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _BookingBar(sp: sp),
    );
  }
}

class _Hero extends StatelessWidget {
  final Specialist sp;
  const _Hero({required this.sp});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Column(
      children: [
        Center(
          child: GradientAvatar(
            initials: sp.initials,
            gradient: sp.avatarGradient,
            size: 104,
            radius: 32,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sp.fullName,
              style: TextStyle(
                color: t.text,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.verified_rounded, color: t.blue, size: 18),
          ],
        ),
        const SizedBox(height: 4),
        Text(sp.title,
            style: TextStyle(color: t.textSec, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 13, color: t.teal),
            const SizedBox(width: 4),
            Text(
              S(AppLang.ru).verified,
              style: TextStyle(
                color: t.teal,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsRow extends ConsumerWidget {
  final Specialist sp;
  const _StatsRow({required this.sp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    Widget cell(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.textSec, fontSize: 11)),
            ],
          ),
        );
    return GlassCard(
      elevated: true,
      radius: 20,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        children: [
          cell('${sp.rating}', '${sp.reviewCount} ${s.reviews.toLowerCase()}'),
          _Divider(),
          cell('${sp.yearsExperience}', s.yearsExp),
          _Divider(),
          cell('${sp.languages.length}',
              s.lang == AppLang.en ? 'languages' : 'языка'),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Container(width: 1, height: 30, color: t.divider);
  }
}

class _EducationRow extends StatelessWidget {
  final Education e;
  const _EducationRow({required this.e});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.school_outlined, color: t.blue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.institution,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(e.degree,
                    style:
                        TextStyle(color: t.textSec, fontSize: 12.5, height: 1.4)),
                const SizedBox(height: 2),
                Text(e.years,
                    style: TextStyle(color: t.textTer, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiplomasGallery extends StatelessWidget {
  final List<String> diplomas;
  const _DiplomasGallery({required this.diplomas});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: diplomas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          return Container(
            width: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  t.blue.withValues(alpha: 0.18),
                  t.teal.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(color: t.divider),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: t.blue, size: 22),
                Text(
                  diplomas[i],
                  style: TextStyle(
                    color: t.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GuaranteeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: t.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 13,
                      height: 1.4,
                    )),
              ),
            ],
          ),
        );
    return GlassCard(
      elevated: true,
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [t.teal, t.blue]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(s.nuvaGuarantee,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          row(Icons.swap_horiz_rounded, s.guarantee1),
          row(Icons.account_balance_wallet_outlined, s.guarantee2),
          row(Icons.lock_outline_rounded, s.guarantee3),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review r;
  const _ReviewCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StarRow(rating: r.rating.toDouble()),
                const Spacer(),
                Text(r.dateLabel,
                    style: TextStyle(color: t.textTer, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(r.text,
                style: TextStyle(color: t.text, fontSize: 13.5, height: 1.45)),
            const SizedBox(height: 8),
            Text(r.authorAlias,
                style: TextStyle(color: t.textTer, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

class _BookingBar extends ConsumerWidget {
  final Specialist sp;
  const _BookingBar({required this.sp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    return Container(
      decoration: BoxDecoration(
        color: t.surface.withValues(alpha: 0.85),
        border: Border(top: BorderSide(color: t.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.sessionFrom,
                  style: TextStyle(color: t.textSec, fontSize: 11)),
              Text(_priceFmt.format(sp.sessionPriceKzt),
                  style: TextStyle(
                    color: t.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  )),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    context.push('/booking/${sp.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(s.bookSession),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
