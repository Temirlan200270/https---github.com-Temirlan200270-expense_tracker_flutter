// SSS UI Audit — эвристики для PR (motion governor + сырые цвета + дубли hero).
// Запуск из корня репозитория: dart tool/sss_ui_audit.dart [--strict]
// Документация: docs/SSS_UI_SYSTEM_V2.md §8
//
// Игнор всего файла: первая строка // sss-ui-audit-ignore-file
// Игнор строки: в конце строки // sss-ui-audit-ignore

import 'dart:io';

void main(List<String> args) {
  final strict = args.contains('--strict');
  final root = _resolveRepoRoot();
  final findings = <_Finding>[];

  final libRoots = _collectLibRoots(root);
  for (final lib in libRoots) {
    _auditDirectory(lib, lib, findings);
  }

  findings.sort((a, b) {
    final c = a.filePath.compareTo(b.filePath);
    if (c != 0) return c;
    return a.line.compareTo(b.line);
  });

  stderr.writeln('SSS UI Audit (repo: ${root.path})');
  stderr.writeln('=' * 60);

  var errors = 0;
  var warnings = 0;
  for (final f in findings) {
    final label = f.severity == _Severity.error ? 'ERROR' : 'WARN';
    stderr.writeln('[$label] ${f.filePath}:${f.line} — ${f.message}');
    if (f.severity == _Severity.error) {
      errors++;
    } else {
      warnings++;
    }
  }

  if (findings.isEmpty) {
    stderr.writeln('OK — нарушений не найдено.');
  } else {
    stderr.writeln('=' * 60);
    stderr.writeln('Итого: $errors error(s), $warnings warning(s)');
  }

  final fail = errors > 0 || (strict && warnings > 0);
  exit(fail ? 1 : 0);
}

Directory _resolveRepoRoot() {
  try {
    final scriptPath = Platform.script.toFilePath();
    final scriptDir = File(scriptPath).parent;
    if (scriptDir.path.endsWith('tool')) {
      final candidate = scriptDir.parent;
      if (Directory('${candidate.path}${Platform.pathSeparator}packages')
          .existsSync()) {
        return candidate;
      }
    }
  } catch (_) {
    // ignore, fallback below
  }

  var cwd = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (Directory('${cwd.path}${Platform.pathSeparator}packages')
        .existsSync()) {
      return cwd;
    }
    final parent = cwd.parent;
    if (parent.path == cwd.path) break;
    cwd = parent;
  }
  stderr.writeln('Не найден корень репозитория (ожидается каталог с packages/).');
  exit(2);
}

List<Directory> _collectLibRoots(Directory root) {
  final packages = Directory('${root.path}${Platform.pathSeparator}packages');
  if (!packages.existsSync()) return [];
  final out = <Directory>[];
  for (final entity in packages.listSync(followLinks: false)) {
    if (entity is! Directory) continue;
    final lib = Directory('${entity.path}${Platform.pathSeparator}lib');
    if (lib.existsSync()) out.add(lib);
  }
  return out;
}

void _auditDirectory(Directory dir, Directory libRoot, List<_Finding> out) {
  for (final entity in dir.listSync(followLinks: false)) {
    if (entity is Directory) {
      if (entity.path.contains('.dart_tool')) continue;
      _auditDirectory(entity, libRoot, out);
    } else if (entity is File && entity.path.endsWith('.dart')) {
      final base = entity.uri.pathSegments.last;
      if (base.endsWith('.g.dart') ||
          base.endsWith('.freezed.dart') ||
          base.endsWith('.gr.dart')) {
        continue;
      }
      _auditFile(entity, libRoot, out);
    }
  }
}

final _forbiddenCurves = RegExp(
  r'Curves\.(bounce|elastic)\w*',
  caseSensitive: true,
);

/// Вызовы эффектов flutter_animate с bounce/elastic.
final _animateBounceElastic = RegExp(
  r'\.(bounce|elastic)\s*\(',
  caseSensitive: true,
);

final _rawArgbColor = RegExp(
  r'Color\s*\(\s*0x[0-9A-Fa-f]{8}\s*\)',
);

final _homeWalletHeroCard = RegExp(r'homeWalletHeroCard\s*\(');

final _listTileCtor = RegExp(r'\bListTile\s*\(');

/// Граница примитивов: только пакеты features_* (app/shell — отдельные контракты).
void _auditFeatureBoundaryPrimitives({
  required String codeOnly,
  required String absolutePath,
  required String rel,
  required int lineNumber,
  required List<_Finding> out,
}) {
  final norm = absolutePath.replaceAll(r'\', '/');
  if (!norm.contains('/packages/features_')) return;
  if (norm.contains('/ui_components/lib/')) return;

  if (_listTileCtor.hasMatch(codeOnly)) {
    out.add(_Finding(
      _Severity.warning,
      rel,
      lineNumber,
      'ListTile во фиче: используй SettingsTile / CompactRow / строку на InkWell (DESIGN_SYSTEM §7, SssScreenContract).',
    ));
  }

  final hasScaffold = codeOnly.contains('Scaffold(');
  final okScaffold = codeOnly.contains('PrimaryScaffold(') ||
      codeOnly.contains('ScaffoldMessenger') ||
      codeOnly.contains('Scaffold.of');
  if (hasScaffold && !okScaffold) {
    out.add(_Finding(
      _Severity.warning,
      rel,
      lineNumber,
      'Scaffold во фиче: предпочитай PrimaryScaffold (+ SssScreenContract).',
    ));
  }
}

void _auditFile(File file, Directory libRoot, List<_Finding> out) {
  final rel = _relativeToPackages(file.path, libRoot);
  final lines = file.readAsLinesSync();

  if (lines.isNotEmpty &&
      lines.first.trim() == '// sss-ui-audit-ignore-file') {
    return;
  }

  var heroCardCount = 0;
  for (var i = 0; i < lines.length; i++) {
    final lineNumber = i + 1;
    var line = lines[i];
    if (line.contains('// sss-ui-audit-ignore')) continue;

    final codeOnly = _stripTrailingLineComment(line);
    if (_forbiddenCurves.hasMatch(codeOnly)) {
      out.add(_Finding(
        _Severity.error,
        rel,
        lineNumber,
        'Запрещённая кривая (bounce/elastic). Используй AppMotion.curve.',
      ));
    }
    if (_animateBounceElastic.hasMatch(codeOnly)) {
      out.add(_Finding(
        _Severity.error,
        rel,
        lineNumber,
        'Запрещённый эффект .bounce / .elastic. См. DESIGN_SYSTEM + AppMotion.',
      ));
    }

    if (_rawArgbColor.hasMatch(codeOnly)) {
      final severity = _rawColorSeverity(file.path);
      if (severity != null) {
        out.add(_Finding(
          severity,
          rel,
          lineNumber,
          'Сырой Color(0x…). Предпочитай colorScheme / токены темы (см. DESIGN_SYSTEM §6).',
        ));
      }
    }

    heroCardCount += _homeWalletHeroCard.allMatches(codeOnly).length;

    _auditFeatureBoundaryPrimitives(
      codeOnly: codeOnly,
      absolutePath: file.path,
      rel: rel,
      lineNumber: lineNumber,
      out: out,
    );
  }

  // Допускаем 2 ветки в одном файле (например FTUE + loaded); 3+ — подозрительно.
  if (heroCardCount > 2) {
    out.add(_Finding(
      _Severity.warning,
      rel,
      1,
      'Найдено $heroCardCount вызовов homeWalletHeroCard — проверь: не два hero на одном экране (DESIGN_SYSTEM §6).',
    ));
  }
}

/// null = не репортим (ui_components и theme app).
_Severity? _rawColorSeverity(String absolutePath) {
  final norm = absolutePath.replaceAll(r'\', '/');
  if (norm.contains('/ui_components/lib/')) {
    return null;
  }
  if (norm.contains('/app/lib/src/core/theme/')) {
    return null;
  }
  if (norm.contains('/packages/app/lib/')) {
    return _Severity.warning;
  }
  if (norm.contains('/packages/features_')) {
    return _Severity.warning;
  }
  return null;
}

String _stripTrailingLineComment(String line) {
  final idx = line.indexOf('//');
  if (idx < 0) return line;
  // Грубая эвристика: не отрезать // внутри строки
  final before = line.substring(0, idx);
  final quotes = "'".allMatches(before).length + '"'.allMatches(before).length;
  if (quotes % 2 == 1) return line;
  return before;
}

String _relativeToPackages(String filePath, Directory libRoot) {
  final packagesIdx = filePath.replaceAll(r'\', '/').lastIndexOf('/packages/');
  if (packagesIdx >= 0) {
    return filePath.substring(packagesIdx + 1).replaceAll(r'\', '/');
  }
  return filePath.replaceAll(r'\', '/');
}

enum _Severity { error, warning }

class _Finding {
  _Finding(this.severity, this.filePath, this.line, this.message);

  final _Severity severity;
  final String filePath;
  final int line;
  final String message;
}
