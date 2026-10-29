import 'package:flutter_test/flutter_test.dart';
import 'package:agora/data.dart';
import 'package:agora/links.dart';

void main() {
  test('store link names come from store names', () {
    expect(handleFrom('Store by Ella'), 'storebyella');
    expect(handleFrom('Ìlú Leatherworks'), 'iluleatherworks');
    expect(storeLink('storebyella'), 'agoramarket.ng/storebyella');
  });
  test('links open the right store', () {
    expect(handleFromPath('/storebyella'), 'storebyella');
    expect(handleFromPath('/StoreByElla?fbclid=abc'), 'storebyella');
    expect(handleFromPath('/'), isNull);
    expect(handleFromPath('/a/b'), isNull);
    expect(storeByHandle('storebyella')?.name, 'Store by Ella');
    expect(storeByHandle('nobodyhere'), isNull);
  });
  test('store link names are checked', () {
    expect(handleProblem('kuyegadgets'), isNull);
    expect(handleProblem('ab'), isNotNull);
    expect(handleProblem('admin'), isNotNull);
    expect(handleProblem('storebyella'), isNotNull);
  });
}
