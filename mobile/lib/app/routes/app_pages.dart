import 'package:get/get.dart';

import '../modules/account/account_binding.dart';
import '../modules/account/account_page.dart';
import '../modules/booking/booking_binding.dart';
import '../modules/booking/pages/category_list_page.dart';
import '../modules/booking/pages/confirmation_page.dart';
import '../modules/booking/pages/details_page.dart';
import '../modules/booking/pages/service_list_page.dart';
import '../modules/booking/pages/slot_page.dart';
import '../modules/booking/pages/staff_list_page.dart';
import '../modules/login/login_binding.dart';
import '../modules/login/login_page.dart';
import '../modules/welcome/welcome_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = <GetPage>[
    GetPage(name: AppRoutes.welcome, page: () => const WelcomePage()),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.account,
      page: () => const AccountPage(),
      binding: AccountBinding(),
    ),
    GetPage(
      name: AppRoutes.bookCategory,
      page: () => const CategoryListPage(),
      binding: BookingBinding(),
    ),
    GetPage(name: AppRoutes.bookService, page: () => const ServiceListPage()),
    GetPage(name: AppRoutes.bookStaff, page: () => const StaffListPage()),
    GetPage(name: AppRoutes.bookSlot, page: () => const SlotPage()),
    GetPage(name: AppRoutes.bookDetails, page: () => const DetailsPage()),
    GetPage(
      name: AppRoutes.bookConfirmation,
      page: () => const ConfirmationPage(),
    ),
  ];
}
