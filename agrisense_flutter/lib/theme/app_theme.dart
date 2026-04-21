import 'package:flutter/material.dart';

/// Flask design token colours
class AppColors {
  static const Color g50  = Color(0xFFF0FAF0);   // --g50  background
  static const Color g100 = Color(0xFFD6F0D6);
  static const Color g200 = Color(0xFFB0DEB0);
  static const Color g300 = Color(0xFF7EC87E);
  static const Color g400 = Color(0xFF4FAD4F);   // --g400 medium green
  static const Color g500 = Color(0xFF34912F);
  static const Color g600 = Color(0xFF2A7525);   // --g600 dark green
  static const Color g700 = Color(0xFF1E571A);
  static const Color bdr  = Color(0xFFCDE8CD);   // --bdr  border

  static const Color textDark   = Color(0xFF1A2E1A);
  static const Color textMedium = Color(0xFF3D5E3A);
  static const Color textMuted  = Color(0xFF6B8F65);

  static const Color errorRed = Color(0xFFE53E3E);
}

/// Reusable card with gradient header — matches Flask .form-card + .fc-header
class FlaskCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  /// Optional widget shown on the right side of the header (e.g. a fetch button)
  final Widget? action;

  const FlaskCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.bdr),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1234912F),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.g600, AppColors.g400],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section label — matches Flask .fsec-title
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.g500,
        ),
      ),
    );
  }
}

/// Flask-styled input decoration
InputDecoration flaskInput(String label, {String? hint, Widget? prefix}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textMedium,
    ),
    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
    prefixIcon: prefix,
    filled: true,
    fillColor: AppColors.g50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.bdr, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.bdr, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.g400, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
    ),
  );
}

/// Flask-styled submit button
class SubmitButton extends StatelessWidget {
  final bool loading;
  final String label;
  final String loadingLabel;
  final IconData icon;
  final VoidCallback? onPressed;

  const SubmitButton({
    super.key,
    required this.loading,
    required this.label,
    required this.loadingLabel,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [AppColors.g600, AppColors.g400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: loading ? AppColors.g200 : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: loading
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x4D2A7525),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Icon(icon, color: Colors.white, size: 18),
          label: Text(
            loading ? loadingLabel : label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
