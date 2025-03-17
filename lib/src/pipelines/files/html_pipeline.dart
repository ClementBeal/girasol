import 'dart:io';
import 'package:girasol/girasol.dart';
import 'package:html/dom.dart';

abstract class HTMLItem {
  final String html;
  HTMLItem({required this.html});
}

/// The HTML pipeline is designed to save a minimized HTML file locally
/// focusing only on content that matters for NLP processing.
///
/// The pipeline will:
/// - Remove all unnecessary tags and attributes
/// - Strip formatting and styling elements
/// - Preserve only the semantic content
/// - Minify the output
class HtmlPipeline<Item extends HTMLItem> extends Pipeline<Item> {
  /// Output file path, defaults to "output.html" in current directory
  final String outputPath;

  /// Remove all comments
  final bool cleanComments;

  /// Remove all script tags
  final bool cleanScripts;

  /// Remove all noscript tags
  final bool cleanNoscripts;

  /// Remove all style tags
  final bool cleanStyles;

  /// Remove all SVG elements
  final bool cleanSvg;

  /// Remove event handlers (onClick, etc.)
  final bool cleanEventHandlers;

  /// Remove all CSS classes and inline styles
  final bool cleanStylesAndClasses;

  /// Remove all meta tags
  final bool cleanMetaTags;

  /// Remove all link tags (usually CSS)
  final bool cleanLinkTags;

  /// Remove all images
  final bool cleanImages;

  /// Remove all iframes
  final bool cleanIframes;

  /// Remove all form elements
  final bool cleanForms;

  /// Remove data-* attributes
  final bool cleanDataAttributes;

  /// Remove empty elements that have no text content
  final bool removeEmptyElements;

  /// Convert divs to spans to flatten DOM
  final bool flattenDivs;

  /// Replace multiple spaces with a single space
  final bool normalizeWhitespace;

  HtmlPipeline({
    this.outputPath = "output.html",
    this.cleanComments = true,
    this.cleanScripts = true,
    this.cleanStyles = true,
    this.cleanEventHandlers = true,
    this.cleanNoscripts = true,
    this.cleanSvg = true,
    this.cleanStylesAndClasses = true,
    this.cleanMetaTags = true,
    this.cleanLinkTags = true,
    this.cleanImages = true,
    this.cleanIframes = true,
    this.cleanForms = true,
    this.cleanDataAttributes = true,
    this.removeEmptyElements = true,
    this.flattenDivs = true,
    this.normalizeWhitespace = true,
  });

  @override
  Future<void> clean() async {}

  @override
  Future<void> receiveData(data) async {
    final document = parse(data.html);

    _cleanHtml(document);

    String cleanedHtml = document.outerHtml;
    if (normalizeWhitespace) {
      cleanedHtml = _normalizeWhitespace(cleanedHtml);
    }

    final outputHTML = File(outputPath);
    await outputHTML.writeAsString(cleanedHtml);
  }

  void _cleanHtml(Document document) {
    if (cleanComments) {
      _removeComments(document.nodes);
    }

    if (cleanScripts) {
      document
          .querySelectorAll('script')
          .forEach((element) => element.remove());
    }

    // Remove noscript tags
    if (cleanNoscripts) {
      document
          .querySelectorAll('noscript')
          .forEach((element) => element.remove());
    }

    // Remove style tags
    if (cleanStyles) {
      document.querySelectorAll('style').forEach((element) => element.remove());
    }

    // Remove SVG elements
    if (cleanSvg) {
      document.querySelectorAll('svg').forEach((element) => element.remove());
    }

    // Remove meta tags
    if (cleanMetaTags) {
      document.querySelectorAll('meta').forEach((element) => element.remove());
      document.querySelectorAll('head').forEach((element) {
        if (element.nodes.isEmpty) element.remove();
      });
    }

    // Remove link tags (usually CSS)
    if (cleanLinkTags) {
      document.querySelectorAll('link').forEach((element) => element.remove());
    }

    // Remove images
    if (cleanImages) {
      document.querySelectorAll('img').forEach((element) => element.remove());
    }

    // Remove iframes
    if (cleanIframes) {
      document
          .querySelectorAll('iframe')
          .forEach((element) => element.remove());
    }

    // Remove form elements
    if (cleanForms) {
      final formElements = [
        'form',
        'input',
        'button',
        'select',
        'option',
        'textarea',
      ];
      for (final tag in formElements) {
        document.querySelectorAll(tag).forEach((element) => element.remove());
      }
    }

    // Process all elements for attributes
    final elements = document.querySelectorAll("*");
    for (final element in elements) {
      final attributes =
          element.attributes.keys
              .toList(); // Convert to list to avoid concurrent modification

      for (final attribute in attributes) {
        if (attribute is String) {
          if (cleanEventHandlers && attribute.startsWith("on")) {
            element.attributes.remove(attribute);
            continue;
          }

          if (cleanStylesAndClasses && ["class", "style"].contains(attribute)) {
            element.attributes.remove(attribute);
            continue;
          }

          if (cleanDataAttributes && attribute.startsWith("data-")) {
            element.attributes.remove(attribute);
            continue;
          }

          if (["id", "aria-*", "role", "tabindex", "title"].any(
            (prefix) =>
                attribute == prefix ||
                (prefix.endsWith('*') &&
                    attribute.startsWith(
                      prefix.substring(0, prefix.length - 1),
                    )),
          )) {
            element.attributes.remove(attribute);
          }
        }
      }
    }

    if (removeEmptyElements) {
      _removeEmptyElements(document);
    }
  }

  void _removeComments(List<Node> nodes) {
    final List<Node> commentsToRemove = [];

    for (var node in nodes) {
      if (node is Comment) {
        commentsToRemove.add(node);
      } else if (node.hasChildNodes()) {
        _removeComments(node.nodes);
      }
    }

    for (var comment in commentsToRemove) {
      comment.remove();
    }
  }

  void _removeEmptyElements(Document document) {
    // Exclude elements like <br>, <hr>, etc. that are meant to be empty
    final elementsToCheck = document.querySelectorAll(
      "p, span, div, h1, h2, h3, h4, h5, h6, li, ul, ol",
    );

    for (final element in elementsToCheck) {
      if (!element.hasChildNodes() ||
          (element.nodes.length == 1 &&
              element.nodes[0] is Text &&
              (element.nodes[0] as Text).text.trim().isEmpty)) {
        element.remove();
      }
    }
  }

  String _normalizeWhitespace(String html) {
    return html
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'>\s+<'), '><')
        .trim();
  }
}
