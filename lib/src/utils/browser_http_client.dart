import 'dart:convert';
import 'dart:typed_data';

import 'package:es_compression/brotli.dart';

import 'user_agents.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

/// A browser-like HTTP client that automatically sets appropriate headers
class BrowserHttpClient {
  final http.Client _client;
  final Map<String, String> _defaultHeaders;

  BrowserHttpClient({
    http.Client? client,
    Map<String, String>? additionalHeaders,
  }) : _client = RetryClient(client ?? http.Client()),
       _defaultHeaders = {
         'Accept':
             'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
         'Accept-Language': 'en-US,en;q=0.5',
         'Accept-Encoding': 'gzip, deflate, br',
         'Connection': 'keep-alive',
         ...?additionalHeaders,
         ...fakeUserAgent(),
       };

  Future<CrawlResponse> send(CrawlRequest request) async {
    final client = http.Client();
    http.Request req;
    try {
      req = http.Request(request.method, request.url);
      req.followRedirects = true;
    } catch (e, stackTrace) {
      print('Error creating the request: $e\n$stackTrace');
      rethrow;
    }

    req.headers.addAll({..._defaultHeaders, ...?request.headers});

    // Handle body (encoding based on contentType)
    if (request.body != null) {
      if (request.contentType == 'application/json') {
        req.headers['Content-Type'] = 'application/json';
        req.body = jsonEncode(request.body); // Encode to JSON
      } else if (request.contentType == 'application/x-www-form-urlencoded') {
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded';
        if (request.body is Map) {
          req.bodyFields =
              request.body.cast<String, String>(); // Encode as form data
        } else {
          throw ArgumentError('Body must be a Map for x-www-form-urlencoded');
        }
      } else {
        if (request.body is String) {
          req.body = request.body; // Use as-is for plain text or other types
        } else {
          throw ArgumentError(
            "Not supported Content-Type and body type combination",
          );
        }
      }
    }

    try {
      final streamedResponse = await client.send(req);

      final response = await http.Response.fromStream(streamedResponse);

      return CrawlResponse(
        statusCode: response.statusCode,
        body: _decodeResponseBody(response),
        bodyBytes: response.bodyBytes,
        headers: response.headers,
        request: request,
      );
    } catch (e, stackTrace) {
      print('Error during request: $e\n$stackTrace');
      rethrow;
    } finally {
      client.close();
    }
  }

  void close() {
    _client.close();
  }

  /// dart:http cannot decompress HTTP responses if they
  /// use the brotli compression.
  ///
  /// This function does 2 things :
  /// - check if it uses brotli and decode the response correctly
  /// - check the charset and decode in utf8 or latin1
  String _decodeResponseBody(http.Response response) {
    final Uint8List bytes = response.bodyBytes;
    List<int> decompressedBytes = bytes;

    // Check for compression encoding
    final contentEncoding = response.headers['content-encoding']?.toLowerCase();
    if (contentEncoding != null) {
      if (contentEncoding.contains('br') ||
          contentEncoding.contains('brotli')) {
        try {
          decompressedBytes = brotli.decode(bytes);
        } catch (e) {
          print('Error decompressing Brotli content: $e');
        }
      }
    }

    // Now handle character encoding
    // Try to get charset from Content-Type header
    final contentType = response.headers['content-type'];
    if (contentType != null) {
      final charsetMatch = RegExp(r'charset=([^\s;]+)').firstMatch(contentType);
      if (charsetMatch != null) {
        final charset = charsetMatch.group(1)!.toLowerCase();
        try {
          // Handle known charsets
          if (charset == 'iso-8859-1' || charset == 'latin1') {
            return latin1.decode(decompressedBytes);
          } else if (charset == 'utf-8') {
            return utf8.decode(decompressedBytes);
          } else if (charset == 'ascii') {
            return ascii.decode(decompressedBytes);
          }
          // Other specific charsets could be handled here
        } catch (e) {
          print('Error decoding with charset $charset: $e');
        }
      }
    }

    // If no charset specified or decoding failed, try UTF-8 first
    try {
      return utf8.decode(decompressedBytes);
    } catch (e) {
      // Fall back to Latin-1 which accepts any byte sequence
      return latin1.decode(decompressedBytes);
    }
  }
}

/// Represents an HTTP request
class CrawlRequest {
  /// The URL of the request
  final Uri url;

  /// HTTP method : GET, PUT, POST, DELETE...
  final String method;

  final Map<String, String>? headers;
  final dynamic body;
  final String? contentType;

  /// Represent the current depth of the request.
  ///
  /// "1" means it's a request from the first level
  final int depth;

  CrawlRequest({
    required this.url,
    this.method = 'GET',
    this.headers,
    this.body,
    this.contentType,
    this.depth = 1,
  });

  // Helper method for creating POST requests
  static CrawlRequest post(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    String? contentType,
    int? depth,
  }) {
    return CrawlRequest(
      url: url,
      method: 'POST',
      headers: headers,
      body: body,
      contentType: contentType,
      depth: depth ?? 1,
    );
  }

  static CrawlRequest get(Uri url, {Map<String, String>? headers, int? depth}) {
    return CrawlRequest(
      url: url,
      method: 'GET',
      headers: headers,
      depth: depth ?? 1,
    );
  }
}

/// Represents an HTTP response with its request
class CrawlResponse {
  final int statusCode;
  final String body;
  final Uint8List bodyBytes;
  final Map<String, String> headers;
  final CrawlRequest request;

  CrawlResponse({
    required this.statusCode,
    required this.body,
    required this.bodyBytes,
    required this.headers,
    required this.request,
  });
}
