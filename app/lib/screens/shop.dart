import 'package:flutter/material.dart';
import '../data.dart';
import '../icons.dart';
import '../nav.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'account.dart';
import 'checkout.dart';
import 'orders.dart';
import 'seller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _catBtn(String c, String icon) => Pressable(
        scale: 0.94,
        onTap: () {
          app.cat = c;
          app.touch();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: app.cat == c ? C.blue : Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Ic(icon, size: 22, color: app.cat == c ? Colors.white : C.ink),
            const SizedBox(width: 6),
            Text(c, style: ts(15, w: w5, c: app.cat == c ? Colors.white : C.ink)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final list = kProducts.where((p) => app.cat == 'All' || p.cat == app.cat).toList();
          final o = app.order;
          return AppPage(
            topbar: false,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            children: [
              Row(children: [
                const LogoTile(size: 32),
                const SizedBox(width: 8),
                Text('Agora', style: ts(18, w: w7)),
                const Spacer(),
                const CartButton(),
                const SizedBox(width: 4),
                Pressable(
                  scale: 0.9,
                  label: 'Profile',
                  onTap: () => go(const ProfileScreen()),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFB38A), Color(0xFFE5533C)])),
                    child: Center(child: Text(initials(app.userName), style: ts(13, w: w7, c: Colors.white))),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Pressable(
                scale: 0.99,
                onTap: () => go(const SearchScreen()),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line)),
                  child: Row(children: [Ic('search', size: 20, color: C.faint), const SizedBox(width: 10), Text('Search for shoes, bags, clothes...', style: ts(14, c: C.faint))]),
                ),
              ),
              if (o != null && o.status != 'released') ...[
                const SizedBox(height: 16),
                OrderCard(o, onTap: () => openOrder()).rise(80),
              ],
              const SizedBox(height: 16),
              const _Banner().rise(120),
              const SizedBox(height: 18),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    for (final c in const [('All', 'grid'), ('Electronics', 'laptop'), ('Phones', 'headph'), ('Bags', 'bag'), ('Fashion', 'shirt')]) ...[
                      _catBtn(c.$1, c.$2),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              KeyedSubtree(key: ValueKey(app.cat), child: ProductGrid(list)),
            ],
          );
        },
      );
}

class _Banner extends StatelessWidget {
  const _Banner();
  @override
  Widget build(BuildContext context) => Container(
        height: 122,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: const Color(0xFF15181F), borderRadius: BorderRadius.circular(20)),
        child: LayoutBuilder(
          builder: (_, box) => Stack(children: [
            for (final (i, t) in const [(0.58, 0.08, -0.31), (0.74, 0.52, 0.24), (0.88, 0.16, 0.38), (0.64, 0.74, -0.14), (0.46, 0.40, 0.17), (0.92, 0.70, -0.35)].indexed)
              Positioned(
                left: box.maxWidth * t.$1,
                top: 122 * t.$2,
                child: Transform.rotate(
                  angle: t.$3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFC8102E).withValues(alpha: 0.85), borderRadius: BorderRadius.circular(2)),
                    child: Text('SALE', style: ts(11, w: w7, c: const Color(0xFFFFD9DF), ls: 0.9)),
                  ),
                ).floaty(i * 400),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Black Friday, protected', style: ts(21, w: w6, c: Colors.white)),
                const SizedBox(height: 6),
                Text('Every purchase is held in escrow', style: ts(12.5, c: Colors.white.withValues(alpha: 0.85))),
              ]),
            ),
          ]),
        ),
      );
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final q = TextEditingController();
  List<Product> _results() {
    final t = q.text.trim().toLowerCase();
    const alias = {'footwear': 'sneaker', 'watches': 'watch', 'knitwear': 'sweater'};
    final words = (alias[t] ?? t).split(RegExp(r'\s+')).map((w) => w.endsWith('s') ? w.substring(0, w.length - 1) : w);
    return kProducts.where((p) {
      final h = '${p.name} ${p.cat} ${p.seller} ${p.art}'.toLowerCase();
      return words.every(h.contains);
    }).toList();
  }

  void _set(String v) {
    q.text = v;
    q.selection = TextSelection.collapsed(offset: v.length);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final has = q.text.trim().isNotEmpty;
    final r = has ? _results() : <Product>[];
    return AppPage(
      topbar: false,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 20, 10),
        child: Row(children: [
          IconBtn('back', label: 'Back', onTap: () => back()),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: q,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                app.recent.remove(v.trim());
                app.recent.insert(0, v.trim());
              },
              style: ts(16),
              decoration: InputDecoration(
                hintText: 'Search for shoes, bags, clothes...',
                hintStyle: ts(15, c: C.faint),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                prefixIcon: Padding(padding: const EdgeInsets.all(12), child: Ic('search', size: 20, color: C.faint)),
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.blue, width: 1.5)),
              ),
            ),
          ),
        ]),
      ),
      children: has
          ? [
              if (r.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(children: [
                    Ic('search', size: 56, color: C.blue),
                    const SizedBox(height: 12),
                    Text('No matches for "${q.text}"', style: ts(18, w: w6)),
                    const SizedBox(height: 6),
                    Text('Try a broader word like bags, phones or fashion.', style: ts(14, c: C.muted)),
                  ]),
                )
              else ...[
                Text('${r.length} result${r.length > 1 ? 's' : ''}', style: ts(15, w: w6)),
                const SizedBox(height: 12),
                ProductGrid(r),
              ],
            ]
          : [
              if (app.recent.isNotEmpty) ...[
                Row(children: [
                  Expanded(child: Text('Recent searches', style: ts(15, w: w6))),
                  TextBtn('Clear all', onTap: () => setState(() => app.recent.clear())),
                ]),
                for (final s in List.of(app.recent))
                  Row(children: [
                    Expanded(child: Pressable(scale: 0.98, onTap: () => _set(s), child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(s, style: ts(15))))),
                    IconBtn('x', label: 'Remove', color: C.muted, onTap: () => setState(() => app.recent.remove(s))),
                  ]),
                const SizedBox(height: 18),
              ],
              Text('Browse by category', style: ts(15, w: w6)),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (_, box) {
                final w = (box.maxWidth - 36) / 4;
                return Wrap(spacing: 12, runSpacing: 16, children: [
                  for (final (n, id) in const [('Fashion', 'p2'), ('Footwear', 'p9'), ('Bags', 'p4'), ('Electronics', 'p1'), ('Phones', 'p5'), ('Watches', 'p7'), ('Power', 'p8'), ('Knitwear', 'p6')])
                    SizedBox(
                      width: w,
                      child: Pressable(
                        onTap: () => _set(n),
                        child: Column(children: [ProductArt(productById(id), aspect: 1.1, radius: 12, inset: 0.66), const SizedBox(height: 8), Text(n, style: ts(12.5), maxLines: 1, overflow: TextOverflow.ellipsis)]),
                      ),
                    ),
                ]);
              }),
              const SizedBox(height: 24),
              Text('Trending now', style: ts(15, w: w6)),
              const SizedBox(height: 14),
              ProductGrid([productById('p7'), productById('p4')]),
            ],
    );
  }
}

class ProductScreen extends StatefulWidget {
  final Product p;
  const ProductScreen(this.p, {super.key});
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int thumb = 0;
  String? size;
  bool added = false;
  @override
  void initState() {
    super.initState();
    final s = widget.p.sizes;
    size = s == null ? null : (s.length > 3 ? s[3] : s.first);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final tints = [p.bg, const Color(0xFFE3E6EC), const Color(0xFFECE7DF), const Color(0xFFE2E9F4)];
    final s = kSellers[p.seller]!;
    return AppPage(
      title: 'Details',
      trailing: const CartButton(),
      bottom: Btn(
        added ? 'Go to cart' : 'Add to cart',
        kind: BtnKind.primary,
        icon: added ? 'cart' : null,
        onTap: () {
          if (added) {
            go(const CartScreen());
            return;
          }
          app.addToCart(p.id, size);
          setState(() => added = true);
          toast('${p.short} added to cart');
        },
      ),
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ProductArt(p, key: ValueKey(thumb), tint: tints[thumb], aspect: 1.22, radius: 20, inset: 0.62),
        ).rise(),
        const SizedBox(height: 12),
        Row(children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Pressable(
                onTap: () => setState(() => thumb = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: thumb == i ? C.blue : Colors.transparent, width: 2)),
                  child: ProductArt(p, tint: tints[i], aspect: 1.2, radius: 9),
                ),
              ),
            ),
          ],
        ]).rise(60),
        const SizedBox(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Text(p.name, style: ts(22, w: w7, h: 1.2))),
          const SizedBox(width: 12),
          Text(naira(p.price), style: ts(22, w: w6)),
        ]).fadeUp(100),
        const SizedBox(height: 8),
        Row(children: [Ic('star', size: 14, color: C.amber), const SizedBox(width: 3), Text('${p.rating}', style: ts(13)), const SizedBox(width: 10), Text('${p.stock} in stock', style: ts(13, c: C.muted))]),
        const SizedBox(height: 10),
        Text('Price includes everything. No fee added at checkout.', style: ts(12.5)),
        if (p.sizes != null) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 10, children: [
            for (final z in p.sizes!)
              Pressable(
                scale: 0.92,
                onTap: () => setState(() => size = z),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 34,
                  constraints: const BoxConstraints(minWidth: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: size == z ? C.blue : const Color(0xFFC9DAF8), borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text(z, style: ts(15, w: w6, c: Colors.white)),
                ),
              ),
          ]),
        ],
        const SizedBox(height: 20),
        Pressable(
          onTap: () => go(StoreScreen(s)),
          child: CardBox(
            padding: const EdgeInsets.all(12),
            radius: 16,
            child: Row(children: [
              StoreAvatar(s, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Flexible(child: Text(s.name, style: ts(14.5, w: w6))), const SizedBox(width: 5), Ic('badge', size: 16, color: C.blue)]),
                  const SizedBox(height: 2),
                  Text('${s.area}, ${s.city.split(',').first} · ${s.cac != null ? 'CAC registered' : 'ID verified'} · ${p.sales}+ sales', style: ts(12.5, c: C.muted, h: 1.4)),
                ]),
              ),
              Ic('chev', size: 18, color: C.faint),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(color: C.green50, borderRadius: BorderRadius.circular(16)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 4), child: Ic('shield', size: 26, color: C.green)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Protected by Agora escrow', style: ts(15.5, w: w6, c: C.green)),
                const SizedBox(height: 4),
                Text('We hold your ${naira(p.price)} until you confirm this arrived as described. If the seller does not dispatch within 48 hours, you are refunded automatically.', style: ts(13, c: C.muted, h: 1.45)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        Text('About this item', style: ts(14.5, w: w6)),
        const SizedBox(height: 6),
        Text(p.about, style: ts(13.5, c: C.muted, h: 1.5)),
      ],
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          if (app.cart.isEmpty) {
            return AppPage(title: 'Your cart', children: [
              const SizedBox(height: 50),
              Column(children: [
                Ic('cart', size: 64, color: C.blue).popIn(),
                const SizedBox(height: 14),
                Text('Your cart is empty', style: ts(18, w: w6)),
                const SizedBox(height: 8),
                Text('Everything you add is protected by Agora escrow until it arrives.', textAlign: TextAlign.center, style: ts(14, c: C.muted, h: 1.5)),
                const SizedBox(height: 18),
                Btn('Browse the marketplace', small: true, expand: false, onTap: () => goReset(const HomeScreen())),
              ]),
            ]);
          }
          return AppPage(
            title: 'Your cart',
            trailing: const CartButton(),
            bottom: Btn('Proceed to checkout', trail: 'arrow', onTap: () => go(const CheckoutScreen())),
            children: [
              for (var i = 0; i < app.cart.length; i++) ...[
                _CartRow(app.cart[i]).rise(i * 50),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 8),
              const NoteBox(kind: 'green', icon: 'shield', title: 'All items are verified by buyers before funds are released.'),
              const SizedBox(height: 22),
              Row(children: [Expanded(child: Text('Subtotal', style: ts(15))), Text(naira(app.subtotal), style: ts(15))]),
              const SizedBox(height: 10),
              Row(children: [Expanded(child: Text('Total', style: ts(18, w: w7))), Text(naira(app.subtotal), style: ts(18, w: w7))]),
            ],
          );
        },
      );
}

class _CartRow extends StatelessWidget {
  final CartItem c;
  const _CartRow(this.c);
  @override
  Widget build(BuildContext context) {
    final p = c.product;
    Widget qbtn(String icon, VoidCallback f) => Pressable(scale: 0.85, onTap: f, child: SizedBox(width: 28, height: 26, child: Center(child: Ic(icon, size: 14))));
    return CardBox(
      padding: const EdgeInsets.all(11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ProductArt(p, width: 94),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${p.short}${c.size != null ? ' ${c.size}' : ''}', style: ts(14.5, w: w5)),
              Text('Qty ${c.qty}', style: ts(13, c: C.muted)),
              const SizedBox(height: 10),
              Row(children: [
                Container(
                  decoration: BoxDecoration(border: Border.all(color: C.line), borderRadius: BorderRadius.circular(9)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    qbtn('minus', () {
                      if (c.qty > 1) {
                        c.qty--;
                      } else {
                        app.cart.remove(c);
                      }
                      app.touch();
                    }),
                    SizedBox(width: 18, child: Text('${c.qty}', textAlign: TextAlign.center, style: ts(14))),
                    qbtn('plus', () {
                      c.qty++;
                      app.touch();
                    }),
                  ]),
                ),
                const Spacer(),
                Text(naira(p.price * c.qty), style: ts(15, w: w6)),
              ]),
            ]),
          ),
        ),
        IconBtn('trash', label: 'Remove', color: C.muted, onTap: () {
          app.cart.remove(c);
          app.touch();
          toast('${p.short} removed', icon: 'trash');
        }),
      ]),
    );
  }
}

/// Opens the right screen for the live order from anywhere.
void openOrder() {
  final o = app.order;
  if (o == null) return;
  switch (o.status) {
    case 'awaiting':
      go(const PendingScreen());
    case 'delivered':
      go(const ArrivedScreen());
    default:
      go(const TrackScreen());
  }
}
