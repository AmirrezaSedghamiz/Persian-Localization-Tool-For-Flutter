import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:persian_localizer/persian_localizer.dart' as globals;
import 'package:persian_localizer/src/models/concatenationAnalysis.dart';
import 'package:persian_localizer/src/models/stringlocation.dart';
import 'package:persian_localizer/src/utils/FileUtils.dart';
import 'package:persian_localizer/src/utils/TextUtils.dart';

/// Extracts strings from Dart file using AST parsing
void extractStringsWithAST(File file, String content) {
  final result = parseString(content: content, path: file.path);
  result.unit.visitChildren(_Visitor(file.path));
}

class _Visitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final Set<String> _processedExpressions = {};

  _Visitor(this.filePath);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final typeName = constructorName.type.toSource() ?? 'Unknown';

    print('   🔍 Found widget: $typeName');

    if (textWidgets.contains(typeName)) {
      print('   ✅ Processing as text widget');
      _processWidget(node, typeName);
    } else {
      print('   ⚠️ Checking for text parameters');
      _checkForTextParameters(node);
    }

    super.visitInstanceCreationExpression(node);
  }

  void _processWidget(InstanceCreationExpression node, String typeName) {
    print('   🔧 Processing $typeName widget');

    for (final arg in node.argumentList.arguments) {
      if (arg is NamedExpression) {
        final paramName = arg.name.label.name;
        print('     📌 Named parameter: $paramName');

        if (textParameters.contains(paramName)) {
          print('     ✅ Extracting from $paramName');
          _extractFromExpression(arg.expression, context: paramName);
        } else {
          _extractFromExpression(arg.expression, context: 'widget parameter');
        }
      } else if (arg is Expression) {
        print('     📌 Positional parameter');
        _extractFromExpression(arg, context: 'widget positional');
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    final target = node.target;

    print('   🔍 Found method invocation: $methodName');

    if (target is SimpleIdentifier) {
      final targetName = target.name;

      if (methodName == 'rich' && targetName == 'Text') {
        print('     ✅ Found Text.rich() named constructor');
        _processTextRich(node);
        return;
      }

      if (textWidgets.contains(targetName)) {
        print('     ⚠️ $targetName.$methodName might be a named constructor');
        for (final arg in node.argumentList.arguments) {
          if (arg is Expression) {
            _extractFromExpression(arg, context: 'method parameter');
          }
        }
      }
    }

    for (final arg in node.argumentList.arguments) {
      if (arg is Expression) {
        _extractFromExpression(arg, context: 'method parameter');
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.initializer != null) {
      print('   🔍 Found variable declaration: ${node.name}');
      _extractFromExpression(node.initializer!, context: 'variable');
    }

    if (node.parent is VariableDeclarationList) {
      final parentList = node.parent as VariableDeclarationList;
      if (parentList.isConst || parentList.isFinal) {
        print('   📌 Variable is const/final: ${node.name}');
        if (node.initializer != null) {
          _extractFromExpression(node.initializer!, context: 'const variable');
        }
      }
    }

    super.visitVariableDeclaration(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      print('   🔍 Found return statement');
      _extractFromExpression(node.expression!, context: 'return value');
    }
    super.visitReturnStatement(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _extractFromExpression(node.rightHandSide, context: 'assignment');
    super.visitAssignmentExpression(node);
  }

  void _checkForTextParameters(InstanceCreationExpression node) {
    for (final arg in node.argumentList.arguments) {
      if (arg is NamedExpression) {
        final paramName = arg.name.label.name;
        if (textParameters.contains(paramName)) {
          _extractFromExpression(arg.expression, context: paramName);
        }
      } else if (arg is Expression) {
        if (arg is InstanceCreationExpression) {
          final argTypeName = arg.constructorName.type.toSource() ?? '';
          if (textWidgets.contains(argTypeName)) {
            _processWidget(arg, argTypeName);
          }
        }
        _extractFromExpression(arg, context: 'widget parameter');
      }
    }
  }

  void _processTextRich(MethodInvocation node) {
    print('   📝 Processing Text.rich() method');

    for (final arg in node.argumentList.arguments) {
      if (arg is NamedExpression) {
        final paramName = arg.name.label.name;
        print('     📌 Named parameter: $paramName');

        if (paramName == 'text') {
          print('     ✅ Processing Text.rich() text parameter');
          _extractFromExpression(arg.expression, context: 'Text.rich text');
        } else {
          _extractFromExpression(arg.expression,
              context: 'Text.rich parameter');
        }
      } else if (arg is Expression &&
          node.argumentList.arguments.indexOf(arg) == 0) {
        print('     📌 First positional argument for Text.rich()');
        _extractFromExpression(arg, context: 'Text.rich positional');
      } else {
        _extractFromExpression(arg, context: 'Text.rich parameter');
      }
    }
  }

  void _extractFromExpression(Expression expr, {String? context}) {
    final exprKey = '${expr.runtimeType}:${expr.offset}:${expr.end}';
    if (_processedExpressions.contains(exprKey)) {
      return;
    }
    _processedExpressions.add(exprKey);

    if (expr is NamedExpression) {
      print('     📌 Found NamedExpression: ${expr.name.label.name}');
      _extractFromExpression(expr.expression, context: expr.name.label.name);
      return;
    }

    if (expr is MethodInvocation) {
      final methodName = expr.methodName.name;
      final target = expr.target;

      print('     🔍 Found method invocation: $methodName');

      if (methodName == 'rich' &&
          target is SimpleIdentifier &&
          target.name == 'Text') {
        print('     ✅ Found Text.rich()');
        _processTextRich(expr);
        return;
      }

      if (target == null && textWidgets.contains(methodName)) {
        print('     🎯 Found $methodName constructor call');
        for (final arg in expr.argumentList.arguments) {
          _extractFromExpression(arg, context: 'constructor parameter');
        }
        return;
      }

      for (final arg in expr.argumentList.arguments) {
        if (arg is Expression) {
          _extractFromExpression(arg, context: 'method parameter');
        }
      }
      return;
    }

    if (expr is SimpleStringLiteral) {
      print(
          '     ✅ Found simple string literal: "${truncateText(expr.value)}"');

      final location = StringLocation(
        filePath: filePath,
        offset: expr.offset,
        end: expr.end,
        originalText: expr.toSource(),
        context: context ?? 'string literal',
      );

      _addString(expr.value, location);
      return;
    }

    if (expr is StringInterpolation) {
      print('     ✅ Found string interpolation');
      _processStringInterpolation(expr, context: context);
      return;
    }

    if (expr is BinaryExpression && expr.operator.lexeme == '+') {
      print('     ✅ Found string concatenation');

      // Check for complex edge cases first
      final exprString = expr.toSource();
      final isComplexEdgeCase = _isComplexEdgeCase(exprString);

      if (isComplexEdgeCase) {
        _handleComplexConcatenationEdgeCases(expr, context: context);
        return;
      }

      // Analyze the concatenation pattern
      final analysis = _analyzeConcatenation(expr);
      print(
          '     📊 Concatenation analysis: ${analysis.staticParts.length} static parts, ${analysis.dynamicParts.length} dynamic parts');

      if (analysis.isAllStatic) {
        // All parts are static strings
        print('     📊 All static concatenation');
        final combined = analysis.staticParts.join();
        if (combined.isNotEmpty) {
          final location = StringLocation(
            filePath: filePath,
            offset: expr.offset,
            end: expr.end,
            originalText: expr.toSource(),
            context: context ?? 'static concatenation',
          );
          _addString(combined, location);
        }
      } else if (analysis.hasPersianStaticParts) {
        // Has Persian static parts mixed with variables
        print('     📊 Mixed concatenation with Persian content');
        for (final part in analysis.staticParts) {
          if (part.isNotEmpty && hasPersianArabicCharacters(part)) {
            final location = StringLocation(
              filePath: filePath,
              offset: expr.offset,
              end: expr.end,
              originalText: expr.toSource(),
              context: context ?? 'mixed concatenation part',
            );
            _addString(part, location);
          }
        }

        // Record dynamic info
        final dynamicInfo = '''
MIXED CONCATENATION - CONSIDER REFACTORING:
  File: $filePath
  Expression: ${expr.toSource()}
  Static Persian parts: ${analysis.staticParts.where((p) => hasPersianArabicCharacters(p)).toList()}
  Dynamic parts: ${analysis.dynamicParts}
  Context: ${context ?? 'unknown'}
  Recommendation: Consider using string formatting or separate localization keys
''';
        _recordDynamic(dynamicInfo);
      } else {
        print('     ⚠️ No Persian content in concatenation');
      }
      return;
    }

    if (expr is ConditionalExpression) {
      print('     ✅ Found conditional expression');
      _processConditionalExpression(expr, context: context);
      return;
    }

    if (expr is ListLiteral) {
      print('     ✅ Found list literal with ${expr.elements.length} elements');
      for (final element in expr.elements) {
        if (element is Expression) {
          _extractFromExpression(element, context: context);
        } else if (element is SpreadElement) {
          if (element.expression is Expression) {
            _extractFromExpression(element.expression as Expression,
                context: context);
          }
        }
      }
      return;
    }

    if (expr is InstanceCreationExpression) {
      final typeName = expr.constructorName.type.toSource() ?? '';
      print('     🔍 Found instance creation: $typeName');

      if (textWidgets.contains(typeName)) {
        print('     ✅ Processing $typeName as text widget');
        _processWidget(expr, typeName);
      } else {
        print('     ⚠️ Checking $typeName for text parameters');
        _checkForTextParameters(expr);
      }
      return;
    }

    if (expr is PrefixedIdentifier || expr is PropertyAccess) {
      print('     ⚠️ Found prefixed/property access: ${expr.toSource()}');
      _recordDynamic('Reference: ${expr.toSource()}');
      return;
    }

    if (expr is ParenthesizedExpression) {
      print('     🔍 Found parenthesized expression');
      _extractFromExpression(expr.expression, context: context);
      return;
    }

    if (expr is PostfixExpression && expr.operator.type.name == 'BANG') {
      print('     🔍 Found null-aware operator');
      _extractFromExpression(expr.operand, context: context);
      return;
    }

    if (expr is BinaryExpression && expr.operator.lexeme == '??') {
      print('     🔍 Found if-null expression');
      _extractFromExpression(expr.leftOperand, context: context);
      _extractFromExpression(expr.rightOperand, context: context);
      return;
    }

    if (expr is BinaryExpression && expr.operator.lexeme == '*') {
      print('     🔍 Found string multiplication');
      if (expr.leftOperand is SimpleStringLiteral) {
        _recordDynamic('String multiplication: ${expr.toSource()}');
        _extractFromExpression(expr.leftOperand, context: context);
      }
      return;
    }

    if (expr is SimpleIdentifier) {
      print('     ⚠️ Found simple identifier: ${expr.name}');
      _recordDynamic('Variable reference: ${expr.name}');
      return;
    }

    print('     ⚠️ Unhandled expression type: ${expr.runtimeType}');
  }

  bool _isComplexEdgeCase(String exprString) {
    return exprString.contains('AppLocalizations.of') ||
        exprString.contains('formatCurrency') ||
        exprString.contains('formatNumber') ||
        exprString.contains('widget.') && exprString.contains('+') ||
        exprString.contains('?? ""') && exprString.contains('+') ||
        exprString.contains('\\"') && exprString.contains('+') ||
        exprString.contains('\\n') && exprString.contains('+');
  }

  void _handleComplexConcatenationEdgeCases(Expression expr,
      {String? context}) {
    print('     🎯 Handling complex concatenation edge case');

    final exprString = expr.toSource();

    // Use regex to extract Persian parts from complex concatenations
    final persianRegex = RegExp(
        r'''['"]([^'"\n]*[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF][^'"\n]*)['"]''',
        multiLine: true);

    final matches = persianRegex.allMatches(exprString);
    int extractedCount = 0;

    for (final match in matches) {
      if (match.groupCount > 0) {
        String value = match.group(1) ?? '';
        if (value.trim().isNotEmpty && hasPersianArabicCharacters(value)) {
          // Clean up the value
          value = value.replaceAll(r'\"', '"').replaceAll(r"\'", "'");
          value = value.replaceAll(r'\n', '\n');
          value = value.replaceAll(r'\t', '\t');

          // Estimate position
          final estimatedOffset = expr.offset + match.start;
          final estimatedEnd = expr.offset + match.end;

          final location = StringLocation(
            filePath: filePath,
            offset: estimatedOffset,
            end: estimatedEnd,
            originalText: match.group(0) ?? '',
            context: 'complex concatenation edge case',
          );
          _addString(value, location);
          extractedCount++;
        }
      }
    }

    if (extractedCount > 0) {
      print(
          '     ✅ Extracted $extractedCount Persian parts from complex concatenation');
    }

    // Record this as a special case needing attention
    final dynamicInfo = '''
COMPLEX EDGE CASE - REQUIRES MANUAL REFACTORING:
  File: $filePath
  Expression: ${truncateText(exprString, 100)}
  Context: ${context ?? 'unknown'}
  Type: ${_identifyEdgeCaseType(exprString)}
  Recommendation: ${_getRefactoringRecommendation(exprString)}
''';
    _recordDynamic(dynamicInfo);
  }

  String _identifyEdgeCaseType(String expr) {
    if (expr.contains('formatCurrency'))
      return 'Function call in concatenation';
    if (expr.contains('AppLocalizations.of'))
      return 'Already localized string in concatenation';
    if (expr.contains('?? ""')) return 'Null-coalescing in concatenation';
    if (expr.contains('\\"')) return 'Escaped quotes in concatenation';
    if (expr.contains('\\n')) return 'Newlines in concatenation';
    if (expr.contains('widget.')) return 'Widget property in concatenation';
    return 'Complex mixed concatenation';
  }

  String _getRefactoringRecommendation(String expr) {
    if (expr.contains('formatCurrency')) {
      return 'Use string formatting: formatCurrency(amount) + " " + localizedString';
    }
    if (expr.contains('AppLocalizations.of')) {
      return 'Combine localized strings into single key or use string formatting with parameters';
    }
    if (expr.contains('?? ""')) {
      return 'Handle empty/optional values in localization logic, not in string concatenation';
    }
    if (expr.contains('\\"')) {
      return 'Avoid escaped quotes in translatable strings - use parameters instead';
    }
    return 'Consider refactoring into parameters: {name}, {amount}, {unit}, etc.';
  }

  ConcatenationAnalysis _analyzeConcatenation(BinaryExpression expr) {
    final analysis = ConcatenationAnalysis();

    void analyzeExpression(Expression e) {
      if (e is SimpleStringLiteral) {
        final value = e.value;
        analysis.staticParts.add(value);

        if (hasPersianArabicCharacters(value)) {
          analysis.hasPersianStaticParts = true;
        }
      } else if (e is StringInterpolation) {
        bool hasDynamicInterpolation = false;
        for (final element in e.elements) {
          if (element is InterpolationString) {
            final value = element.value;
            analysis.staticParts.add(value);

            if (hasPersianArabicCharacters(value)) {
              analysis.hasPersianStaticParts = true;
            }
          } else if (element is InterpolationExpression) {
            hasDynamicInterpolation = true;
            final dynamicExpr = element.expression;

            if (dynamicExpr is SimpleStringLiteral) {
              final value = dynamicExpr.value;
              analysis.staticParts.add(value);
              if (hasPersianArabicCharacters(value)) {
                analysis.hasPersianStaticParts = true;
              }
            } else if (dynamicExpr is MethodInvocation) {
              analysis.isAllStatic = false;
              final methodName = dynamicExpr.methodName.name;
              analysis.dynamicParts.add('function: $methodName()');
            } else if (_isLocalizationExpression(dynamicExpr)) {
              analysis.isAllStatic = false;
              analysis.dynamicParts.add('already localized');
            } else {
              analysis.dynamicParts.add(_simplifyExpression(dynamicExpr));
              analysis.isAllStatic = false;
            }
          }
        }
        if (hasDynamicInterpolation) {
          analysis.isAllStatic = false;
        }
      } else if (e is BinaryExpression && e.operator.lexeme == '+') {
        analyzeExpression(e.leftOperand);
        analyzeExpression(e.rightOperand);
      } else if (e is ParenthesizedExpression) {
        analyzeExpression(e.expression);
      } else if (e is ConditionalExpression) {
        analysis.isAllStatic = false;
        analysis.dynamicParts.add('conditional');

        // Extract strings from conditional branches
        _extractFromExpression(e.thenExpression, context: 'conditional then');
        _extractFromExpression(e.elseExpression, context: 'conditional else');
      } else if (_isLocalizationExpression(e)) {
        analysis.isAllStatic = false;
        analysis.dynamicParts.add('already localized');
      } else if (e is SimpleIdentifier ||
          e is PropertyAccess ||
          e is PrefixedIdentifier) {
        analysis.isAllStatic = false;
        analysis.dynamicParts.add(_simplifyExpression(e));
      } else if (e is MethodInvocation) {
        analysis.isAllStatic = false;
        final methodName = e.methodName.name;

        if (methodName.contains('format')) {
          analysis.dynamicParts.add('format function');
        } else {
          analysis.dynamicParts.add('method: $methodName');
        }
      } else {
        analysis.isAllStatic = false;
        analysis.dynamicParts.add('expression');
      }
    }

    analyzeExpression(expr);
    return analysis;
  }

  bool _isLocalizationExpression(Expression expr) {
    final source = expr.toSource();
    return source.contains('AppLocalizations.of') ||
        source.contains('.fa_') ||
        (source.startsWith('fa_') && source.length < 10);
  }

  String _simplifyExpression(Expression expr) {
    final source = expr.toSource();
    if (source.length > 30) {
      return '${source.substring(0, 27)}...';
    }
    return source;
  }

  void _processConditionalExpression(ConditionalExpression expr,
      {String? context}) {
    _extractFromExpression(expr.thenExpression, context: context);
    _extractFromExpression(expr.elseExpression, context: context);
  }

  void _processStringInterpolation(StringInterpolation expr,
      {String? context}) {
    bool hasDynamicParts = false;
    final staticParts = <String>[];
    final dynamicPartsInfo = <String>[];

    for (final element in expr.elements) {
      if (element is InterpolationString) {
        final value = element.value;
        if (value.isNotEmpty) {
          staticParts.add(value);
        }
      } else if (element is InterpolationExpression) {
        hasDynamicParts = true;
        final dynamicPart = element.expression.toSource();
        dynamicPartsInfo.add(dynamicPart);

        if (element.expression is SimpleStringLiteral) {
          final literal = element.expression as SimpleStringLiteral;
          final value = literal.value;
          if (value.isNotEmpty) {
            staticParts.add(value);
          }
        }
      }
    }

    for (final staticPart in staticParts) {
      if (staticPart.isNotEmpty) {
        final location = StringLocation(
          filePath: filePath,
          offset: expr.offset,
          end: expr.end,
          originalText: expr.toSource(),
          context: context ?? 'string interpolation',
        );

        _addString(staticPart, location);
      }
    }

    if (hasDynamicParts) {
      final fullInterpolation = expr.toSource();
      final dynamicInfo = 'Dynamic parts: ${dynamicPartsInfo.join(", ")}';
      final staticInfo = 'Static parts: ${staticParts.join(", ")}';
      _recordDynamic('$fullInterpolation\n$dynamicInfo\n$staticInfo');
    }
  }

  void _addString(String value, StringLocation? location) {
    if (value.isEmpty) return;

    if (!hasPersianArabicCharacters(value)) {
      return;
    }

    String cleanValue = value;

    // Handle escaped characters
    cleanValue = cleanValue.replaceAll(r'\"', '"').replaceAll(r"\'", "'");
    cleanValue = cleanValue.replaceAll(r'\n', '\n');
    cleanValue = cleanValue.replaceAll(r'\t', '\t');
    cleanValue = cleanValue.replaceAll(r'\r', '\r');

    // Remove surrounding quotes
    if ((cleanValue.startsWith("'") && cleanValue.endsWith("'")) ||
        (cleanValue.startsWith('"') && cleanValue.endsWith('"'))) {
      cleanValue = cleanValue.substring(1, cleanValue.length - 1);
    }

    // Skip very short strings that are likely just spaces or punctuation
    if (cleanValue.trim().length < 2 &&
        !hasPersianArabicCharacters(cleanValue.trim())) {
      return;
    }

    // Check for existing string
    String? existingKey;
    for (final entry in globals.extractedStrings.entries) {
      if (entry.value == cleanValue) {
        existingKey = entry.key;
        break;
      }
    }

    if (existingKey != null) {
      if (location != null) {
        globals.stringLocations[existingKey] = [
          ...(globals.stringLocations[existingKey] ?? []),
          location
        ];
        print('   🔗 Added location to existing key $existingKey');
      }
    } else {
      final key = 'fa_${++globals.counter}';
      globals.extractedStrings[key] = cleanValue;
      if (location != null) {
        globals.stringLocations[key] = [location];
      }
      print('   ✅ Extracted ($key): "${truncateText(cleanValue)}"');
    }
  }

  void _recordDynamic(String source) {
    globals.dynamicStrings.add(source);
  }
}