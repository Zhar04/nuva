import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Progress dots for onboarding steppers.
class StepDots extends StatelessWidget {
  final int count;
  final int active;
  const StepDots({super.key, required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Row(
      children: List.generate(count, (i) {
        final on = i <= active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          width: i == active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: on ? t.blue : t.textTer,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Single-select option list (calm intro questions / pickers).
class SingleSelect extends StatelessWidget {
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  const SingleSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Column(
      children: options.map((o) {
        final sel = o == value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onChanged(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: sel ? t.blue.withValues(alpha: 0.16) : t.glassBgUp,
                border: Border.all(
                  color: sel ? t.blue : t.glassBorder,
                  width: sel ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      o,
                      style: TextStyle(
                        color: t.text,
                        fontSize: 15,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: sel ? t.blue : t.textTer,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Labeled glass text field for onboarding/edit forms.
class OnboardField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  const OnboardField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              color: t.textSec,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: t.text, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.textTer),
            filled: true,
            fillColor: t.glassBgUp,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: t.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: t.blue, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Avatar placeholder with an "add photo" affordance (upload stubbed in prototype).
class AvatarPickerStub extends StatelessWidget {
  final String initials;
  final List<Color> gradient;
  final VoidCallback onTap;
  const AvatarPickerStub({
    super.key,
    required this.initials,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                )),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: t.surface,
                shape: BoxShape.circle,
                border: Border.all(color: t.glassBorder),
              ),
              child: Icon(Icons.add_a_photo_rounded, size: 16, color: t.blue),
            ),
          ),
        ],
      ),
    );
  }
}
