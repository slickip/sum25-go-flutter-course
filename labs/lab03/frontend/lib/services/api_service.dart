import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static const Duration timeout = Duration(seconds: 30);
  late final http.Client _client;

  // TODO: Add constructor that initializes _client = http.Client();
  ApiService({http.Client? client}) {
    _client = client ?? http.Client();
  }

  // TODO: Add dispose() method that calls _client.close();
  void dispose() {
    _client.close();
  }

  // TODO: Add _getHeaders() method that returns Map<String, String>
  // Return headers with 'Content-Type': 'application/json' and 'Accept': 'application/json'
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // TODO: Add _handleResponse<T>() method with parameters:
  // http.Response response, T Function(Map<String, dynamic>) fromJson
  // Check if response.statusCode is between 200-299
  // If successful, decode JSON and return fromJson(decodedData)
  // If 400-499, throw client error with message from response
  // If 500-599, throw server error
  // For other status codes, throw general error
  T _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final statusCode = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (statusCode >= 200 && statusCode < 300) {
      return fromJson(body);
    } else if (statusCode >= 400 && statusCode < 500) {
      final message = body is Map && body['error'] != null
          ? body['error'].toString()
          : 'Client error: $statusCode';
      throw ApiException(message);
    } else if (statusCode >= 500 && statusCode < 600) {
      throw ServerException('Server error: $statusCode');
    } else {
      throw ApiException('Unexpected error: $statusCode');
    }
  }

  // Get all messages
  Future<List<Message>> getMessages() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/messages'), headers: _getHeaders())
          .timeout(timeout);

      return _handleResponse(response, (json) {
        final data = json['data'] as List<dynamic>;
        return data.map((item) => Message.fromJson(item)).toList();
      });
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // Create a new message
  Future<Message> createMessage(CreateMessageRequest request) async {
    request.validate();

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/messages'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);

      return _handleResponse(response, (json) {
        return Message.fromJson(json['data']);
      });
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // Update an existing message
  Future<Message> updateMessage(int id, UpdateMessageRequest request) async {
    request.validate();

    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/api/messages/$id'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);

      return _handleResponse(response, (json) {
        return Message.fromJson(json['data']);
      });
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<void> deleteMessage(int id) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/api/messages/$id'),
            headers: _getHeaders(),
          )
          .timeout(timeout);

      if (response.statusCode != 204) {
        throw ApiException('Failed to delete message');
      }
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // Get HTTP status information

  Future<HTTPStatusResponse> getHTTPStatus(int statusCode) async {
    if (statusCode < 100 || statusCode >= 600) {
      throw ValidationException('Invalid status code: $statusCode');
    }

    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/api/status/$statusCode'),
            headers: _getHeaders(),
          )
          .timeout(timeout);

      return _handleResponse(response, (json) {
        return HTTPStatusResponse.fromJson(json['data']);
      });
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/health'), headers: _getHeaders())
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(
            'Health check failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}

class ValidationException extends ApiException {
  ValidationException(String message) : super(message);
}
