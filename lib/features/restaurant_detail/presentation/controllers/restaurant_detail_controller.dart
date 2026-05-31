import 'package:flutter/foundation.dart';
import '../../data/models/restaurant_detail_model.dart';
import '../../domain/usecases/get_restaurant_detail_usecase.dart';

enum RestaurantDetailStatus { loading, loaded, error }

class RestaurantDetailController extends ChangeNotifier {
  final GetRestaurantDetailUseCase _useCase;

  RestaurantDetailController(this._useCase);

  RestaurantDetailStatus _status = RestaurantDetailStatus.loading;
  RestaurantDetailModel? _detail;
  String _errorMessage = '';

  RestaurantDetailStatus get status => _status;
  RestaurantDetailModel? get detail => _detail;
  String get errorMessage => _errorMessage;

  Future<void> loadDetail(int commerceId) async {
    _status = RestaurantDetailStatus.loading;
    notifyListeners();

    try {
      _detail = await _useCase.execute(commerceId);
      _status = RestaurantDetailStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = RestaurantDetailStatus.error;
    }

    notifyListeners();
  }
}
