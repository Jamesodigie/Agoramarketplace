import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../delivery.dart';
import '../icons.dart';
import '../nav.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'shop.dart';

/* ---------------- Small pieces ---------------- */

Widget stagePill(String stage) {
  final c = stageColor(stage);
  return Pill(kStageInfo[stage]?.$1 ?? stage, bg: c.withValues(alpha: 0.1), fg: c);
}

class CarrierTile extends StatelessWidget {
  final double size;
  const CarrierTile({super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: const Color(0xFFEAF7EE), borderRadius: BorderRadius.circular(size * 0.32)),
        child: Center(child: Ic('truck', size: size * 0.5, color: const Color(0xFF15803D))),
      );
}

/// Six segments that fill as the parcel moves.
class StageBar extends StatelessWidget {
  final Shipment s;
  const StageBar(this.s, {super.key});
  @override
  Widget build(BuildContext context) {
    final at = s.stage == 'failed' ? stageIndex('out') : stageIndex(s.stage);
    final c = stageColor(s.stage);
    return Row(children: [
      for (var i = 0; i < kShipStages.length; i++) ...[
        if (i > 0) const SizedBox(width: 4),
        Expanded(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 400 + i * 80),
            curve: kEase,
            height: 6,
            decoration: BoxDecoration(color: i <= at ? c : const Color(0xFFE6EAF2), borderRadius: BorderRadius.circular(9)),
          ),
        ),
      ],
    ]);
  }
}

/* ---------------- The tracker card ---------------- */

class ShipmentTracker extends StatelessWidget {
  final Shipment s;
  final bool showEvents;
  const ShipmentTracker(this.s, {super.key, this.showEvents = true});

  @override
  Widget build(BuildContext context) {
    final events = s.events.reversed.toList();
    return CardBox(
      radius: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const CarrierTile(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('GIG Logistics', style: ts(15.5, w: w7)),
              Text(s.serviceLabel, style: ts(13, c: C.muted)),
            ]),
          ),
          stagePill(s.stage),
        ]),
        const SizedBox(height: 16),
        Pressable(
          label: 'Copy waybill number',
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: s.waybill));
            toast('Waybill number copied', icon: 'copy');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Text('Waybill', style: ts(13.5, c: C.muted)),
              const SizedBox(width: 10),
              Expanded(child: Text(s.waybill, style: ts(15, w: w7, ls: 0.6))),
              Ic('copy', size: 17, color: C.blue),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _end('From', s.fromName, s.fromCity)),
          Padding(padding: const EdgeInsets.only(top: 14), child: Ic('arrow', size: 18, color: C.faint)),
          const SizedBox(width: 10),
          Expanded(child: _end('To', s.toName, s.toCity)),
        ]),
        const SizedBox(height: 18),
        StageBar(s),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text(s.done ? (s.stage == 'delivered' ? 'Delivered ${timeLabel(s.events.last.at)}' : 'Shipment cancelled') : 'Arrives in ${s.eta}', style: ts(13.5, w: w6, c: stageColor(s.stage)))),
          Text('Updated ${agoLabel(s.updated)}', style: ts(12.5, c: C.muted)),
        ]),
        if (showEvents) ...[
          const SizedBox(height: 20),
          for (var i = 0; i < events.length; i++) _EventRow(events[i], first: i == 0, last: i == events.length - 1).fadeUp(60 + i * 50),
        ],
      ]),
    );
  }

  Widget _end(String k, String name, String city) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: ts(12, c: C.muted)),
        const SizedBox(height: 2),
        Text(name, style: ts(14, w: w6), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(city, style: ts(12.5, c: C.muted), maxLines: 2),
      ]);
}

class _EventRow extends StatelessWidget {
  final TrackEvent e;
  final bool first, last;
  const _EventRow(this.e, {required this.first, required this.last});
  @override
  Widget build(BuildContext context) {
    final c = first ? stageColor(e.stage) : C.faint;
    Widget dot = Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(top: 3),
      decoration: BoxDecoration(shape: BoxShape.circle, color: first ? c : Colors.white, border: Border.all(color: c, width: 2.5)),
    );
    if (first && e.stage != 'delivered') {
      dot = Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        Container(width: 14, height: 14, margin: const EdgeInsets.only(top: 3), decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.3)))
            .animate(onPlay: (a) => a.repeat())
            .scaleXY(begin: 1, end: 2.4, duration: 1600.ms, curve: Curves.easeOut)
            .fade(begin: 1, end: 0, duration: 1600.ms),
        dot,
      ]);
    }
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 14,
          child: Column(children: [
            dot,
            if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: const Color(0xFFE6EAF2))),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.title, style: ts(14, w: first ? w6 : w5, c: first ? C.ink : C.muted, h: 1.35)),
              const SizedBox(height: 3),
              Text('${e.location} · ${timeLabel(e.at)}', style: ts(12.5, c: C.muted)),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// A shipment in a list (seller dashboard, admin console).
class ShipmentRow extends StatelessWidget {
  final Shipment s;
  final VoidCallback onTap;
  final bool showStore;
  const ShipmentRow(this.s, {super.key, required this.onTap, this.showStore = false});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: CardBox(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: stageColor(s.stage).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(13)),
                child: Center(child: Ic(kStageInfo[s.stage]?.$2 ?? 'truck', size: 20, color: stageColor(s.stage))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(showStore ? '${s.fromName} → ${s.toName}' : 'To ${s.toName}', style: ts(14.5, w: w6), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${s.toCity.split(',').first} · WB ${s.waybill}', style: ts(12.5, c: C.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                stagePill(s.stage),
                const SizedBox(height: 4),
                Text(agoLabel(s.events.last.at), style: ts(12, c: C.muted)),
              ]),
            ]),
            const SizedBox(height: 12),
            StageBar(s),
          ]),
        ),
      );
}

/* ---------------- Shipment page (buyer, seller, admin) ---------------- */

class ShipmentScreen extends StatefulWidget {
  final Shipment s;
  final String viewer; // buyer | seller | admin
  const ShipmentScreen(this.s, {super.key, required this.viewer});
  @override
  State<ShipmentScreen> createState() => _ShipmentScreenState();
}

class _ShipmentScreenState extends State<ShipmentScreen> {
  final poll = ShipmentPoller();
  bool busy = false;
  Shipment get s => widget.s;

  @override
  void initState() {
    super.initState();
    poll.start(s, () => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    poll.stop();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => busy = true);
    try {
      await deliveryApi.track(s);
      toast('Latest from GIG', icon: 'truck');
    } catch (e) {
      toast('$e', icon: 'err');
    }
    if (mounted) setState(() => busy = false);
  }

  void _advance() {
    DemoDelivery.advance(s);
    // Keep the buyer's order in step with the parcel.
    final o = app.order;
    if (o != null && o.shipment == s) syncOrderWithShipment(o);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.viewer == 'admin';
    final seller = widget.viewer == 'seller';
    return AppPage(
      title: 'Order ${s.orderId}',
      trailing: busy
          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
          : IconBtn('return', label: 'Refresh tracking', onTap: _refresh),
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        if (admin) ..._adminActions(context),
        if (seller && s.stage == 'booked') Btn('Print waybill', icon: 'doc', kind: BtnKind.outline, onTap: () => toast('Waybill sent to your email for printing', icon: 'doc')),
        if (!s.done && kApiBase.isEmpty) ...[const SizedBox(height: 10), DemoBtn('GIG scans the next update', onTap: _advance)],
      ]),
      children: [
        ShipmentTracker(s).rise(),
        const SizedBox(height: 14),
        if (s.issue)
          NoteBox(
            kind: 'red',
            icon: 'err',
            title: 'GIG could not deliver',
            body: admin ? 'The courier could not reach the buyer. Call them, then rebook delivery. Payment stays in escrow.' : 'GIG will try again. Agora support will call to arrange a new time. Payment stays in escrow.',
          ).rise(60),
        if (s.stage == 'delivered') ...[
          CardBox(
            child: Row(children: [
              Ic('badge', size: 24, color: C.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Proof of delivery', style: ts(15, w: w7)),
                  Text('Signed for by ${s.podName ?? s.toName}. GIG keeps the delivery photo and signature.', style: ts(13, c: C.muted, h: 1.4)),
                ]),
              ),
            ]),
          ).rise(60),
          const SizedBox(height: 14),
        ],
        if (seller && s.stage == 'booked')
          const NoteBox(kind: 'blue', icon: 'pkg', title: 'Get it ready for the GIG rider', body: 'Pack the item, write the order number on the box and keep your phone on. The rider will call before arriving.').rise(80),
        if (!seller && !admin)
          const NoteBox(kind: 'green', icon: 'shield', title: 'Your money is safe', body: 'Agora holds your payment until you confirm the order arrived as described.').rise(80),
        if (admin) _adminFacts().rise(80),
      ],
    );
  }

  Widget _adminFacts() => CardBox(
        child: Column(children: [
          for (final (k, v) in [('Order', s.orderId), ('Seller', s.fromName), ('Buyer', '${s.toName} · ${s.toPhone}'), ('Delivery fee', naira(s.price)), ('Service', s.serviceLabel), ('Escrow', s.stage == 'delivered' ? 'Waiting for buyer to confirm' : 'Held')])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 104, child: Text(k, style: ts(13.5, c: C.muted))),
                Expanded(child: Text(v, style: ts(13.5, w: w6))),
              ]),
            ),
        ]),
      );

  List<Widget> _adminActions(BuildContext context) => [
        if (s.stage == 'booked')
          Btn('Cancel pickup', kind: BtnKind.danger, onTap: () async {
            await deliveryApi.cancel(s);
            if (mounted) setState(() {});
            toast('Pickup cancelled with GIG', icon: 'x');
          }),
        if (s.issue)
          Btn('Rebook delivery', icon: 'truck', onTap: () {
            s
              ..stage = 'out'
              ..events.add(TrackEvent('out', 'Redelivery booked by Agora. Out for delivery', s.toCity.split(',').first, DateTime.now()));
            setState(() {});
            toast('Redelivery booked with GIG', icon: 'truck');
          }),
        if (s.stage == 'delivered')
          Btn('Release payment to seller', kind: BtnKind.success, onTap: () => toast('Payment released to ${s.fromName}', icon: 'check')),
        if (!s.done) ...[
          const SizedBox(height: 10),
          Btn('Refund buyer', kind: BtnKind.outline, onTap: () => toast('Refund sent to ${s.toName}', icon: 'return')),
        ],
      ];
}

/// Moves the buyer's escrow order along with the GIG parcel.
void syncOrderWithShipment(Order o) {
  final s = o.shipment;
  if (s == null) return;
  final i = stageIndex(s.stage);
  if (i >= stageIndex('picked') && o.status == 'held') {
    o
      ..status = 'dispatched'
      ..dispAt = nowLabel();
  }
  if (s.stage == 'delivered' && o.status == 'dispatched') {
    o
      ..status = 'delivered'
      ..delAt = nowLabel();
  }
  app.touch();
}

/* ---------------- Admin console ---------------- */

class AdminScreen extends StatefulWidget {
  final bool entry;
  const AdminScreen({super.key, this.entry = false});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String tab = 'All';
  final q = TextEditingController();

  List<Shipment> get all => [if (app.order?.shipment != null) app.order!.shipment!, ...kDemoShipments];

  @override
  Widget build(BuildContext context) {
    final tabs = <String, bool Function(Shipment)>{
      'All': (_) => true,
      'Needs attention': (s) => s.issue || (s.stage == 'booked' && DateTime.now().difference(s.events.first.at).inHours > 48),
      'Awaiting pickup': (s) => s.stage == 'booked',
      'On the way': (s) => const ['picked', 'transit', 'arrived', 'out'].contains(s.stage),
      'Delivered': (s) => s.stage == 'delivered',
    };
    final text = q.text.trim().toLowerCase();
    final list = all.where(tabs[tab]!).where((s) => text.isEmpty || '${s.waybill} ${s.orderId} ${s.fromName} ${s.toName}'.toLowerCase().contains(text)).toList();
    int count(String t) => all.where(tabs[t]!).length;

    Widget stat(String v, String l, Color c) => Expanded(
          child: CardBox(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            radius: 16,
            child: Column(children: [Text(v, style: ts(18, w: w7, c: c)), const SizedBox(height: 2), Text(l, textAlign: TextAlign.center, style: ts(12, c: C.muted))]),
          ),
        );

    return AppPage(
      title: 'Agora admin · Deliveries',
      back: true,
      onBack: widget.entry ? () => goReset(const HomeScreen()) : null,
      header: SizedBox(
        height: 54,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          scrollDirection: Axis.horizontal,
          children: [
            for (final t in tabs.keys) ...[
              Pressable(
                scale: 0.94,
                onTap: () => setState(() => tab = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: tab == t ? C.navy : Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text('$t  ${count(t)}', style: ts(14, w: w5, c: tab == t ? Colors.white : C.ink)),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ),
      children: [
        Row(children: [
          stat('${count('On the way')}', 'On the way', C.blue),
          const SizedBox(width: 10),
          stat('${count('Awaiting pickup')}', 'Awaiting pickup', C.amberInk),
          const SizedBox(width: 10),
          stat('${count('Needs attention')}', 'Need attention', C.red),
        ]).rise(),
        const SizedBox(height: 14),
        TextField(
          controller: q,
          onChanged: (_) => setState(() {}),
          style: ts(15),
          decoration: InputDecoration(
            hintText: 'Search waybill, order, store or buyer',
            hintStyle: ts(15, c: C.faint),
            prefixIcon: Padding(padding: const EdgeInsets.all(12), child: Ic('search', size: 20, color: C.muted)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ).rise(40),
        const SizedBox(height: 16),
        if (list.isEmpty)
          Padding(padding: const EdgeInsets.only(top: 30), child: Text('No deliveries here', textAlign: TextAlign.center, style: ts(15, c: C.muted)))
        else
          for (var i = 0; i < list.length; i++) ...[
            KeyedSubtree(
              key: ValueKey('$tab${list[i].waybill}'),
              child: ShipmentRow(list[i], showStore: true, onTap: () async {
                await go(ShipmentScreen(list[i], viewer: 'admin'));
                if (mounted) setState(() {});
              }).rise(60 + i * 40),
            ),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 6),
        Text(kApiBase.isEmpty ? 'Demo data. Connect the backend to see live GIG shipments.' : 'Live from GIG. Refreshes every few minutes.', textAlign: TextAlign.center, style: ts(12.5, c: C.muted)),
      ],
    );
  }
}
