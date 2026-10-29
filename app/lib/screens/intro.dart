import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data.dart';
import '../icons.dart';
import '../nav.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'auth.dart';
import 'seller_onboarding.dart';

/* ---------------- Splash ---------------- */

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _out = false;
  Timer? _t1, _t2;
  @override
  void initState() {
    super.initState();
    _t1 = Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      setState(() => _out = true);
      _t2 = Timer(const Duration(milliseconds: 420), () {
        if (mounted) navKey.currentState?.pushReplacement(fadeRoute(const IntroScreen(), ms: 1));
      });
    });
  }

  @override
  void dispose() {
    _t1?.cancel();
    _t2?.cancel();
    super.dispose();
  }

  Widget _ring(int delay) => Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2)),
      )
          .animate(delay: delay.ms)
          .scaleXY(begin: 0.6, end: 2.6, duration: 1900.ms, curve: kEase)
          .fade(begin: 0, end: 1, duration: 450.ms)
          .then()
          .fade(begin: 1, end: 0, duration: 1450.ms);

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).width * 0.4).clamp(110.0, 156.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: C.brand),
      child: Scaffold(
        backgroundColor: C.brand,
        body: Stack(alignment: Alignment.center, children: [
          Container(
            width: 640,
            height: 640,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0)], stops: const [0, 0.6])),
          ).animate(delay: 200.ms).fadeIn(duration: 1200.ms),
          _ring(450),
          _ring(850),
          AnimatedOpacity(
            opacity: _out ? 0 : 1,
            duration: const Duration(milliseconds: 380),
            child: AnimatedSlide(
              offset: _out ? const Offset(0, -0.12) : Offset.zero,
              duration: const Duration(milliseconds: 420),
              curve: kEase,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.28),
                    boxShadow: const [BoxShadow(color: Color(0x59001E6E), blurRadius: 50, offset: Offset(0, 24))],
                    border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.5),
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(size * 0.28), child: Image.asset('assets/logo.png', fit: BoxFit.cover)),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scaleXY(begin: 0.35, end: 1, duration: 1050.ms, curve: kSpring)
                    .moveY(begin: 30, end: 0, duration: 1050.ms, curve: kSpring)
                    .blur(begin: const Offset(8, 8), end: Offset.zero, duration: 600.ms),
                const SizedBox(height: 22),
                Text('Agora', style: ts(26, w: w7, c: Colors.white, ls: -0.5)).fadeUp(700),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/* ---------------- Intro slides ---------------- */

class _Slide {
  final Color bg, fg, nextBg, nextFg;
  final String title, body;
  final Widget Function() mock;
  const _Slide(this.bg, this.fg, this.nextBg, this.nextFg, this.title, this.body, this.mock);
}

final _slides = <_Slide>[
  _Slide(C.brand, Colors.white, Colors.white, C.brand, 'Shop sellers you can trust', 'Every store is checked before it can sell: ID, address and business details. You always know who you are buying from.', () => const _MockTrust()),
  _Slide(C.navy, Colors.white, C.brand, Colors.white, 'Pay once. We hold it.', 'Your money sits safely in escrow. If the seller does not dispatch within 48 hours, you get it back automatically.', () => const _MockEscrow()),
  _Slide(C.light, C.ink, C.ink, Colors.white, 'It arrives. Then they get paid.', 'Check your order when it lands. The seller is paid only after you confirm it is as described.', () => const _MockRelease()),
];

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pc = PageController();
  double _page = 0;
  @override
  void initState() {
    super.initState();
    _pc.addListener(() => setState(() => _page = _pc.page ?? 0));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Color _lerp(Color Function(_Slide) f) {
    final i = _page.floor().clamp(0, _slides.length - 1);
    final j = (i + 1).clamp(0, _slides.length - 1);
    return Color.lerp(f(_slides[i]), f(_slides[j]), _page - i)!;
  }

  void _next() {
    final i = _page.round();
    if (i >= _slides.length - 1) {
      go(const RoleScreen());
    } else {
      _pc.animateToPage(i + 1, duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _lerp((s) => s.bg);
    final fg = _lerp((s) => s.fg);
    final last = _page > 1.5;
    final pad = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (_page > 1.5 ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light).copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: bg),
      child: Scaffold(
        backgroundColor: bg,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(children: [
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _slides.length,
                  itemBuilder: (_, i) => _SlideView(_slides[i], top: pad.top, fg: _slides[i].fg),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 14, 24, 20 + pad.bottom),
                child: Row(children: [
                  AnimatedOpacity(
                    opacity: last ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(ignoring: last, child: TextBtn('Skip', color: fg, size: 15, onTap: () => go(const RoleScreen()))),
                  ),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: last ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        for (var i = 0; i < _slides.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Container(
                            width: 7 + 17 * (1 - (_page - i).abs()).clamp(0.0, 1.0),
                            height: 7,
                            decoration: BoxDecoration(
                              color: fg.withValues(alpha: 0.35 + 0.65 * (1 - (_page - i).abs()).clamp(0.0, 1.0)),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ),
                  Pressable(
                    scale: 0.92,
                    label: last ? 'Get started' : 'Next slide',
                    onTap: _next,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 550),
                      curve: kSpring,
                      height: 56,
                      width: last ? 152 : 56,
                      decoration: BoxDecoration(
                        color: _lerp((s) => s.nextBg),
                        borderRadius: BorderRadius.circular(last ? 16 : 28),
                        boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 24, offset: Offset(0, 10))],
                      ),
                      child: ClipRect(
                        child: Stack(alignment: Alignment.center, children: [
                          AnimatedOpacity(opacity: last ? 0 : 1, duration: const Duration(milliseconds: 250), child: Ic('arrow', size: 22, color: _lerp((s) => s.nextFg))),
                          AnimatedOpacity(
                            opacity: last ? 1 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Text('Get started', maxLines: 1, overflow: TextOverflow.clip, softWrap: false, style: ts(15.5, w: w6, c: Colors.white)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide s;
  final double top;
  final Color fg;
  const _SlideView(this.s, {required this.top, required this.fg});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: Stack(alignment: Alignment.center, children: [
            if (s.bg != C.light)
              Container(
                width: 560,
                height: 560,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0)], stops: const [0, 0.62])),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, top + 18, 20, 6),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360, maxHeight: 520),
                  child: FittedBox(fit: BoxFit.scaleDown, child: SizedBox(width: 320, child: s.mock())),
                ),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.title, style: ts(28, w: w7, c: fg, h: 1.15, ls: -0.5)).fadeUp(80),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(s.body, style: ts(15, c: fg.withValues(alpha: 0.78), h: 1.55)).fadeUp(160),
            ),
          ]),
        ),
      ]);
}

/* ---------- Mock-ups that build themselves ---------- */

const _shadowM = [BoxShadow(color: Color(0x47031440), blurRadius: 50, offset: Offset(0, 20))];

Widget _mcard(Widget child) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: _shadowM),
      child: child,
    );

Widget _mav(String ini, Color a, Color b, {double size = 44}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * 0.32), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b])),
      child: Center(child: Text(ini, style: ts(size * 0.34, w: w7, c: Colors.white))),
    );

Widget _tag(String t, int d) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFE9F8EF), borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Ic('check', size: 12, color: C.greenInk), const SizedBox(width: 4), Text(t, style: ts(11.5, w: w6, c: C.greenInk))]),
    ).popIn(d);

Widget _starsAnim(int start, {double size = 14}) => Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 5; i++)
        Stack(children: [
          Ic('star', size: size, color: const Color(0xFFDCE1EA)),
          Ic('star', size: size, color: C.amber).popIn(start + i * 90),
        ]),
    ]);

Widget _float(Widget child, int d) => Container(
      padding: const EdgeInsets.fromLTRB(7, 7, 12, 7),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99), boxShadow: const [BoxShadow(color: Color(0x40031440), blurRadius: 28, offset: Offset(0, 12))]),
      child: child,
    ).floaty(d + 700).popIn(d);

class _MockTrust extends StatelessWidget {
  const _MockTrust();
  @override
  Widget build(BuildContext context) {
    final p = productById('p1');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99), boxShadow: const [BoxShadow(color: Color(0x38031440), blurRadius: 30, offset: Offset(0, 10))]),
        child: Row(children: [
          Ic('search', size: 16, color: C.muted),
          const SizedBox(width: 8),
          Text('Phones · Ikeja', style: ts(13)),
          const Spacer(),
          Text('Verified only', style: ts(13, w: w6, c: C.brand)),
          const SizedBox(width: 8),
          Container(width: 28, height: 28, decoration: const BoxDecoration(color: C.brand, shape: BoxShape.circle), child: Center(child: Ic('check', size: 14, color: Colors.white))),
        ]),
      ).drop(150),
      const SizedBox(height: 14),
      _mcard(col(gap: 12, [
        Row(children: [
          _mav('CE', const Color(0xFF2F7BFF), const Color(0xFF0047C2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text('Chidera Electronics', style: ts(15, w: w6)), const SizedBox(width: 5), Ic('badge', size: 17, color: C.brand).popIn(1100)]),
              const SizedBox(height: 3),
              Row(children: [Ic('pin', size: 12, color: C.muted), const SizedBox(width: 3), Text('Computer Village, Ikeja', style: ts(12, c: C.muted))]),
            ]),
          ),
        ]),
        Row(children: [_starsAnim(1250), const SizedBox(width: 8), Text('4.8 · 132 reviews · 200+ sales', style: ts(12, c: C.muted)).fadeUp(1700)]),
        Wrap(spacing: 6, runSpacing: 6, children: [_tag('ID verified', 1850), _tag('CAC registered', 2000), _tag('Address verified', 2150)]),
        Container(
          padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEEF1F6)))),
          child: Row(children: [
            ProductArt(p, width: 42, aspect: 1, radius: 10),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Wireless Headphones', style: ts(12, c: C.muted)), Text('₦45,000', style: ts(15, w: w6))])),
            Pill.green('Escrow', icon: 'shield'),
          ]),
        ).fadeUp(2300),
      ])).rise(500),
      SizedBox(
        height: 86,
        child: Stack(children: [
          Positioned(left: -10, top: 10, child: _float(Row(mainAxisSize: MainAxisSize.min, children: [_mav('IL', const Color(0xFFC98A4B), const Color(0xFF7A4A20), size: 26), const SizedBox(width: 8), Text('Ìlú Leatherworks', style: ts(12, w: w6)), const SizedBox(width: 6), Ic('badge', size: 15, color: C.brand)]), 2500)),
          Positioned(right: -8, top: 46, child: _float(Row(mainAxisSize: MainAxisSize.min, children: [_mav('IM', const Color(0xFF22C55E), const Color(0xFF0E8A3E), size: 26), const SizedBox(width: 8), Text('Ikeja Mobile Hub', style: ts(12, w: w6)), const SizedBox(width: 6), Ic('badge', size: 15, color: C.brand)]), 2700)),
        ]),
      ),
    ]);
  }
}

class _MockEscrow extends StatelessWidget {
  const _MockEscrow();
  @override
  Widget build(BuildContext context) {
    final p = productById('p1');
    Widget line(String a, String b, {bool tot = false}) => Row(children: [
          Expanded(child: Text(a, style: ts(tot ? 15 : 13, c: tot ? C.ink : C.muted))),
          Text(b, style: ts(tot ? 15 : 13, w: tot ? w7 : FontWeight.w400, c: tot ? C.ink : C.muted)),
        ]);
    final pay = SizedBox(
      height: 50,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        Positioned.fill(child: Container(decoration: BoxDecoration(color: C.brand, borderRadius: BorderRadius.circular(14)))),
        Positioned.fill(child: Container(decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(14))).animate(delay: 1500.ms).fadeIn(duration: 400.ms)),
        Text('Pay ₦48,000 into escrow', style: ts(14.5, w: w6, c: Colors.white)).animate(delay: 1450.ms).fadeOut(duration: 250.ms),
        Row(mainAxisSize: MainAxisSize.min, children: [Ic('lock', size: 16, color: Colors.white), const SizedBox(width: 6), Text('Held safely in escrow', style: ts(14.5, w: w6, c: Colors.white))]).fadeUp(1600),
        Positioned(
          left: 190,
          child: Container(width: 26, height: 26, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle))
              .animate(delay: 1150.ms)
              .scaleXY(begin: 0.3, end: 2.6, duration: 600.ms, curve: Curves.easeOut)
              .fade(begin: 0, end: 1, duration: 180.ms)
              .then()
              .fade(begin: 1, end: 0, duration: 420.ms),
        ),
        const Confetti(delayMs: 1500),
      ]),
    ).animate(delay: 1300.ms).scaleXY(begin: 1, end: 0.95, duration: 140.ms).then().scaleXY(begin: 1, end: 1 / 0.95, duration: 220.ms, curve: kSpring);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _mcard(col(gap: 12, [
        Row(children: [Expanded(child: Text('Checkout', style: ts(15, w: w7))), Pill.green('Secure', icon: 'lock', )]),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            ProductArt(p, width: 42, aspect: 1, radius: 10),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Headphones', style: ts(13.5, w: w6)),
                Row(children: [Text('Chidera Electronics', style: ts(12, c: C.muted)), const SizedBox(width: 3), Ic('badge', size: 12, color: C.brand)]),
              ]),
            ),
            Text('₦45,000', style: ts(13.5, w: w7)),
          ]),
        ),
        line('Delivery · 2–5 days', '₦3,000'),
        line('Total', '₦48,000', tot: true),
        pay,
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Ic('shield', size: 14, color: C.green), const SizedBox(width: 6), Text("The seller can't touch it until you confirm", style: ts(12, c: C.muted))]).fadeUp(2200),
      ])).rise(200),
      SizedBox(
        height: 60,
        child: Stack(children: [
          Positioned(
            right: -6,
            top: 14,
            child: _float(
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 26, height: 26, decoration: const BoxDecoration(color: C.amber50, shape: BoxShape.circle), child: Center(child: Ic('clock', size: 14, color: C.amberInk))),
                const SizedBox(width: 8),
                Text('No dispatch in 48h? ', style: ts(12, w: w6)),
                Text('Auto refund', style: ts(12, w: w6, c: C.greenInk)),
              ]),
              2500,
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _MockRelease extends StatelessWidget {
  const _MockRelease();
  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Paid into escrow', 'Mon, 9:14 AM'),
      ('Dispatched by seller', 'Mon, 2:40 PM'),
      ('Delivered to you', 'Wed, 11:05 AM'),
      ('You confirmed it', 'Wed, 11:20 AM'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(99), boxShadow: const [BoxShadow(color: Color(0x5922C55E), blurRadius: 24, offset: Offset(0, 10))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Ic('wallet', size: 15, color: Colors.white), const SizedBox(width: 6), Text('Released to seller · ₦45,000', style: ts(13, w: w6, c: Colors.white))]),
      ).popIn(2450),
      const SizedBox(height: 10),
      _mcard(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Order', style: ts(11.5, c: C.muted)), Text('AGR-4K7M-2X91', style: ts(14, w: w7, ls: 0.3))])),
          Stack(alignment: Alignment.centerRight, children: [
            Pill.amber('In escrow', icon: 'lock').animate(delay: 2200.ms).fadeOut(duration: 300.ms),
            Pill.green('Completed', icon: 'check').popIn(2300),
          ]),
        ]),
        const SizedBox(height: 14),
        for (var i = 0; i < steps.length; i++)
          _Step(steps[i].$1, steps[i].$2, 550 + i * 420, last: i == steps.length - 1),
      ])).rise(150),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x400F1729), blurRadius: 40, offset: Offset(0, 18))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _starsAnim(3050, size: 13),
          const SizedBox(height: 6),
          Text('"Exactly as described. Came sealed in the box."', style: ts(13.5, c: Colors.white, h: 1.4)),
          const SizedBox(height: 4),
          Text('Tobi A. · Surulere', style: ts(12, c: Colors.white.withValues(alpha: 0.65))),
        ]),
      ).rise(2850),
    ]);
  }
}

class _Step extends StatelessWidget {
  final String title, time;
  final int d;
  final bool last;
  const _Step(this.title, this.time, this.d, {this.last = false});
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 24,
            child: Column(children: [
              Stack(children: [
                Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFFEEF1F6), shape: BoxShape.circle)),
                Container(width: 24, height: 24, decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle), child: Center(child: Ic('check', size: 13, color: Colors.white))).popIn(d),
              ]),
              if (!last)
                Expanded(
                  child: Stack(alignment: Alignment.topCenter, children: [
                    Container(width: 2, color: const Color(0xFFE7EBF2)),
                    Container(width: 2, color: C.green).animate(delay: (d + 200).ms).scaleY(begin: 0, end: 1, alignment: Alignment.topCenter, duration: 400.ms),
                  ]),
                ),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: ts(13.5, w: w6)), Text(time, style: ts(12, c: C.muted))]),
            ).animate(delay: d.ms).fade(begin: 0.4, end: 1, duration: 400.ms),
          ),
        ]),
      );
}

/* ---------------- Role picker ---------------- */

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});
  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  String? pick;
  @override
  void initState() {
    super.initState();
    pick = app.rolePicked ? app.role : null;
  }

  Widget _card(String k, String icon, String t, String s) {
    final on = pick == k;
    return Pressable(
      label: t,
      onTap: () => setState(() => pick = k),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFF5F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? C.blue : C.line, width: 1.5),
          boxShadow: on ? const [BoxShadow(color: Color(0x1F0060FD), blurRadius: 26, offset: Offset(0, 10))] : const [],
        ),
        child: Row(children: [
          AnimatedRotation(
            turns: on ? -0.017 : 0,
            duration: const Duration(milliseconds: 450),
            curve: kSpring,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: on ? C.blue : C.blue50, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Ic(icon, size: 24, color: on ? Colors.white : C.blue)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: ts(16, w: w6)),
              const SizedBox(height: 2),
              Text(s, style: ts(13.5, c: C.muted, h: 1.4)),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 22,
            height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? C.blue : const Color(0xFFC5CCD8), width: 1.5)),
            child: Center(
              child: AnimatedScale(
                scale: on ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                curve: kSpring,
                child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: C.blue, shape: BoxShape.circle)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppPage(
        topbar: false,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        children: [
          Row(children: [const LogoTile(size: 36), const SizedBox(width: 10), Text('Agora', style: ts(17, w: w7))]).fadeUp(20),
          const Gap(28),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Welcome to ', style: ts(28, w: w7, ls: -0.5)),
            TextSpan(text: 'Agora', style: ts(28, w: w7, c: C.blue, ls: -0.5)),
          ])).fadeUp(60),
          const Gap(6),
          Text('Join as a', style: ts(15, c: C.muted)).fadeUp(100),
          const Gap(18),
          _card('buyer', 'cart', 'Buyer', 'Shop with your money protected until it arrives').rise(140),
          const Gap(12),
          _card('seller', 'store', 'Seller', 'Open a verified store and sell with trust').rise(210),
          const Gap(18),
          Btn('Next', onTap: pick == null
              ? null
              : () {
                  app.role = pick!;
                  app.rolePicked = true;
                  go(pick == 'seller' ? const SellerStep1() : const CreateAccountScreen());
                }).fadeUp(300),
          const Gap(4),
          Center(child: TextBtn('I already have an account', onTap: () => go(const SignInScreen()))).fadeUp(340),
          const Gap(10),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(color: const Color(0xFFEAF8F0), borderRadius: BorderRadius.circular(22)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Why Agora?', style: ts(18, w: w7, c: C.greenInk)),
              const SizedBox(height: 8),
              Text(
                'Agora is a Nigerian marketplace where your money is held in escrow until your order arrives as described. Every seller is checked before they can sell, so you always know who you are buying from.',
                style: ts(14, c: const Color(0xFF3C4A40), h: 1.55),
              ),
              const SizedBox(height: 14),
              Wrap(spacing: 16, runSpacing: 8, children: [
                for (final t in ['Escrow payments', 'Verified sellers'])
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.green, width: 1.5)),
                      child: Center(child: Ic('check', size: 12, color: C.greenInk)),
                    ),
                    const SizedBox(width: 6),
                    Text(t, style: ts(13.5, w: w6, c: C.greenInk)),
                  ]),
              ]),
            ]),
          ).rise(400),
        ],
      );
}
