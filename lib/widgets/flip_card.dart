import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/flashcard.dart';

class FlipCardWidget extends StatefulWidget {
  final Flashcard card;
  final int index;

  const FlipCardWidget({
    super.key,
    required this.card,
    required this.index,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.25, 1.0, 0.5, 1.0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardNumber = (widget.index + 1).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final isFront = _animation.value < 0.5;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 3D Perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFront
                ? _buildFrontFace(cardNumber)
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBackFace(cardNumber),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFrontFace(String cardNumber) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top header row
              Container(
                padding: const EdgeInsets.only(bottom: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cardNumber,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF737373),
                      ),
                    ),
                    Text(
                      'PERTANYAAN',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: const Color(0xFF737373),
                      ),
                    ),
                  ],
                ),
              ),
              // Question text
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.card.question,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A0A0A),
                    height: 1.35,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          // Bottom hint row
          Container(
            padding: const EdgeInsets.only(top: 16),
            margin: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Klik untuk membalik',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackFace(String cardNumber) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top header row
              Container(
                padding: const EdgeInsets.only(bottom: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cardNumber,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF737373),
                      ),
                    ),
                    Text(
                      'JAWABAN',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                  ],
                ),
              ),
              // Answer text
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.card.answer,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF171717),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          // Bottom hint row
          Container(
            padding: const EdgeInsets.only(top: 16),
            margin: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E5E5), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Klik untuk membalik',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
