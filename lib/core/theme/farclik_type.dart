
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema tipográfico central do FARCLIK.
class FarclikType {
  FarclikType._();

  static const Color ink = Color(0xFF173B57);
  static const Color body = Color(0xFF465467);
  static const Color muted = Color(0xFF64748B);

  /// Título principal e saudação.
  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.4,
        color: ink,
      );

  /// Título de secção.
  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: -0.2,
        color: ink,
      );

  /// Título de cartão ou item.
  static TextStyle get title => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.1,
        color: ink,
      );

  /// Texto normal.
  static TextStyle get text => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: body,
      );

  /// Legendas e textos de apoio.
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: muted,
      );

  /// Etiquetas e campos.
  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 0.2,
        color: muted,
      );

  /// Preços, códigos e números.
  static TextStyle get number => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.2,
        color: ink,
        fontFeatures: const [
          FontFeature.tabularFigures(),
        ],
      );
}
