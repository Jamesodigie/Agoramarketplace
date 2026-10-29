import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'data.dart';
import 'icons.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

/// The public home of every store: agoramarket.ng/<handle>
const kDomain = 'agoramarket.ng';

const kAppDownload = 'https://github.com/Jamesodigie/Agoramarketplace/releases/latest/download/Agora.apk';

String storeUrl(String handle) => 'https://$kDomain/$handle';
String storeLink(String handle) => '$kDomain/$handle';

/// Names that can never be store links, because the site uses them.
const kReservedHandles = {
  'about', 'account', 'admin', 'api', 'app', 'apps', 'auth', 'blog', 'buy', 'buyer', 'cart', 'checkout', 'download', 'escrow', 'faq',
  'help', 'home', 'legal', 'login', 'logout', 'orders', 'pay', 'payment', 'privacy', 'register', 'search', 'sell', 'seller', 'sellers',
  'settings', 'shop', 'signin', 'signup', 'static', 'store', 'stores', 'support', 'terms', 'track', 'well-known', 'www', 'agora', 'agoramarket',
};

/// Every store the app knows about, including the seller's own once it is set up.
Iterable<Seller> allStores() sync* {
  yield* kSellers.values;
  if (app.verify != 'none') yield app.sel.toSeller();
}

Seller? storeByHandle(String handle) {
  final h = handle.toLowerCase();
  for (final s in allStores()) {
    if (s.slug == h) return s;
  }
  return null;
}

/// Checks a store link name. Returns null when it can be used.
String? handleProblem(String h) {
  if (h.length < 3) return 'Use at least 3 letters or numbers';
  if (h.length > 30) return 'Keep it under 30 characters';
  if (!RegExp(r'^[a-z0-9]+$').hasMatch(h)) return 'Only letters and numbers, no spaces';
  if (kReservedHandles.contains(h)) return 'That name is reserved';
  if (kSellers.values.any((s) => s.slug == h)) return 'Another store already uses this link';
  return null;
}

/// Turns a typed link name into a valid one as the seller types.
class HandleFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

/// Reads a store handle from a link path such as "/storebyella" or "/storebyella?fbclid=…".
String? handleFromPath(String? path) {
  if (path == null) return null;
  final segs = Uri.tryParse(path)?.pathSegments.where((s) => s.isNotEmpty).toList() ?? const [];
  if (segs.length != 1) return null;
  final h = segs.first.toLowerCase();
  return RegExp(r'^[a-z0-9]{3,30}$').hasMatch(h) ? h : null;
}

String _shareText(Seller s) => 'Shop ${s.name} on Agora. Your money stays in escrow until your order arrives.\n${storeUrl(s.slug)}';

Future<void> _open(String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok) toast('Could not open that app', icon: 'err');
}

Future<void> copyStoreLink(Seller s) async {
  await Clipboard.setData(ClipboardData(text: storeUrl(s.slug)));
  toast('Link copied: ${storeLink(s.slug)}', icon: 'copy');
}

/// The share sheet: link card, social apps, QR code.
Future<void> shareStore(BuildContext context, Seller s) => showSheet(
      context,
      title: 'Share your store',
      body: 'Post this link anywhere. Buyers tap it and land straight on your store.',
      child: _ShareBody(s),
    );

class _ShareBody extends StatefulWidget {
  final Seller s;
  const _ShareBody(this.s);
  @override
  State<_ShareBody> createState() => _ShareBodyState();
}

class _ShareBodyState extends State<_ShareBody> {
  bool qr = false;

  Seller get s => widget.s;

  Widget _app(String label, Widget glyph, Color bg, VoidCallback onTap, {Gradient? gradient}) => Expanded(
        child: Pressable(
          label: label,
          onTap: onTap,
          child: Column(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: gradient == null ? bg : null, gradient: gradient, borderRadius: BorderRadius.circular(18)),
              child: Center(child: glyph),
            ),
            const SizedBox(height: 7),
            Text(label, style: ts(12.5, c: C.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  Widget _letter(String t, {double size = 22}) => Text(t, style: ts(size, w: w7, c: Colors.white, h: 1));

  @override
  Widget build(BuildContext context) {
    final url = storeUrl(s.slug);
    final text = _shareText(s);
    final enc = Uri.encodeComponent(text);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Link card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.blue50, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          StoreAvatar(s, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: ts(15.5, w: w7), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: '$kDomain/', style: ts(14, c: C.muted)),
                  TextSpan(text: s.slug, style: ts(14, w: w7, c: C.blue)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          IconBtn('copy', label: 'Copy store link', onTap: () => copyStoreLink(s)),
        ]),
      ).rise(),
      const SizedBox(height: 18),
      Row(children: [
        _app('WhatsApp', Ic('msg', size: 26, color: Colors.white), const Color(0xFF25D366), () => _open('https://wa.me/?text=$enc')),
        _app('Instagram', Ic('insta', size: 26, color: Colors.white), Colors.black, () async {
          // Instagram has no link-sharing URL, so copy the link and open the system sheet.
          await Clipboard.setData(ClipboardData(text: url));
          toast('Link copied. Paste it in your bio or story', icon: 'copy');
          if (!kIsWeb) await Share.share(text, subject: s.name);
        }, gradient: const LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: [Color(0xFFFEC53A), Color(0xFFF2433A), Color(0xFFC2257E), Color(0xFF6A3BD8)])),
        _app('X', _letter('X'), Colors.black, () => _open('https://twitter.com/intent/tweet?text=$enc')),
        _app('Facebook', _letter('f', size: 28), const Color(0xFF1877F2), () => _open('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}')),
        _app('More', Ic('share', size: 24, color: C.ink), C.bg, () async {
          if (kIsWeb) {
            await copyStoreLink(s);
          } else {
            await Share.share(text, subject: s.name);
          }
        }),
      ]).rise(80),
      const SizedBox(height: 18),
      AnimatedSize(
        duration: const Duration(milliseconds: 320),
        curve: kEase,
        child: qr
            ? Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: C.line)),
                    child: QrImageView(
                      data: url,
                      size: 196,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: C.navy),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: C.navy),
                    ),
                  ).popIn(),
                  const SizedBox(height: 10),
                  Text('Print it for your shop counter, packaging or flyers.', textAlign: TextAlign.center, style: ts(13.5, c: C.muted)),
                ]),
              )
            : const SizedBox(width: double.infinity),
      ),
      Btn(qr ? 'Hide QR code' : 'Show QR code', icon: 'grid', kind: BtnKind.outline, onTap: () => setState(() => qr = !qr)),
    ]);
  }
}

/// The store link as a card on the seller's dashboard.
class StoreLinkCard extends StatelessWidget {
  final Seller s;
  const StoreLinkCard(this.s, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2F7BFF), Color(0xFF0047C2)]),
          boxShadow: const [BoxShadow(color: Color(0x330060FD), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your store link', style: ts(13, c: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 3),
              Text(storeLink(s.slug), style: ts(16, w: w7, c: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Pressable(
            label: 'Copy store link',
            onTap: () => copyStoreLink(s),
            child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)), child: Center(child: Ic('copy', size: 20, color: Colors.white))),
          ),
          const SizedBox(width: 8),
          Pressable(
            label: 'Share store',
            onTap: () => shareStore(context, s),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Ic('share', size: 18, color: C.blue), const SizedBox(width: 6), Text('Share', style: ts(14, w: w7, c: C.blue))]),
            ),
          ),
        ]),
      );
}
