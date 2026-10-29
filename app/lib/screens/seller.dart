import 'package:flutter/material.dart';
import '../data.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../icons.dart';
import '../links.dart';
import '../delivery.dart';
import 'delivery_ui.dart';
import '../nav.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'account.dart';
import 'seller_onboarding.dart';
import 'shop.dart';

class SellerDashboard extends StatelessWidget {
  const SellerDashboard({super.key});

  Widget _stat(String v, String l, Color c, VoidCallback? onTap) => Expanded(
        child: Pressable(
          onTap: onTap,
          child: CardBox(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            radius: 16,
            child: Column(children: [Text(v, style: ts(15, w: w7, c: c)), const SizedBox(height: 2), Text(l, textAlign: TextAlign.center, style: ts(12.5, c: C.muted))]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final has = app.sellerHas;
          const rows = [
            ('p1', 'AG0123458', '12 Oct 2026', 45000, 'Delivered'),
            ('p2', 'AG0123459', '14 Oct 2026', 20000, 'In escrow'),
            ('p7', 'AG0123462', '19 Oct 2026', 52000, 'Delivered'),
            ('p10', 'AG0123470', '24 Oct 2026', 21000, 'Dispatched'),
          ];
          final hour = DateTime.now().hour;
          final greet = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
          return AppPage(
            topbar: false,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            children: [
              Row(children: [
                const LogoTile(size: 32),
                const SizedBox(width: 8),
                Text('Agora', style: ts(18, w: w7)),
                const Spacer(),
                IconBtn('cart', label: 'Switch to buying', onTap: () {
                  app.role = 'buyer';
                  goReset(const HomeScreen());
                }),
                const SizedBox(width: 4),
                Pressable(scale: 0.9, label: 'Profile', onTap: () => go(const ProfileScreen()), child: avatar(34)),
              ]),
              const SizedBox(height: 22),
              Text('$greet, ${app.first}', style: ts(24, w: w7, ls: -0.3)).fadeUp(),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Pressable(
                  scale: 0.96,
                  onTap: () => go(StoreScreen(app.sel.toSeller())),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Ic('badge', size: 15, color: C.green),
                    const SizedBox(width: 5),
                    Text('Verified seller · ${app.sel.store}', style: ts(13, c: C.green)),
                    const SizedBox(width: 3),
                    Ic('chev', size: 14, color: C.green.withValues(alpha: 0.6)),
                  ]),
                ),
              ).fadeUp(40),
              const SizedBox(height: 18),
              StoreLinkCard(app.sel.toSeller()).rise(60),
              const SizedBox(height: 14),
              Row(children: [
                _stat(has ? '₦245,000' : '₦0', 'Paid out', C.green, () => go(const PaidOutScreen())),
                const SizedBox(width: 12),
                _stat(has ? '₦72,000' : '₦0', 'Held in escrow', C.blue, () => go(const HeldScreen())),
                const SizedBox(width: 12),
                _stat('${(has ? 20 : 0) + app.sellerProducts}', 'Products live', C.ink, () => go(const AddProductScreen())),
              ]).rise(80),
              const SizedBox(height: 28),
              SectionHead('Recent orders', trailing: has ? TextBtn('View all', onTap: () => toast('All orders open here in the full app', icon: 'info')) : null),
              if (has)
                for (final (i, r) in rows.indexed) ...[
                  CardBox(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      ProductArt(productById(r.$1), width: 72, aspect: 1.25),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Order ID: #${r.$2}', style: ts(13.5, c: C.muted, h: 1.6)),
                          Text(r.$3, style: ts(13.5, c: C.muted, h: 1.6)),
                          Text(naira(r.$4), style: ts(15, w: w7)),
                        ]),
                      ),
                      switch (r.$5) {
                        'Delivered' => Pill.green('Delivered'),
                        'In escrow' => Pill.amber('In escrow'),
                        _ => Pill.blue('Dispatched'),
                      },
                    ]),
                  ).rise(140 + i * 60),
                  const SizedBox(height: 12),
                ]
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(children: [
                    Ic('pkg', size: 64, color: C.blue).popIn(),
                    const SizedBox(height: 12),
                    Text('No orders yet', style: ts(18, w: w6)),
                    const SizedBox(height: 6),
                    Text('Share your store link. Buyers who see escrow protection convert better than buyers who do not.', textAlign: TextAlign.center, style: ts(14, c: C.muted, h: 1.5)),
                    const SizedBox(height: 16),
                    Btn('Share store link', icon: 'share', small: true, expand: false, onTap: () => shareStore(context, app.sel.toSeller())),
                  ]),
                ),
              if (has) ...[
                const SizedBox(height: 16),
                SectionHead('Deliveries', trailing: Row(mainAxisSize: MainAxisSize.min, children: [Ic('truck', size: 15, color: const Color(0xFF15803D)), const SizedBox(width: 4), Text('GIG Logistics', style: ts(12.5, w: w6, c: const Color(0xFF15803D)))])),
                for (final (i, sh) in kDemoShipments.where((x) => x.fromName == 'Kuye Gadgets').indexed) ...[
                  ShipmentRow(sh, onTap: () => go(ShipmentScreen(sh, viewer: 'seller'))).rise(200 + i * 60),
                  const SizedBox(height: 12),
                ],
              ],
              const SizedBox(height: 10),
              DemoBtn(has ? 'show a new store with no orders' : 'show a store with orders', onTap: () {
                app.sellerHas = !has;
                app.touch();
              }),
            ],
          );
        },
      );
}

class _Big extends StatefulWidget {
  final String icon, label, value;
  final bool hideable;
  const _Big(this.icon, this.label, this.value, {this.hideable = false});
  @override
  State<_Big> createState() => _BigState();
}

class _BigState extends State<_Big> {
  bool hidden = false;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: C.blue, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x380060FD), blurRadius: 24, offset: Offset(0, 10))]),
        child: Row(children: [
          Ic(widget.icon, size: 28, color: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.label, style: ts(13, c: Colors.white.withValues(alpha: 0.8))),
              AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: Text(hidden ? '₦ • • • • •' : widget.value, key: ValueKey(hidden), style: ts(24, w: w7, c: Colors.white))),
            ]),
          ),
          if (widget.hideable) IconBtn(hidden ? 'eyeoff' : 'eye', label: 'Hide amount', color: Colors.white, onTap: () => setState(() => hidden = !hidden)),
        ]),
      );
}

Widget _moneyRow(Widget lead, String title, List<String> lines, Widget pill, String amount) => CardBox(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        lead,
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: ts(14.5, w: w6)), for (final l in lines) Text(l, style: ts(13.5, c: C.muted, h: 1.55))])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [pill, const SizedBox(height: 8), Text(amount, style: ts(15, w: w7))]),
      ]),
    );

class PaidOutScreen extends StatelessWidget {
  const PaidOutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const pays = [(72000, '24 Oct 2026, 2:45 PM'), (45000, '19 Oct 2026, 11:10 AM'), (86000, '12 Oct 2026, 4:30 PM'), (42000, '5 Oct 2026, 9:05 AM')];
    return AppPage(title: 'Paid out', children: [
      const _Big('wallet', 'Total paid out', '₦245,000', hideable: true).rise(),
      const SizedBox(height: 16),
      Row(children: [
        for (final (i, s) in const [('Last 7 days', '₦72,000'), ('Last 30 days', '₦245,000'), ('Total orders', '20')].indexed) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: CardBox(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), radius: 16, child: Column(children: [Text(s.$1, style: ts(12.5, c: C.muted)), const SizedBox(height: 4), Text(s.$2, style: ts(15, w: w7))]))),
        ],
      ]).rise(60),
      const SizedBox(height: 26),
      const SectionHead('Recent payouts'),
      for (final (i, p) in pays.indexed) ...[
        _moneyRow(
          Container(width: 44, height: 44, decoration: BoxDecoration(color: C.blue50, borderRadius: BorderRadius.circular(12)), child: Center(child: Ic('bank', size: 22, color: C.blue))),
          'Payout to bank',
          ['GTBank, ***1234', p.$2],
          Pill.green('Completed'),
          naira(p.$1),
        ).rise(120 + i * 60),
        const SizedBox(height: 12),
      ],
    ]);
  }
}

class HeldScreen extends StatelessWidget {
  const HeldScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(title: 'Held in escrow', children: [
        const _Big('lock', 'Total in escrow', '₦72,000').rise(),
        const SizedBox(height: 16),
        const NoteBox(kind: 'green', icon: 'shield', title: 'Escrow keeps everyone safe', body: "Funds are released to you once the buyer confirms they've received the item in good condition."),
        const SizedBox(height: 26),
        const SectionHead('Orders with funds in escrow'),
        for (final (i, r) in const [('p2', 'AGO1234', '24 Oct 2026, 2:45 PM', 20000), ('p7', 'AGO1241', '26 Oct 2026, 10:12 AM', 52000)].indexed) ...[
          _moneyRow(ProductArt(productById(r.$1), width: 72, aspect: 1.1), productById(r.$1).short, ['Order #${r.$2}', r.$3], Pill.amber('In escrow'), naira(r.$4)).rise(120 + i * 60),
          const SizedBox(height: 12),
        ],
      ]);
}

/// The page buyers see when they tap a seller: badges, checks, reviews, products.
class StoreScreen extends StatelessWidget {
  final Seller s;
  /// True when the page was opened from a shared link, so there is nothing to go back to.
  final bool entry;
  const StoreScreen(this.s, {super.key, this.entry = false});

  Widget _stat(Widget top, String l) => Expanded(
        child: CardBox(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          radius: 18,
          child: Column(children: [top, const SizedBox(height: 2), Text(l, style: ts(12, c: C.muted))]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final prods = kProducts.where((p) => p.seller == s.name).toList();
    final rows = trustRows(s);
    return AppPage(
      title: entry ? storeLink(s.slug) : 'Store',
      onBack: entry ? () => goReset(const HomeScreen()) : null,
      trailing: IconBtn('share', label: 'Share store', onTap: () => shareStore(context, s)),
      children: [
        if (entry && kIsWeb) ...[const GetAppBanner().drop(), const SizedBox(height: 14)],
        StoreHeader(s).rise(),
        const SizedBox(height: 14),
        Row(children: [
          _stat(
            s.rating != null
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [Ic('star', size: 15, color: C.amber), const SizedBox(width: 4), Text('${s.rating}', style: ts(16, w: w7))])
                : Text('New', style: ts(16, w: w7)),
            s.reviews > 0 ? '${s.reviews} reviews' : 'No reviews yet',
          ),
          const SizedBox(width: 10),
          _stat(Text(s.sales, style: ts(16, w: w7)), 'Sales'),
          const SizedBox(width: 10),
          _stat(Text(s.since, style: ts(16, w: w7)), 'Selling since'),
        ]).rise(60),
        const SizedBox(height: 14),
        CardBox(
          radius: 24,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Ic('shield', size: 20, color: C.green), const SizedBox(width: 8), Text('Why you can trust this store', style: ts(16, w: w7))]),
            const SizedBox(height: 4),
            for (var i = 0; i < rows.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(border: i == rows.length - 1 ? null : const Border(bottom: BorderSide(color: Color(0xFFEEF1F6)))),
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: rows[i].$4 ? const Color(0xFFF1F3F7) : C.blue50, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Ic(rows[i].$1, size: 19, color: rows[i].$4 ? C.muted : C.blue)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(rows[i].$2, style: ts(14.5, w: w6)), Text(rows[i].$3, style: ts(12.5, c: C.muted, h: 1.4))])),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: rows[i].$4 ? const Color(0xFFEEF1F6) : C.green, shape: BoxShape.circle),
                    child: Center(child: Ic(rows[i].$4 ? 'info' : 'check', size: 13, color: rows[i].$4 ? C.muted : Colors.white)),
                  ).popIn(600 + i * 120),
                ]),
              ).fadeUp(350 + i * 120),
            const SizedBox(height: 6),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text('Agora checked these details before this store could sell. ', style: ts(12.5, c: C.muted, h: 1.5)),
              TextBtn('How escrow works', size: 12.5, onTap: () => go(const EscrowScreenLink())),
            ]),
          ]),
        ).rise(120),
        const SizedBox(height: 14),
        CardBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          radius: 22,
          child: Column(children: [
            for (final (i, (ic, t)) in [('msg', s.reply), ('return', s.returns), if (s.ig != null) ('insta', 'Also on Instagram: ${s.ig}')].indexed)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: Color(0xFFEEF1F6)))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Ic(ic, size: 19, color: C.blue), const SizedBox(width: 12), Expanded(child: Text(t, style: ts(13.5, h: 1.45)))]),
              ),
          ]),
        ).rise(180),
        const SizedBox(height: 14),
        const NoteBox(kind: 'amber', icon: 'lock', title: 'Only pay inside Agora', body: 'Escrow protects you only when you pay in the app. Report any seller who asks you to pay outside it.').rise(220),
        if (s.revs.isNotEmpty) ...[
          const SizedBox(height: 26),
          SectionHead('Reviews', trailing: Row(children: [Ic('star', size: 13, color: C.amber), const SizedBox(width: 4), Text('${s.rating} · ${s.reviews} reviews', style: ts(13))])),
          for (final r in s.revs) ...[
            CardBox(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: C.blue50, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(initials(r.name), style: ts(13, w: w7, c: C.blue)))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.name, style: ts(14, w: w6)), Text(r.area, style: ts(12, c: C.muted))])),
                  Stars(r.stars),
                ]),
                const SizedBox(height: 8),
                Text(r.text, style: ts(14, h: 1.5)),
                const SizedBox(height: 8),
                Pill.green('Verified purchase', icon: 'check'),
              ]),
            ),
            const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 14),
        if (prods.isNotEmpty) ...[
          SectionHead('Products', trailing: Text('${prods.length} items', style: ts(13, c: C.muted))),
          ProductGrid(prods),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(children: [
              Ic('pkg', size: 56, color: C.blue),
              const SizedBox(height: 10),
              Text('No products yet', style: ts(17, w: w6)),
              const SizedBox(height: 6),
              Text(s.own ? 'Products you add show here, with your verified badges.' : 'This store has not listed anything yet.', textAlign: TextAlign.center, style: ts(14, c: C.muted)),
              if (s.own) ...[const SizedBox(height: 14), Btn('Add your first product', icon: 'plus', small: true, expand: false, onTap: () => go(const AddProductScreen()))],
            ]),
          ),
        if (!s.own) ...[
          const SizedBox(height: 20),
          Center(
            child: TextBtn('Report this store', color: C.muted, onTap: () => showSheet(context,
                title: 'Report this store',
                body: 'We review every report within 24 hours. Any money of yours in escrow stays frozen while we look.',
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  for (final x in const ['Fake or counterfeit items', 'Asked me to pay outside Agora', 'Rude or abusive', 'Something else'])
                    SheetOption(x, onTap: () {
                      Navigator.of(context).pop();
                      toast('Report sent. Thank you.', icon: 'shield');
                    }),
                ]))),
          ),
        ],
      ],
    );
  }
}

/// Small indirection so the store page can open the escrow explainer without a circular const.
class EscrowScreenLink extends StatelessWidget {
  const EscrowScreenLink({super.key});
  @override
  Widget build(BuildContext context) => const EscrowScreen();
}

/// Shown on the web when someone arrives from a store link.
class GetAppBanner extends StatelessWidget {
  const GetAppBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const LogoTile(size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Agora Marketplace', style: ts(14, w: w7, c: Colors.white)),
              Text('Pay safely. Money held until delivery.', style: ts(12, c: Colors.white.withValues(alpha: 0.7))),
            ]),
          ),
          Pressable(
            label: 'Get the app',
            onTap: () => launchUrl(Uri.parse(kAppDownload), mode: LaunchMode.externalApplication),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: C.brand, borderRadius: BorderRadius.circular(12)),
              child: Text('Get app', style: ts(13.5, w: w7, c: Colors.white)),
            ),
          ),
        ]),
      );
}

/// Shown when a link points to a store that does not exist.
class StoreNotFoundScreen extends StatelessWidget {
  final String handle;
  const StoreNotFoundScreen(this.handle, {super.key});
  @override
  Widget build(BuildContext context) => AppPage(
        back: false,
        children: [
          const SizedBox(height: 60),
          Center(child: Ic('store', size: 72, color: C.blue).popIn()),
          const SizedBox(height: 18),
          Text('No store at this link', textAlign: TextAlign.center, style: ts(22, w: w7)).fadeUp(80),
          const SizedBox(height: 8),
          Text('${storeLink(handle)} is not a store on Agora yet. Check the spelling, or ask the seller for their link.', textAlign: TextAlign.center, style: ts(14.5, c: C.muted, h: 1.5)).fadeUp(140),
          const SizedBox(height: 26),
          Btn('Browse Agora', onTap: () => goReset(const HomeScreen())).rise(200),
        ],
      );
}
