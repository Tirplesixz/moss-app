import 'package:flutter/material.dart';

/// Represents an Eisenhower Matrix board with customizable quadrant names.
@immutable
class MatrixBoard {
  final String id;
  final String name;
  final int iconCode;
  final int colorValue;
  final String q1Name;
  final String q2Name;
  final String q3Name;
  final String q4Name;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const MatrixBoard({
    required this.id,
    required this.name,
    this.iconCode = 0xe900,
    this.colorValue = 0xFFF5A623,
    this.q1Name = 'สำคัญและเร่งด่วน',
    this.q2Name = 'สำคัญ',
    this.q3Name = 'เร่งด่วน',
    this.q4Name = 'สักวันหนึ่ง',
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  MatrixBoard copyWith({
    String? name,
    int? iconCode,
    int? colorValue,
    String? q1Name,
    String? q2Name,
    String? q3Name,
    String? q4Name,
    bool? isDefault,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return MatrixBoard(
      id: id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      q1Name: q1Name ?? this.q1Name,
      q2Name: q2Name ?? this.q2Name,
      q3Name: q3Name ?? this.q3Name,
      q4Name: q4Name ?? this.q4Name,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code': iconCode,
      'color_value': colorValue,
      'q1_name': q1Name,
      'q2_name': q2Name,
      'q3_name': q3Name,
      'q4_name': q4Name,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory MatrixBoard.fromMap(Map<String, dynamic> map) {
    return MatrixBoard(
      id: map['id'] as String,
      name: map['name'] as String,
      iconCode: (map['icon_code'] as int?) ?? 0xe900,
      colorValue: (map['color_value'] as int?) ?? 0xFFF5A623,
      q1Name: (map['q1_name'] as String?) ?? 'สำคัญและเร่งด่วน',
      q2Name: (map['q2_name'] as String?) ?? 'สำคัญ',
      q3Name: (map['q3_name'] as String?) ?? 'เร่งด่วน',
      q4Name: (map['q4_name'] as String?) ?? 'สักวันหนึ่ง',
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
    );
  }

  static List<MatrixBoard> createDefaults() {
    final now = DateTime.now().toUtc();
    return [
      MatrixBoard(
        id: 'default_my_matrix',
        name: 'เมทริกซ์ของฉัน',
        iconCode: Icons.grid_view_rounded.codePoint,
        colorValue: 0xFFF5A623,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      MatrixBoard(
        id: 'board_work',
        name: 'งานและออฟฟิศ',
        iconCode: Icons.work_outline_rounded.codePoint,
        colorValue: 0xFF0A84FF,
        q1Name: 'ด่วนมาก (ส่งวันนี้)',
        q2Name: 'วางแผนระยะยาว',
        q3Name: 'มอบหมาย/ตามงาน',
        q4Name: 'ไอเดียสำรอง',
        createdAt: now,
        updatedAt: now,
      ),
      MatrixBoard(
        id: 'board_personal',
        name: 'ชีวิตส่วนตัว',
        iconCode: Icons.favorite_outline_rounded.codePoint,
        colorValue: 0xFFFF453A,
        q1Name: 'เรื่องด่วนครอบครัว',
        q2Name: 'สุขภาพ & พักผ่อน',
        q3Name: 'ธุระนอกบ้าน',
        q4Name: 'สิ่งที่อยากทำ',
        createdAt: now,
        updatedAt: now,
      ),
      MatrixBoard(
        id: 'board_study',
        name: 'การเรียนรู้ & โปรเจกต์',
        iconCode: Icons.school_outlined.codePoint,
        colorValue: 0xFF34D399,
        q1Name: 'การบ้าน/ส่งสอบ',
        q2Name: 'ทบทวนบทเรียน',
        q3Name: 'หาข้อมูลเพิ่ม',
        q4Name: 'คอร์สที่สนใจ',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
