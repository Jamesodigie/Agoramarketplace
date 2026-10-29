import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data.dart';
import '../icons.dart';
import '../nav.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'orders.dart';
import 'shop.dart';

class Stepper3 extends StatelessWidget {
  final int n;
  const Stepper3(this.n, {super.key});
  Widget _step(int i, String l) {
    final done = i < n, on = i == n;
    return SizedBox(
      width: 64,
      child: Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, color: done || on ? C.blue : Colors.white, border: Border.all(color: done || on ? C.blue : C.faint, width: 1.5)),
          child: Center(child: done ? Ic('check', size: 14, color: Colors.white) : Text('$i', style: ts(14, w: w6, c: on ? Colors.white : C.muted))),
        ),
        const SizedBox(height: 8),
        Text(l, style: ts(13.5)),
      ]),
    );
  }

  Widget _bar(bool on) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(top: 13),
          height: 3,
          decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(9)),
          child: on
              ? Container(decoration: BoxDecoration(color: C.blue, borderRadius: BorderRadius.circular(9))).animate().scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft, duration: 500.ms, curve: kEase)
              : null,
        ),
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 26),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [_step(1, 'Delivery'), _bar(n > 1), _step(2, 'Review'), _bar(n > 2), _step(3, 'Payment')]),
      );
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final s = app.ship;
  late final name = TextEditingController(text: s.name), phone = TextEditingController(text: s.phone), addr = TextEditingController(text: s.address), city = TextEditingController(text: s.city), notes = TextEditingController(text: s.notes);
  late String state = s.state;
  String? err;

  Widget _method(String key, String icon, String t, String sub, int price) {
    final on = app.delivery == key;
    return Pressable(
      onTap: () => setState(() => app.delivery = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: on ? const Color(0xFFF7FAFF) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: on ? C.blue : C.line, width: 1.5)),
        child: Row(children: [
          _Radio(on),
          const SizedBox(width: 14),
          Ic(icon, size: 28, color: C.blue),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: ts(15, w: w6)), Text(sub, style: ts(13, c: C.muted))])),
          Text(naira(price), style: ts(15, w: w6)),
        ]),
      ),
    );
  }

  void _submit() {
    s
      ..name = name.text.trim()
      ..phone = phone.text.trim()
      ..address = addr.text.trim()
      ..city = city.text.trim()
      ..state = state
      ..notes = notes.text.trim();
    if (s.name.isEmpty || s.address.isEmpty || s.phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      return setState(() => err = 'Add your name, a delivery address and an 11-digit phone number.');
    }
    go(const ReviewScreen());
  }

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Checkout',
        bottom: Btn('Continue to review', trail: 'arrow', onTap: _submit),
        children: [
          const Stepper3(1),
          Text('Shipping details', style: ts(18, w: w6)),
          const SizedBox(height: 16),
          ...stagger([
            Field(label: 'Full name', ctrl: name, autofill: const [AutofillHints.name]),
            Field(label: 'Phone number', ctrl: phone, keyboard: TextInputType.phone, autofill: const [AutofillHints.telephoneNumber]),
            Field(label: 'Address', ctrl: addr, autofill: const [AutofillHints.streetAddressLine1]),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Field(label: 'City', ctrl: city)),
              const SizedBox(width: 14),
              Expanded(child: SelectField(label: 'State', value: state, options: kStates, onChanged: (v) => setState(() => state = v))),
            ]),
            Field(label: 'Additional notes', optional: true, ctrl: notes, hint: 'Gate code, landmark, best time to call'),
          ]).expand((w) => [w, const SizedBox(height: 18)]),
          const SizedBox(height: 4),
          Text('Delivery method', style: ts(18, w: w6)),
          const SizedBox(height: 14),
          _method('standard', 'truck', 'Standard delivery', '2–5 business days', 3000),
          const SizedBox(height: 12),
          _method('express', 'bolt', 'Express delivery', '1–2 business days', 5000),
          ErrText(err),
        ],
      );
}

class _Radio extends StatelessWidget {
  final bool on;
  const _Radio(this.on);
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 20,
        height: 20,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? C.blue : C.faint, width: 1.5)),
        child: Center(
          child: AnimatedScale(
            scale: on ? 1 : 0,
            duration: const Duration(milliseconds: 380),
            curve: kSpring,
            child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: C.blue, shape: BoxShape.circle)),
          ),
        ),
      );
}

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = app.ship;
    Widget row(String a, String b, {bool tot = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [Expanded(child: Text(a, style: ts(tot ? 18 : 15, w: tot ? w7 : FontWeight.w400))), Text(b, style: ts(tot ? 18 : 15, w: tot ? w7 : w6))]),
        );
    return AppPage(
      title: 'Checkout',
      bottom: Btn('Pay ${naira(app.subtotal + app.fee)} into escrow', onTap: () => go(const PaymentScreen())),
      children: [
        const Stepper3(2),
        CardBox(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Ic('pin', size: 24, color: C.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(s.name, style: ts(15, w: w6))), TextBtn('Change', onTap: () => back())]),
                Text('${s.address}, ${s.city}.\n${s.phone}', style: ts(14, c: C.muted, h: 1.55)),
              ]),
            ),
          ]),
        ).rise(),
        const SizedBox(height: 16),
        CardBox(child: Column(children: [row('Items (${app.cartCount})', naira(app.subtotal)), row('Delivery', naira(app.fee)), row('Total pay', naira(app.subtotal + app.fee), tot: true)])).rise(60),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(color: C.green50, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Ic('lock', size: 16, color: C.green), const SizedBox(width: 8), Text('What happens to your money', style: ts(15, w: w6, c: C.green))]),
            const SizedBox(height: 12),
            for (final (i, t) in const [
              'Agora holds it. The seller cannot touch it.',
              'No dispatch within 48 hours means an automatic refund.',
              'After delivery you have 72 hours to confirm or report a problem.',
              'Only then is the seller paid.',
            ].indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(top: 1), child: Ic('check', size: 15, color: C.ink)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: ts(13.5, h: 1.4))),
                ]),
              ).fadeUp(200 + i * 80),
          ]),
        ).rise(120),
      ],
    );
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final cardNum = TextEditingController(), exp = TextEditingController(), cvv = TextEditingController(), holder = TextEditingController(text: app.userName);
  String? err;

  Widget _opt(String key, String icon, String t, String sub) {
    final on = app.pay == key;
    return Pressable(
      onTap: () => setState(() => app.pay = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: on ? const Color(0xFFF7FAFF) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: on ? C.blue : C.line, width: 1.5)),
        child: Row(children: [
          _Radio(on),
          const SizedBox(width: 14),
          Ic(icon, size: 26, color: C.blue),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: ts(15, w: w6)), Text(sub, style: ts(13, c: C.muted))])),
        ]),
      ),
    );
  }

  void _payCard() {
    final n = cardNum.text.replaceAll(' ', '');
    if (n.length < 16 || !RegExp(r'^\d\d/\d\d$').hasMatch(exp.text) || cvv.text.length < 3) {
      return setState(() => err = 'Enter the 16-digit card number, expiry as MM/YY and the 3-digit CVV.');
    }
    setState(() => err = null);
    processing(context, 'Securing your payment…', 'Funds go into escrow, not to the seller', () {
      app.placeOrder('held');
      goReset(const SuccessScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    final tot = app.subtotal + app.fee;
    return AppPage(
      title: 'Checkout',
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        app.pay == 'card'
            ? Btn('Pay ${naira(tot)}', icon: 'lock', onTap: _payCard)
            : Btn('I have made the transfer', onTap: () => processing(context, 'Looking for your transfer…', 'This usually takes under a minute', () {
                  app.placeOrder('awaiting');
                  goReset(const PendingScreen());
                })),
        const SizedBox(height: 10),
        DemoBtn('simulate a failed payment', onTap: () {
          app.failOrder = Order(id: newOrderId(), items: app.cart.map((c) => CartItem(c.pid, c.size, c.qty)).toList(), total: tot, status: 'failed');
          processing(context, 'Securing your payment…', 'Funds go into escrow, not to the seller', () => go(const FailedScreen()));
        }),
      ]),
      children: [
        const Stepper3(3),
        CardBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Payment', style: ts(15, w: w6)),
            const SizedBox(height: 8),
            Text('Funds route to a licensed custodian account. Agora instructs the release; it never holds your money directly.', style: ts(13.5, c: C.muted, h: 1.5)),
            const SizedBox(height: 16),
            _opt('card', 'card', 'Card', 'Visa, Mastercard, Verve'),
            const SizedBox(height: 12),
            _opt('transfer', 'bank', 'Bank transfer', 'A one-time account number'),
          ]),
        ).rise(),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: kEase,
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SizeTransition(sizeFactor: a, axisAlignment: -1, child: c)),
          child: app.pay == 'card'
              ? Column(key: const ValueKey('card'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Card details', style: ts(15, w: w6)),
                  const SizedBox(height: 14),
                  Field(
                    label: 'Card number',
                    ctrl: cardNum,
                    hint: '0000 0000 0000 0000',
                    keyboard: TextInputType.number,
                    autofill: const [AutofillHints.creditCardNumber],
                    formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16), _CardFmt()],
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(child: Field(label: 'Expiry date', ctrl: exp, hint: 'MM/YY', keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), _ExpFmt()])),
                    const SizedBox(width: 14),
                    Expanded(child: Field(label: 'CVV', ctrl: cvv, hint: '123', keyboard: TextInputType.number, maxLength: 3, formatters: [FilteringTextInputFormatter.digitsOnly])),
                  ]),
                  const SizedBox(height: 18),
                  Field(label: 'Cardholder name', ctrl: holder),
                  ErrText(err),
                ])
              : CardBox(
                  key: const ValueKey('transfer'),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Account details', style: ts(15, w: w6)),
                    const SizedBox(height: 4),
                    Text('Transfer exactly ${naira(tot)} to this account. It expires in 30 minutes.', style: ts(13, c: C.muted, h: 1.45)),
                    const CopyRow('Account number', '1503902382', copy: '1503902382'),
                    const CopyRow('Account name', 'Agora Marketplace'),
                    const CopyRow('Bank name', 'Paystack-Titan', copy: 'Paystack-Titan'),
                  ]),
                ),
        ),
        const SizedBox(height: 24),
        Text('Order summary', style: ts(15, w: w6)),
        const SizedBox(height: 10),
        for (final (a, b, t) in [('Items', naira(app.subtotal), false), ('Delivery', naira(app.fee), false), ('Total pay', naira(tot), true)])
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Expanded(child: Text(a, style: ts(t ? 18 : 15, w: t ? w7 : FontWeight.w400))), Text(b, style: ts(t ? 18 : 15, w: t ? w7 : FontWeight.w400))])),
      ],
    );
  }
}

class _CardFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll(' ', '');
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class _ExpFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll('/', '');
    final t = d.length > 2 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
        topbar: false,
        bottom: Column(mainAxisSize: MainAxisSize.min, children: [
          Btn('Track order', onTap: () => go(const TrackScreen())),
          const SizedBox(height: 12),
          Btn('Continue shopping', kind: BtnKind.outline, onTap: () => goReset(const HomeScreen())),
        ]),
        children: [
          StatusHead(kind: 'green', icon: 'check', title: 'Order confirmed', body: 'Agora is holding ${naira(app.order!.total)}. Nobody is paid until you confirm your items arrived as described.', confetti: true),
          OrderCard(app.order!).rise(250),
        ],
      );
}

class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) => AppPage(
          topbar: false,
          bottom: Column(mainAxisSize: MainAxisSize.min, children: [
            Btn('Check payment status', onTap: () => processing(context, 'Checking with the bank…', 'Matching your transfer to this order', () {
                  app.order!
                    ..status = 'held'
                    ..heldAt = nowLabel();
                  goReset(const SuccessScreen());
                })),
            const SizedBox(height: 12),
            Btn('Back to home', kind: BtnKind.outline, onTap: () => goReset(const HomeScreen())),
          ]),
          children: [
            StatusHead(kind: 'amber', icon: 'clock', title: 'Order pending', body: 'We are waiting for your transfer of ${naira(app.order!.total)}. Once it lands, Agora holds it until you confirm delivery.'),
            OrderCard(app.order!).rise(250),
          ],
        ),
      );
}

class FailedScreen extends StatelessWidget {
  const FailedScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
        topbar: false,
        bottom: Column(mainAxisSize: MainAxisSize.min, children: [
          Btn('Try again', onTap: () => back()),
          const SizedBox(height: 12),
          Btn('Dismiss', kind: BtnKind.outline, onTap: () => goReset(const HomeScreen())),
        ]),
        children: [
          const StatusHead(kind: 'red', icon: 'err', title: 'Transaction failed', body: 'We could not complete your payment. You have not been charged. Check your card details or try bank transfer.'),
          if (app.failOrder != null) OrderCard(app.failOrder!).rise(250),
        ],
      );
}
