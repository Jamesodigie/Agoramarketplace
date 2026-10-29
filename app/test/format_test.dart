import 'package:flutter_test/flutter_test.dart';
import 'package:agora/state.dart';

void main() {
  test('formats naira with thousands separators', () {
    expect(naira(203000), '₦203,000');
    expect(naira(3000), '₦3,000');
    expect(naira(310000), '₦310,000');
  });
  test('builds store links and initials', () {
    expect(slugify('Kuye Gadgets Hub'), 'kuye-gadgets-hub');
    expect(slugify('Ìlú Leatherworks'), 'ilu-leatherworks');
    expect(initials('Chidera Electronics'), 'CE');
  });
}
