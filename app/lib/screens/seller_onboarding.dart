import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data.dart';
import '../icons.dart';
import '../links.dart';
import '../nav.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'seller.dart';

SellerDraft get sel => app.sel;

/// Shared frame for the six steps: progress bar, title, staggered fields, error, continue.
class StepShell extends StatelessWidget {
  final int n;
  final String title, sub;
  final List<Widget> fields;
  final String cta;
  final String? error;
  final VoidCallback onNext;
  const StepShell({super.key, required this.n, required this.title, required this.sub, required this.fields, required this.onNext, this.error, this.cta = 'Continue'});
  @override
  Widget build(BuildContext context) => AppPage(
        topbar: false,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Row(children: [
            IconBtn('back', label: 'Back', onTap: () => Navigator.of(context).maybePop()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(children: [
                  Text('Step $n of 6', style: ts(12.5, w: w6, c: C.blue)),
                  const SizedBox(height: 7),
                  Row(children: [
                    for (var i = 1; i <= 6; i++) ...[
                      if (i > 1) const SizedBox(width: 5),
                      Expanded(
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(color: i < n ? C.blue : const Color(0xFFDFE6F2), borderRadius: BorderRadius.circular(9)),
                          child: i == n
                              ? Container(decoration: BoxDecoration(color: C.blue, borderRadius: BorderRadius.circular(9)))
                                  .animate(delay: 150.ms)
                                  .scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft, duration: 700.ms, curve: kEase)
                              : null,
                        ),
                      ),
                    ],
                  ]),
                ]),
              ),
            ),
            const SizedBox(width: 44),
          ]),
        ),
        bottom: Btn(cta, trail: 'arrow', onTap: onNext),
        children: [
          const SizedBox(height: 10),
          Text(title, style: ts(25, w: w7, ls: -0.4)).fadeUp(),
          const SizedBox(height: 6),
          Text(sub, style: ts(14.5, c: C.muted, h: 1.5)).fadeUp(40),
          const SizedBox(height: 22),
          ...stagger(fields, start: 60, step: 45).expand((w) => [w, const SizedBox(height: 18)]),
          ErrText(error),
        ],
      );
}

/// Finish a step: return to review if editing from there, otherwise move on.
void stepDone(BuildContext context, bool fromReview, Widget next) {
  if (fromReview) {
    Navigator.of(context).pop();
  } else {
    go(next);
  }
}

class _Hint extends StatelessWidget {
  final String t;
  const _Hint(this.t);
  @override
  Widget build(BuildContext context) => Text(t, style: ts(12.5, c: C.muted, h: 1.45));
}

/* ---------- Step 1: about you ---------- */

class SellerStep1 extends StatefulWidget {
  final bool fromReview;
  const SellerStep1({super.key, this.fromReview = false});
  @override
  State<SellerStep1> createState() => _SellerStep1State();
}

class _SellerStep1State extends State<SellerStep1> {
  late final name = TextEditingController(text: sel.name), phone = TextEditingController(text: sel.phone), email = TextEditingController(text: sel.email), pw = TextEditingController(text: sel.pw);
  String? err;
  int _score() {
    final v = pw.text;
    if (v.isEmpty) return 0;
    var s = 0;
    if (v.length >= 8) s++;
    if (RegExp(r'[a-z]').hasMatch(v) && RegExp(r'[A-Z]').hasMatch(v)) s++;
    if (RegExp(r'\d').hasMatch(v)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(v) || v.length >= 12) s++;
    return s < 1 ? 1 : s;
  }

  void _next() {
    sel
      ..name = name.text.trim()
      ..phone = phone.text.trim()
      ..email = email.text.trim()
      ..pw = pw.text;
    String? e;
    if (sel.name.split(RegExp(r'\s+')).length < 2) {
      e = 'Enter your first and last name as they appear on your ID.';
    } else if (sel.phone.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0'), '').length != 10) {
      e = 'Enter a valid Nigerian phone number.';
    } else if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(sel.email)) {
      e = 'Enter a valid email address.';
    } else if (sel.pw.length < 8) {
      e = 'Use at least 8 characters for your password.';
    } else if (!sel.agree) {
      e = 'Accept the Seller Terms to continue.';
    }
    setState(() => err = e);
    if (e != null) return;
    app
      ..userName = sel.name
      ..userEmail = sel.email
      ..role = 'seller';
    stepDone(context, widget.fromReview, const SellerStep2());
  }

  @override
  Widget build(BuildContext context) {
    final sc = _score();
    const cols = [C.red, C.amber, Color(0xFF84CC16), C.green];
    return StepShell(
      n: 1,
      title: 'Tell us about yourself',
      sub: 'Use the name on your ID. Buyers see your store, never your personal details.',
      error: err,
      onNext: _next,
      fields: [
        Field(label: 'Full name', ctrl: name, hint: 'As it appears on your ID', autofill: const [AutofillHints.name], caps: TextCapitalization.words),
        Field(label: 'Phone number', ctrl: phone, prefix: '+234', hint: '801 234 5678', keyboard: TextInputType.phone, autofill: const [AutofillHints.telephoneNumberNational]),
        Field(label: 'Email address', ctrl: email, keyboard: TextInputType.emailAddress, autofill: const [AutofillHints.email]),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Field(label: 'Create a password', ctrl: pw, password: true, hint: 'At least 8 characters', onChanged: (_) => setState(() {}), autofill: const [AutofillHints.newPassword]),
          const SizedBox(height: 8),
          Row(children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 300), height: 4, decoration: BoxDecoration(color: i < sc ? cols[sc - 1] : const Color(0xFFE3E8F0), borderRadius: BorderRadius.circular(9)))),
            ],
          ]),
        ]),
        CheckRow(
          on: sel.agree,
          onChanged: (v) => setState(() => sel.agree = v),
          text: Text.rich(TextSpan(children: [
            const TextSpan(text: "I agree to Agora's "),
            TextSpan(text: 'Seller Terms', style: ts(13.5, w: w6, c: C.blue)),
            const TextSpan(text: ' and '),
            TextSpan(text: 'Privacy Policy', style: ts(13.5, w: w6, c: C.blue)),
            const TextSpan(text: '.'),
          ])),
        ),
      ],
    );
  }
}

/* ---------- Step 2: store ---------- */

class SellerStep2 extends StatefulWidget {
  final bool fromReview;
  const SellerStep2({super.key, this.fromReview = false});
  @override
  State<SellerStep2> createState() => _SellerStep2State();
}

class _SellerStep2State extends State<SellerStep2> {
  late final store = TextEditingController(text: sel.store), desc = TextEditingController(text: sel.desc), handle = TextEditingController(text: sel.handle);
  late bool handleEdited = sel.handleEdited;
  String? err;
  static const cats = ['Electronics', 'Phones', 'Fashion', 'Bags', 'Beauty', 'Home', 'Food', 'Kids', 'Other'];

  void _next() {
    sel
      ..store = store.text.trim()
      ..desc = desc.text.trim()
      ..handle = handle.text
      ..handleEdited = handleEdited;
    String? e;
    final hp = handleProblem(sel.handle);
    if (sel.store.length < 3) {
      e = 'Give your store a name of at least 3 characters.';
    } else if (hp != null) {
      e = 'Store link: $hp.';
    } else if (sel.cats.isEmpty) {
      e = 'Pick at least one thing you sell.';
    } else if (sel.desc.length < 20) {
      e = 'Add a short description of at least 20 characters.';
    }
    setState(() => err = e);
    if (e == null) stepDone(context, widget.fromReview, const SellerStep3());
  }

  @override
  Widget build(BuildContext context) => StepShell(
        n: 2,
        title: 'Set up your store',
        sub: 'This is the first thing buyers see. You can change it later.',
        error: err,
        onNext: _next,
        fields: [
          Center(
            child: Pressable(
              label: 'Add store logo',
              onTap: () async {
                final u = await pickPhoto(context);
                if (u != null) setState(() => sel.logo = u);
              },
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2F7BFF), Color(0xFF0047C2)]),
                    boxShadow: const [BoxShadow(color: Color(0x400060FD), blurRadius: 24, offset: Offset(0, 10))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: sel.logo != null ? UploadThumb(sel.logo!) : Center(child: Text(initials(store.text.isEmpty ? 'A' : store.text), style: ts(28, w: w7, c: Colors.white))),
                  ),
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: kShadow2), child: Center(child: Ic('camera', size: 17, color: C.blue))),
                ),
              ]),
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Field(
              label: 'Store name',
              ctrl: store,
              hint: 'e.g. Kuye Gadgets',
              maxLength: 40,
              caps: TextCapitalization.words,
              onChanged: (_) => setState(() {
                if (!handleEdited) handle.text = handleFrom(store.text);
              }),
            ),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Field(
              label: 'Store link',
              ctrl: handle,
              prefix: '$kDomain/',
              hint: 'storebyella',
              maxLength: 30,
              keyboard: TextInputType.url,
              formatters: [HandleFormatter()],
              onChanged: (_) => setState(() => handleEdited = true),
            ),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final p = handleProblem(handle.text);
              final ok = p == null;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Row(key: ValueKey(p), children: [
                  Ic(ok ? 'check' : 'info', size: 15, color: ok ? C.greenInk : C.red),
                  const SizedBox(width: 5),
                  Expanded(child: Text(ok ? 'Available. Share it on WhatsApp, Instagram, X and more.' : p, style: ts(13, w: w5, c: ok ? C.greenInk : C.red))),
                ]),
              );
            }),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('What do you sell?', style: ts(15, w: w5)),
            const SizedBox(height: 10),
            ChipsSel(options: cats, isOn: sel.cats.contains, onTap: (c) => setState(() {
                if (sel.cats.contains(c)) {
                  sel.cats.remove(c);
                } else {
                  sel.cats.add(c);
                }
              })),
          ]),
          Field(
            label: 'Describe your store',
            ctrl: desc,
            lines: 4,
            maxLength: 160,
            hint: 'What you sell, and why buyers can rely on you',
            onChanged: (_) => setState(() {}),
            labelTrail: Text('${desc.text.length}/160', style: ts(12.5, c: C.muted)),
          ),
        ],
      );
}

/* ---------- Step 3: business ---------- */

class SellerStep3 extends StatefulWidget {
  final bool fromReview;
  const SellerStep3({super.key, this.fromReview = false});
  @override
  State<SellerStep3> createState() => _SellerStep3State();
}

class _SellerStep3State extends State<SellerStep3> {
  late final biz = TextEditingController(text: sel.bizname), cac = TextEditingController(text: sel.cac), ig = TextEditingController(text: sel.ig), web = TextEditingController(text: sel.web);
  String? err;

  void _save() {
    sel
      ..bizname = biz.text.trim()
      ..cac = cac.text.trim().toUpperCase()
      ..ig = ig.text.trim().replaceAll('@', '')
      ..web = web.text.trim();
  }

  void _next() {
    _save();
    String? e;
    if (sel.registered) {
      if (sel.bizname.isEmpty) {
        e = 'Enter your business name as registered with CAC.';
      } else if (!RegExp(r'^(RC|BN|IT)\s?\d{5,8}$').hasMatch(sel.cac)) {
        e = 'CAC numbers look like RC 1234567 or BN 1234567.';
      } else if (sel.cacDoc == null) {
        e = 'Upload your CAC certificate.';
      }
    }
    if (e == null && sel.years.isEmpty) e = 'Tell buyers how long you have been selling.';
    setState(() => err = e);
    if (e == null) stepDone(context, widget.fromReview, const SellerStep4());
  }

  @override
  Widget build(BuildContext context) => StepShell(
        n: 3,
        title: 'Business details',
        sub: 'Registered businesses get a CAC badge on their store. Individuals can sell too.',
        error: err,
        onNext: _next,
        fields: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('How do you sell?', style: ts(15, w: w5)),
            const SizedBox(height: 10),
            Segmented(
              labels: const ['Individual', 'Registered business'],
              index: sel.registered ? 1 : 0,
              onChanged: (i) => setState(() {
                _save();
                sel.btype = i == 1 ? 'registered' : 'individual';
              }),
            ),
          ]),
          AnimatedSize(
            duration: const Duration(milliseconds: 380),
            curve: kEase,
            alignment: Alignment.topCenter,
            child: sel.registered
                ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Field(label: 'Business name', ctrl: biz, hint: 'As registered with CAC', caps: TextCapitalization.words),
                    const SizedBox(height: 18),
                    Field(label: 'CAC registration number', ctrl: cac, hint: 'RC 1234567 or BN 1234567', caps: TextCapitalization.characters),
                    const SizedBox(height: 18),
                    UploadTile(value: sel.cacDoc, title: 'CAC certificate', sub: 'A clear photo of your certificate', onPicked: (u) => setState(() => sel.cacDoc = u)),
                    const SizedBox(height: 10),
                    DemoBtn('use a sample certificate', onTap: () {
                      setState(() => sel.cacDoc = const Upload.sample('cac'));
                      toast('Sample added');
                    }),
                  ])
                : const NoteBox(kind: 'blue', icon: 'info', title: 'Selling as an individual', body: 'You can start once your ID and address are verified. Register with CAC later to add the badge.'),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('How long have you been selling?', style: ts(15, w: w5)),
            const SizedBox(height: 10),
            ChipsSel(options: const ['Just starting', 'Under 1 year', '1–3 years', '3+ years'], isOn: (c) => sel.years == c, onTap: (c) => setState(() => sel.years = c)),
          ]),
          Field(label: 'Instagram', optional: true, ctrl: ig, prefix: '@', hint: 'yourstore'),
          Field(label: 'Website or TikTok', optional: true, ctrl: web, hint: 'https://', keyboard: TextInputType.url),
          const _Hint('Links to where buyers already know you make your store page more convincing.'),
        ],
      );
}

/* ---------- Step 4: address ---------- */

const _mapSvg = r'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 160" preserveAspectRatio="xMidYMid slice"><rect width="360" height="160" fill="#E6EDF7"/><g fill="#D5DFED"><rect x="18" y="12" width="74" height="42" rx="7"/><rect x="108" y="8" width="54" height="34" rx="7"/><rect x="248" y="16" width="86" height="46" rx="7"/><rect x="26" y="86" width="64" height="52" rx="7"/><rect x="204" y="92" width="52" height="42" rx="7"/><rect x="278" y="98" width="64" height="40" rx="7"/></g><path d="M0 70C80 62 140 78 200 74S300 58 360 66" stroke="#fff" stroke-width="13" fill="none"/><path d="M178 0C172 52 188 106 176 160" stroke="#fff" stroke-width="10" fill="none"/><path d="M0 128L360 114" stroke="#fff" stroke-width="6" fill="none"/><circle cx="302" cy="40" r="14" fill="#CDEBD7"/><circle cx="60" cy="40" r="9" fill="#CDEBD7"/></svg>''';
const _pinSvg = r'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 22s7-6.6 7-12a7 7 0 0 0-14 0c0 5.4 7 12 7 12z" fill="#005AE6"/><circle cx="12" cy="10" r="2.6" fill="#fff"/></svg>''';

class SellerStep4 extends StatefulWidget {
  final bool fromReview;
  const SellerStep4({super.key, this.fromReview = false});
  @override
  State<SellerStep4> createState() => _SellerStep4State();
}

class _SellerStep4State extends State<SellerStep4> {
  late final street = TextEditingController(text: sel.street), area = TextEditingController(text: sel.area), city = TextEditingController(text: sel.city), land = TextEditingController(text: sel.landmark);
  String? err;
  void _save() {
    sel
      ..street = street.text.trim()
      ..area = area.text.trim()
      ..city = city.text.trim()
      ..landmark = land.text.trim();
  }

  void _next() {
    _save();
    String? e;
    if (sel.street.isEmpty || sel.area.isEmpty || sel.city.isEmpty) {
      e = 'Add your address, area and city.';
    } else if (sel.poa == null) {
      e = 'Upload a proof of address.';
    }
    setState(() => err = e);
    if (e == null) stepDone(context, widget.fromReview, const SellerStep5());
  }

  @override
  Widget build(BuildContext context) {
    final physical = sel.shop == 'physical';
    final label = '${area.text.trim().isEmpty ? 'Your area' : area.text.trim()}, ${city.text.trim().isEmpty ? 'your city' : city.text.trim()}';
    return StepShell(
      n: 4,
      title: 'Where are you based?',
      sub: 'Buyers see your area, never your full address.',
      error: err,
      onNext: _next,
      fields: [
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Where do you sell from?', style: ts(15, w: w5)),
          const SizedBox(height: 10),
          Segmented(labels: const ['Physical shop', 'Online or from home'], index: physical ? 0 : 1, onChanged: (i) => setState(() => sel.shop = i == 0 ? 'physical' : 'online')),
        ]),
        Field(label: physical ? 'Shop address' : 'Address', ctrl: street, hint: 'Building number and street', autofill: const [AutofillHints.streetAddressLine1]),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Field(label: 'Area', ctrl: area, hint: 'e.g. Computer Village', onChanged: (_) => setState(() {}))),
          const SizedBox(width: 14),
          Expanded(child: Field(label: 'City', ctrl: city, hint: 'e.g. Ikeja', onChanged: (_) => setState(() {}))),
        ]),
        SelectField(label: 'State', value: sel.state, options: kStates, onChanged: (v) => setState(() => sel.state = v)),
        Field(label: 'Nearest landmark', optional: true, ctrl: land, hint: 'e.g. Opposite Zenith Bank'),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 160,
            child: Stack(children: [
              Positioned.fill(child: SvgPicture.string(_mapSvg, fit: BoxFit.cover)),
              Align(
                alignment: const Alignment(0, -0.18),
                child: Container(width: 16, height: 16, decoration: BoxDecoration(color: C.brand.withValues(alpha: 0.3), shape: BoxShape.circle))
                    .animate(delay: 1.seconds, onPlay: (c) => c.repeat())
                    .scaleXY(begin: 0.5, end: 4, duration: 2.seconds, curve: Curves.easeOut)
                    .fade(begin: 1, end: 0, duration: 2.seconds),
              ),
              Align(
                alignment: const Alignment(0, -0.5),
                child: SizedBox(width: 40, height: 40, child: SvgPicture.string(_pinSvg)).animate(delay: 300.ms).fadeIn(duration: 300.ms).moveY(begin: -50, end: 0, duration: 800.ms, curve: kSpring),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: kShadow1),
                  child: Row(children: [
                    Ic('shield', size: 20, color: C.green),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: ts(14, w: w6), maxLines: 1, overflow: TextOverflow.ellipsis), Text('This is all buyers see', style: ts(12, c: C.muted))])),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          UploadTile(value: sel.poa, title: 'Proof of address', sub: 'Utility bill or tenancy agreement from the last 3 months', onPicked: (u) => setState(() => sel.poa = u)),
          const SizedBox(height: 10),
          DemoBtn('use a sample utility bill', onTap: () {
            setState(() => sel.poa = const Upload.sample('bill'));
            toast('Sample added');
          }),
        ]),
        if (physical) UploadTile(value: sel.shopPhoto, title: 'Shop front photo', optional: true, sub: 'Helps buyers recognise your shop', onPicked: (u) => setState(() => sel.shopPhoto = u)),
      ],
    );
  }
}

/* ---------- Step 5: identity ---------- */

class SellerStep5 extends StatefulWidget {
  final bool fromReview;
  const SellerStep5({super.key, this.fromReview = false});
  @override
  State<SellerStep5> createState() => _SellerStep5State();
}

class _SellerStep5State extends State<SellerStep5> {
  late final idNum = TextEditingController(text: sel.idNum);
  String? err;
  void _next() {
    sel.idNum = idNum.text.replaceAll(' ', '');
    String? e;
    if (sel.idType == 'NIN' ? !RegExp(r'^\d{11}$').hasMatch(sel.idNum) : sel.idNum.length < 6) {
      e = sel.idType == 'NIN' ? 'Your NIN has 11 digits.' : 'Enter the number on your ID.';
    } else if (sel.idDoc == null) {
      e = 'Upload a photo of your ID.';
    } else if (sel.selfie == null) {
      e = 'Take a selfie so we can match it to your ID.';
    }
    setState(() => err = e);
    if (e == null) stepDone(context, widget.fromReview, const SellerStep6());
  }

  @override
  Widget build(BuildContext context) {
    final nin = sel.idType == 'NIN';
    final hasSelfie = sel.selfie != null;
    return StepShell(
      n: 5,
      title: 'Verify your identity',
      sub: 'We match your ID to a selfie. Your documents are never shown to buyers.',
      error: err,
      onNext: _next,
      fields: [
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('ID type', style: ts(15, w: w5)),
          const SizedBox(height: 10),
          ChipsSel(
            options: const ['NIN', 'International passport', "Driver's licence", "Voter's card"],
            isOn: (c) => sel.idType == c,
            onTap: (c) => setState(() {
              sel.idType = c;
              idNum.clear();
            }),
          ),
        ]),
        Field(
          key: ValueKey(sel.idType),
          label: nin ? 'NIN (11 digits)' : 'ID number',
          ctrl: idNum,
          hint: nin ? '00000000000' : 'Number on your ID',
          keyboard: nin ? TextInputType.number : TextInputType.text,
          maxLength: nin ? 11 : 20,
          formatters: nin ? [FilteringTextInputFormatter.digitsOnly] : null,
        ),
        UploadTile(value: sel.idDoc, title: 'Photo of your ID', sub: 'Front side, with all four corners visible', onPicked: (u) => setState(() => sel.idDoc = u)),
        Pressable(
          scale: 0.98,
          onTap: () async {
            final u = await pickPhoto(context, selfie: true);
            if (u != null) setState(() => sel.selfie = u);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasSelfie ? const Color(0xFFF3FBF6) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: hasSelfie ? const Color(0xFFBFE8CF) : C.line, width: 1.5),
            ),
            child: Row(children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: hasSelfie ? C.green : const Color(0xFFB9C6DA), width: hasSelfie ? 3 : 2)),
                child: ClipOval(child: hasSelfie ? UploadThumb(sel.selfie!) : Center(child: Ic('face', size: 36, color: C.blue))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(hasSelfie ? 'Selfie added' : 'Take a selfie', style: ts(15, w: w6)),
                  const SizedBox(height: 2),
                  Text(hasSelfie ? "Looks good. We'll match it to your ID photo." : 'Face the light. No glasses or hat.', style: ts(13, c: C.muted, h: 1.4)),
                ]),
              ),
            ]),
          ),
        ),
        DemoBtn('use a sample ID and selfie', onTap: () {
          setState(() {
            sel
              ..idDoc = const Upload.sample('id')
              ..selfie = const Upload.sample('selfie');
            if (idNum.text.isEmpty && nin) idNum.text = '22183749561';
          });
          toast('Samples added');
        }),
        const NoteBox(kind: 'green', icon: 'lock', title: 'Kept private', body: "Only Agora's verification team can see your documents."),
      ],
    );
  }
}

/* ---------- Step 6: payout ---------- */

class SellerStep6 extends StatefulWidget {
  final bool fromReview;
  const SellerStep6({super.key, this.fromReview = false});
  @override
  State<SellerStep6> createState() => _SellerStep6State();
}

class _SellerStep6State extends State<SellerStep6> {
  late final acct = TextEditingController(text: sel.acct);
  bool checking = false;
  Timer? _t;
  String? err;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _resolve() {
    sel.acct = acct.text;
    _t?.cancel();
    if (acct.text.length == 10) {
      setState(() {
        checking = true;
        sel.acctName = null;
      });
      _t = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          checking = false;
          sel.acctName = sel.name.trim().toUpperCase();
        });
      });
    } else {
      setState(() {
        checking = false;
        sel.acctName = null;
      });
    }
  }

  void _next() {
    sel.acct = acct.text;
    String? e;
    if (!RegExp(r'^\d{10}$').hasMatch(sel.acct)) {
      e = 'Account numbers have 10 digits.';
    } else if (sel.acctName == null) {
      e = 'Wait a moment while we confirm the account name.';
    }
    setState(() => err = e);
    if (e == null) stepDone(context, widget.fromReview, const SellerReviewScreen());
  }

  @override
  Widget build(BuildContext context) => StepShell(
        n: 6,
        title: 'Where should we pay you?',
        sub: 'Payouts land here once buyers confirm delivery.',
        cta: 'Review details',
        error: err,
        onNext: _next,
        fields: [
          SelectField(label: 'Bank', value: sel.bank, options: kBanks, onChanged: (v) {
            setState(() => sel.bank = v);
            if (acct.text.length == 10) _resolve();
          }),
          Field(label: 'Account number', ctrl: acct, hint: '10-digit account number', keyboard: TextInputType.number, maxLength: 10, formatters: [FilteringTextInputFormatter.digitsOnly], onChanged: (_) => _resolve()),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SizeTransition(sizeFactor: CurvedAnimation(parent: a, curve: kEase), axisAlignment: -1, child: c)),
            child: checking
                ? _AcctRow(key: const ValueKey('c'), loading: true, title: 'Checking account…', sub: sel.bank)
                : sel.acctName != null
                    ? _AcctRow(key: const ValueKey('ok'), loading: false, title: sel.acctName!, sub: 'Matches the name on your ID')
                    : const SizedBox(key: ValueKey('none'), width: double.infinity),
          ),
          const NoteBox(kind: 'blue', icon: 'info', title: 'The account name must match your ID', body: 'This stops anyone else from collecting your payouts.'),
          const NoteBox(kind: 'amber', icon: 'shield', title: 'Agora will never ask for your PIN or OTP', body: 'Not by phone, WhatsApp or email.'),
        ],
      );
}

class _AcctRow extends StatelessWidget {
  final bool loading;
  final String title, sub;
  const _AcctRow({super.key, required this.loading, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: loading ? Colors.white : const Color(0xFFF3FBF6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: loading ? C.line : const Color(0xFFBFE8CF)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: loading ? C.blue50 : C.green, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: C.blue, backgroundColor: C.blue100))
                  : Ic('check', size: 20, color: Colors.white).popIn(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: ts(15, w: w6, ls: 0.3)), Text(sub, style: ts(12.5, c: loading ? C.muted : C.greenInk))])),
        ]),
      );
}

/* ---------- Review ---------- */

class SellerReviewScreen extends StatefulWidget {
  const SellerReviewScreen({super.key});
  @override
  State<SellerReviewScreen> createState() => _SellerReviewScreenState();
}

class _SellerReviewScreenState extends State<SellerReviewScreen> {
  bool confirm = false;
  String? err;

  Widget _sec(String title, Widget editPage, List<(String, String)> rows) => CardBox(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(title, style: ts(15.5, w: w6))),
            TextBtn('Edit', onTap: () async {
              await navKey.currentState!.push(softRoute(editPage));
              if (mounted) setState(() {});
            }),
          ]),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.$1, style: ts(13.5, c: C.muted)),
                const SizedBox(width: 16),
                Expanded(child: Text(r.$2, textAlign: TextAlign.right, style: ts(13.5, w: w5))),
              ]),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Review and submit',
        bottom: Btn('Submit for verification', onTap: () {
          if (!confirm) return setState(() => err = 'Tick the box to confirm your details are true.');
          processing(context, 'Submitting your store…', 'Your documents are sent securely', () {
            app
              ..verify = 'pending'
              ..vcSeen = false;
            goReset(const VerifyCheckScreen());
          });
        }),
        children: [
          Text('Check everything once. Wrong details slow down verification.', style: ts(14.5, c: C.muted, h: 1.5)).fadeUp(),
          const SizedBox(height: 18),
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text('HOW BUYERS WILL SEE YOU', style: ts(11.5, w: w6, c: C.muted, ls: 1))),
          StoreHeader(sel.toSeller(), pending: true).rise(40),
          const SizedBox(height: 16),
          ...stagger([
            _sec('Store', const SellerStep2(fromReview: true), [('Name', sel.store), ('Link', storeLink(sel.handle)), ('Sells', sel.cats.join(', '))]),
            _sec('Business', const SellerStep3(fromReview: true), [
              ('Type', sel.registered ? 'Registered business' : 'Individual seller'),
              if (sel.registered) ('CAC number', sel.cac),
              if (sel.registered) ('Certificate', 'Uploaded'),
              ('Selling for', sel.years),
              ('Instagram', sel.ig.isEmpty ? 'Not added' : '@${sel.ig}'),
            ]),
            _sec('Address', const SellerStep4(fromReview: true), [('Shown to buyers', '${sel.area}, ${sel.city}'), ('Full address (private)', '${sel.street}, ${sel.state}'), ('Proof of address', 'Uploaded')]),
            _sec('Identity', const SellerStep5(fromReview: true), [('ID', '${sel.idType} ending ${sel.idNum.length >= 3 ? sel.idNum.substring(sel.idNum.length - 3) : sel.idNum}'), ('ID photo', 'Uploaded'), ('Selfie', 'Added')]),
            _sec('Payout', const SellerStep6(fromReview: true), [('Bank', sel.bank), ('Account', 'Ending ${sel.acct.length >= 4 ? sel.acct.substring(sel.acct.length - 4) : sel.acct}'), ('Account name', sel.acctName ?? '')]),
            CheckRow(
              on: confirm,
              onChanged: (v) => setState(() {
                confirm = v;
                err = null;
              }),
              text: const Text('I confirm these details are true. False details lead to permanent removal from Agora.'),
            ),
          ], start: 120).expand((w) => [w, const SizedBox(height: 14)]),
          ErrText(err),
        ],
      );
}

/* ---------- Verification in progress ---------- */

class VerifyCheckScreen extends StatefulWidget {
  const VerifyCheckScreen({super.key});
  @override
  State<VerifyCheckScreen> createState() => _VerifyCheckScreenState();
}

class _VerifyCheckScreenState extends State<VerifyCheckScreen> {
  late final List<(String, String, String, int, bool)> items; // icon, title, sub, ms, passes automatically
  late final List<String> state; // queued | run | ok | wait
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    final reg = sel.registered;
    items = [
      ('bank', 'Payout account', 'Account name matches your ID', 900, true),
      ('face', 'Selfie match', 'Your selfie matches your ID photo', 1800, true),
      ('id', 'ID document', '${sel.idType} checked', 2700, true),
      (reg ? 'building' : 'insta', reg ? 'CAC registration' : 'Online presence', reg ? 'Checking ${sel.cac} with CAC' : 'Reviewing your social profile', 3400, app.verify == 'done'),
      ('pin', 'Shop address', 'Reviewing your proof of address', 3900, app.verify == 'done'),
    ];
    state = List.filled(items.length, 'queued');
    if (app.vcSeen) {
      for (var i = 0; i < items.length; i++) {
        state[i] = items[i].$5 ? 'ok' : 'wait';
      }
      return;
    }
    app.vcSeen = true;
    for (var i = 0; i < items.length; i++) {
      final d = items[i].$4;
      _timers.add(Timer(Duration(milliseconds: (d - 750).clamp(300, 99999)), () {
        if (mounted && state[i] == 'queued') setState(() => state[i] = 'run');
      }));
      _timers.add(Timer(Duration(milliseconds: d), () {
        if (mounted && state[i] != 'ok') setState(() => state[i] = items[i].$5 ? 'ok' : 'wait');
      }));
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _approve() {
    app.verify = 'done';
    final pending = [for (var i = 0; i < state.length; i++) if (state[i] != 'ok') i];
    for (var k = 0; k < pending.length; k++) {
      _timers.add(Timer(Duration(milliseconds: 250 + k * 380), () {
        if (mounted) setState(() => state[pending[k]] = 'ok');
      }));
    }
    _timers.add(Timer(Duration(milliseconds: 900 + pending.length * 380), () {
      if (mounted) goReset(const VerifyDoneScreen());
    }));
  }

  @override
  Widget build(BuildContext context) {
    final done = state.where((s) => s == 'ok').length;
    final all = done == items.length;
    return AppPage(
      topbar: false,
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        Btn('Add products while you wait', icon: 'plus', onTap: () => go(const AddProductScreen())),
        const SizedBox(height: 10),
        DemoBtn('finish verification now', onTap: _approve),
      ]),
      children: [
        const SizedBox(height: 18),
        Center(
          child: SizedBox(
            width: 92,
            height: 92,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: done / items.length),
              duration: const Duration(milliseconds: 700),
              curve: kEase,
              builder: (_, v, __) => Stack(alignment: Alignment.center, children: [
                SizedBox.expand(child: CircularProgressIndicator(value: 1, strokeWidth: 8, color: const Color(0xFFE3EAF5), strokeCap: StrokeCap.round)),
                SizedBox.expand(child: CircularProgressIndicator(value: v, strokeWidth: 8, color: all ? C.green : C.blue, strokeCap: StrokeCap.round)),
                Text('$done/${items.length}', style: ts(18, w: w7)),
              ]),
            ),
          ).popIn(),
        ),
        const SizedBox(height: 14),
        Text("We're checking your store", textAlign: TextAlign.center, style: ts(23, w: w7)).fadeUp(80),
        const SizedBox(height: 8),
        Text("Most stores are approved within 24 hours. We'll text you on +234 ${sel.phone} and email you when it's done.", textAlign: TextAlign.center, style: ts(14, c: C.muted, h: 1.5)).fadeUp(120),
        const SizedBox(height: 22),
        CardBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          radius: 24,
          child: Column(children: [
            for (var i = 0; i < items.length; i++)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: state[i] == 'queued' ? 0.55 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(border: i == items.length - 1 ? null : const Border(bottom: BorderSide(color: Color(0xFFEEF1F6)))),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: state[i] == 'ok' ? C.green50 : (state[i] == 'queued' ? const Color(0xFFF1F4F9) : C.blue50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Ic(items[i].$1, size: 20, color: state[i] == 'ok' ? C.green : (state[i] == 'queued' ? C.muted : C.blue))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(items[i].$2, style: ts(14.5, w: w6)), Text(items[i].$3, style: ts(12.5, c: C.muted))])),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: kSpring), child: c),
                      child: switch (state[i]) {
                        'run' => const SizedBox(key: ValueKey('r'), width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: C.blue, backgroundColor: C.blue100)),
                        'ok' => Container(key: const ValueKey('o'), width: 26, height: 26, decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle), child: Center(child: Ic('check', size: 14, color: Colors.white))),
                        'wait' => Pill.amber('In review', key: const ValueKey('w')),
                        _ => Text('Queued', key: const ValueKey('q'), style: ts(12, c: C.faint)),
                      },
                    ),
                  ]),
                ),
              ),
          ]),
        ).rise(160),
      ],
    );
  }
}

class VerifyDoneScreen extends StatelessWidget {
  const VerifyDoneScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
        topbar: false,
        bottom: Column(mainAxisSize: MainAxisSize.min, children: [
          Btn('Go to my dashboard', onTap: () => goReset(const SellerDashboard())),
          const SizedBox(height: 12),
          Btn('See my store as buyers do', kind: BtnKind.outline, onTap: () => go(StoreScreen(sel.toSeller()))),
        ]),
        children: [
          StatusHead(kind: 'green', icon: 'check', title: '${sel.store} is verified', body: 'Your store is live. Buyers see these badges on your store and every product you list.', confetti: true),
          StoreHeader(sel.toSeller()).rise(200),
        ],
      );
}

/* ---------- Add a product ---------- */

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final imgs = <Upload>[];
  final name = TextEditingController(text: 'Wireless earbuds'), price = TextEditingController(text: '25000');
  String cat = 'Electronics';
  String? err;
  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Add a product',
        bottom: Btn('Add product', onTap: () {
          if (name.text.trim().isEmpty || price.text.trim().isEmpty) return setState(() => err = 'Add a product name and a price.');
          app.sellerProducts++;
          toast('${name.text.trim()} added');
          if (app.verify == 'done') {
            goReset(const SellerDashboard());
          } else {
            back();
          }
        }),
        children: [
          Column(children: [
            Ic('camera', size: 50, color: C.blue).popIn(),
            const SizedBox(height: 10),
            Text('Upload product images', style: ts(20, w: w7)),
            const SizedBox(height: 6),
            Text('Add up to five clear photos. Buyers trust real photos over stock images.', textAlign: TextAlign.center, style: ts(14, c: C.muted, h: 1.5)),
          ]),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (_, box) {
            final w = (box.maxWidth - 32) / 5;
            return Row(children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                SizedBox(
                  width: w,
                  height: w,
                  child: i < imgs.length
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: UploadThumb(imgs[i])).popIn()
                      : Pressable(
                          onTap: i == imgs.length
                              ? () async {
                                  final u = await pickPhoto(context);
                                  if (u != null) setState(() => imgs.add(u));
                                }
                              : null,
                          child: Opacity(
                            opacity: i == imgs.length ? 1 : 0.5,
                            child: DashedBox(radius: 12, child: Center(child: i == imgs.length ? Ic('plus', size: 22, color: C.blue) : const SizedBox())),
                          ),
                        ),
                ),
              ],
            ]);
          }),
          const SizedBox(height: 24),
          ...stagger([
            Field(label: 'Product name', ctrl: name),
            SelectField(label: 'Category', value: cat, options: const ['Electronics', 'Phones', 'Bags', 'Fashion', 'Beauty', 'Home'], onChanged: (v) => setState(() => cat = v)),
            Field(label: 'Price (₦)', ctrl: price, keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]),
          ]).expand((w) => [w, const SizedBox(height: 18)]),
          ErrText(err),
        ],
      );
}
