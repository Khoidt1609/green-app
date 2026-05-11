import 'dart:convert';
import 'package:http/http.dart' as http;


class VietnamGeographyApi {
  final String baseUrl;
  VietnamGeographyApi({this.baseUrl = 'https://provinces.open-api.vn/api'});

  Future<List<dynamic>> fetchProvinces() async {
    final response = await http.get(Uri.parse('$baseUrl/p/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load provinces');
    }
  }

  Future<List<dynamic>> fetchDistricts(String provinceCode) async {
    final response = await http.get(Uri.parse('$baseUrl/p/$provinceCode?depth=2'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['districts'] ?? [];
    } else {
      throw Exception('Failed to load districts');
    }
  }
}
