import 'dart:convert';
import 'package:flutter/services.dart';

class VietnamGeographyApi {
  static List<dynamic>? _cachedData;

  Future<List<dynamic>> _loadData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/data/vietnam_provinces.json');
      _cachedData = jsonDecode(jsonString) as List;
      return _cachedData!;
    } catch (e) {
      print('❌ Lỗi load JSON: $e');
      _cachedData = [];
      return [];
    }
  }

  Future<List<dynamic>> getProvinces() async {
    try {
      final data = await _loadData();
      final provincesMap = <String, dynamic>{};

      for (var item in data) {
        if (item is! Map<String, dynamic>) continue;
        
        final columns = item['columns'] as List?;
        if (columns == null || columns.isEmpty) continue;

        final provinceName = columns[0]?.toString().trim();
        if (provinceName == null || provinceName.isEmpty) continue;

        if (!provincesMap.containsKey(provinceName)) {
          provincesMap[provinceName] = {
            'name': provinceName,
            'code': provinceName,
          };
        }
      }

      final provinces = provincesMap.values.toList();
      provinces.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
      print('✅ Load ${provinces.length} provinces successfully');
      return provinces;
    } catch (e) {
      print('❌ Lỗi getProvinces: $e');
      return [];
    }
  }

  Future<List<dynamic>> getDistricts(String province) async {
    try {
      final data = await _loadData();
      final districtsMap = <String, dynamic>{};

      for (var item in data) {
        if (item is! Map<String, dynamic>) continue;
        
        final columns = item['columns'] as List?;
        if (columns == null || columns.length < 2) continue;

        final provinceName = columns[0]?.toString().trim();
        if (provinceName != province) continue;

        final districtName = columns[1]?.toString().trim();
        if (districtName == null || districtName.isEmpty) continue;

        if (!districtsMap.containsKey(districtName)) {
          districtsMap[districtName] = {
            'name': districtName,
            'code': districtName,
          };
        }
      }

      final districts = districtsMap.values.toList();
      districts.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
      print('✅ Load ${districts.length} districts for $province');
      return districts;
    } catch (e) {
      print('❌ Lỗi getDistricts: $e');
      return [];
    }
  }
}