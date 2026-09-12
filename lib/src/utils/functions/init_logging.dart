import 'package:logging/logging.dart';

final Logger logger = Logger.root;
void initLogging() {
  final expression = RegExp(r'[\[\]]');
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
  print('[${record.level.name}][${record.time}]: ${record.stackTrace.toString().split('\n')[1].replaceAll(expression, '')}: ${record.message}');
});
}