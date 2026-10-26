// Mobile / Desktop implementation — uses dart:io and path_provider.
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveBytes(String filename, List<int> bytes) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}

Future<void> deleteFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {}
}
