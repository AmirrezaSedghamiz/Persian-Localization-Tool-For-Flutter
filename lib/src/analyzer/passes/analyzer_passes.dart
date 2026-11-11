import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../models/evidence_models.dart';
import '../models/project_registry.dart';

class _DataFlowVisitor extends RecursiveAstVisitor<void> {
  final ProjectRegistry registry;

  _DataFlowVisitor(this.registry);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.staticElement;

    if (element is FieldElement) {
      if (element.type.isDartCoreString == true) {
        final className = element.enclosingElement3.name;
        if (className != null) {
          final parentEv = registry.identifiers[className];
          if (parentEv != null && parentEv.isWidget) {
            registry.getParameter(element.name).definitionSiteTextUsages++;
            parentEv.textDataFlowOccurrences++;
          }
        }
            }
    } else if (element is PropertyAccessorElement) {
      if (element.returnType.isDartCoreString == true) {
        final className = element.enclosingElement3.name;
        if (className != null) {
          final parentEv = registry.identifiers[className];
          if (parentEv != null && parentEv.isWidget) {
            registry.getParameter(element.name).definitionSiteTextUsages++;
            parentEv.textDataFlowOccurrences++;
          }
        }
            }
    } else if (element is ParameterElement) {
      if (element.type.isDartCoreString == true) {
        final enclosing = element.enclosingElement3;
        if (enclosing is ConstructorElement) {
          final className = enclosing.enclosingElement3.name;
          final parentEv = registry.identifiers[className];
          if (parentEv != null && parentEv.isWidget) {
            registry.getParameter(element.name).definitionSiteTextUsages++;
            parentEv.textDataFlowOccurrences++;
          }
                }
      }
    }

    super.visitSimpleIdentifier(node);
  }
}

class TypedEvidenceVisitor extends RecursiveAstVisitor<void> {
  final ProjectRegistry registry;
  int _uiContextDepth = 0;

  TypedEvidenceVisitor(this.registry);

  bool get _inUiContext => _uiContextDepth > 0;

  bool _isWidgetElement(Element? element) {
    if (element == null) return false;
    ClassElement? classElement;
    if (element is ClassElement) {
      classElement = element;
    } else if (element is ConstructorElement) {
      classElement = element.enclosingElement3 as ClassElement?;
    }

    if (classElement != null) {
      if (classElement.name.contains('Widget')) return true;
      for (final supertype in classElement.allSupertypes) {
        if (supertype.element.name == 'Widget' ||
            supertype.element.name == 'StatelessWidget' ||
            supertype.element.name == 'StatefulWidget') {
          return true;
        }
      }
    }
    return false;
  }

  bool _isStateElement(Element? element) {
    if (element == null) return false;
    ClassElement? classElement;
    if (element is ClassElement) {
      classElement = element;
    } else if (element is ConstructorElement) {
      classElement = element.enclosingElement3 as ClassElement?;
    }

    if (classElement != null) {
      for (final supertype in classElement.allSupertypes) {
        if (supertype.element.name == 'State') {
          return true;
        }
      }
    }
    return false;
  }

  bool _isCoreTextWidget(Element? element, String fallbackName) {
    String name = fallbackName;
    if (element != null) {
      name = element.name ?? name;
      if (element is ConstructorElement) {
        name = element.enclosingElement3.name;
      }
    }
    return name == 'Text' ||
        name == 'RichText' ||
        name == 'SelectableText' ||
        name == 'TextField' ||
        name == 'TextFormField';
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final name = node.name.lexeme;
    final element = node.declaredElement;

    final superclassName = node.extendsClause?.superclass.name2.lexeme;
    final ev = registry.getIdentifier(name);
    ev.superclassName = superclassName;

    final structuralNames = {
      'child',
      'children',
      'body',
      'builder',
      'slivers',
      'itemBuilder'
    };
    for (final member in node.members) {
      if (member is FieldDeclaration) {
        for (final variable in member.fields.variables) {
          if (structuralNames.contains(variable.name.lexeme)) {
            ev.declaresStructuralParameters = true;
          }
        }
      }
    }

    if (_isStateElement(element) || superclassName == 'State') {
      registry.recordEntityKind(name, EntityKind.stateClass);
    } else if (_isWidgetElement(element) ||
        (superclassName != null && superclassName.contains('Widget'))) {
      registry.recordEntityKind(name, EntityKind.widgetClass);
    } else {
      registry.recordEntityKind(name, EntityKind.otherClass);
    }

    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    registry.recordEntityKind(node.name.lexeme, EntityKind.method);

    bool isBuildMethod = node.name.lexeme == 'build' &&
        node.parameters?.parameters.length == 1 &&
        (node.parameters?.parameters.first
                .toSource()
                .contains('BuildContext') ??
            false);

    if (isBuildMethod) {
      _uiContextDepth++;
    }

    super.visitMethodDeclaration(node);

    if (isBuildMethod) {
      _uiContextDepth--;
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    registry.recordEntityKind(node.name.lexeme, EntityKind.function);
    super.visitFunctionDeclaration(node);
  }

  bool _isStrongTextParameterName(String name) {
    final lower = name.toLowerCase();
    return lower.contains('title') ||
        lower.contains('label') ||
        lower.contains('text') ||
        lower.contains('message') ||
        lower.contains('caption') ||
        lower.contains('hint') ||
        lower.contains('tooltip') ||
        lower.contains('description');
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name2.lexeme;
    final element = node.constructorName.staticElement;
    final isWidget = _isWidgetElement(element);

    if (element != null && !isWidget) {
      if (registry.getIdentifier(typeName).kind == EntityKind.unknown) {
        registry.recordEntityKind(typeName, EntityKind.otherClass);
      }
    }

    bool hasPositionalString = false;
    for (final arg in node.argumentList.arguments) {
      if (arg is! NamedExpression) {
        if (arg.staticType?.isDartCoreString == true ||
            arg is SimpleStringLiteral ||
            arg is StringInterpolation) {
          hasPositionalString = true;
        }
      }
    }

    registry.recordInstantiation(typeName, _inUiContext, hasPositionalString);

    final isCore = _isCoreTextWidget(element, typeName);

    for (final arg in node.argumentList.arguments) {
      if (arg is NamedExpression) {
        final argName = arg.name.label.name;
        if (isCore || _isStrongTextParameterName(argName)) {
          arg.expression.accept(_DataFlowVisitor(registry));
        }
      } else {
        if (isCore) {
          arg.accept(_DataFlowVisitor(registry));
          if (typeName == 'Text' || typeName == 'SelectableText') break;
        }
      }
    }

    for (final arg in node.argumentList.arguments) {
      if (arg is NamedExpression) {
        final paramName = arg.name.label.name;
        final expr = arg.expression;
        final type = expr.staticType;

        bool isStringType = type?.isDartCoreString == true;
        bool isStringLiteral =
            expr is SimpleStringLiteral || expr is StringInterpolation;

        bool isNonString = false;
        if (type != null && type is! DynamicType) {
          isNonString = !type.isDartCoreString;
        } else {
          isNonString = !isStringLiteral &&
              !(expr is SimpleIdentifier) &&
              !(expr is MethodInvocation);
        }

        registry.recordParameterUsage(
          paramName,
          isStringType: isStringType,
          isStringLiteral: isStringLiteral,
          isNonString: isNonString,
          inUiContext: _inUiContext || isWidget,
        );
      }
    }

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    final element = node.methodName.staticElement;

    final isCore = _isCoreTextWidget(element, name);

    for (final arg in node.argumentList.arguments) {
      if (arg is NamedExpression) {
        final argName = arg.name.label.name;
        if (isCore || _isStrongTextParameterName(argName)) {
          arg.expression.accept(_DataFlowVisitor(registry));
        }
      } else {
        if (isCore) {
          arg.accept(_DataFlowVisitor(registry));
          if (name == 'Text' || name == 'SelectableText') break;
        }
      }
    }

    if (element != null) {
      registry.recordEntityKind(name, EntityKind.method);
    } else if (name.isNotEmpty &&
        name[0].toUpperCase() == name[0] &&
        name[0] != '_') {
      bool hasPositionalString = false;
      for (final arg in node.argumentList.arguments) {
        if (arg is! NamedExpression) {
          if (arg is SimpleStringLiteral || arg is StringInterpolation) {
            hasPositionalString = true;
          }
        }
      }
      registry.recordInstantiation(name, _inUiContext, hasPositionalString);

      for (final arg in node.argumentList.arguments) {
        if (arg is NamedExpression) {
          final paramName = arg.name.label.name;
          final expr = arg.expression;

          bool isStringLiteral =
              expr is SimpleStringLiteral || expr is StringInterpolation;
          bool isNonString = !isStringLiteral &&
              !(expr is SimpleIdentifier) &&
              !(expr is MethodInvocation);

          registry.recordParameterUsage(
            paramName,
            isStringType: false,
            isStringLiteral: isStringLiteral,
            isNonString: isNonString,
            inUiContext: _inUiContext,
          );
        }
      }
    }

    super.visitMethodInvocation(node);
  }
}
