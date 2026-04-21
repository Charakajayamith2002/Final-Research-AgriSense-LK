import 'package:flutter/material.dart';

// ── Flask auth colour tokens ──────────────────────────────────
const Color authBg     = Color(0xFF0D1A0A);
const Color authEarth  = Color(0xFF1A1A0E);
const Color authLeaf   = Color(0xFF4A7C35);
const Color authLime   = Color(0xFF7AB648);
const Color authBorder = Color(0xFFE2EADA);
const Color authMuted  = Color(0xFF6B7C5A);
const Color authField  = Color(0xFFF8FAF5);

// ── Hero feature item ─────────────────────────────────────────
class AuthFeature {
  final IconData icon;
  final String title;
  final String sub;
  const AuthFeature(this.icon, this.title, this.sub);
}

// ── Left hero panel ───────────────────────────────────────────
class AuthHeroSection extends StatelessWidget {
  final String headline;
  final List<AuthFeature> features;
  const AuthHeroSection({super.key, required this.headline, required this.features});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: authLime,
                borderRadius: BorderRadius.circular(11),
                boxShadow: const [BoxShadow(color: Color(0x667AB648), blurRadius: 14, offset: Offset(0, 4))],
              ),
              child: const Center(child: Text('🌱', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                children: [
                  TextSpan(text: 'Agri'),
                  TextSpan(text: 'Sense', style: TextStyle(color: authLime, fontStyle: FontStyle.italic)),
                  TextSpan(text: ' LK'),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 22),
          Text(headline,
              style: const TextStyle(
                color: Colors.white, fontSize: 26,
                fontWeight: FontWeight.w900, height: 1.15,
              )),
          const SizedBox(height: 10),
          const Text(
            'Join thousands of Sri Lankan farmers using AI-powered insights to make confident decisions every harvest season.',
            style: TextStyle(
                color: Color(0x70FFFFFF), fontSize: 13,
                fontWeight: FontWeight.w300, height: 1.65),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.5,
            children: features.map((f) => _FeatCard(f)).toList(),
          ),
        ],
      ),
    );
  }
}

class _FeatCard extends StatelessWidget {
  final AuthFeature f;
  const _FeatCard(this.f);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: const Color(0x1F7AB648),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x387AB648)),
          ),
          child: Icon(f.icon, color: authLime, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(f.title,
            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
            maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

// ── White card with Sign In / Register tabs ───────────────────
class AuthCard extends StatelessWidget {
  final int activeTab; // 0 = Sign In, 1 = Register
  final Widget child;
  final VoidCallback onTabSwitch;
  const AuthCard({super.key, required this.activeTab, required this.child, required this.onTabSwitch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 48, offset: Offset(0, 16)),
          ],
        ),
        child: Column(
          children: [
            // Tabs
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4EC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: authBorder)),
              ),
              child: Row(children: [
                _AuthTab(label: 'Sign In',  active: activeTab == 0,
                    onTap: activeTab == 1 ? onTabSwitch : null),
                _AuthTab(label: 'Register', active: activeTab == 1,
                    onTap: activeTab == 0 ? onTabSwitch : null),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _AuthTab({required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: active
                ? const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
                : null,
            border: active
                ? const Border(bottom: BorderSide(color: authLime, width: 2.5))
                : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600,
                  color: active ? authLeaf : authMuted)),
        ),
      ),
    );
  }
}

// ── Card heading ──────────────────────────────────────────────
class AuthCardHeading extends StatelessWidget {
  final String title;
  final String sub;
  const AuthCardHeading({super.key, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
            fontSize: 21, fontWeight: FontWeight.w700, color: authEarth, height: 1.2)),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(sub, style: const TextStyle(fontSize: 12.5, color: authMuted, fontWeight: FontWeight.w300)),
        ],
      ]),
    );
  }
}

// ── Input field ───────────────────────────────────────────────
class AuthField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const AuthField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.onToggleObscure,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: authEarth)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13.5, color: authEarth),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFC2D0B4), fontSize: 13),
            filled: true,
            fillColor: authField,
            prefixIcon: Icon(icon, color: const Color(0xFFBBC9AA), size: 17),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFFBBC9AA), size: 18,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: authBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: authBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: authLime, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Submit button ─────────────────────────────────────────────
class AuthSubmitBtn extends StatelessWidget {
  final bool loading;
  final String label;
  final String loadingLabel;
  final IconData icon;
  final VoidCallback? onPressed;
  const AuthSubmitBtn({super.key, required this.loading, required this.label,
      required this.loadingLabel, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: authLime,
          foregroundColor: authEarth,
          disabledBackgroundColor: authLime.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: loading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(icon, size: 18),
        label: Text(loading ? loadingLabel : label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── OR divider ────────────────────────────────────────────────
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        const Expanded(child: Divider(color: authBorder)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: Color(0xFFC2D0B4), letterSpacing: 1)),
        ),
        const Expanded(child: Divider(color: authBorder)),
      ]),
    );
  }
}

// ── Outline button ────────────────────────────────────────────
class AuthOutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const AuthOutlineBtn({super.key, required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: authEarth,
          side: const BorderSide(color: authBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, size: 17),
        label: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// ── Section label (register) ──────────────────────────────────
class AuthSectionLabel extends StatelessWidget {
  final String text;
  const AuthSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: authMuted)),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: authBorder, height: 1)),
      ]),
    );
  }
}

// ── User type card (register) ─────────────────────────────────
class UserTypeCard extends StatelessWidget {
  final String icon;
  final String title;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  const UserTypeCard({
    super.key,
    required this.icon, required this.title, required this.sub,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0x117AB648) : authField,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? authLime : authBorder, width: 1.5),
          boxShadow: selected
              ? [const BoxShadow(color: Color(0x217AB648), blurRadius: 8, offset: Offset(0, 2))]
              : null,
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: selected ? authLeaf : authEarth)),
          const SizedBox(height: 2),
          Text(sub, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: authMuted, fontWeight: FontWeight.w300),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
