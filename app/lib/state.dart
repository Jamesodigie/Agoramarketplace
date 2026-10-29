import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'data.dart';

/// A picked photo, or a built-in sample (for trying the prototype without real documents).
class Upload {
  final Uint8List? bytes;
  final String? sample; // id | cac | bill | selfie | shop
  const Upload.bytes(Uint8List b)
      : bytes = b,
        sample = null;
  const Upload.sample(String s)
      : bytes = null,
        sample = s;
}

class CartItem {
  final String pid;
  final String? size;
  int qty;
  CartItem(this.pid, this.size, this.qty);
  Product get product => productById(pid);
}

class Order {
  final String id;
  final List<CartItem> items;
  final int total;
  String status; // awaiting | held | dispatched | delivered | released | failed
  String? heldAt, dispAt, delAt;
  Order({required this.id, required this.items, required this.total, required this.status, this.heldAt});
  Product get first => items.first.product;
}

class PastOrder {
  final String id, pid, date;
  final int total;
  final String status; // progress | completed | cancelled
  final bool live;
  const PastOrder(this.id, this.pid, this.total, this.date, this.status, {this.live = false});
}

class Address {
  final String label, line, line2;
  bool def;
  Address(this.label, this.line, this.line2, this.def);
}

class Ship {
  String name, phone, address, city, state, notes;
  Ship({required this.name, required this.phone, required this.address, required this.city, required this.state, this.notes = ''});
}

/// Everything a seller fills in across the six verification steps.
class SellerDraft {
  String name = 'Boluwatife Kuye', phone = '813 061 2867', email = 'Kuyebolu101@gmail.com', pw = '';
  bool agree = false;
  String store = 'Kuye Gadgets', desc = 'Original phones, chargers and audio accessories. Sealed boxes and a 6-month warranty on every gadget.';
  List<String> cats = ['Electronics', 'Phones'];
  Upload? logo;
  String btype = 'registered', bizname = 'Kuye Gadgets Enterprises', cac = 'BN 3204718', years = '1–3 years', ig = 'kuyegadgets', web = '';
  Upload? cacDoc;
  String shop = 'physical', street = 'Shop 14, Otigba Plaza, 3 Otigba Street', area = 'Computer Village', city = 'Ikeja', state = 'Lagos', landmark = 'Opposite Zenith Bank';
  Upload? poa, shopPhoto;
  String idType = 'NIN', idNum = '';
  Upload? idDoc, selfie;
  String bank = 'GTBank', acct = '';
  String? acctName;

  bool get registered => btype == 'registered';

  Seller toSeller() => Seller(
        name: store.trim().isEmpty ? 'Your store' : store.trim(),
        ini: initials(store.trim().isEmpty ? 'Your store' : store),
        color: const Color(0xFF0060FD),
        color2: const Color(0xFF0039A6),
        area: area.trim().isEmpty ? 'Your area' : area.trim(),
        city: '${city.trim().isEmpty ? 'City' : city.trim()}, ${state.replaceAll(' (FCT)', '')}',
        cats: cats.isEmpty ? 'Your categories' : cats.take(2).join(' · '),
        since: 'Oct 2026',
        rating: null,
        reviews: 0,
        sales: 'New',
        reply: 'Replies show here after your first chats',
        cac: registered ? cac.trim() : null,
        ig: ig.trim().isEmpty ? null : '@${ig.trim().replaceAll('@', '')}',
        addrNote: '${shop == 'physical' ? 'Shop in' : 'Based in'} ${area.trim()}, ${city.trim()}',
        returns: 'Returns within 72 hours of delivery if the item is not as described.',
        revs: const [],
        own: true,
        logo: logo,
      );
}

class AppState extends ChangeNotifier {
  String role = 'buyer';
  bool rolePicked = false;
  String userName = 'Boluwatife Kuye', userEmail = 'Kuyebolu101@gmail.com';
  String get first => userName.trim().split(' ').first;

  final List<CartItem> cart = [];
  String cat = 'All';
  String delivery = 'standard';
  String pay = 'card';
  final Ship ship = Ship(name: 'Boluwatife Kuye', phone: '08130612867', address: '21 Ekololu Street, Surulere', city: 'Lagos', state: 'Lagos');
  Order? order;
  Order? failOrder;
  final List<PastOrder> orders = [
    const PastOrder('AGR-8Q2D-7L40', 'p6', 15000, '12 Oct 2026', 'completed'),
    const PastOrder('AGR-3M1X-9K22', 'p3', 32000, '4 Oct 2026', 'cancelled'),
  ];
  final List<String> recent = ['Wireless headphones', 'Smart watch', 'Sneakers', 'Casual shirt'];
  final List<Address> addresses = [
    Address('Home', '21 Ekololu Street, Surulere', 'Off Ojuelegba Road, Lagos', true),
    Address('Office', '14 Adeola Odeku Street', 'Victoria Island, Lagos', false),
  ];

  String verify = 'none'; // none | pending | done
  bool vcSeen = false;
  bool sellerHas = true;
  bool twofa = false;
  int sellerProducts = 0;
  final SellerDraft sel = SellerDraft();
  Upload? orderPhoto;

  int get cartCount => cart.fold(0, (a, c) => a + c.qty);
  int get subtotal => cart.fold(0, (a, c) => a + c.product.price * c.qty);
  int get fee => delivery == 'express' ? 5000 : 3000;

  void touch() => notifyListeners();

  void addToCart(String pid, String? size) {
    final i = cart.indexWhere((c) => c.pid == pid && c.size == size);
    if (i >= 0) {
      cart[i].qty++;
    } else {
      cart.add(CartItem(pid, size, 1));
    }
    notifyListeners();
  }

  void placeOrder(String status) {
    order = Order(
      id: newOrderId(),
      items: cart.map((c) => CartItem(c.pid, c.size, c.qty)).toList(),
      total: subtotal + fee,
      status: status,
      heldAt: status == 'held' ? nowLabel() : null,
    );
    cart.clear();
    notifyListeners();
  }
}

final app = AppState();

String naira(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '₦$b';
}

String initials(String n) {
  final parts = n.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).toList();
  if (parts.isEmpty) return 'A';
  return parts.map((w) => w.characters.first).join().toUpperCase();
}

String slugify(String n) {
  const map = {'à': 'a', 'á': 'a', 'â': 'a', 'è': 'e', 'é': 'e', 'ẹ': 'e', 'ì': 'i', 'í': 'i', 'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ù': 'u', 'ú': 'u', 'ṣ': 's', 'ñ': 'n'};
  var s = n.toLowerCase();
  map.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  return s.isEmpty ? 'your-store' : s;
}

final _rnd = Random();
String newOrderId() {
  const c = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  String r(int n) => List.generate(n, (_) => c[_rnd.nextInt(c.length)]).join();
  return 'AGR-${r(4)}-${r(4)}';
}

String nowLabel() {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final d = DateTime.now();
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${m[d.month - 1]} at $h:$mm ${d.hour < 12 ? 'AM' : 'PM'}';
}
