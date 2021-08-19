import 'dart:convert';
import 'dart:io';

import 'package:intl_converter/intl_converter.dart';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';
// import 'package:shell/shell.dart';

final String defClassFileName = 'strings_define.dart';
final String jsonConfigFileName = 'intl_converter.json';
final Map<String, String> helps = {
  'scan-dir': 'the path where to scan android style strings-xx.xml files',
  'out-dir': 'ARB and dart file output path',
  'gen-class': 'the dart class name of auto generated',
  'file-name':
      'the dart file name of auto generated.default is:"$defClassFileName"',
  'dev-locale': 'use which locale content to generate default dart class',
};

main(List<String> args) async {
  String? scanDir;
  String? outDir;
  String? genClass;
  String? genClassFileName;
  String? devLocaleStr;
  var parser = new ArgParser();
  parser.addOption('scan-dir',
      callback: (x) => scanDir = x, help: helps['scan-dir']);
  parser.addOption('out-dir',
      callback: (x) => outDir = x, help: helps['out-dir']);
  parser.addOption('gen-class',
      callback: (x) => genClass = x, help: helps['gen-class']);
  parser.addOption('file-name',
      defaultsTo: defClassFileName,
      callback: (x) => genClassFileName = x,
      help: helps['file-name']);
  parser.addOption('dev-locale',
      callback: (x) => devLocaleStr = x, help: helps['dev-locale']);
  parser.parse(args);

  if (args.length == 0) {
    Map<String, dynamic>? json = readConfigFileJson();
    if (json == null) {
      print('''
      can't find "$jsonConfigFileName" config file. and no valide args
      ''');
      print(parser.usage);
      exit(0);
    }
    scanDir = json['scan-dir'];
    outDir = json['out-dir'];
    genClass = json['gen-class'];
    genClassFileName = json['file-name'];
    devLocaleStr = json['dev-locale'];
  }
  if (scanDir == null ||
      outDir == null ||
      genClass == null ||
      devLocaleStr == null) {
    print(parser.usage);
    exit(0);
  }
  Locale devLocale = Locale.parse(devLocaleStr!);
  if (devLocale.isEmpty()) {
    print('--dev-locale invalide : $devLocaleStr');
    print(parser.usage);
    exit(0);
  }
  final File genClassFile =
      File(path.join(path.absolute(outDir!), genClassFileName));
  IntlBuilder builder = IntlBuilder(
      scanDir: path.absolute(scanDir!),
      outDir: path.absolute(outDir!),
      genClass: genClass,
      genClassFile: genClassFile,
      devLocale: devLocale);
  BuildResult result = builder.build();
  if (result.isOk) {
    // var shell = Shell();
    final cmd = 'flutter';
    List<String> args = [
      'packages',
      'pub',
      'run',
      'intl_generator:generate_from_arb',
      '--output-dir=$outDir',
      '--no-use-deferred-loading',
      'lib/i18n/gen/$genClassFileName',
    ];

    for (String fileName in result.arbFilenNames) {
      args.add('$outDir/$fileName');
      print('$outDir/$fileName');
    }
    var results = await Process.run(cmd, args);
    if (results.exitCode != 0) {
      print('Error! exitCode: ${results.exitCode}, message: ${results.stderr}');
    } else {
      print('Build done! Please check the outDir:$outDir');
    }
  }
}

Map<String, dynamic>? readConfigFileJson() {
  File file = File(path.join(path.current, jsonConfigFileName));
  print(file.path);
  if (!file.existsSync()) {
    return null;
  }
  return jsonDecode(file.readAsStringSync());
}
