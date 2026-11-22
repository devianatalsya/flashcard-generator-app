import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/flashcard.dart';

class ApiService {
  // Backend URL Next.js production di Vercel
  static String baseUrl = 'https://flashcard-kamu.vercel.app';

  static Future<List<Flashcard>> generateFlashcards({
    required String inputType,
    required int cardCount,
    String? text,
    Uint8List? fileBytes,
    String? filePath,
    String? fileName,
  }) async {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$cleanBaseUrl/api/generate');

    final request = http.MultipartRequest('POST', uri);
    request.fields['inputType'] = inputType;
    request.fields['cardCount'] = cardCount.toString();

    if (inputType == 'file') {
      if (fileBytes != null && fileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: fileName,
          ),
        );
      } else if (filePath != null && fileName != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            filename: fileName,
          ),
        );
      } else {
        throw Exception('Pilih file PDF atau DOCX terlebih dahulu.');
      }
    } else {
      if (text == null || text.trim().isEmpty) {
        throw Exception('Masukkan materi terlebih dahulu.');
      }
      request.fields['text'] = text.trim();
    }

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw TimeoutException(
            'Koneksi timeout. Server membutuhkan waktu terlalu lama untuk merespons. Silakan coba lagi.',
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = utf8.decode(response.bodyBytes);

      Map<String, dynamic>? data;
      try {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        // Body bukan format JSON valid
      }

      if (response.statusCode != 200) {
        if (data != null && data.containsKey('error') && data['error'] != null) {
          throw Exception(data['error'].toString());
        }
        if (response.statusCode == 404) {
          throw Exception('Endpoint API tidak ditemukan di $cleanBaseUrl/api/generate (HTTP 404).');
        } else if (response.statusCode == 504) {
          throw Exception('Server timeout dari Vercel Gateway (HTTP 504). Coba kurangi materi atau jumlah kartu.');
        } else {
          throw Exception('Gagal memproses materi (HTTP ${response.statusCode}).');
        }
      }

      if (data == null) {
        throw Exception('Format respon server tidak valid (bukan JSON).');
      }

      if (!data.containsKey('flashcards')) {
        final errorMsg = data['error'] as String? ?? 'Respon server tidak memiliki data flashcard.';
        throw Exception(errorMsg);
      }

      final flashcardsRaw = data['flashcards'];
      if (flashcardsRaw is! List || flashcardsRaw.isEmpty) {
        throw Exception('Tidak ada flashcard yang berhasil dibuat oleh AI.');
      }

      return flashcardsRaw
          .map((item) => Flashcard.fromJson(item as Map<String, dynamic>))
          .toList();
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? 'Koneksi timeout.');
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server di $cleanBaseUrl.\n'
        'Pastikan perangkat terhubung ke internet dan backend Vercel aktif.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Gagal menghubungi server di $cleanBaseUrl (${e.message}).\n'
        'Pastikan perangkat memiliki koneksi internet aktif.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
