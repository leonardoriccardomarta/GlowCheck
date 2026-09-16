import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/services/glow_auth.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/view/login/login_screen.dart';
import 'package:flutter/material.dart';

Future<bool?> showGlowLoginSheet(BuildContext context, {bool required = false}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    isDismissible: !required,
    enableDrag: !required,
    backgroundColor: Colors.transparent,
    builder: (context) => WillPopScope(
      onWillPop: () async => !required,
      child: GlowLoginSheet(locked: required),
    ),
  );
}

class GlowLoginSheet extends StatefulWidget {
  const GlowLoginSheet({Key? key, this.locked = false}) : super(key: key);

  final bool locked;

  @override
  State<GlowLoginSheet> createState() => _GlowLoginSheetState();
}

class _GlowLoginSheetState extends State<GlowLoginSheet> {
  bool busy = false;
  String? error;

  Future<void> _social(String provider) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await GlowAuth.social(provider);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _email() async {
    final ok = await Navigator.pushNamed(context, LoginScreen.routeName);
    if (!mounted) return;
    if (ok == true) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(22, 12, 22, 20 + bottom),
        decoration: const BoxDecoration(
          color: Color(0xFFF3F1ED),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.locked) ...[
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E2DC),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
            ] else
              const SizedBox(height: 8),
            Text(
              GlowL10n.t(GlowStore.instance.mustClaimPurchase ? 'hook_after_pay' : 'hook_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFF111111),
                  backgroundColor: Color(0xFFE6E2DC),
                ),
              ),
            AbsorbPointer(
              absorbing: busy,
              child: Column(
                children: [
                  _SheetButton(
                    label: GlowL10n.t('login_google'),
                    leading: const GlowGoogleMark(size: 18),
                    onTap: () => _social('google'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _email,
                    child: Text(
                      GlowL10n.t('login_email_instead'),
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFF1744), fontSize: 13, height: 1.35),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
