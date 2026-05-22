import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reduccion_desperdicio_alimentos/core/constants/api_constants.dart';
import '../models/order_model.dart';

class OrderRepository {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String _tokenKey = 'auth_token';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<OrderResponse> createOrder({
    required int productId,
    required int quantity,
    String paymentMethod = 'cash',
  }) async {
    final token = await _getToken();
    if (token == null) throw OrderAuthException();

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

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return OrderResponse.fromJson(data);
    }

    final body = _tryDecodeBody(response.body);
    if (response.statusCode == 400) {
      if (body?.contains('ya no está disponible') == true) {
        throw OrderNotAvailableException();
      }
      if (body?.contains('Solo quedan') == true || body?.contains('unidades disponibles') == true) {
        throw OrderInsufficientStockException(body ?? 'Cantidad no disponible');
      }
    }
    if (response.statusCode == 401) {
      throw OrderAuthException();
    }

    throw OrderException(body ?? 'Error al crear la reserva (${response.statusCode})');
  }

  Future<List<OrderResponse>> getMyOrders() async {
    final token = await _getToken();
    if (token == null) throw OrderAuthException();

    final response = await http.get(
      Uri.parse('$baseUrl/orders/my-orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => OrderResponse.fromJson(json)).toList();
    }
    if (response.statusCode == 401) throw OrderAuthException();

    throw OrderException('Error al obtener pedidos (${response.statusCode})');
  }

  Future<OrderResponse> payOrder({
    required int orderId,
    String paymentProvider = 'stripe',
    String? transactionId,
  }) async {
    final token = await _getToken();
    if (token == null) throw OrderAuthException();

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
      return OrderResponse.fromJson(jsonDecode(response.body));
    }

    final msg = _tryDecodeBody(response.body);
    if (response.statusCode == 400) {
      if (msg?.contains('ya fue pagado') == true) {
        throw OrderException('El pedido ya fue pagado');
      }
      if (msg?.contains('cancelada') == true) {
        throw OrderException('No se puede pagar una orden cancelada');
      }
      if (msg?.contains('efectivo') == true) {
        throw OrderException('Los pedidos en efectivo se pagan al recoger');
      }
    }
    if (response.statusCode == 404) throw OrderException('Pedido no encontrado');
    if (response.statusCode == 401) throw OrderAuthException();

    throw OrderException(msg ?? 'Error al procesar el pago (${response.statusCode})');
  }

  Future<OrderResponse> cancelOrder(int orderId) async {
    final token = await _getToken();
    if (token == null) throw OrderAuthException();

    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return OrderResponse.fromJson(jsonDecode(response.body));
    }

    final msg = _tryDecodeBody(response.body);
    if (response.statusCode == 400) {
      if (msg?.contains('cancelada') == true) {
        throw OrderException('El pedido ya fue cancelado');
      }
    }
    if (response.statusCode == 404) throw OrderException('Pedido no encontrado');
    if (response.statusCode == 401) throw OrderAuthException();

    throw OrderException(msg ?? 'Error al cancelar el pedido (${response.statusCode})');
  }

  String? _tryDecodeBody(String raw) {
    try {
      final data = jsonDecode(raw);
      return data['message']?.toString();
    } catch (_) {
      return raw;
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
