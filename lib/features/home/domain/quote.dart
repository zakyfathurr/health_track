class QuoteData {
  final String text;
  final String author;

  const QuoteData({required this.text, required this.author});

  factory QuoteData.fromJson(Map<String, dynamic> json) =>
      QuoteData(text: json['q'] as String, author: json['a'] as String);
}
