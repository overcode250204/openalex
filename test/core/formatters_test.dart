import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/utils/formatters.dart';

void main() {
  group('Formatters', () {
    group('truncateText', () {
      test('returns the original text when within limit', () {
        expect(Formatters.truncateText('Hello', 10), 'Hello');
      });

      test('returns the original text when length equals limit exactly', () {
        expect(Formatters.truncateText('Hello', 5), 'Hello');
      });

      test('truncates and appends ellipsis when text exceeds limit', () {
        expect(Formatters.truncateText('Hello World', 5), 'Hello...');
      });

      test('handles empty string', () {
        expect(Formatters.truncateText('', 10), '');
      });

      test('truncates correctly with limit of 1', () {
        expect(Formatters.truncateText('AB', 1), 'A...');
      });
    });

    group('formatCitation', () {
      test('formats zero correctly', () {
        expect(Formatters.formatCitation(0), '0');
      });

      test('formats numbers below thousand without separator', () {
        expect(Formatters.formatCitation(999), '999');
      });

      test('formats thousands with decimal separator', () {
        final result = Formatters.formatCitation(1000);
        expect(result, contains('1'));
        expect(result, contains('000'));
      });

      test('formats large numbers with decimal pattern', () {
        final result = Formatters.formatCitation(1234567);
        expect(result, isNotEmpty);
        expect(result, contains('1'));
      });
    });

    group('formatNumber', () {
      test('formats zero', () {
        expect(Formatters.formatNumber(0), '0');
      });

      test('does not add comma for numbers below 1000', () {
        expect(Formatters.formatNumber(999), '999');
      });

      test('adds comma for thousands', () {
        expect(Formatters.formatNumber(1000), '1,000');
      });

      test('adds commas for millions', () {
        expect(Formatters.formatNumber(1000000), '1,000,000');
      });

      test('formats complex number correctly', () {
        expect(Formatters.formatNumber(12345678), '12,345,678');
      });
    });

    group('formatCompactAxis', () {
      test('returns string representation for values below 1000', () {
        expect(Formatters.formatCompactAxis(0), '0');
        expect(Formatters.formatCompactAxis(999), '999');
      });

      test('formats exact thousand as integer K', () {
        expect(Formatters.formatCompactAxis(1000), '1K');
        expect(Formatters.formatCompactAxis(5000), '5K');
      });

      test('formats non-round thousands with one decimal K', () {
        expect(Formatters.formatCompactAxis(1500), '1.5K');
        expect(Formatters.formatCompactAxis(2300), '2.3K');
      });

      test('formats very large numbers in K', () {
        expect(Formatters.formatCompactAxis(10000), '10K');
        expect(Formatters.formatCompactAxis(100000), '100K');
      });
    });
  });
}
