import 'dart:convert';
import 'package:flutter/services.dart';

class VietnamGeographyApi {
  static List<dynamic>? _cachedData;

  // Lấy dữ liệu từ asset file
  Future<List<dynamic>> _loadData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }
    
    try {
      final jsonString = await rootBundle.loadString('data/vietnam_provinces.json');
      _cachedData = jsonDecode(jsonString) as List;
      return _cachedData!;
    } catch (e) {
      throw Exception('Failed to load Vietnam geography data: $e');
    }
  }

  // Lấy danh sách tỉnh/thành phố unique
  Future<List<dynamic>> getProvinces() async {
    try {
      final data = await _loadData();
      final provincesMap = <String, dynamic>{};
      
      for (var item in data) {
        final columns = item['columns'] as List?;
        if (columns != null && columns.isNotEmpty) {
          final provinceName = columns[0].toString();
          if (!provincesMap.containsKey(provinceName)) {
            provincesMap[provinceName] = {
              'name': provinceName,
              'code': provinceName,
            };
          }
        }
      }
      
      final provinces = provincesMap.values.toList();
      provinces.sort((a, b) => a['name'].compareTo(b['name']));
      return provinces;
    } catch (e) {
      throw Exception('Failed to parse provinces: $e');
    }
  }

  // Lấy danh sách huyện/quận của một tỉnh
  Future<List<dynamic>> getDistricts(String province) async {
    try {
      final data = await _loadData();
      final districtsMap = <String, dynamic>{};
      
      for (var item in data) {
        final columns = item['columns'] as List?;
        if (columns != null && 
            columns.length >= 2 && 
            columns[0].toString() == province) {
          final districtName = columns[1].toString();
          if (!districtsMap.containsKey(districtName)) {
            districtsMap[districtName] = {
              'name': districtName,
              'code': districtName,
            };
          }
        }
      }
      
      final districts = districtsMap.values.toList();
      districts.sort((a, b) => a['name'].compareTo(b['name']));
      return districts;

    } catch (e) {
      throw Exception('Failed to parse districts for $province: $e');
    }
  }
}
