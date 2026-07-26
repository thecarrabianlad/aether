import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Horizontal row of accent color swatches with the active one ringed
/// and glowing, matching the app's accent-glow language.
class AccentPicker extends StatelessWidget {
  final AccentPreset selected;
  final ValueChanged<AccentPreset> onSelected;

  const AccentPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final preset in AccentPreset.values)
            _AccentSwatch(
              preset: preset,
              isSelected: preset == selected,
              mutedColor: aether.textMuted,
              onTap: () => onSelected(preset),
            ),
        ],
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final AccentPreset preset;
  final bool isSelected;
  final Color mutedColor;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.preset,
    required this.isSelected,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${preset.label} accent${isSelected ? ', selected' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: preset.color,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: preset.color.withValues(alpha: 0.6),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              preset.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? preset.color : mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-option segmented control for the background variant.
class BackgroundVariantPicker extends StatelessWidget {
  final BackgroundVariant selected;
  final ValueChanged<BackgroundVariant> onSelected;

  const BackgroundVariantPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: aether.surfaceAlt.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (final variant in BackgroundVariant.values)
              Expanded(
                child: _VariantSegment(
                  variant: variant,
                  isSelected: variant == selected,
                  onTap: () => onSelected(variant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VariantSegment extends StatelessWidget {
  final BackgroundVariant variant;
  final bool isSelected;
  final VoidCallback onTap;

  const _VariantSegment({
    required this.variant,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${variant.label} background${isSelected ? ', selected' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? aether.accent.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? aether.accent.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            variant.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? aether.accent : aether.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
