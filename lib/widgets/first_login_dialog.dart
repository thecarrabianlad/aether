import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Dialog shown to new users to collect their display name.
/// Returns the entered name, or null if cancelled.
Future<String?> showFirstLoginDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _FirstLoginDialog(),
  );
}

class _FirstLoginDialog extends StatefulWidget {
  const _FirstLoginDialog();

  @override
  State<_FirstLoginDialog> createState() => _FirstLoginDialogState();
}

class _FirstLoginDialogState extends State<_FirstLoginDialog> {
  final _controller = TextEditingController();
  final bool _isLoading = false;

  AetherTheme get _aether => context.aether;
  Color get _bgColor => _aether.surface;
  Color get _textColor => _aether.text;
  Color get _mutedColor => _aether.textMuted;
  Color get _accentColor => _aether.accent;
  Color get _inputBgColor => _aether.surfaceAlt;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a username'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.of(context).pop(name);
  }

  void _skip() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Welcome to Aether!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'What should we call you?',
              style: TextStyle(
                fontSize: 14,
                color: _mutedColor,
              ),
            ),
            const SizedBox(height: 24),

            // Input field
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: _textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(color: _mutedColor),
                filled: true,
                fillColor: _inputBgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Skip button
                TextButton(
                  onPressed: _isLoading ? null : _skip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: _mutedColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Spacer(),
                // Continue button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: _textColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _textColor,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
