import 'package:flutter_bloc/flutter_bloc.dart';

import 'location_service.dart';

sealed class LocationState {}

class LocLoading extends LocationState {}

class LocReady extends LocationState {}

class LocationCubit extends Cubit<LocationState> {
  LocationCubit() : super(LocLoading()) {
    _init();
  }

  final _svc = LocationService();

  Future<void> _init() async {
    await _svc.prefetchStates();
    emit(LocReady());
  }

  List<String> get states => _svc.states;

  Future<List<String>> districts(String s) => _svc.districts(s);

  List<String>? cachedDistricts(String s) => _svc.cachedDistricts(s);
}
