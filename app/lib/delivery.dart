// Delivery with GIG Logistics (GIGL).
//
// The app never talks to GIG directly: GIG credentials live on the server.
// The app calls Agora's backend function `gig` (backend/supabase/functions/gig),
// which logs in to GIG, prices, books and tracks shipments.
//
// Without a backend configured (no --dart-define=AGORA_API=...), the app uses
// DemoDelivery, which behaves the same way with simulated GIG data.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'data.dart';
import 'state.dart';

/* ---------------- Stages ---------------- */

/// The stages every shipment moves through, in order.
const kShipStages = ['booked', 'picked', 'transit', 'arrived', 'out', 'delivered'];

const Map<String, (String label, String icon)> kStageInfo = {
  'booked': ('Pickup booked', 'clock'),
  'picked': ('Picked up from seller', 'pkg'),
  'transit': ('In transit', 'truck'),
  'arrived': ('At GIG centre near you', 'building'),
  'out': ('Out for delivery', 'bolt'),
  'delivered': ('Delivered', 'check'),
  'failed': ('Delivery attempt failed', 'err'),
  'cancelled': ('Cancelled', 'x'),
};

int stageIndex(String s) => kShipStages.indexOf(s);

/// Turns a GIG scan status into one of our stages. GIG sends a status code and a
/// description with every tracking event; the description is the reliable part,
/// so it is matched first and codes refine it.
String stageFromGig(String code, String description) {
  final d = description.toLowerCase();
  final c = code.toUpperCase();
  if (d.contains('cancel')) return 'cancelled';
  if (d.contains('fail') || d.contains('unable') || d.contains('return')) return 'failed';
  if (d.contains('delivered') || d.contains('collected by') || c == 'OKT' || c == 'OKC') return 'delivered';
  if (d.contains('out for delivery') || d.contains('with courier') || d.contains('dispatched for delivery')) return 'out';
  if (d.contains('arrived') || d.contains('ready for pickup') || d.contains('available for collection')) return 'arrived';
  if (d.contains('transit') || d.contains('departed') || d.contains('in route') || d.contains('enroute')) return 'transit';
  if (d.contains('picked') || d.contains('received') || d.contains('shipment collected')) return 'picked';
  return 'booked';
}

/* ---------------- Models ---------------- */

class TrackEvent {
  final String stage, title, location;
  final DateTime at;
  const TrackEvent(this.stage, this.title, this.location, this.at);

  factory TrackEvent.fromJson(Map<String, dynamic> j) => TrackEvent(
        j['stage'] as String? ?? stageFromGig('${j['code'] ?? ''}', '${j['title'] ?? ''}'),
        '${j['title'] ?? ''}',
        '${j['location'] ?? ''}',
        DateTime.tryParse('${j['at']}')?.toLocal() ?? DateTime.now(),
      );
}

class DeliveryQuote {
  final String service; // home | centre
  final int price;
  final String eta;
  const DeliveryQuote(this.service, this.price, this.eta);
}

class Shipment {
  final String orderId, waybill, service, fromName, fromCity, toName, toCity, toPhone;
  final int price;
  String stage;
  String eta;
  final List<TrackEvent> events;
  String? podPhoto; // proof of delivery photo URL
  String? podName; // who signed for it
  DateTime updated;
  Shipment({
    required this.orderId,
    required this.waybill,
    required this.service,
    required this.fromName,
    required this.fromCity,
    required this.toName,
    required this.toCity,
    required this.toPhone,
    required this.price,
    required this.stage,
    required this.eta,
    required this.events,
    DateTime? updated,
  }) : updated = updated ?? DateTime.now();

  bool get done => stage == 'delivered' || stage == 'cancelled';
  bool get issue => stage == 'failed';
  String get serviceLabel => service == 'centre' ? 'Collect at GIG centre' : 'GIG home delivery';

  factory Shipment.fromJson(Map<String, dynamic> j) => Shipment(
        orderId: '${j['order_id']}',
        waybill: '${j['waybill']}',
        service: '${j['service'] ?? 'home'}',
        fromName: '${j['from_name'] ?? ''}',
        fromCity: '${j['from_city'] ?? ''}',
        toName: '${j['to_name'] ?? ''}',
        toCity: '${j['to_city'] ?? ''}',
        toPhone: '${j['to_phone'] ?? ''}',
        price: (j['price'] as num?)?.round() ?? 0,
        stage: '${j['stage'] ?? 'booked'}',
        eta: '${j['eta'] ?? ''}',
        events: [for (final e in (j['events'] as List? ?? const [])) TrackEvent.fromJson(Map<String, dynamic>.from(e as Map))],
        updated: DateTime.tryParse('${j['updated_at']}')?.toLocal(),
      )
        ..podPhoto = j['pod_photo'] as String?
        ..podName = j['pod_name'] as String?;
}

/// Where a seller ships from, read from the store's city ("Ikeja, Lagos" -> Lagos).
String storeState(Seller s) {
  final last = s.city.split(',').last.trim();
  return (last == 'FCT' || last == 'Abuja') ? 'Abuja (FCT)' : last;
}

/* ---------------- API ---------------- */

/// Set at build time: flutter build apk --dart-define=AGORA_API=https://<project>.supabase.co --dart-define=AGORA_KEY=<anon key>
const kApiBase = String.fromEnvironment('AGORA_API');
const kApiKey = String.fromEnvironment('AGORA_KEY');

abstract class DeliveryApi {
  Future<List<DeliveryQuote>> quote({required String fromState, required String toState, required double kg, required int value});
  Future<Shipment> book(Order o, {required Seller from, required Ship to, required String service});
  Future<Shipment> track(Shipment s);
  Future<void> cancel(Shipment s);
}

final DeliveryApi deliveryApi = kApiBase.isEmpty ? DemoDelivery() : LiveDelivery(kApiBase, kApiKey);

/// Talks to Agora's backend, which talks to GIG.
class LiveDelivery implements DeliveryApi {
  final String base, key;
  String? userToken; // the signed-in user's session token
  LiveDelivery(this.base, this.key);

  Future<Map<String, dynamic>> _call(String action, Map<String, dynamic> body) async {
    final r = await http
        .post(
          Uri.parse('$base/functions/v1/gig'),
          headers: {'content-type': 'application/json', 'apikey': key, 'authorization': 'Bearer ${userToken ?? key}'},
          body: jsonEncode({'action': action, ...body}),
        )
        .timeout(const Duration(seconds: 30));
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 400 || j['error'] != null) throw DeliveryError('${j['error'] ?? 'Delivery service error (${r.statusCode})'}');
    return j;
  }

  @override
  Future<List<DeliveryQuote>> quote({required String fromState, required String toState, required double kg, required int value}) async {
    final j = await _call('quote', {'from_state': fromState, 'to_state': toState, 'weight': kg, 'value': value});
    return [for (final q in j['quotes'] as List) DeliveryQuote('${q['service']}', (q['price'] as num).round(), '${q['eta']}')];
  }

  @override
  Future<Shipment> book(Order o, {required Seller from, required Ship to, required String service}) async =>
      Shipment.fromJson((await _call('book', {'order_id': o.id, 'service': service}))['shipment'] as Map<String, dynamic>);

  @override
  Future<Shipment> track(Shipment s) async => Shipment.fromJson((await _call('track', {'waybill': s.waybill}))['shipment'] as Map<String, dynamic>);

  @override
  Future<void> cancel(Shipment s) => _call('cancel', {'waybill': s.waybill});
}

class DeliveryError implements Exception {
  final String message;
  DeliveryError(this.message);
  @override
  String toString() => message;
}

/* ---------------- Demo ---------------- */

const _zones = {
  'Lagos': 'SW', 'Ogun': 'SW', 'Oyo': 'SW', 'Osun': 'SW', 'Ondo': 'SW', 'Ekiti': 'SW',
  'Abia': 'SE', 'Anambra': 'SE', 'Ebonyi': 'SE', 'Enugu': 'SE', 'Imo': 'SE',
  'Rivers': 'SS', 'Delta': 'SS', 'Edo': 'SS', 'Bayelsa': 'SS', 'Akwa Ibom': 'SS', 'Cross River': 'SS',
  'Abuja (FCT)': 'NC', 'Kogi': 'NC', 'Kwara': 'NC', 'Nasarawa': 'NC', 'Niger': 'NC', 'Benue': 'NC', 'Plateau': 'NC',
};

/// Simulated GIG. Prices follow GIG's pattern: same state is cheapest, then same
/// region, then cross-country, plus weight. Collecting at a GIG centre is cheaper.
class DemoDelivery implements DeliveryApi {
  final _rnd = Random();

  int _base(String from, String to) {
    if (from == to) return 3500;
    if (_zones[from] != null && _zones[from] == _zones[to]) return 4800;
    return 6900;
  }

  String _eta(String from, String to) => from == to ? '1–2 days' : (_zones[from] == _zones[to] ? '2–3 days' : '3–5 days');

  @override
  Future<List<DeliveryQuote>> quote({required String fromState, required String toState, required double kg, required int value}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final extra = (max(0, kg - 2) * 450).round();
    final b = _base(fromState, toState) + extra;
    return [DeliveryQuote('home', b, _eta(fromState, toState)), DeliveryQuote('centre', b - 1200, _eta(fromState, toState))];
  }

  @override
  Future<Shipment> book(Order o, {required Seller from, required Ship to, required String service}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final fs = storeState(from);
    return Shipment(
      orderId: o.id,
      waybill: '${1000000000 + _rnd.nextInt(899999999)}',
      service: service,
      fromName: from.name,
      fromCity: from.city,
      toName: to.name,
      toCity: '${to.city}, ${to.state}',
      toPhone: to.phone,
      price: app.fee,
      stage: 'booked',
      eta: _eta(fs, to.state),
      events: [TrackEvent('booked', 'Shipment created. GIG rider assigned for pickup', '${from.area}, ${from.city}', DateTime.now())],
    );
  }

  @override
  Future<Shipment> track(Shipment s) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return s..updated = DateTime.now();
  }

  @override
  Future<void> cancel(Shipment s) async {
    await Future.delayed(const Duration(milliseconds: 400));
    s
      ..stage = 'cancelled'
      ..events.add(TrackEvent('cancelled', 'Pickup cancelled by Agora', 'Agora operations', DateTime.now()));
  }

  /// Moves a demo shipment one step on, the way GIG scans would.
  static void advance(Shipment s) {
    final i = stageIndex(s.stage);
    if (i < 0 || i >= kShipStages.length - 1) return;
    final next = kShipStages[i + 1];
    final dest = s.toCity.split(',').first;
    final (title, where) = switch (next) {
      'picked' => ('Shipment collected from seller by GIG rider', s.fromCity),
      'transit' => ('Departed GIG hub. In transit to $dest', 'GIG hub, ${s.fromCity.split(',').last.trim()}'),
      'arrived' => (s.service == 'centre' ? 'Arrived. Ready for collection at GIG centre' : 'Arrived at GIG centre', 'GIG centre, $dest'),
      'out' => ('Out for delivery with courier', dest),
      _ => ('Delivered. Signed for by ${s.toName.split(' ').first}', s.toCity),
    };
    s
      ..stage = next
      ..events.add(TrackEvent(next, title, where, DateTime.now()))
      ..updated = DateTime.now();
    if (next == 'delivered') s.podName = s.toName;
  }
}

/* ---------------- Demo shipments for seller and admin views ---------------- */

DateTime _ago(int h) => DateTime.now().subtract(Duration(hours: h));

Shipment _demo(String id, String wb, String store, String from, String to, String toName, String stage, int price, {String service = 'home', int startH = 70}) {
  final events = <TrackEvent>[];
  final upto = stage == 'failed' ? stageIndex('out') : stageIndex(stage);
  final titles = {
    'booked': ('Shipment created. GIG rider assigned for pickup', from),
    'picked': ('Shipment collected from seller by GIG rider', from),
    'transit': ('Departed GIG hub. In transit', 'GIG hub, ${from.split(',').last.trim()}'),
    'arrived': ('Arrived at GIG centre', 'GIG centre, ${to.split(',').first}'),
    'out': ('Out for delivery with courier', to.split(',').first),
    'delivered': ('Delivered. Signed for by ${toName.split(' ').first}', to),
  };
  for (var i = 0; i <= upto; i++) {
    final k = kShipStages[i];
    events.add(TrackEvent(k, titles[k]!.$1, titles[k]!.$2, _ago(startH - i * (startH ~/ 6))));
  }
  if (stage == 'failed') events.add(TrackEvent('failed', 'Delivery attempt failed. Receiver not reachable', to.split(',').first, _ago(3)));
  return Shipment(orderId: id, waybill: wb, service: service, fromName: store, fromCity: from, toName: toName, toCity: to, toPhone: '0803 000 0000', price: price, stage: stage, eta: '2–3 days', events: events, updated: events.last.at)
    ..podName = stage == 'delivered' ? toName : null;
}

/// Shipments shown on the seller dashboard and in the admin console.
final List<Shipment> kDemoShipments = [
  _demo('AG0123470', '1204587731', 'Kuye Gadgets', 'Ikeja, Lagos', 'Wuse 2, Abuja (FCT)', 'Amaka Obi', 'transit', 6900),
  _demo('AG0123459', '1204587102', 'Kuye Gadgets', 'Ikeja, Lagos', 'Surulere, Lagos', 'Tobi Adeyemi', 'out', 3500, startH: 30),
  _demo('AG0123462', '1204586650', 'Kuye Gadgets', 'Ikeja, Lagos', 'GRA, Port Harcourt, Rivers', 'Ebi Douglas', 'delivered', 6900),
  _demo('AG0123458', '1204586011', 'Kuye Gadgets', 'Ikeja, Lagos', 'Yaba, Lagos', 'Kemi Bello', 'delivered', 3500, startH: 120),
  _demo('AG0123481', '1204588120', 'Store by Ella', 'Wuse 2, Abuja (FCT)', 'Lekki, Lagos', 'Tolu Alade', 'arrived', 5700, service: 'centre'),
  _demo('AG0123483', '1204588305', 'Chidera Electronics', 'Ikeja, Lagos', 'Ibadan, Oyo', 'Seun Ola', 'failed', 4800),
  _demo('AG0123485', '1204588416', 'Ìlú Leatherworks', 'Aba, Abia', 'Enugu, Enugu', 'Chioma Eze', 'booked', 4800, startH: 4),
  _demo('AG0123486', '1204588477', 'Ikeja Mobile Hub', 'Ikeja, Lagos', 'Ikorodu, Lagos', 'Femi Lawal', 'picked', 3500, startH: 10),
];

String agoLabel(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

String timeLabel(DateTime t) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '${t.day} ${m[t.month - 1]}, $h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'am' : 'pm'}';
}

/// Keeps a shipment fresh while its page is open: asks the backend every 60 seconds.
class ShipmentPoller {
  Timer? _t;
  void start(Shipment s, VoidCallback onUpdate) {
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 60), (_) async {
      if (s.done) return;
      try {
        final n = await deliveryApi.track(s);
        if (!identical(n, s)) {
          s
            ..stage = n.stage
            ..eta = n.eta
            ..podName = n.podName
            ..podPhoto = n.podPhoto;
          s.events
            ..clear()
            ..addAll(n.events);
        }
        onUpdate();
      } catch (_) {}
    });
  }

  void stop() => _t?.cancel();
}

/// A reusable colour for each stage.
Color stageColor(String s) => switch (s) {
      'delivered' => const Color(0xFF16A34A),
      'failed' => const Color(0xFFDC2626),
      'cancelled' => const Color(0xFF6B7280),
      'out' => const Color(0xFFD97706),
      _ => const Color(0xFF005AE6),
    };
