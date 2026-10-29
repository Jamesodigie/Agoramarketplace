import 'package:flutter/material.dart';

class Product {
  final String id, name, short, cat, seller, art, color, about;
  final int price, stock, sales;
  final double rating;
  final Color bg;
  final List<String>? sizes;
  const Product({
    required this.id,
    required this.name,
    required this.short,
    required this.price,
    required this.cat,
    required this.seller,
    required this.rating,
    required this.stock,
    required this.art,
    required this.color,
    required this.bg,
    required this.sales,
    required this.about,
    this.sizes,
  });
}

const List<Product> kProducts = [
  Product(id: 'p1', name: 'Wireless Bluetooth Headphones', short: 'Wireless Bluetooth', price: 45000, cat: 'Electronics', seller: 'Chidera Electronics', rating: 4.8, stock: 12, art: 'headphones', color: '#1D2433', bg: Color(0xFFE6D6C3), sales: 200, about: 'Over-ear headphones with 30-hour battery life, active noise cancelling and a fold-flat design for commutes across Lagos.'),
  Product(id: 'p2', name: 'Volt Runner', short: 'Volt Runner', price: 20000, cat: 'Fashion', seller: 'Chidera Electronics', rating: 4.8, stock: 12, art: 'jacket', color: '#C9724F', bg: Color(0xFFE7E8EC), sizes: ['S', 'M', 'L', 'XL'], sales: 200, about: 'Stylish and comfortable, this versatile piece is perfect for everyday wear and special occasions. Made with quality fabric, it offers a great fit, a modern look, and lasting comfort.'),
  Product(id: 'p3', name: 'Leather Tote Bag', short: 'Leather Tote', price: 32000, cat: 'Bags', seller: 'Ìlú Leatherworks', rating: 4.7, stock: 8, art: 'tote', color: '#9A5A2E', bg: Color(0xFFEFE3D6), sales: 140, about: 'Hand-stitched full-grain leather tote from Aba artisans, with an inner zip pocket and brass hardware.'),
  Product(id: 'p4', name: 'Top-Handle Bag', short: 'Top-Handle Bag', price: 27500, cat: 'Bags', seller: 'Ìlú Leatherworks', rating: 4.9, stock: 5, art: 'handbag', color: '#D62F2F', bg: Color(0xFFF4E1DC), sales: 140, about: 'Structured top-handle bag with a detachable strap. Fits a phone, wallet and power bank.'),
  Product(id: 'p5', name: 'Smartphone 128GB', short: 'Smartphone 128GB', price: 310000, cat: 'Phones', seller: 'Ikeja Mobile Hub', rating: 4.6, stock: 20, art: 'phone', color: '#E8B79A', bg: Color(0xFFE4E7EE), sales: 320, about: '6.5" display, dual SIM, 5000mAh battery and 128GB storage. Sealed in box with a one-year seller warranty.'),
  Product(id: 'p6', name: 'Knit Sweater', short: 'Knit Sweater', price: 15000, cat: 'Fashion', seller: 'Lekki Threads', rating: 4.5, stock: 16, art: 'sweater', color: '#8A6A9E', bg: Color(0xFFECE7F1), sizes: ['S', 'M', 'L', 'XL'], sales: 85, about: 'Soft cotton-blend knit for harmattan mornings and air-conditioned offices.'),
  Product(id: 'p7', name: 'Smart Watch', short: 'Smart Watch', price: 52000, cat: 'Electronics', seller: 'Chidera Electronics', rating: 4.7, stock: 9, art: 'watch', color: '#2F7BFF', bg: Color(0xFFDDE6F5), sales: 200, about: 'Heart rate, sleep and step tracking with a 7-day battery and water resistance.'),
  Product(id: 'p8', name: 'Power Bank 20000mAh', short: 'Power Bank', price: 18000, cat: 'Phones', seller: 'Ikeja Mobile Hub', rating: 4.8, stock: 30, art: 'power', color: '#22C55E', bg: Color(0xFFE3F1E8), sales: 320, about: 'Charges a phone four times over. Fast charging on both USB-C and USB-A ports, handy during power cuts.'),
  Product(id: 'p9', name: 'Canvas Sneakers', short: 'Canvas Sneakers', price: 24000, cat: 'Fashion', seller: 'Lekki Threads', rating: 4.6, stock: 14, art: 'sneaker', color: '#C67B2E', bg: Color(0xFFF1E4CC), sizes: ['40', '41', '42', '43'], sales: 85, about: 'Everyday canvas sneakers with a cushioned insole and gum rubber sole.'),
  Product(id: 'p11', name: 'Mini Shoulder Bag', short: 'Mini Shoulder Bag', price: 38500, cat: 'Bags', seller: 'Store by Ella', rating: 4.9, stock: 6, art: 'handbag', color: '#D9468F', bg: Color(0xFFF7E3EE), sales: 150, about: 'Compact shoulder bag in soft vegan leather with a gold chain strap. Fits a phone, cards and lipstick.'),
  Product(id: 'p12', name: 'Weekend Tote', short: 'Weekend Tote', price: 29000, cat: 'Bags', seller: 'Store by Ella', rating: 4.8, stock: 10, art: 'tote', color: '#3E3A63', bg: Color(0xFFE6E5F2), sales: 150, about: 'Roomy structured tote for work or a weekend away, with a laptop sleeve and a zip pocket.'),
  Product(id: 'p10', name: 'Studio Earbuds', short: 'Studio Earbuds', price: 21000, cat: 'Electronics', seller: 'Chidera Electronics', rating: 4.4, stock: 25, art: 'headphones', color: '#F5F5F5', bg: Color(0xFF2B3445), sales: 200, about: 'Wireless earbuds with charging case and touch controls.'),
];

Product productById(String id) => kProducts.firstWhere((p) => p.id == id);

class Review {
  final String name, area, text;
  final int stars;
  const Review(this.name, this.area, this.stars, this.text);
}

class Seller {
  final String name, ini, area, city, cats, since, sales, reply, addrNote, returns;
  final String? cac, ig;
  final Color color, color2;
  final double? rating;
  final int reviews;
  final List<Review> revs;
  final bool own;
  final dynamic logo; // Upload? for the seller's own store
  final String? handle; // the store link name: agoramarket.ng/<handle>
  const Seller({
    required this.name,
    required this.ini,
    required this.color,
    required this.color2,
    required this.area,
    required this.city,
    required this.cats,
    required this.since,
    required this.rating,
    required this.reviews,
    required this.sales,
    required this.reply,
    required this.cac,
    required this.ig,
    required this.addrNote,
    required this.returns,
    required this.revs,
    this.own = false,
    this.logo,
    this.handle,
  });
  String get slug => handle ?? handleFrom(name);
  List<String> get badges => ['ID verified', if (cac != null) 'CAC registered', 'Address verified', 'Bank verified'];
}

const Map<String, Seller> kSellers = {
  'Chidera Electronics': Seller(name: 'Chidera Electronics', ini: 'CE', color: Color(0xFF2F7BFF), color2: Color(0xFF0047C2), area: 'Computer Village', city: 'Ikeja, Lagos', cats: 'Electronics · Audio', since: 'Mar 2024', rating: 4.8, reviews: 132, sales: '200+', reply: 'Usually replies within 1 hour', cac: 'RC 1849263', ig: '@chideraelectronics', addrNote: 'Shop 22, Otigba Plaza, Computer Village, Ikeja', returns: 'Returns within 72 hours of delivery if the item is not as described. Sealed electronics carry a 6-month seller warranty.', revs: [
    Review('Ngozi E.', 'Yaba', 5, 'Headphones were sealed and original. Delivered in two days.'),
    Review('Femi A.', 'Ajah', 5, 'I asked a lot of questions in chat and they answered all of them quickly.'),
    Review('Halima S.', 'Wuse, Abuja', 4, 'Good product. Delivery took one extra day but they kept me updated.'),
  ]),
  'Ìlú Leatherworks': Seller(name: 'Ìlú Leatherworks', ini: 'IL', color: Color(0xFFC98A4B), color2: Color(0xFF7A4A20), area: 'Ariaria Market', city: 'Aba, Abia', cats: 'Bags · Leather goods', since: 'Jul 2024', rating: 4.8, reviews: 86, sales: '140+', reply: 'Usually replies within 3 hours', cac: 'BN 2716604', ig: '@ilu.leather', addrNote: 'Workshop in Ariaria International Market, Aba', returns: 'Returns within 72 hours of delivery if the item is not as described. Custom orders are final.', revs: [
    Review('Ada N.', 'Lekki', 5, 'The leather feels real and the stitching is neat.'),
    Review('Kola B.', 'Ibadan', 5, 'Bought it as a gift. The packaging was lovely.'),
  ]),
  'Ikeja Mobile Hub': Seller(name: 'Ikeja Mobile Hub', ini: 'IM', color: Color(0xFF22C55E), color2: Color(0xFF0E8A3E), area: 'Allen Avenue', city: 'Ikeja, Lagos', cats: 'Phones · Power', since: 'Jan 2024', rating: 4.7, reviews: 211, sales: '320+', reply: 'Usually replies within 30 minutes', cac: 'RC 1502271', ig: '@ikejamobilehub', addrNote: 'Shop 5, 41 Allen Avenue, Ikeja', returns: 'Returns within 72 hours if not as described. Phones come with a 12-month seller warranty.', revs: [
    Review('Tunde O.', 'Surulere', 5, 'Phone was brand new and the IMEI checked out.'),
    Review('Blessing U.', 'Port Harcourt', 4, 'Fast delivery to PH. The power bank works well.'),
  ]),
  'Store by Ella': Seller(name: 'Store by Ella', handle: 'storebyella', ini: 'SE', color: Color(0xFFD9468F), color2: Color(0xFF8E1F5A), area: 'Wuse 2', city: 'Abuja, FCT', cats: 'Bags · Fashion', since: 'Feb 2026', rating: 4.9, reviews: 63, sales: '150+', reply: 'Usually replies within 30 minutes', cac: 'BN 3398120', ig: '@storebyella', addrNote: 'Boutique in Wuse 2, Abuja', returns: 'Exchanges within 72 hours of delivery. Item must be unused with tags.', revs: [
    Review('Hauwa B.', 'Garki', 5, 'Ella sent a video of my bag before dispatch. Exactly what I got.'),
    Review('Tolu A.', 'Lekki', 5, 'Delivered to Lagos in 2 days, well packaged.'),
  ]),
  'Lekki Threads': Seller(name: 'Lekki Threads', ini: 'LT', color: Color(0xFF8A6A9E), color2: Color(0xFF4F3563), area: 'Lekki Phase 1', city: 'Lekki, Lagos', cats: 'Fashion · Footwear', since: 'May 2025', rating: 4.5, reviews: 41, sales: '85+', reply: 'Usually replies within 2 hours', cac: null, ig: '@lekkithreads', addrNote: 'Sells from home in Lekki Phase 1', returns: 'Size exchanges within 72 hours of delivery.', revs: [
    Review('Zainab M.', 'Ikoyi', 5, 'True to size and soft. I will buy again.'),
    Review('Chuka I.', 'Gbagada', 4, 'Nice sneakers. Took a while to dispatch but arrived fine.'),
  ]),
};

const kStates = ['Abia', 'Abuja (FCT)', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue', 'Borno', 'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi', 'Kogi', 'Kwara', 'Lagos', 'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau', 'Rivers', 'Sokoto', 'Taraba', 'Yobe', 'Zamfara'];
const kBanks = ['Access Bank', 'Fidelity Bank', 'First Bank', 'FCMB', 'GTBank', 'Kuda', 'Moniepoint', 'Opay', 'Palmpay', 'Stanbic IBTC', 'Sterling Bank', 'UBA', 'Union Bank', 'Wema Bank', 'Zenith Bank'];

/// A store link name built from the store name: "Store by Ella" -> "storebyella".
String handleFrom(String name) {
  const map = {'à': 'a', 'á': 'a', 'â': 'a', 'è': 'e', 'é': 'e', 'ẹ': 'e', 'ì': 'i', 'í': 'i', 'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ù': 'u', 'ú': 'u', 'ṣ': 's', 'ñ': 'n'};
  var s = name.toLowerCase();
  map.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (s.length > 30) s = s.substring(0, 30);
  return s;
}
