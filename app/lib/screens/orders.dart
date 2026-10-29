import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data.dart';
import '../delivery.dart';
import '../icons.dart';
import '../nav.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'delivery_ui.dart';
import 'shop.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final o = app.order;
          if (o == null) return const OrdersScreen();
          final st = kStage[o.status] ?? 0;
          final p = o.first;
          final steps = [
            ('Money held by Agora', o.heldAt ?? 'Waiting for payment'),
            ('Picked up by GIG Logistics', o.dispAt ?? 'Seller has 48 hours to hand it to GIG'),
            ('Delivered', o.delAt ?? (o.shipment != null ? 'Arrives in ${o.shipment!.eta}' : 'Estimated 2–5 business days')),
            ('Released to the seller', 'After you confirm delivery'),
          ];
          return AppPage(
            title: 'Track order',
            bottom: Column(mainAxisSize: MainAxisSize.min, children: [
              if (o.shipment != null && !o.shipment!.done && kApiBase.isEmpty)
                DemoBtn('GIG scans the next update', onTap: () {
                  DemoDelivery.advance(o.shipment!);
                  syncOrderWithShipment(o);
                  if (o.status == 'delivered') go(const ArrivedScreen());
                }),
              if (o.status == 'delivered') Btn('Confirm delivery', onTap: () => go(const ArrivedScreen())),
            ]),
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Order', style: ts(20, w: w7)), const SizedBox(height: 4), Text(o.id, style: ts(13.5, c: C.muted))])),
                Text(naira(o.total), style: ts(16, w: w7)),
              ]),
              const SizedBox(height: 18),
              CardBox(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [Expanded(child: Text('Order\n${o.id}', style: ts(14, w: w6, h: 1.4))), statusPill(o.status)]),
                  const SizedBox(height: 14),
                  Row(children: [
                    ProductArt(p, width: 86, aspect: 1.2),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.short, style: ts(14.5, w: w5)), Text(p.seller, style: ts(13, c: C.muted))])),
                    Text(naira(o.total), style: ts(15, w: w6)),
                  ]),
                  const SizedBox(height: 22),
                  for (var i = 0; i < steps.length; i++)
                    _TimelineStep(steps[i].$1, steps[i].$2, done: i + 2 <= st, now: i + 2 == st + 1, last: i == steps.length - 1).fadeUp(100 + i * 70),
                ]),
              ).rise(),
              if (o.status != 'awaiting' && o.status != 'failed') ...[
                const SizedBox(height: 22),
                SectionHead('Delivery', trailing: o.shipment == null ? null : TextBtn('Full tracking', onTap: () => go(ShipmentScreen(o.shipment!, viewer: 'buyer')))),
                if (o.shipment == null)
                  CardBox(
                    child: Row(children: [
                      const CarrierTile(),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Booking your GIG pickup…', style: ts(14.5, w: w6))),
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    ]),
                  ).rise(120)
                else
                  ShipmentTracker(o.shipment!).rise(120),
              ],
            ],
          );
        },
      );
}

class _TimelineStep extends StatelessWidget {
  final String title, sub;
  final bool done, now, last;
  const _TimelineStep(this.title, this.sub, {required this.done, required this.now, required this.last});
  @override
  Widget build(BuildContext context) {
    Widget dot = AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 24,
      height: 24,
      decoration: BoxDecoration(shape: BoxShape.circle, color: done ? C.green : (now ? C.blue50 : const Color(0xFFEEF1F6))),
      child: Center(
        child: done
            ? Ic('check', size: 12, color: Colors.white).popIn()
            : now
                ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.blue, shape: BoxShape.circle))
                : null,
      ),
    );
    if (now) {
      dot = Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: C.blue.withValues(alpha: 0.25)))
            .animate(onPlay: (c) => c.repeat())
            .scaleXY(begin: 1, end: 2, duration: 1600.ms, curve: Curves.easeOut)
            .fade(begin: 1, end: 0, duration: 1600.ms),
        dot,
      ]);
    }
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 24,
          child: Column(children: [
            dot,
            if (!last) Expanded(child: Center(child: AnimatedContainer(duration: const Duration(milliseconds: 400), width: 2, color: done ? C.green : C.line))),
          ]),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 26),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: ts(15, w: w5, c: done || now ? C.ink : C.muted)),
              const SizedBox(height: 2),
              Text(sub, style: ts(13.5, c: C.muted)),
            ]),
          ),
        ),
      ]),
    );
  }
}

const _arrivedSvg = r'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 170"><ellipse cx="120" cy="160" rx="100" ry="7" fill="#0F1729" opacity=".08"/><path d="M120 40l56 24v58l-56 24-56-24V64z" fill="#E8C792"/><path d="M64 64l56 24 56-24-56-24z" fill="#F4DCB0"/><path d="M120 88v58l56-24V64z" fill="#D4AD72"/><rect x="88" y="54" width="64" height="10" rx="3" fill="#005AE6" opacity=".8" transform="rotate(23 120 59)"/><circle cx="40" cy="44" r="5" fill="#2F7BFF"/><circle cx="58" cy="22" r="3" fill="#F59E0B"/><circle cx="210" cy="100" r="4" fill="#F59E0B"/></svg>''';

Widget _itemRow(Order o) {
  final p = o.first;
  return CardBox(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      ProductArt(p, width: 86, aspect: 1.2),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.short, style: ts(14.5, w: w5)), Text(p.seller, style: ts(13, c: C.muted))])),
      Text(naira(o.total), style: ts(15, w: w6)),
    ]),
  );
}

class ArrivedScreen extends StatelessWidget {
  const ArrivedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final o = app.order!;
    return AppPage(
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        Btn('Confirm delivery', onTap: () => go(const ConfirmPhotoScreen())),
        const SizedBox(height: 12),
        Btn('Report a problem', kind: BtnKind.outline, onTap: () => showSheet(context,
            title: 'Report a problem',
            body: 'Your ${naira(o.total)} stays in escrow while we look into it. The seller is not paid until this is resolved.',
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final x in const ['Item is damaged', 'Wrong item or size', 'Item not as described', 'Missing items'])
                SheetOption(x, onTap: () {
                  Navigator.of(context).pop();
                  toast('Report sent. Your money stays frozen.', icon: 'shield');
                }),
            ]))),
      ]),
      children: [
        Column(children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(width: 240, height: 170, child: SvgPicture.string(_arrivedSvg)).floaty(),
            Positioned(right: 18, top: 10, child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle), child: Center(child: Ic('check', size: 20, color: Colors.white))).popIn(300)),
          ]).popIn(),
          const SizedBox(height: 16),
          Text('Your order is here!', style: ts(24, w: w7)).fadeUp(100),
          const SizedBox(height: 8),
          Text("Please confirm that you've received your item in good condition before we release the payment to the seller.", textAlign: TextAlign.center, style: ts(14.5, c: C.muted, h: 1.5)).fadeUp(150),
        ]),
        const SizedBox(height: 26),
        _itemRow(o).rise(200),
      ],
    );
  }
}

class ConfirmPhotoScreen extends StatefulWidget {
  const ConfirmPhotoScreen({super.key});
  @override
  State<ConfirmPhotoScreen> createState() => _ConfirmPhotoScreenState();
}

class _ConfirmPhotoScreenState extends State<ConfirmPhotoScreen> {
  Future<void> _pick() async {
    final u = await pickPhoto(context);
    if (u != null) setState(() => app.orderPhoto = u);
  }

  @override
  Widget build(BuildContext context) {
    final ph = app.orderPhoto;
    return AppPage(
      title: 'Confirm your order',
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        Btn('Continue', onTap: ph == null
            ? null
            : () {
                final o = app.order!;
                o.status = 'released';
                app.orders.insert(0, PastOrder(o.id, o.first.id, o.total, '28 Oct 2026', 'completed'));
                app.touch();
                goReset(const DeliveredScreen());
              }),
        const SizedBox(height: 10),
        DemoBtn('use a sample photo', onTap: () => setState(() => app.orderPhoto = const Upload.sample('shop'))),
      ]),
      children: [
        Text('Take a photo of the item to confirm delivery', textAlign: TextAlign.center, style: ts(14, c: C.muted)),
        const SizedBox(height: 18),
        Pressable(
          scale: 0.98,
          onTap: _pick,
          child: AspectRatio(
            aspectRatio: 1.35,
            child: DashedBox(
              dashed: ph == null,
              radius: 20,
              fill: const Color(0xFFE9EDF3),
              color: const Color(0xFFC6CEDB),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ph != null
                    ? SizedBox.expand(child: UploadThumb(ph))
                    : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Ic('camera', size: 44, color: C.blue), const SizedBox(height: 8), Text('Tap to take or upload a photo', style: ts(14, c: C.muted))])),
              ),
            ),
          ),
        ).rise(),
        if (ph != null) ...[const SizedBox(height: 16), Btn('Retake photo', icon: 'camera', kind: BtnKind.outline, onTap: _pick)],
        const SizedBox(height: 18),
        Text('This helps us keep your order safe and makes sure the seller gets paid.', textAlign: TextAlign.center, style: ts(14, c: C.muted, h: 1.5)),
      ],
    );
  }
}

class DeliveredScreen extends StatelessWidget {
  const DeliveredScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final o = app.order!;
    return AppPage(
      topbar: false,
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        Btn('Rate your experience', onTap: () => go(const RateScreen())),
        const SizedBox(height: 12),
        Btn('View my orders', kind: BtnKind.outline, onTap: () => go(const OrdersScreen())),
      ]),
      children: [
        StatusHead(kind: 'green', icon: 'check', title: 'Order delivered', body: "You've confirmed that you received your item. ${naira(o.total)} will be released to the seller.", confetti: true),
        _itemRow(o).rise(250),
      ],
    );
  }
}

class RateScreen extends StatefulWidget {
  const RateScreen({super.key});
  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  int rating = 0;
  final review = TextEditingController();
  static const _labels = ['Tap a star to rate', 'Poor', 'Fair', 'Good', 'Very good', 'Excellent'];
  @override
  Widget build(BuildContext context) => AppPage(
        bottom: Btn('Submit', onTap: rating == 0
            ? null
            : () {
                toast('Thanks for rating ${app.order?.first.seller ?? 'the seller'}');
                app.order = null;
                app.orderPhoto = null;
                app.touch();
                goReset(const HomeScreen());
              }),
        children: [
          const StatusHead(kind: 'amber', icon: 'smile', title: 'How was your experience?', body: 'Your feedback helps us improve and support our sellers.'),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 1; i <= 5; i++)
              Pressable(
                scale: 0.8,
                label: '$i star',
                onTap: () => setState(() => rating = i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedScale(
                    scale: i <= rating ? 1.08 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: kSpring,
                    child: Ic('star', size: 38, color: i <= rating ? C.amber : const Color(0xFFD5DAE3)),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Center(child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: Text(_labels[rating], key: ValueKey(rating), style: ts(14, c: C.muted)))),
          const SizedBox(height: 26),
          Field(label: 'Leave a review', optional: true, ctrl: review, lines: 5, hint: 'Tell us about your experience'),
        ],
      );
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String tab = 'All';
  @override
  Widget build(BuildContext context) {
    final o = app.order;
    final all = [
      if (o != null) PastOrder(o.id, o.first.id, o.total, '28 Oct 2026', o.status == 'released' ? 'completed' : 'progress', live: true),
      ...app.orders,
    ];
    final filter = {
      'All': (PastOrder _) => true,
      'In progress': (PastOrder x) => x.status == 'progress',
      'Completed': (PastOrder x) => x.status == 'completed',
      'Cancelled': (PastOrder x) => x.status == 'cancelled',
    };
    final list = all.where(filter[tab]!).toList();
    return AppPage(
      title: 'Orders',
      header: SizedBox(
        height: 54,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          scrollDirection: Axis.horizontal,
          children: [
            for (final t in filter.keys) ...[
              Pressable(
                scale: 0.94,
                onTap: () => setState(() => tab = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: tab == t ? C.blue : Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text(t, style: ts(14.5, w: w5, c: tab == t ? Colors.white : C.ink)),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ),
      children: list.isEmpty
          ? [
              const SizedBox(height: 30),
              Column(children: [
                Ic('pkg', size: 64, color: C.blue).popIn(),
                const SizedBox(height: 12),
                Text('No orders here', style: ts(18, w: w6)),
                const SizedBox(height: 6),
                Text('When you buy something, this is where you follow the money and the package.', textAlign: TextAlign.center, style: ts(14, c: C.muted, h: 1.5)),
                const SizedBox(height: 16),
                Btn('Browse the marketplace', small: true, expand: false, onTap: () => goReset(const HomeScreen())),
              ]),
            ]
          : [
              for (var i = 0; i < list.length; i++) ...[
                KeyedSubtree(key: ValueKey('$tab${list[i].id}'), child: _OrderRow(list[i]).rise(i * 50)),
                const SizedBox(height: 14),
              ],
            ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  final PastOrder o;
  const _OrderRow(this.o);
  @override
  Widget build(BuildContext context) {
    final p = productById(o.pid);
    final (label, color) = switch (o.status) {
      'progress' => ('In progress', C.blue),
      'completed' => ('Completed', C.green),
      _ => ('Cancelled', C.red),
    };
    return CardBox(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ProductArt(p, width: 86, aspect: 1.2),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.short, style: ts(15, w: w6)),
            Text('Order ID: ${o.id}', style: ts(13.5, c: C.muted, h: 1.6)),
            Text(o.date, style: ts(13.5, c: C.muted, h: 1.6)),
            Text(label, style: ts(13, w: w6, c: color, h: 1.6)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(naira(o.total), style: ts(15, w: w7))),
              Pressable(
                scale: 0.94,
                onTap: () => o.live ? openOrder() : toast('Order details open here in the full app', icon: 'info'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(color: C.blue50, borderRadius: BorderRadius.circular(10)),
                  child: Text(o.status == 'progress' ? 'Track order' : 'View details', style: ts(13.5, w: w6, c: C.blue)),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
