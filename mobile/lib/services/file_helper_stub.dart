// Web stub — file I/O not available on Flutter Web.
Future<String> saveBytes(String filename, List<int> bytes) async {
  throw UnsupportedError('File saving is not supported on Flutter Web.');
}

Future<void> deleteFile(String path) async {}
