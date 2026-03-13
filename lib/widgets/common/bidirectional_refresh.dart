import 'package:flutter/material.dart';

enum _RefreshEdge { top, bottom }

class BidirectionalRefresh extends StatefulWidget {
  static const double defaultTriggerDistance = 90;

  final Widget child;
  final Future<void> Function() onRefresh;
  final double triggerDistance;

  const BidirectionalRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.triggerDistance = defaultTriggerDistance,
  });

  @override
  State<BidirectionalRefresh> createState() => _BidirectionalRefreshState();
}

class _BidirectionalRefreshState extends State<BidirectionalRefresh> {
  double _topPullDistance = 0;
  double _bottomPullDistance = 0;
  bool _isRefreshing = false;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isRefreshing) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      _resetPullDistance();
      return false;
    }

    if (notification is OverscrollNotification) {
      final metrics = notification.metrics;
      final isAtTop = metrics.extentBefore == 0;
      final isAtBottom = metrics.extentAfter == 0;

      if (!isAtTop && !isAtBottom) {
        return false;
      }

      var shouldRefresh = false;
      setState(() {
        if (isAtTop) {
          _topPullDistance += notification.overscroll.abs();
          shouldRefresh = _topPullDistance >= widget.triggerDistance;
        }
        if (isAtBottom) {
          _bottomPullDistance += notification.overscroll.abs();
          shouldRefresh =
              shouldRefresh || _bottomPullDistance >= widget.triggerDistance;
        }
      });
      if (shouldRefresh) {
        _runRefresh();
      }
      return false;
    }

    if (notification is ScrollEndNotification) {
      _resetPullDistance();
    }

    return false;
  }

  Future<void> _runRefresh() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      await widget.onRefresh();
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRefreshing = false;
        _topPullDistance = 0;
        _bottomPullDistance = 0;
      });
    }
  }

  void _resetPullDistance() {
    if (_topPullDistance == 0 && _bottomPullDistance == 0) {
      return;
    }

    setState(() {
      _topPullDistance = 0;
      _bottomPullDistance = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topProgress = (_topPullDistance / widget.triggerDistance).clamp(
      0.0,
      1.0,
    );
    final bottomProgress = (_bottomPullDistance / widget.triggerDistance).clamp(
      0.0,
      1.0,
    );

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        children: [
          widget.child,
          _RefreshIndicatorOverlay(
            alignment: Alignment.topCenter,
            progress: _isRefreshing ? 1 : topProgress,
            visible: _isRefreshing || _topPullDistance > 0,
            edge: _RefreshEdge.top,
          ),
          _RefreshIndicatorOverlay(
            alignment: Alignment.bottomCenter,
            progress: _isRefreshing ? 1 : bottomProgress,
            visible: _isRefreshing || _bottomPullDistance > 0,
            edge: _RefreshEdge.bottom,
          ),
        ],
      ),
    );
  }
}

class _RefreshIndicatorOverlay extends StatelessWidget {
  final Alignment alignment;
  final double progress;
  final bool visible;
  final _RefreshEdge edge;

  const _RefreshIndicatorOverlay({
    required this.alignment,
    required this.progress,
    required this.visible,
    required this.edge,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final indicator = RefreshProgressIndicator(value: progress);
    final padding = edge == _RefreshEdge.top
        ? const EdgeInsets.only(top: 12)
        : const EdgeInsets.only(bottom: 12);

    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: padding,
            child: SizedBox.square(dimension: 28, child: indicator),
          ),
        ),
      ),
    );
  }
}
