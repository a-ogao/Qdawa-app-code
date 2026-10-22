import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Downloads an encrypted report PDF and opens it with the device viewer.
Future<String?> downloadAndOpenReportPdf(String downloadUrl) async {
  final uri = Uri.parse(downloadUrl);
  final response = await http.get(uri);

  if (response.statusCode != 200) {
    return 'Download failed (HTTP ${response.statusCode}).';
  }

  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/quikdawa_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
  );
  await file.writeAsBytes(response.bodyBytes);

  final result = await OpenFilex.open(file.path);
  if (result.type == ResultType.done) {
    return null;
  }

  return result.message.isNotEmpty
      ? result.message
      : 'Could not open the downloaded PDF.';
}

/// Fallback: open URL in external browser when direct download fails.
Future<bool> openReportDownloadUrl(String downloadUrl) async {
  final uri = Uri.parse(downloadUrl);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
