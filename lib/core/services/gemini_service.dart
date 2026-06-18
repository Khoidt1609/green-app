// lib/core/services/gemini_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class GeminiAnalysisResult {
  final bool isValid;
  final String verdict; // 'approved' | 'rejected' | 'uncertain'
  final String explanation;
  final double confidence; // 0.0 → 1.0

  const GeminiAnalysisResult({
    required this.isValid,
    required this.verdict,
    required this.explanation,
    required this.confidence,
  });

  factory GeminiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return GeminiAnalysisResult(
      isValid: json['isValid'] as bool? ?? false,
      verdict: json['verdict'] as String? ?? 'uncertain',
      explanation: json['explanation'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory GeminiAnalysisResult.error() => const GeminiAnalysisResult(
    isValid: false,
    verdict: 'uncertain',
    explanation: 'Không thể phân tích ảnh lúc này. Admin sẽ duyệt thủ công.',
    confidence: 0.0,
  );
}

class GeminiService {
  static const _apiKey = 'AQ.Ab8RN6ICCxHwkBrl5cfYAahWWoEON3oeGmrFTTs-UFN4-gIMfg';
  static const _model = 'gemini-2.5-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  final _dio = Dio();

  Future<GeminiAnalysisResult> analyzeSubmission({
    required File imageFile,
    required String taskTitle,
    required String taskDescription,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final mimeType = _getMimeType(imageFile.path);

      print('[Gemini] Bắt đầu phân tích ảnh: ${imageFile.path}');

      // FIX 1: Prompt yêu cầu JSON ngắn gọn hơn, tránh bị cắt
      final prompt = '''
Bạn là hệ thống kiểm tra bằng chứng cho ứng dụng GreenStep.
Nhiệm vụ: "$taskTitle" - $taskDescription

Xem ảnh và trả về JSON (ngắn gọn, tối đa 100 ký tự cho explanation):
{"isValid":true,"verdict":"approved","explanation":"lý do","confidence":0.9}

Quy tắc verdict: "approved"=ảnh hợp lệ, "rejected"=không hợp lệ, "uncertain"=không chắc.
CHỈ trả JSON, không markdown, không text khác.
''';

      final response = await _dio.post(
        '$_baseUrl?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  }
                },
                {'text': prompt},
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            // FIX 2: Tăng maxOutputTokens để tránh JSON bị cắt giữa chừng
            'maxOutputTokens': 512,
            // FIX 3: Thêm stopSequences để Gemini dừng đúng sau dấu }
            'stopSequences': ['\n\n'],
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );

      print('[Gemini] Status: ${response.statusCode}');

      // Kiểm tra finishReason để phát hiện bị cắt
      final candidates = response.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        print('[Gemini] Không có candidates');
        return GeminiAnalysisResult.error();
      }

      final candidate = candidates[0] as Map<String, dynamic>;
      final finishReason = candidate['finishReason'] as String? ?? '';
      print('[Gemini] finishReason: $finishReason');

      // Nếu bị cắt do token limit → trả error ngay, không parse JSON thừa
      if (finishReason == 'MAX_TOKENS') {
        print('[Gemini] Bị cắt do MAX_TOKENS, tăng maxOutputTokens nếu cần');
        return GeminiAnalysisResult.error();
      }

      final text = candidate['content']['parts'][0]['text'] as String? ?? '';
      print('[Gemini] Raw response: $text');

      // Dọn sạch markdown nếu có
      String cleanJson = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Tìm JSON object
      final jsonStart = cleanJson.indexOf('{');
      final jsonEnd = cleanJson.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        print('[Gemini] Không tìm thấy JSON hợp lệ trong response');
        return GeminiAnalysisResult.error();
      }

      cleanJson = cleanJson.substring(jsonStart, jsonEnd + 1);
      print('[Gemini] Clean JSON: $cleanJson');

      final json = jsonDecode(cleanJson) as Map<String, dynamic>;
      final result = GeminiAnalysisResult.fromJson(json);
      print('[Gemini] Verdict: ${result.verdict} (${result.confidence})');
      return result;

    } on DioException catch (e) {
      print('[Gemini] DioException: ${e.response?.statusCode} — ${e.response?.data}');
      return GeminiAnalysisResult.error();
    } catch (e) {
      print('[Gemini] Lỗi không xác định: $e');
      return GeminiAnalysisResult.error();
    }
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}