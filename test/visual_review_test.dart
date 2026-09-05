import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/overlays/menu_overlay.dart';
import 'package:turbo_traffic_rush/overlays/paywall_overlay.dart';
import 'package:turbo_traffic_rush/progression/subscription.dart';
import 'driving_engine_test.dart' show makeGame;
void main() {
  testWidgets('export review screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final bytes = File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytesSync();
    final loader = FontLoader('Review')..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
    await icons.load();
    final game = await makeGame();
    game.progression.onRunStarted();
    game.progression.purchases.debugSetOffers(const [
      SubscriptionOffer(id:'m', period:PassPeriod.monthly, priceLabel:'149,99 TL', price:149.99),
      SubscriptionOffer(id:'y', period:PassPeriod.annual, priceLabel:'999,99 TL', price:999.99,pricePerMonthLabel:'83,33 TL'),
    ]);
    for(final entry in {'menu':MenuOverlay(game:game),'pass':PaywallOverlay(game:game)}.entries) {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(theme:ThemeData.dark().copyWith(textTheme:ThemeData.dark().textTheme.apply(fontFamily:'Review')),
        home:Scaffold(backgroundColor:const Color(0xFF101D30),body:RepaintBoundary(key:key,child:entry.value))));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final pic=await (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio:2);
        final data=await pic.toByteData(format:ui.ImageByteFormat.png);
        File('/tmp/ttr-${entry.key}.png').writeAsBytesSync(data!.buffer.asUint8List());
        pic.dispose();
      });
    }
    game.onRemove();
  });
}
