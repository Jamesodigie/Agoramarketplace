import 'package:flutter/material.dart';
import '../icons.dart';
import '../nav.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'auth.dart';
import 'intro.dart';
import 'orders.dart';
import 'seller.dart';
import 'seller_onboarding.dart';

class MenuItem extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const MenuItem(this.icon, this.label, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        label: label,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: kShadow1),
          child: Row(children: [Ic(icon, size: 22, color: C.blue), const SizedBox(width: 14), Expanded(child: Text(label, style: ts(15.5, w: w5))), Ic('chev', size: 18, color: C.faint)]),
        ),
      );
}

Widget avatar(double size, {double? radius}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius ?? size / 2),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFB38A), Color(0xFFE5533C)]),
      ),
      child: Center(child: Text(initials(app.userName), style: ts(size * 0.33, w: w7, c: Colors.white))),
    );

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) => AppPage(title: 'Profile', children: [
          Column(children: [
            avatar(96, radius: 28).popIn(),
            const SizedBox(height: 12),
            Text(app.userName, style: ts(17, w: w6)),
            Text(app.userEmail, style: ts(14, c: C.muted)),
          ]),
          const SizedBox(height: 24),
          ...stagger([
            MenuItem('pkg', 'Orders', onTap: () => go(const OrdersScreen())),
            MenuItem('pin', 'Delivery address', onTap: () => go(const AddressesScreen())),
            MenuItem('shield', 'How escrow works', onTap: () => go(const EscrowScreen())),
            MenuItem('gear', 'Settings', onTap: () => go(const SettingsScreen())),
          ]).expand((w) => [w, const SizedBox(height: 12)]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(color: C.blue50, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.verify == 'none' ? 'Sell on Agora' : 'Selling on Agora', style: ts(16, w: w6)),
              const SizedBox(height: 6),
              Text(
                app.verify == 'none'
                    ? 'Open a verified store. Buyers pay into escrow, so they trust you from the first order.'
                    : app.verify == 'done'
                        ? 'Your store is verified. Switch to seller view to manage orders and payouts.'
                        : 'Your store is being verified. You can add products while you wait.',
                style: ts(14, c: C.muted, h: 1.45),
              ),
              const SizedBox(height: 14),
              Btn(
                app.verify == 'none' ? 'Start selling' : (app.verify == 'done' ? 'Open seller dashboard' : 'Check verification'),
                icon: 'store',
                small: true,
                expand: false,
                onTap: () {
                  app.role = 'seller';
                  if (app.verify == 'none') {
                    go(const SellerStep1());
                  } else if (app.verify == 'done') {
                    goReset(const SellerDashboard());
                  } else {
                    go(const VerifyCheckScreen());
                  }
                },
              ),
            ]),
          ).rise(300),
        ]),
      );
}

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  void _add() {
    final label = TextEditingController(text: 'Office'), line = TextEditingController();
    showSheet(context,
        title: 'Add new address',
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Field(label: 'Label', ctrl: label),
          const SizedBox(height: 16),
          Field(label: 'Address', ctrl: line, hint: 'Street, area'),
          const SizedBox(height: 20),
          Btn('Save address', onTap: () {
            if (line.text.trim().isEmpty) return toast('Enter an address first', icon: 'err');
            setState(() => app.addresses.add(Address(label.text.trim().isEmpty ? 'Other' : label.text.trim(), line.text.trim(), 'Lagos', false)));
            Navigator.of(context).pop();
            toast('Address saved');
          }),
        ]));
  }

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Delivery address',
        bottom: Btn('Add new address', icon: 'plus', kind: BtnKind.outline, onTap: _add),
        children: [
          Text('Manage your saved addresses for faster checkout.', style: ts(14.5, c: C.muted, h: 1.5)),
          const SizedBox(height: 20),
          for (var i = 0; i < app.addresses.length; i++) ...[
            CardBox(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: C.blue50, borderRadius: BorderRadius.circular(12)), child: Center(child: Ic(app.addresses[i].label == 'Home' ? 'home' : 'store', size: 24, color: C.blue))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Text(app.addresses[i].label, style: ts(15, w: w6)), if (app.addresses[i].def) ...[const SizedBox(width: 8), Pill.green('Default')]]),
                    const SizedBox(height: 4),
                    Text('${app.addresses[i].line}\n${app.addresses[i].line2}', style: ts(14, c: C.muted, h: 1.5)),
                    if (!app.addresses[i].def)
                      TextBtn('Set as default', size: 13.5, onTap: () {
                        setState(() {
                          for (final a in app.addresses) {
                            a.def = false;
                          }
                          app.addresses[i].def = true;
                        });
                        toast('Default address updated');
                      }),
                  ]),
                ),
                IconBtn('edit', label: 'Edit', color: C.muted, onTap: () => toast('Address editing opens here in the full app', icon: 'info')),
              ]),
            ).rise(i * 60),
            const SizedBox(height: 14),
          ],
        ],
      );
}

class EscrowScreen extends StatelessWidget {
  const EscrowScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Pay securely', 'Your funds are held safely by Agora.'),
      ('Seller ships your order', 'Track delivery updates in real time.'),
      ('Confirm your item', 'Inspect your purchase on arrival.'),
      ('Funds are released', 'The seller gets paid after you confirm.'),
    ];
    return AppPage(title: 'How escrow works', children: [
      Column(children: [
        Ic('shield', size: 50, color: C.green).popIn(),
        const SizedBox(height: 12),
        Text('Your purchase is protected', style: ts(20, w: w7)).fadeUp(60),
        const SizedBox(height: 8),
        Text("Agora's escrow keeps your money safe until you receive and confirm your item.", textAlign: TextAlign.center, style: ts(14.5, c: C.muted, h: 1.5)).fadeUp(100),
      ]),
      const SizedBox(height: 28),
      for (var i = 0; i < steps.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 24,
              child: Column(children: [
                Container(width: 24, height: 24, decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle), child: Center(child: Text('${i + 1}', style: ts(13, w: w7, c: Colors.white)))),
                if (i < steps.length - 1) Expanded(child: Container(width: 2, color: C.green)),
              ]),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 26),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(steps[i].$1, style: ts(15, w: w6)), Text(steps[i].$2, style: ts(14, c: C.muted))]),
              ),
            ),
          ]),
        ).rise(150 + i * 80),
      const SizedBox(height: 6),
      const NoteBox(kind: 'blue', icon: 'info', title: 'Having any issues?', body: 'Contact support before confirming delivery.'),
      const SizedBox(height: 16),
      Btn('Contact support', onTap: () => showSheet(context,
          title: 'Contact support',
          body: 'Agora support replies within 15 minutes, 7am to 10pm daily.',
          child: Column(mainAxisSize: MainAxisSize.min, children: [const CopyRow('Email', 'help@agora.ng', copy: 'help@agora.ng'), const SizedBox(height: 16), Btn('Done', onTap: () => Navigator.of(context).pop())]))),
    ]);
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    void soon() => toast('This section opens here in the full app', icon: 'info');
    return AppPage(title: 'Settings', children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        avatar(52, radius: 14),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(app.userName, style: ts(15, w: w6)), Text(app.userEmail, style: ts(14, c: C.muted))]),
      ]),
      const SizedBox(height: 26),
      ...stagger([
        MenuItem('user', 'Personal information', onTap: () => go(const PersonalScreen())),
        MenuItem('lock', 'Password & security', onTap: () => go(const SecurityScreen())),
        MenuItem('bell', 'Notifications', onTap: soon),
        MenuItem('card', 'Payment methods', onTap: soon),
        MenuItem('privacy', 'Privacy', onTap: soon),
      ]).expand((w) => [w, const SizedBox(height: 12)]),
      const SizedBox(height: 10),
      ...stagger([
        MenuItem('help', 'Help & support', onTap: () => go(const EscrowScreen())),
        MenuItem('doc', 'Terms & conditions', onTap: soon),
      ], start: 320).expand((w) => [w, const SizedBox(height: 12)]),
      const SizedBox(height: 14),
      Btn('Log out', icon: 'logout', kind: BtnKind.danger, onTap: () {
        app
          ..order = null
          ..rolePicked = false;
        app.cart.clear();
        goReset(const RoleScreen());
      }),
    ]);
  }
}

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});
  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  final name = TextEditingController(text: app.userName), email = TextEditingController(text: app.userEmail), phone = TextEditingController(text: '07056423703'), loc = TextEditingController(text: 'Lagos, Nigeria');
  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Personal information',
        bottom: Btn('Save changes', onTap: () {
          app.userName = name.text.trim();
          app.userEmail = email.text.trim();
          app.touch();
          back();
          toast('Changes saved');
        }),
        children: [
          Center(
            child: Stack(clipBehavior: Clip.none, children: [
              avatar(76),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: C.blue, shape: BoxShape.circle, border: Border.all(color: C.bg, width: 3)),
                  child: Center(child: Ic('camera', size: 14, color: Colors.white)),
                ),
              ),
            ]),
          ).popIn(),
          const SizedBox(height: 24),
          ...stagger([
            Field(label: 'Full name', ctrl: name),
            Field(label: 'Email address', ctrl: email, keyboard: TextInputType.emailAddress),
            Field(label: 'Phone number', ctrl: phone, keyboard: TextInputType.phone),
            Field(label: 'Location', ctrl: loc),
          ]).expand((w) => [w, const SizedBox(height: 18)]),
        ],
      );
}

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  @override
  Widget build(BuildContext context) => AppPage(title: 'Password & security', children: [
        Pressable(
          onTap: () => go(const NewPasswordScreen(change: true)),
          child: CardBox(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Ic('lock', size: 22, color: C.blue),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Change your password', style: ts(15, w: w6)), Text('Update your password regularly to keep your account secure.', style: ts(13.5, c: C.muted, h: 1.45))])),
              Ic('chev', size: 18, color: C.faint),
            ]),
          ),
        ).rise(),
        const SizedBox(height: 14),
        CardBox(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Ic('shield', size: 22, color: C.blue),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Two-factor authentication', style: ts(15, w: w6)), Text('Ask for a code from your phone each time you sign in on a new device.', style: ts(13.5, c: C.muted, h: 1.45))])),
            Switch.adaptive(
              value: app.twofa,
              activeTrackColor: C.green,
              onChanged: (v) {
                setState(() => app.twofa = v);
                toast(v ? 'Two-factor authentication on' : 'Two-factor authentication off', icon: v ? 'shield' : 'info');
              },
            ),
          ]),
        ).rise(60),
      ]);
}
