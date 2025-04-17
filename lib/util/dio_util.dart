import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Dio? _dio;
var cookieJar = CookieJar();

class DioUtil {
  static Dio getDio() {
    if (_dio == null) {
      _dio = Dio();
      
      // Configure options for both platforms
      // _dio!.options.connectTimeout = Duration(minutes: 1);
      // _dio!.options.receiveTimeout = Duration(minutes: 1);
      
      // Only set headers that are safe for web browsers
      _dio!.options.headers["accept-encoding"] = "gzip";
      
      // Only set User-Agent header on non-web platforms
      if (!kIsWeb) {
        _dio!.options.headers["user-agent"] =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36";
      }
      
      CookieManager cookieManager = CookieManager(cookieJar);
      _dio!.interceptors.add(cookieManager);
    }
    return _dio!;
  }

  static setCookie(String link, String key, String value) {
    // Skip cookie setting in web - managed by browser
    // This function is a no-op for web
  }

  static Future<Map<String, dynamic>?> get(String link,
      [Map<String, dynamic>? queryParameters,
      Map<String, String>? header]) async {
    var dio = getDio();
    if (header != null) {
      dio.options.headers.addAll(header);
    }
    Response resp = await dio.get(link, queryParameters: queryParameters);
    if (resp.statusCode == 200) {
      if (resp.data is String) {
        return json.decode(resp.data);
      }
      return resp.data;
    } else {
      return null;
    }
  }

  static Future<String?> getStr(String link,
      [Map<String, dynamic>? queryParameters,
      Map<String, String>? header]) async {
    var dio = getDio();
    if (header != null) {
      dio.options.headers.addAll(header);
    }
    Response resp =
        await dio.get<String>(link, queryParameters: queryParameters);
    if (resp.statusCode == 200) {
      return resp.data;
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> post(
      String link, Map<String, dynamic> parameters,
      [Map<String, String>? header]) async {
    var dio = getDio();
    if (header != null) {
      dio.options.headers.addAll(header);
    }
    Response resp = await dio.post(link, data: parameters);
    return resp.data;
  }
}