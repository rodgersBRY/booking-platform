import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'barber_shell_controller.dart';
import 'models/staff_customer_model.dart';
import 'repositories/staff_customers_repository.dart';

/// Drives the barber "My Customers" tab — GET /v1/staff/clients, with
/// server-side search as the barber types. Per BARBER-APP.md's Customers
/// section: "Not the entire customer database" — only clients this staff
/// member has served.
class BarberCustomersController extends GetxController {
  final StaffCustomersRepository _repo = StaffCustomersRepository();

  final searchController = TextEditingController();
  final query = ''.obs;
  final customers = <StaffCustomerModel>[].obs;

  final loading = true.obs;

  final loadError = RxnString();

  final refreshError = RxnString();

  Timer? _searchDebounce;
  Worker? _tabWorker;

  @override
  void onInit() {
    super.onInit();
    _fetch();

    // Refresh whenever the barber switches back to this tab — same
    // rationale as BarberScheduleController's tab-focus refresh (the
    // shell keeps every tab alive in an IndexedStack, so there's no
    // page-opened lifecycle hook to use instead).
    if (Get.isRegistered<BarberShellController>()) {
      final shell = Get.find<BarberShellController>();
      _tabWorker = ever<int>(shell.currentTab, (tab) {
        if (tab == barberCustomersTabIndex) refreshCustomers();
      });
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    _tabWorker?.dispose();
    super.onClose();
  }

  void onQueryChanged(String value) {
    query.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _fetch);
  }

  Future<void> refreshCustomers() async {
    refreshError.value = null;
    await _fetch();
  }

  Future<void> _fetch() async {
    final searchedQuery = query.value.trim();
    if (customers.isEmpty) loading.value = true;

    final result = await _repo.fetchMyCustomers(
      query: searchedQuery.isEmpty ? null : searchedQuery,
    );

    if (query.value.trim() != searchedQuery) return;

    loading.value = false;
    if (result.success) {
      customers.assignAll(result.customers ?? []);
      loadError.value = null;
      refreshError.value = null;
    } else if (customers.isEmpty) {
      loadError.value = result.message;
    } else {
      refreshError.value = result.message;
    }
  }
}
