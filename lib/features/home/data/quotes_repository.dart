import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/quote.dart';

/// DATA layer: ambil quote dari ZenQuotes.
class QuotesRepository {
  static const _todayUrl = 'https://zenquotes.io/api/today';
  static const _randomUrl = 'https://zenquotes.io/api/random';

  Future<QuoteData> fetchTodayQuote() => _fetch(_todayUrl);

  Future<QuoteData> fetchRandomQuote() => _fetch(_randomUrl);

  Future<QuoteData> _fetch(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil quote: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return QuoteData.fromJson(list.first as Map<String, dynamic>);
  }
}
