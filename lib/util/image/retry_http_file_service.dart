import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/hash_util.dart';

import '../../consts/base64.dart';

class RetryHttpFileService extends FileService {
  final http.Client _httpClient;

  RetryHttpFileService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String>? headers}) async {
    // Validate URL
    if (url.isEmpty || url == 'null' || url == 'undefined') {
      log("Invalid image URL: $url", name: "RetryHttpFileService");
      return _createEmptyResponse();
    }
    
    url = url.trim();
    log("Loading image from $url", name: "RetryHttpFileService");
    
    try {
      // Handle base64 encoded images
      if (BASE64.check(url)) {
        try {
          return Baes64FileResponse(BASE64.toData(url));
        } catch (e) {
          log("Error decoding base64 image: $e", name: "RetryHttpFileService");
          return _createEmptyResponse();
        }
      }

      // Validate URL format
      Uri? uri;
      try {
        uri = Uri.parse(url);
        if (!uri.hasScheme || !uri.hasAuthority) {
          log("Invalid URL format: $url", name: "RetryHttpFileService");
          return _createEmptyResponse();
        }
      } catch (e) {
        log("Error parsing URL $url: $e", name: "RetryHttpFileService");
        return _createEmptyResponse();
      }

      // Make the request with error handling
      try {
        // Create request
        var req = http.Request('GET', uri);
        if (headers != null) {
          req.headers.addAll(headers);
        }
        
        // Send request with timeout
        var httpResponse = await _httpClient.send(req)
            .timeout(const Duration(seconds: 15));
            
        // Handle redirects for all platforms
        if (httpResponse.statusCode == 301 || httpResponse.statusCode == 302) {
          var location = httpResponse.headers["location"] ?? httpResponse.headers["Location"];
          if (location != null && location.isNotEmpty) {
            log("Following redirect from $url to $location", name: "RetryHttpFileService");
            url = location;
            Uri redirectUri;
            try {
              redirectUri = Uri.parse(location);
              // Handle relative URLs
              if (!redirectUri.hasScheme) {
                redirectUri = uri.replace(path: location);
              }
            } catch (e) {
              log("Error parsing redirect URL $location: $e", name: "RetryHttpFileService");
              redirectUri = uri;
            }
            var redirectReq = http.Request('GET', redirectUri);
            if (headers != null) {
              redirectReq.headers.addAll(headers);
            }
            httpResponse = await _httpClient.send(redirectReq)
                .timeout(const Duration(seconds: 15));
          }
        }

        // Create response and check status
        var response = HttpGetResponse(httpResponse);
        if (response.statusCode > 299) {
          log("HTTP error for $url: ${response.statusCode}", name: "RetryHttpFileService");
          return retry(url, headers: headers);
        }
        
        return response;
      } catch (e) {
        log("Error fetching image $url: $e", name: "RetryHttpFileService");
        return retry(url, headers: headers);
      }
    } catch (e) {
      // Catch-all for any unexpected errors
      log("Unexpected error loading image $url: $e", name: "RetryHttpFileService");
      return retry(url, headers: headers);
    }
  }
  
  // Create an empty response for invalid URLs or errors
  FileServiceResponse _createEmptyResponse() {
    return Baes64FileResponse(Uint8List(0));
  }

  Future<FileServiceResponse> retry(String url,
      {Map<String, String>? headers}) async {
    log("Retrying image fetch via proxy: $url", name: "RetryHttpFileService");
    
    try {
      // Encode the URL for the proxy service
      var base64Url = base64UrlEncode(utf8.encode(url));
      int t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      var sign = HashUtil.md5("$base64Url$t${Base.imageProxyServiceKey}");
  
      // Prepare proxy URL
      url = "${Base.imageProxyService}$base64Url";
      log("Proxied URL: $url", name: "RetryHttpFileService");
  
      // Send request through proxy
      try {
        final req = http.Request('GET', Uri.parse(url));
        if (headers != null) {
          req.headers.addAll(headers);
        }
        req.headers.addAll({"t": "$t", "sign": sign});
        
        // Use timeout to prevent hanging
        final httpResponse = await _httpClient.send(req)
            .timeout(const Duration(seconds: 20));
  
        // Check response status
        if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
          log("Proxy request successful", name: "RetryHttpFileService");
          return HttpGetResponse(httpResponse);
        } else {
          log("Proxy request failed with status: ${httpResponse.statusCode}", 
              name: "RetryHttpFileService");
          // Return empty response instead of throwing
          return _createEmptyResponse();
        }
      } catch (e) {
        log("Error in proxy request: $e", name: "RetryHttpFileService");
        return _createEmptyResponse();
      }
    } catch (e) {
      log("Failed to create proxy request: $e", name: "RetryHttpFileService");
      return _createEmptyResponse();
    }
  }
}

class Baes64FileResponse implements FileServiceResponse {
  Uint8List data;

  // Constructor with validation
  Baes64FileResponse(this.data) {
    // Ensure data is never null
    if (data.isEmpty) {
      log("Created empty Base64FileResponse", name: "Base64FileResponse");
    }
  }

  final DateTime _receivedTime = DateTime.now();

  @override
  int get statusCode => data.isEmpty ? HttpStatus.noContent : HttpStatus.ok;

  String? _header(String name) {
    return null;
  }

  @override
  Stream<List<int>> get content {
    // Always return a valid stream, even if data is empty
    return Stream.value(data.toList());
  }

  @override
  int? get contentLength => data.length;

  @override
  DateTime get validTill {
    // Short validity for empty responses, longer for valid ones
    var ageDuration = data.isEmpty 
        ? const Duration(minutes: 5)  // Short cache for empty/invalid images
        : const Duration(days: 7);    // Longer cache for valid images
    return _receivedTime.add(ageDuration);
  }

  @override
  String? get eTag => _header(HttpHeaders.etagHeader);

  @override
  String get fileExtension {
    // PNG is a better default as it supports transparency
    return "png";
  }
}
