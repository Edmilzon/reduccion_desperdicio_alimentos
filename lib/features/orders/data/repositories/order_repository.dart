import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:reduccion_desperdicio_alimentos/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_model.dart';
import '../models/pickup_validation_result.dart';

class OrderRepository {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String _tokenKey = 'auth_token';

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) {
      throw OrderAuthException();
    }

    return token;
  }

  Future<OrderModel> createCashOrder({
    required int productId,
    required int quantity,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        'paymentMethod': 'cash',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return OrderModel.fromJson(jsonDecode(response.body));
    }

    _handleOrderError(response);
  }

  Future<OrderModel> createOrder({
    required int productId,
    required int quantity,
    String paymentMethod = 'cash',
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        'paymentMethod': paymentMethod,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return OrderModel.fromJson(jsonDecode(response.body));
    }

    _handleOrderError(response);
  }

  Future<List<OrderModel>> getMyOrders() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/orders/my-orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => OrderModel.fromJson(json)).toList();
    }

    _handleOrderError(response);
  }

  Future<List<OrderModel>> getMerchantOrders() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/orders/merchant'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => OrderModel.fromJson(json)).toList();
    }

    _handleOrderError(response);
  }

  Future<OrderModel> payOrder({
    required int orderId,
    String paymentProvider = 'stripe',
    String? transactionId,
  }) async {
    final token = await _getToken();

    final body = <String, dynamic>{
      'paymentProvider': paymentProvider,
    };
    if (transactionId != null) body['transactionId'] = transactionId;

    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/pay'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(response.body));
    }

    final msg = _extractErrorRaw(response);
    if (response.statusCode == 400) {
      if (msg.contains('ya fue pagado')) {
        throw OrderException('El pedido ya fue pagado');
      }
      if (msg.contains('cancelada')) {
        throw OrderException('No se puede pagar una orden cancelada');
      }
      if (msg.contains('efectivo')) {
        throw OrderException('Los pedidos en efectivo se pagan al recoger');
      }
    }
    if (response.statusCode == 404) throw OrderException('Pedido no encontrado');
    if (response.statusCode == 401) throw OrderAuthException();

    throw OrderException(msg);
  }

  Future<OrderModel> cancelOrder(int orderId) async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(response.body));
    }

    final msg = _extractErrorRaw(response);
    if (response.statusCode == 400) {
      throw OrderException(msg);
    }
    if (response.statusCode == 404) throw OrderException('Pedido no encontrado');
    if (response.statusCode == 401) throw OrderAuthException();

    throw OrderException(msg);
  }

  Future<OrderModel> markPaidAndDelivered(int orderId) async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/mark-paid-delivered'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(response.body));
    }

    _handleOrderError(response);
  }

  Future<OrderModel> deliverOrder(int orderId) async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/deliver'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(response.body));
    }

    final msg = _extractErrorRaw(response);
    if (response.statusCode == 400) throw OrderException(msg);
    if (response.statusCode == 401) throw OrderAuthException();
    if (response.statusCode == 403) throw OrderException('No tienes permiso para realizar esta acción');
    if (response.statusCode == 404) throw OrderException('Pedido no encontrado');
    throw OrderException(msg);
  }

  Future<OrderModel> markAsNotPickedUp(int orderId) async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/mark-not-picked-up'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(response.body));
    }

    final msg = _extractErrorRaw(response);
    if (response.statusCode == 400) throw OrderException(msg);
    if (response.statusCode == 401) throw OrderAuthException();
    if (response.statusCode == 403) throw OrderException('No tienes permiso para realizar esta acción');
    if (response.statusCode == 404) throw OrderException('Pedido no encontrado');
    throw OrderException(msg);
  }

  Future<PickupValidationResult> validatePickup({
  required String reservationCode,
}) async {
  final token = await _getToken();

  final response = await http.post(
    Uri.parse('$baseUrl/orders/validate-pickup'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'reservationCode': reservationCode.trim(),
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return PickupValidationResult.fromJson(jsonDecode(response.body));
  }

  final message = _extractErrorRaw(response);

  if (response.statusCode == 400) {
    throw OrderException(message);
  }

  if (response.statusCode == 401) {
    throw OrderAuthException();
  }

  if (response.statusCode == 403) {
    throw OrderException('No tienes permiso para validar este pedido');
  }

  if (response.statusCode == 404) {
    throw OrderException(
      message.isEmpty ? 'Código inválido' : message,
    );
  }

  throw OrderException(message);
}

  Never _handleOrderError(http.Response response) {
    final message = _extractError(response);

    if (response.statusCode == 400) {
      if (message.contains('ya no está disponible') ||
          message.contains('Oferta agotada')) {
        throw OrderNotAvailableException();
      }

      if (message.contains('Solo quedan') ||
          message.contains('unidades disponibles') ||
          message.contains('Cantidad no disponible')) {
        throw OrderInsufficientStockException(message);
      }

      throw OrderException(message);
    }

    if (response.statusCode == 401) {
      throw OrderAuthException();
    }

    if (response.statusCode == 403) {
      throw OrderException('No tienes permiso para realizar esta acción');
    }

    if (response.statusCode == 404) {
      throw OrderException('Pedido no encontrado');
    }

    throw OrderException(message);
  }

  String _extractError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final message = data['message'];

      if (message is List) {
        return message.join(', ');
      }

      return message?.toString() ??
          'Error inesperado (${response.statusCode})';
    } catch (_) {
      return 'Error de conexión con el servidor (${response.statusCode})';
    }
  }

  String _extractErrorRaw(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['message']?.toString() ?? 'Error desconocido';
    } catch (_) {
      return 'Error de conexión con el servidor (${response.statusCode})';
    }
  }
}

class OrderException implements Exception {
  final String message;

  OrderException(this.message);

  @override
  String toString() => message;
}

class OrderAuthException extends OrderException {
  OrderAuthException() : super('Debes iniciar sesión para reservar');
}

class OrderNotAvailableException extends OrderException {
  OrderNotAvailableException() : super('Oferta agotada');
}

class OrderInsufficientStockException extends OrderException {
  OrderInsufficientStockException(super.message);
}
