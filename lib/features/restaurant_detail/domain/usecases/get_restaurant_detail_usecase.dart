import '../../data/models/restaurant_detail_model.dart';
import '../../data/repositories/restaurant_detail_repository.dart';

class GetRestaurantDetailUseCase {
  final RestaurantDetailRepository repository;

  GetRestaurantDetailUseCase(this.repository);

  Future<RestaurantDetailModel> execute(int commerceId) {
    return repository.getRestaurantDetail(commerceId);
  }
}
