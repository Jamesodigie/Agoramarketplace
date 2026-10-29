import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'art_data.dart';
import 'data.dart';
import 'icons.dart';
import 'nav.dart';
import 'samples.dart';
import 'state.dart';
import 'theme.dart';
import 'screens/shop.dart';

/* ---------------- Motion ---------------- */

extension SoftAnim on Widget {
  Widget rise([int ms = 0]) => animate(delay: ms.ms)
      .fadeIn(duration: 420.ms, curve: Curves.easeOut)
      .moveY(begin: 26, end: 0, duration: 650.ms, curve: kSpring);
  Widget popIn([int ms = 0]) => animate(delay: ms.ms)
      .fadeIn(duration: 220.ms)
      .scaleXY(begin: 0.4, end: 1, duration: 550.ms, curve: kSpring);
  Widget fadeUp([int ms = 0]) => animate(delay: ms.ms)
      .fadeIn(duration: 500.ms, curve: Curves.easeOut)
      .moveY(begin: 10, end: 0, duration: 600.ms, curve: kEase);
  Widget drop([int ms = 0]) => animate(delay: ms.ms)
      .fadeIn(duration: 350.ms)
      .moveY(begin: -22, end: 0, duration: 700.ms, curve: kSpring);
  Widget floaty([int ms = 0]) => animate(delay: ms.ms, onPlay: (c) => c.repeat(reverse: true))
      .moveY(begin: 0, end: -6, duration: 2200.ms, curve: Curves.easeInOut);
}

List<Widget> stagger(List<Widget> ws, {int start = 60, int step = 50}) =>
    [for (var i = 0; i < ws.length; i++) ws[i].rise(start + i * step)];

/* ---------------- Press feedback ---------------- */

class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? label;
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97, this.label});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  void _set(bool v) {
    if (widget.onTap == null) return;
    if (mounted && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      enabled: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
          child: AnimatedScale(
            scale: _down ? widget.scale : 1,
            duration: Duration(milliseconds: _down ? 90 : 420),
            curve: _down ? Curves.easeOut : kSpring,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/* ---------------- Buttons ---------------- */

enum BtnKind { primary, outline, success, danger, dark, white }

class Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String? icon;
  final String? trail;
  final BtnKind kind;
  final bool small;
  final bool expand;
  const Btn(this.label, {super.key, this.onTap, this.icon, this.trail, this.kind = BtnKind.primary, this.small = false, this.expand = true});

  @override
  Widget build(BuildContext context) {
    Color bg = C.blue, fg = Colors.white;
    Border? border;
    List<BoxShadow> shadow = const [];
    switch (kind) {
      case BtnKind.primary:
        bg = C.blue;
        fg = Colors.white;
        shadow = const [BoxShadow(color: Color(0x380060FD), blurRadius: 20, offset: Offset(0, 8))];
      case BtnKind.success:
        bg = C.green;
        fg = Colors.white;
        shadow = const [BoxShadow(color: Color(0x4022C55E), blurRadius: 20, offset: Offset(0, 8))];
      case BtnKind.outline:
        bg = Colors.white;
        fg = C.blue;
        border = Border.all(color: C.blue, width: 1.5);
      case BtnKind.danger:
        bg = Colors.white;
        fg = C.red;
        border = Border.all(color: C.red, width: 1.5);
      case BtnKind.dark:
        bg = C.ink;
        fg = Colors.white;
        shadow = const [BoxShadow(color: Color(0x30000000), blurRadius: 20, offset: Offset(0, 8))];
      case BtnKind.white:
        bg = Colors.white;
        fg = C.blue;
    }
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Ic(icon!, size: 22, color: fg), const SizedBox(width: 10)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: ts(small ? 15 : 17, w: w5, c: fg))),
        if (trail != null) ...[const SizedBox(width: 10), Ic(trail!, size: 20, color: fg)],
      ],
    );
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: onTap == null ? 0.45 : 1,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: small ? 46 : 56,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: small ? 20 : 22),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: border, boxShadow: onTap == null ? const [] : shadow),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}

/// Dashed "Prototype:" button that simulates a backend event.
class DemoBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const DemoBtn(this.label, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: DashedBox(
          radius: 12,
          color: C.faint,
          fill: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Ic('play', size: 14, color: C.muted),
              const SizedBox(width: 6),
              Flexible(child: Text('Prototype: $label', textAlign: TextAlign.center, style: ts(13, c: C.muted))),
            ]),
          ),
        ),
      );
}

class IconBtn extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final Color? color;
  final int badge;
  final String? label;
  const IconBtn(this.icon, {super.key, this.onTap, this.color, this.badge = 0, this.label});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        scale: 0.9,
        label: label,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(clipBehavior: Clip.none, children: [
            Center(child: Ic(icon, size: 24, color: color ?? C.ink)),
            if (badge > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 19),
                  height: 19,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(color: C.blue, borderRadius: BorderRadius.circular(99), border: Border.all(color: C.bg, width: 2)),
                  alignment: Alignment.center,
                  child: Text('$badge', style: ts(10.5, w: w7, c: Colors.white)),
                ).popIn(),
              ),
          ]),
        ),
      );
}

class CartButton extends StatelessWidget {
  const CartButton({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, __) => IconBtn('cart', label: 'Cart', badge: app.cartCount, onTap: () => go(const CartScreen())),
      );
}

class TextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double size;
  const TextBtn(this.label, {super.key, required this.onTap, this.color = C.blue, this.size = 14.5});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        scale: 0.95,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text(label, style: ts(size, w: w6, c: color))),
      );
}

/* ---------------- Page scaffolding ---------------- */

class TopBar extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final bool back;
  final VoidCallback? onBack;
  const TopBar({super.key, this.title, this.trailing, this.back = true, this.onBack});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Row(children: [
          SizedBox(width: 44, child: back ? IconBtn('back', label: 'Back', onTap: onBack ?? () => Navigator.of(context).maybePop()) : null),
          Expanded(child: Text(title ?? '', textAlign: TextAlign.center, style: ts(17, w: w6), maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 44, child: trailing),
        ]),
      );
}

class AppPage extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final bool back;
  final bool topbar;
  final Widget? header;
  final List<Widget> children;
  final Widget? bottom;
  final EdgeInsets padding;
  final ScrollController? controller;
  final VoidCallback? onBack;
  const AppPage({
    super.key,
    this.onBack,
    this.title,
    this.trailing,
    this.back = true,
    this.topbar = true,
    this.header,
    required this.children,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 0),
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final safeB = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: C.bg),
      child: Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(children: [
                if (topbar) TopBar(title: title, trailing: trailing, back: back, onBack: onBack),
                if (header != null) header!,
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: padding.copyWith(bottom: bottom == null ? 28 + safeB : 20),
                    children: children,
                  ),
                ),
                if (bottom != null)
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 14 + safeB),
                    color: C.bg,
                    child: bottom,
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class Gap extends StatelessWidget {
  final double h;
  const Gap(this.h, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(height: h, width: h);
}

Widget col(List<Widget> children, {double gap = 14, CrossAxisAlignment cross = CrossAxisAlignment.stretch}) => Column(
      crossAxisAlignment: cross,
      children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]]],
    );

/* ---------------- Surfaces ---------------- */

class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.radius = 20, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius), boxShadow: kShadow1),
        child: child,
      );
}

class NoteBox extends StatelessWidget {
  final String kind; // blue | green | amber | red
  final String icon;
  final String title;
  final String? body;
  const NoteBox({super.key, required this.kind, required this.icon, required this.title, this.body});
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      'green' => (C.green50, C.greenInk),
      'amber' => (C.amber50, C.amberInk),
      'red' => (C.red50, C.red),
      _ => (C.blue50, C.blue),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 1), child: Ic(icon, size: 18, color: fg)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: ts(13.5, w: w6, c: fg, h: 1.35)),
            if (body != null) Text(body!, style: ts(13, c: C.ink.withValues(alpha: 0.75), h: 1.4)),
          ]),
        ),
      ]),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final String? icon;
  final Color bg, fg;
  final double size;
  const Pill(this.text, {super.key, this.icon, required this.bg, required this.fg, this.size = 12});
  factory Pill.green(String t, {String? icon, Key? key}) => Pill(t, key: key, icon: icon, bg: C.green50, fg: C.greenInk);
  factory Pill.amber(String t, {String? icon, Key? key}) => Pill(t, key: key, icon: icon, bg: C.amber50, fg: C.amberInk);
  factory Pill.blue(String t, {String? icon, Key? key}) => Pill(t, key: key, icon: icon, bg: C.blue50, fg: C.blue);
  factory Pill.red(String t, {String? icon, Key? key}) => Pill(t, key: key, icon: icon, bg: C.red50, fg: C.red);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Ic(icon!, size: size + 2, color: fg), const SizedBox(width: 5)],
          Text(text, style: ts(size, w: w6, c: fg)),
        ]),
      );
}

Widget statusPill(String s) => switch (s) {
      'awaiting' => Pill.amber('Awaiting payment', icon: 'clock'),
      'held' => Pill.green('Funds held', icon: 'shield'),
      'dispatched' => Pill.blue('Dispatched', icon: 'truck'),
      'delivered' => Pill.blue('Delivered', icon: 'pkg'),
      'released' => Pill.green('Completed', icon: 'check'),
      _ => Pill.red('Failed', icon: 'err'),
    };

class Stars extends StatelessWidget {
  final int n;
  final double size;
  const Stars(this.n, {super.key, this.size = 13});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < 5; i++) Ic('star', size: size, color: i < n ? C.amber : const Color(0xFFDCE1EA))],
      );
}

class SectionHead extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHead(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [Expanded(child: Text(title, style: ts(17, w: w6))), if (trailing != null) trailing!]),
      );
}

class LogoTile extends StatelessWidget {
  final double size;
  const LogoTile({super.key, this.size = 32});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [BoxShadow(color: C.brand.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(size * 0.28), child: Image.asset('assets/logo.png', fit: BoxFit.cover)),
      );
}

/* ---------------- Dashed border ---------------- */

class DashedBox extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;
  final Color fill;
  final bool dashed;
  const DashedBox({super.key, required this.child, this.radius = 18, this.color = const Color(0xFFC9D3E3), this.fill = Colors.white, this.dashed = true});
  @override
  Widget build(BuildContext context) {
    final box = Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: dashed ? null : Border.all(color: color, width: 1.5),
      ),
      child: child,
    );
    if (!dashed) return box;
    return CustomPaint(foregroundPainter: _DashPainter(color, radius), child: box);
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashPainter(this.color, this.radius);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.75));
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, min(d + 6, m.length)), p);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color || old.radius != radius;
}

/* ---------------- Form controls ---------------- */

class Field extends StatefulWidget {
  final String label;
  final bool optional;
  final TextEditingController ctrl;
  final String? hint;
  final bool password;
  final TextInputType? keyboard;
  final String? prefix;
  final int lines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? formatters;
  final Widget? labelTrail;
  final TextCapitalization caps;
  final Iterable<String>? autofill;
  const Field({
    super.key,
    required this.label,
    required this.ctrl,
    this.optional = false,
    this.hint,
    this.password = false,
    this.keyboard,
    this.prefix,
    this.lines = 1,
    this.maxLength,
    this.onChanged,
    this.formatters,
    this.labelTrail,
    this.caps = TextCapitalization.none,
    this.autofill,
  });
  @override
  State<Field> createState() => _FieldState();
}

class _FieldState extends State<Field> {
  final _focus = FocusNode();
  bool _obscure = true;
  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  OutlineInputBorder _b(Color c, [double w = 1]) => OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Text(widget.label, style: ts(15, w: w5)),
        if (widget.optional) Text('  (optional)', style: ts(13, c: C.muted)),
        const Spacer(),
        if (widget.labelTrail != null) widget.labelTrail!,
      ]),
      const SizedBox(height: 9),
      AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: _focus.hasFocus ? [BoxShadow(color: C.brand.withValues(alpha: 0.12), spreadRadius: 4)] : const [],
        ),
        child: TextField(
          controller: widget.ctrl,
          focusNode: _focus,
          obscureText: widget.password && _obscure,
          keyboardType: widget.keyboard ?? (widget.lines > 1 ? TextInputType.multiline : TextInputType.text),
          textCapitalization: widget.caps,
          maxLines: widget.password ? 1 : widget.lines,
          minLines: widget.lines > 1 ? widget.lines : 1,
          maxLength: widget.maxLength,
          inputFormatters: widget.formatters,
          onChanged: widget.onChanged,
          autofillHints: widget.autofill,
          style: ts(16),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: ts(16, c: C.faint),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            prefixIcon: widget.prefix == null ? null : Padding(padding: const EdgeInsets.only(left: 14, right: 8), child: Text(widget.prefix!, style: ts(16, c: C.muted))),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: widget.password
                ? IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Ic(_obscure ? 'eyeoff' : 'eye', size: 20, color: C.muted))
                : null,
            enabledBorder: _b(C.line),
            border: _b(C.line),
            focusedBorder: _b(C.blue, 1.5),
          ),
        ),
      ),
    ]);
  }
}

class SelectField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const SelectField({super.key, required this.label, required this.value, required this.options, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(label, style: ts(15, w: w5)),
        const SizedBox(height: 9),
        Pressable(
          scale: 0.99,
          onTap: () async {
            final v = await showSheet<String>(
              context,
              title: label,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final o in options)
                    Pressable(
                      onTap: () => Navigator.of(context).pop(o),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
                        child: Row(children: [
                          Expanded(child: Text(o, style: ts(15.5, w: o == value ? w6 : FontWeight.w400, c: o == value ? C.blue : C.ink))),
                          if (o == value) Ic('check', size: 18, color: C.blue),
                        ]),
                      ),
                    ),
                ],
              ),
              scroll: options.length > 8,
            );
            if (v != null) onChanged(v);
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line)),
            child: Row(children: [Expanded(child: Text(value, style: ts(16))), Ic('down', size: 18, color: C.muted)]),
          ),
        ),
      ]);
}

class ChipsSel extends StatelessWidget {
  final List<String> options;
  final bool Function(String) isOn;
  final ValueChanged<String> onTap;
  const ChipsSel({super.key, required this.options, required this.isOn, required this.onTap});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final o in options)
          Pressable(
            scale: 0.93,
            onTap: () => onTap(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isOn(o) ? C.blue : Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: isOn(o) ? C.blue : C.line, width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: kSpring,
                  child: isOn(o) ? Padding(padding: const EdgeInsets.only(right: 6), child: Ic('check', size: 15, color: Colors.white)) : const SizedBox.shrink(),
                ),
                Text(o, style: ts(14, w: w5, c: isOn(o) ? Colors.white : C.ink)),
              ]),
            ),
          ),
      ]);
}

class Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const Segmented({super.key, required this.labels, required this.index, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: const Color(0xFFE8EDF5), borderRadius: BorderRadius.circular(14)),
        child: LayoutBuilder(
          builder: (_, box) => Stack(children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 450),
              curve: kSpring,
              alignment: index == 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: box.maxWidth / 2,
                height: 42,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), boxShadow: const [BoxShadow(color: Color(0x14101828), blurRadius: 8, offset: Offset(0, 2))]),
              ),
            ),
            Row(children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: ts(14, w: w6, c: i == index ? C.ink : C.muted),
                        child: Text(labels[i], textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
            ]),
          ]),
        ),
      );
}

class CheckRow extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChanged;
  final Widget text;
  const CheckRow({super.key, required this.on, required this.onChanged, required this.text});
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!on),
        child: Semantics(
          checked: on,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: on ? C.blue : Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: on ? C.blue : C.faint, width: 1.5),
              ),
              child: AnimatedScale(
                scale: on ? 1 : 0,
                duration: const Duration(milliseconds: 350),
                curve: kSpring,
                child: Ic('check', size: 15, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: DefaultTextStyle(style: ts(13.5, c: C.muted, h: 1.45), child: text)),
          ]),
        ),
      );
}

class ErrText extends StatelessWidget {
  final String? msg;
  const ErrText(this.msg, {super.key});
  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: kEase,
        child: msg == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(msg!, style: ts(13.5, c: C.red, h: 1.4)).animate(key: ValueKey(msg)).shakeX(hz: 5, amount: 3, duration: 300.ms),
              ),
      );
}

/* ---------------- Uploads ---------------- */

Future<Upload?> pickPhoto(BuildContext context, {bool selfie = false}) async {
  final src = await showSheet<ImageSource>(
    context,
    title: selfie ? 'Take a selfie' : 'Add a photo',
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      _SourceRow(icon: 'camera', label: selfie ? 'Open front camera' : 'Take a photo', onTap: () => Navigator.of(context).pop(ImageSource.camera)),
      const SizedBox(height: 10),
      _SourceRow(icon: 'upload', label: 'Choose from gallery', onTap: () => Navigator.of(context).pop(ImageSource.gallery)),
    ]),
  );
  if (src == null) return null;
  try {
    final x = await ImagePicker().pickImage(
      source: src,
      maxWidth: 1400,
      imageQuality: 82,
      preferredCameraDevice: selfie ? CameraDevice.front : CameraDevice.rear,
    );
    if (x == null) return null;
    return Upload.bytes(await x.readAsBytes());
  } catch (_) {
    toast('Could not open the camera or gallery. Check the app permissions.', icon: 'err');
    return null;
  }
}

class _SourceRow extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const _SourceRow({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: C.blue50, borderRadius: BorderRadius.circular(12)), child: Center(child: Ic(icon, size: 21, color: C.blue))),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: ts(15.5, w: w5))),
            Ic('chev', size: 18, color: C.faint),
          ]),
        ),
      );
}

class UploadThumb extends StatelessWidget {
  final Upload u;
  const UploadThumb(this.u, {super.key});
  @override
  Widget build(BuildContext context) {
    if (u.bytes != null) return Image.memory(u.bytes!, fit: BoxFit.cover, gaplessPlayback: true);
    return SvgPicture.string(kSampleSvgs[u.sample] ?? kSampleSvgs['bill']!, fit: BoxFit.cover);
  }
}

class UploadTile extends StatelessWidget {
  final Upload? value;
  final String title, sub;
  final bool optional;
  final bool selfie;
  final ValueChanged<Upload> onPicked;
  const UploadTile({super.key, required this.value, required this.title, required this.sub, required this.onPicked, this.optional = false, this.selfie = false});
  @override
  Widget build(BuildContext context) {
    final done = value != null;
    return Pressable(
      scale: 0.98,
      onTap: () async {
        final u = await pickPhoto(context, selfie: selfie);
        if (u != null) onPicked(u);
      },
      child: DashedBox(
        dashed: !done,
        color: done ? const Color(0xFFBFE8CF) : const Color(0xFFC9D3E3),
        fill: done ? const Color(0xFFF3FBF6) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 48,
                height: 48,
                child: done ? UploadThumb(value!) : Container(color: C.blue50, child: Center(child: Ic('upload', size: 22, color: C.blue))),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: title, style: ts(14.5, w: w6)),
                  if (optional) TextSpan(text: '  (optional)', style: ts(12.5, c: C.muted)),
                ])),
                const SizedBox(height: 2),
                Text(done ? 'Uploaded. Tap to replace.' : sub, style: ts(12.5, c: C.muted, h: 1.35)),
              ]),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: kSpring), child: c),
              child: done ? Ic('check', key: const ValueKey('d'), size: 22, color: C.green) : Text('Upload', key: const ValueKey('u'), style: ts(12.5, w: w6, c: C.blue)),
            ),
          ]),
        ),
      ),
    );
  }
}

/* ---------------- Product + store visuals ---------------- */

class ProductArt extends StatelessWidget {
  final Product p;
  final Color? tint;
  final double radius;
  final double aspect;
  final double? width;
  final double inset;
  const ProductArt(this.p, {super.key, this.tint, this.radius = 14, this.aspect = 1.08, this.width, this.inset = 0.72});
  @override
  Widget build(BuildContext context) {
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">${kArt[p.art]!(p.color)}</svg>';
    final box = Container(
      decoration: BoxDecoration(color: tint ?? p.bg, borderRadius: BorderRadius.circular(radius)),
      child: Center(child: FractionallySizedBox(widthFactor: inset, heightFactor: inset, child: SvgPicture.string(svg))),
    );
    if (width != null) return SizedBox(width: width, height: width! / aspect, child: box);
    return AspectRatio(aspectRatio: aspect, child: box);
  }
}

class StoreAvatar extends StatelessWidget {
  final Seller s;
  final double size;
  final double? radius;
  final bool border;
  const StoreAvatar(this.s, {super.key, this.size = 42, this.radius, this.border = false});
  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.31;
    final logo = s.logo is Upload ? s.logo as Upload : null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: logo == null ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [s.color, s.color2]) : null,
        color: logo == null ? null : Colors.white,
        border: border ? Border.all(color: Colors.white, width: 4) : null,
        boxShadow: border ? const [BoxShadow(color: Color(0x26101828), blurRadius: 20, offset: Offset(0, 8))] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(border ? r - 4 : r),
        child: logo != null ? UploadThumb(logo) : Center(child: Text(s.ini, style: ts(size * 0.32, w: w7, c: Colors.white))),
      ),
    );
  }
}

class StoreHeader extends StatelessWidget {
  final Seller s;
  final bool pending;
  const StoreHeader(this.s, {super.key, this.pending = false});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: kShadow1),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(height: 84, child: CustomPaint(painter: _CoverPainter(s.color))),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 42, 18, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 6, children: [
                  Text(s.name, style: ts(20, w: w7, ls: -0.2)),
                  pending ? Pill.amber('In review', icon: 'clock') : Ic('badge', size: 20, color: C.blue),
                ]),
                const SizedBox(height: 4),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(top: 2), child: Ic('pin', size: 14, color: C.muted)),
                  const SizedBox(width: 5),
                  Expanded(child: Text('${s.area}, ${s.city} · ${s.cats}', style: ts(13, c: C.muted, h: 1.4))),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (var i = 0; i < s.badges.length; i++)
                    (pending ? Pill.amber(s.badges[i], icon: 'clock') : Pill.green(s.badges[i], icon: 'check')).popIn(300 + i * 80),
                ]),
              ]),
            ),
          ]),
          Positioned(left: 18, top: 52, child: StoreAvatar(s, size: 64, radius: 20, border: true)),
        ]),
      );
}

class _CoverPainter extends CustomPainter {
  final Color c;
  _CoverPainter(this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..color = c);
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(center: const Alignment(-0.65, -0.8), radius: 0.9, colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0)]).createShader(r),
    );
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(center: const Alignment(0.9, 1.6), radius: 1.0, colors: [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0)]).createShader(r),
    );
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.22);
    for (double y = 7; y < size.height; y += 14) {
      for (double x = 7; x < size.width; x += 14) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoverPainter old) => old.c != c;
}

List<(String, String, String, bool)> trustRows(Seller s) => [
      ('id', 'Identity verified', "Owner's ID matched to a live selfie", false),
      if (s.cac != null) ('building', 'Registered business', 'CAC ${s.cac}', false) else ('user', 'Individual seller', 'Not a registered business. ID and address are verified.', true),
      ('pin', 'Address verified', s.addrNote, false),
      ('bank', 'Payout account verified', "Bank account name matches the owner's ID", false),
      ('shield', 'Every order is escrow-protected', 'You pay the seller only after you confirm delivery', false),
    ];

class ProductCard extends StatelessWidget {
  final Product p;
  final int index;
  const ProductCard(this.p, {super.key, this.index = 0});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () => go(ProductScreen(p)),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: kShadow1),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ProductArt(p),
            const SizedBox(height: 8),
            Text(p.short, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(14, w: w5)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(children: [
                Expanded(child: Text(naira(p.price), style: ts(14, w: w6))),
                Ic('star', size: 12, color: C.amber),
                const SizedBox(width: 3),
                Text('${p.rating}', style: ts(13)),
              ]),
            ),
            const SizedBox(height: 4),
            Text(p.seller, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13, c: C.muted)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(color: C.green50, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Ic('shield', size: 15, color: C.green),
                const SizedBox(width: 5),
                Text('Escrow protected', style: ts(12, w: w5, c: C.greenInk)),
              ]),
            ),
          ]),
        ),
      ).rise(40 + min(index, 8) * 40);
}

class ProductGrid extends StatelessWidget {
  final List<Product> items;
  const ProductGrid(this.items, {super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final cols = box.maxWidth > 480 ? 3 : 2;
        final w = (box.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (var i = 0; i < items.length; i++) SizedBox(width: w, child: ProductCard(items[i], index: i)),
        ]);
      });
}

const Map<String, int> kStage = {'awaiting': 1, 'held': 2, 'dispatched': 3, 'delivered': 4, 'released': 5};

class OrderCard extends StatelessWidget {
  final Order o;
  final VoidCallback? onTap;
  const OrderCard(this.o, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = o.first;
    final more = o.items.length > 1 ? ' +${o.items.length - 1} more' : '';
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: kShadow1),
      child: col([
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Order', style: ts(13, c: C.muted)), Text(o.id, style: ts(14, w: w6, ls: 0.3))])),
          statusPill(o.status),
        ]),
        Container(
          padding: const EdgeInsets.only(top: 14),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.line))),
          child: Row(children: [
            ProductArt(p, width: 64, aspect: 1.15),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${p.short}$more', style: ts(14.5, w: w5)), Text(p.seller, style: ts(13, c: C.muted))])),
            Text(naira(o.total), style: ts(15, w: w6)),
          ]),
        ),
        if (o.status == 'awaiting') const NoteBox(kind: 'amber', icon: 'shield', title: 'Not yet protected', body: 'Complete your payment to protect your money'),
        if (o.status == 'held') NoteBox(kind: 'green', icon: 'lock', title: 'Agora is holding ${naira(o.total)}', body: 'The seller has 48 hours to dispatch'),
        if (o.status != 'failed')
          Row(children: [
            for (var i = 1; i <= 5; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 4,
                  decoration: BoxDecoration(color: i <= (kStage[o.status] ?? 0) ? C.blue : C.blue50, borderRadius: BorderRadius.circular(9)),
                ),
              ),
            ],
          ]),
      ]),
    );
    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}

/* ---------------- Celebration ---------------- */

class Confetti extends StatefulWidget {
  final int delayMs;
  final double spread;
  const Confetti({super.key, this.delayMs = 150, this.spread = 140});
  @override
  State<Confetti> createState() => _ConfettiState();
}

class _Bit {
  final double dx, dy, rot, lag;
  final Color color;
  _Bit(this.dx, this.dy, this.rot, this.color, this.lag);
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final List<_Bit> _bits;
  Timer? _t;
  @override
  void initState() {
    super.initState();
    final r = Random();
    const cols = [C.blue, C.green, C.amber, Color(0xFF2F7BFF), C.red];
    _bits = List.generate(24, (i) {
      final a = i / 24 * 2 * pi + r.nextDouble() * 0.3;
      final d = 70 + r.nextDouble() * widget.spread * 0.55;
      return _Bit(cos(a) * d, sin(a) * d - 20, r.nextDouble() * 9, cols[i % 5], r.nextDouble() * 0.15);
    });
    _t = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(child: CustomPaint(size: Size.zero, painter: _ConfettiPainter(_c, _bits)));
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> a;
  final List<_Bit> bits;
  _ConfettiPainter(this.a, this.bits) : super(repaint: a);
  @override
  void paint(Canvas canvas, Size size) {
    if (a.value == 0) return;
    for (final b in bits) {
      final raw = ((a.value - b.lag) / (1 - b.lag)).clamp(0.0, 1.0);
      if (raw <= 0) continue;
      final t = Curves.easeOutCubic.transform(raw);
      final p = Offset(b.dx * t, b.dy * t + 40 * raw * raw);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(b.rot * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-3.5, -5.5, 7, 11), const Radius.circular(2)),
        Paint()..color = b.color.withValues(alpha: (1 - raw).clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}

/// Big round success / pending / error badge for status screens.
class BadgeIcon extends StatelessWidget {
  final String kind; // green | amber | red | blue
  final String icon;
  const BadgeIcon(this.kind, this.icon, {super.key});
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      'green' => (C.green, Colors.white),
      'amber' => (C.amber50, C.amber),
      'red' => (C.red50, C.red),
      _ => (C.blue50, C.blue),
    };
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: kind == 'green' ? const [BoxShadow(color: C.green50, spreadRadius: 10)] : null,
      ),
      child: Center(child: Ic(icon, size: 32, color: fg)),
    ).popIn();
  }
}

class StatusHead extends StatelessWidget {
  final String kind, icon, title, body;
  final bool confetti;
  const StatusHead({super.key, required this.kind, required this.icon, required this.title, required this.body, this.confetti = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 30, 0, 26),
        child: Column(children: [
          Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            BadgeIcon(kind, icon),
            if (confetti) const Positioned(top: 32, child: Confetti()),
          ]),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: ts(24, w: w7, ls: -0.3)).fadeUp(100),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(body, textAlign: TextAlign.center, style: ts(14.5, c: C.muted, h: 1.5)).fadeUp(160),
          ),
        ]),
      );
}

/* ---------------- Overlays ---------------- */

void toast(String msg, {String icon = 'check'}) {
  final m = messengerKey.currentState;
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: C.ink,
    elevation: 0,
    duration: const Duration(milliseconds: 2200),
    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    content: Row(children: [
      Ic(icon, size: 18, color: icon == 'err' ? C.red : C.green),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: ts(14, c: Colors.white))),
    ]),
  ));
}

Future<T?> showSheet<T>(BuildContext context, {String? title, String? body, required Widget child, bool scroll = false}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: C.ink.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) {
      final inner = Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.paddingOf(c).bottom + MediaQuery.viewInsetsOf(c).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(9)))),
          const SizedBox(height: 16),
          if (title != null) Text(title, style: ts(18, w: w7)),
          if (body != null) ...[const SizedBox(height: 6), Text(body, style: ts(14, c: C.muted, h: 1.5))],
          if (title != null || body != null) const SizedBox(height: 16),
          child,
        ]),
      );
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.85),
        child: scroll ? SingleChildScrollView(child: inner) : inner,
      );
    },
  );
}

Future<void> processing(BuildContext context, String title, String sub, VoidCallback then) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: C.ink.withValues(alpha: 0.45),
    builder: (_) => Center(
      child: Container(
        width: 290,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Material(
          color: Colors.transparent,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 4, color: C.blue, backgroundColor: C.blue50)),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: ts(16, w: w6)),
            const SizedBox(height: 6),
            Text(sub, textAlign: TextAlign.center, style: ts(13.5, c: C.muted, h: 1.4)),
          ]),
        ),
      ).popIn(),
    ),
  );
  await Future.delayed(const Duration(milliseconds: 1500));
  navKey.currentState?.pop();
  then();
}

class SheetOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SheetOption(this.label, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Pressable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line, width: 1.5)),
            child: Row(children: [Expanded(child: Text(label, style: ts(15, w: w6))), Ic('chev', size: 18, color: C.faint)]),
          ),
        ),
      );
}

class CopyRow extends StatelessWidget {
  final String label, value;
  final String? copy;
  const CopyRow(this.label, this.value, {super.key, this.copy});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: ts(13, c: C.muted)), const SizedBox(height: 4), SelectableText(value, style: ts(17, w: w6))])),
          if (copy != null)
            Pressable(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: copy!));
                toast('Copied $copy', icon: 'copy');
              },
              child: Row(children: [Ic('copy', size: 18, color: C.blue), const SizedBox(width: 6), Text('Copy', style: ts(13, w: w6, c: C.blue))]),
            ),
        ]),
      );
}
