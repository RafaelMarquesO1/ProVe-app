import 'package:flutter/material.dart';

class BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;

  const BounceButton({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.96,
  });

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (mounted) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!mounted) return;
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    if (mounted) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
