// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

void downloadCsvWeb(String csvData) {
  final bytes = Utf8Encoder().convert(csvData);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'gastos.csv')
    ..click();
  html.Url.revokeObjectUrl(url);
}
