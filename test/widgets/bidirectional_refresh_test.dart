import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/widgets/common/bidirectional_refresh.dart';

void main() {
  Future<BuildContext> pumpRefreshHarness(
    WidgetTester tester, {
    required Future<void> Function() onRefresh,
  }) {
    late BuildContext childContext;

    return tester
        .pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BidirectionalRefresh(
                onRefresh: onRefresh,
                child: Builder(
                  builder: (context) {
                    childContext = context;
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        )
        .then((_) => childContext);
  }

  OverscrollNotification topOverscroll(BuildContext context) {
    return OverscrollNotification(
      metrics: FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 500,
        pixels: 0,
        viewportDimension: 300,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      ),
      context: context,
      overscroll: -120,
    );
  }

  OverscrollNotification bottomOverscroll(BuildContext context) {
    return OverscrollNotification(
      metrics: FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 500,
        pixels: 500,
        viewportDimension: 300,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      ),
      context: context,
      overscroll: 120,
    );
  }

  testWidgets('refresh triggers from top overscroll', (tester) async {
    var refreshCount = 0;
    final childContext = await pumpRefreshHarness(
      tester,
      onRefresh: () async {
        refreshCount++;
      },
    );

    topOverscroll(childContext).dispatch(childContext);
    await tester.pump();

    expect(refreshCount, 1);
  });

  testWidgets('refresh triggers from bottom overscroll', (tester) async {
    var refreshCount = 0;
    final childContext = await pumpRefreshHarness(
      tester,
      onRefresh: () async {
        refreshCount++;
      },
    );

    bottomOverscroll(childContext).dispatch(childContext);
    await tester.pump();

    expect(refreshCount, 1);
  });
}
