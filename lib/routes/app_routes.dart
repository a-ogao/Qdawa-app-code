import 'package:flutter/material.dart';
import '../presentation/app_navigation_screen/app_navigation_screen.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/full_slider_screen/full_slider_screen.dart';
import '../presentation/menu_slide_display_screen/menu_slide_display_screen.dart';
import '../presentation/order_list_pharmacy_screen/order_list_pharmacy_screen.dart';
import '../presentation/order_list_screen/order_list_screen.dart';
import '../presentation/order_list_screen/delivered_porder_list_screen.dart';
import '../presentation/order_list_screen/inprocess_order_list_screen.dart';
import '../presentation/order_track_status_screen/order_track_status_screen.dart';
import '../presentation/pharmacy_list_screen/pharmacy_list_screen.dart';
import '../presentation/quotation_list_screen/quotation_list_screen.dart';
import '../presentation/quotation_list_screen/quotationrequest_patient_screen.dart';
import '../presentation/quotation_list_screen/quotationrecived_patient_screen.dart';
import '../presentation/pharmacy/quotation_requests_pharmacy_screen/quotation_requests_pharmacy_screen.dart';
import '../presentation/quotation_view_screen/quotation_view_screen.dart';
import '../presentation/scan_prescription_screen/scan_prescription_screen.dart';
import '../presentation/scanned_prescription_screen/scanned_prescription_screen.dart';
import '../presentation/sign_in_screen/sign_in_screen.dart';
import '../presentation/sign_up_screen/sign_up_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/pharmacy/quotation_requests_pharmacy_screen/submit_quotation_screen.dart';
import '../presentation/subscribe_screen/subscribe_screen.dart';
import '../presentation/success_two_screen/success_two_screen.dart';
import '../presentation/transaction_details_screen/transaction_details_screen.dart';
import '../presentation/transaction_details_screen/transaction_detailsnew_screen.dart';
import '../presentation/user_setting_screen/user_setting_screen.dart';
import '../presentation/user_verification_screen/user_verification_screen.dart';
import '../presentation/view_order_screen/view_order_screen.dart';
import '../presentation/view_order_three_screen/view_order_three_screen.dart';
import '../presentation/view_order_two_screen/view_order_two_screen.dart';
import '../presentation/pharmacy/order_list_screen/order_list_screen.dart';
import '../presentation/pharmacy/order_list_screen/delivered_order_list_screen.dart';
import '../presentation/pharmacy/order_list_screen/pending_order_list_screen.dart';
import '../presentation/pharmacy/customers_list_screen/pharmacy_customers_list_screen.dart';
import '../presentation/pharmacy/coupons_screen/pharmacy_coupons_list_screen.dart';

import '../presentation/pharmacy/quotation_requests_pharmacy_screen/view_quotation_screen.dart';
import '../presentation/pharmacy/order_view/order_view.dart';
import '../presentation/delivery/delivery_details_view/delivery_details_view.dart';
import '../presentation/pharmacy/pharmacy_dashboard_screen/pharmacy_dashboard_screen.dart';
import '../presentation/forget_password/forget_password.dart';
import '../presentation/privacy_policy/privacy_policy.dart';
import '../presentation/delivery/delivery_requests/delivery_requests.dart';
import '../presentation/delivery/delivered_orders/delivered_order_list_screen.dart';
import '../presentation/delivery/delivered_dashboard/delivery_dashboard_screen.dart';
import '../presentation/notification_screen/notification_screen.dart';
import '../presentation/pharmacy/notification_screen/notification_screen.dart';
import '../presentation/doctor/notification_screen/notification_screen.dart';
import '../presentation/delivery/notification_screen/notification_screen.dart';
import '../presentation/delivery/delivery_requests/pickeup_order_list.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/profile_screen/edit_profile.dart';
import '../presentation/profile_screen/changes.dart';
import '../presentation/profile_screen/report_code_screen.dart';
import '../presentation/invoice_screen/invoice_screen.dart';
import '../presentation/insurance_payment_screen.dart';
import '../presentation/coupon_screen.dart';
import '../presentation/medicine_request.dart';
import '../presentation/pharmacy/quotation_requests_pharmacy_screen/pharmacy_usersymptoms_screen.dart';
import '../presentation/pharmacy/quotation_requests_pharmacy_screen/submit_otc_screen.dart';
import '../presentation/pharmacy/riderlist_screen.dart';
import '../presentation/dpharmacy_list.dart';
import '../presentation/reports.dart';
import '../presentation/pharmacy/pharmcy_reports.dart';
import '../presentation/pharmacy/rider_choose_screen.dart';
import '../presentation/reminder_screen.dart';
import '../presentation/doctor/dashboard_screen/dashboard.dart';
import '../presentation/doctor/quotation_list_screen/quotation_list_screen.dart';
import '../presentation/doctor/quotation_list_screen/quotationrequest_patient_screen.dart';
import '../presentation/doctor/dpharmacy_list.dart';
import '../presentation/doctor/patientlist_screen.dart';
import '../presentation/doctor/petientview_screen.dart';
import '../presentation/doctor/order_list_screen/order_list_screen.dart';
import '../presentation/doctor/quotation_view_screen/quotation_view_screen.dart';
import '../presentation/doctor/order_list_screen/ddoctor_order_list_screen.dart';
import '../presentation/doctor/order_track_status_screen/order_track_status_screen.dart';
import '../presentation/pharmacy/payment_pharmacy_screen.dart';
import '../presentation/ddoctor_list.dart';
import '../presentation/doctor/written_prescription_list/written_prescription_list.dart';
import '../presentation/payment_history/patient_payments_screen.dart';
import '../presentation/prescriptions/patient_prescriptions_screen.dart';

// ignore_for_file: must_be_immutable
class AppRoutes {
  static const String signUpScreen = '/sign_up_screen';
  static const String report = '/reports';
  static const String preport = '/pharmacy_reports';
  static const String privacypolicy = '/privacy_policy';

  static const String orderTrackStatusScreen = '/order_track_status_screen';
  static const String dOrderTrackStatusScreen = '/doctororderview';

  static const String splashScreen = '/splash_screen';

  static const String fullSliderScreen = '/full_slider_screen';

  static const String userVerificationScreen = '/user_verification_screen';

  static const String subscribeScreen = '/subscribe_screen';

  static const String signInScreen = '/sign_in_screen';

  static const String userSettingScreen = '/user_setting_screen';

  static const String menuSlideDisplayScreen = '/menu_slide_display_screen';

  static const String dashboardScreen = '/dashboard_screen';
  static const String doctordashboardScreen = '/doctordashboard_screen';

  static const String pharmacydashboardScreen = '/pharmcy_dashboard_screen';
  static const String deliverydashboardScreen = '/delivery_dashboard_screen';

  static const String scanPrescriptionScreen = '/scan_prescription_screen';

  static const String scannedPrescriptionScreen =
      '/scanned_prescription_screen';

  static const String pharmacyListScreen = '/pharmacy_list_screen';
  static const String dpharmacyListScreen = '/dpharmacy_list';
  static const String dupharmacyListScreen = '/dupharmacy_list';

  static const String successTwoScreen = '/success_two_screen';

  static const String quotationListScreen = '/quotation_list_screen';
  static const String quotationRequestScreen =
      '/quotationrequest_patient_screen';
  static const String quotationReceivedScreen =
      '/quotationrecived_patient_screen';

  static const String dquotationListScreen = '/quotation_dlist_screen';
  static const String dquotationRequestScreen =
      '/quotationrequest_dpatient_screen';
  static const String quotationViewScreen = '/quotation_view_screen';
  static const String dquotationViewScreen = '/dquotation_view_screen';

  static const String transactionDetailsScreen = '/transaction_details_screen';
  static const String transactionDetailsnewScreen =
      '/transaction_detailsnew_screen';

  static const String orderListScreen = '/order_list_screen';
  static const String dporderListScreen = '/dpatient_order_list_screen';
  static const String inporderListScreen = '/inporder_list_screen';

  static const String DorderListScreen = '/dorder_list_screen';

  static const String quotationRequestsPharmacyScreen =
      '/quotation_requests_pharmacy_screen';

  static const String submitQuotationScreen = '/submit_quotation_screen';
  static const String submitOtc = '/submit_otc_screen';

  static const String orderListPharmacyScreen = '/order_list_pharmacy_screen';

  static const String viewOrderScreen = '/view_order_screen';

  static const String viewOrderTwoScreen = '/view_order_two_screen';

  static const String viewOrderThreeScreen = '/view_order_three_screen';

  static const String appNavigationScreen = '/app_navigation_screen';

  static const String initialRoute = '/initialRoute';
  static const String dPharmacyorderlist = '/dPharmacy_order_list_screen';

  static const String viewPharmacyorderlist = '/Pharmacy_order_list_screen';
  static const String pendingPharmacyorderlist = '/Pending_order_list_screen';
  static const String viewPharmacyquotlist = '/view_quotation_screen';
  static const String orderview = '/order_view';
  static const String deliverydetails = '/delivery_details';
  static const String deliveryorders = '/delivery_orders';
  static const String pickedorders = '/pickeup_requests';
  static const String deliveryrequests = '/delivery_requests';
  static const String forgetscreen = '/forget_screen';
  static const String notification = '/notification';
  static const String dnotification = '/dnotification';

  static const String pharmacynotification = '/pharmacy_notification';
  static const String doctornotification = '/doctor_notification';
  static const String profilescreen = '/profile_screen';
  static const String editprofile = '/edit_profile';
  static const String changeemail = '/change_email';
  static const String changephoneno = '/change_phoneno';
  static const String changepassword = '/change_password';
  static const String reportCodeScreen = '/report_code_screen';
  static const String invoicescreen = '/invoice_screen';
  static const String reminderscreen = '/reminder_screen';
  static const String insurancepaymentscreen = '/insurance_payment_screen';
  static const String coupon_screen = '/coupon_screen';
  static const String medicinerequest = '/medicine_request';
  static const String pharmacySymptoms = '/pharmacy_usersymptoms_screen';
  static const String riderlist = '/rider_choose_screen';
  static const String viewriderlist = '/riderlist_screen';
  static const String dpatientlist = '/patientlist_screen';
  static const String dpatientview = '/patientview_screen';
  static const String ddoctororderlist = '/ddoctor_order_list_screen';
  static const String paymentscreen = '/payment_pharmacy_screen';
  static const String doctorlist = '/ddoctor_list';
  static const String writtenprescriptions = '/written_prescription_list';
  static const String patientPrescriptionsScreen =
      '/patient_prescriptions_screen';
  static const String patientPaymentsScreen = '/patient_payments_screen';
  static const String pharmacyCustomersListScreen =
      '/pharmacy_customers_list_screen';
  static const String pharmacyCouponsScreen = '/pharmacy_coupons_screen';

  static Map<String, WidgetBuilder> routes = {
    signUpScreen: (context) => SignUpScreen(),
    orderTrackStatusScreen: (context) {
      final Map<String, dynamic> arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return OrderTrackStatusScreen(orderId: arguments['orderId']);
    },
    dOrderTrackStatusScreen: (context) {
      final Map<String, dynamic> arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return DOrderTrackStatusScreen(orderId: arguments['orderId']);
    },
    dpatientview: (context) {
      final Map<String, dynamic> arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return PatientViewScreen(patientid: arguments['patientid']);
    },
    transactionDetailsScreen: (context) {
      final Map<String, dynamic> arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return TransactionDetailsScreen(trid: arguments['trid']);
    },
    transactionDetailsnewScreen: (context) {
      final Map<String, dynamic> arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return TransactionDetailsnewScreen(
        trid: arguments['trid'],
        transaction_id: arguments['transaction_id'], // Use named parameter
      );
    },
    orderview: (context) {
      final Map<String, dynamic> arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return OrderView(orderId: arguments['orderId']);
    },
    insurancepaymentscreen: (context) {
      final Map<String, dynamic> arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return InsurancePaymentScreen(qid: arguments['qid']);
    },
    coupon_screen: (context) {
      final Map<String, dynamic> arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return CouponPaymentScreen(qid: arguments['qid']);
    },
    deliverydetails: (context) {
      final Map<String, dynamic> arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      return DeliveryDetailScreen(
        orderId: arguments['orderId'],
        requestId: arguments['requestId'], // Use named parameter
      );
    },
    riderlist: (context) {
      final Map<String, dynamic> arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      return RiderListScreen(
        orderidd: arguments['orderidd'],
        ordertypee: arguments['ordertypee'], // Use named parameter
      );
    },
    submitQuotationScreen: (context) {
      final arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return SubmitQuotationScreen(id: arguments['id']);
    },
    submitOtc: (context) {
      final arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return SubmitOTCScreen(id: arguments['id']);
    },
    viewPharmacyquotlist: (context) {
      final arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return ViewQuotationScreen(id: arguments['id']);
    },
    invoicescreen: (context) {
      final arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return InvoiceScreen(orderId: arguments['orderId']);
    },
    reminderscreen: (context) {
      final arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return ReminderScreen(orderId: arguments['orderId']);
    },
    splashScreen: (context) => SplashScreen(),
    fullSliderScreen: (context) => FullSliderScreen(),
    viewriderlist: (context) => vRiderListScreen(),
    userVerificationScreen: (context) => UserVerificationScreen(),
    subscribeScreen: (context) => SubscribeScreen(),
    signInScreen: (context) => SignInScreen(),
    userSettingScreen: (context) => UserSettingScreen(),
    menuSlideDisplayScreen: (context) => MenuSlideDisplayScreen(),
    dashboardScreen: (context) => DashboardScreen(),
    doctordashboardScreen: (context) => DoctordashboardScreen(),
    deliverydashboardScreen: (context) => DeliverydashboardScreen(),
    scanPrescriptionScreen: (context) => ScanPrescriptionScreen(),
    scannedPrescriptionScreen: (context) => ScannedPrescriptionScreen(),
    pharmacyListScreen: (context) => PharmacyListScreen(),
    successTwoScreen: (context) => SuccessTwoScreen(),
    quotationListScreen: (context) => QuotationListScreen(),
    quotationRequestScreen: (context) => QuotationRequestScreen(),
    quotationReceivedScreen: (context) => QuotationReceivedScreen(),
    dquotationListScreen: (context) => DQuotationListScreen(),
    dquotationRequestScreen: (context) => DQuotationRequestScreen(),
    quotationViewScreen: (context) => QuotationViewScreen(),
    dquotationViewScreen: (context) => DQuotationViewScreen(),
    ddoctororderlist: (context) => DDoctorOrderListScreen(),
    orderListScreen: (context) => OrderListScreen(),
    inporderListScreen: (context) => inpOrderListScreen(),
    dporderListScreen: (context) => dpOrderListScreen(),
    DorderListScreen: (context) => DoctorOrderListScreen(),
    quotationRequestsPharmacyScreen: (context) =>
        QuotationRequestsPharmacyScreen(),
    orderListPharmacyScreen: (context) => OrderListPharmacyScreen(),
    viewOrderScreen: (context) => ViewOrderScreen(),
    viewOrderTwoScreen: (context) => ViewOrderTwoScreen(),
    viewOrderThreeScreen: (context) => ViewOrderThreeScreen(),
    appNavigationScreen: (context) => AppNavigationScreen(),
    initialRoute: (context) => SplashScreen(),
    viewPharmacyorderlist: (context) => PharmacyOrderListScreen(),
    pendingPharmacyorderlist: (context) => PendingOrderListScreen(),
    dPharmacyorderlist: (context) => dPharmacyOrderListScreen(),
    pharmacydashboardScreen: (context) => PharmacyDashboardScreen(),
    forgetscreen: (context) => ForgetPasswordScreen(),
    privacypolicy: (context) => PrivacyPolicyScreen(),
    deliveryorders: (context) => DeliveredOrdersItem(),
    pickedorders: (context) => RPickeupOrderList(),
    deliveryrequests: (context) => DeliveryRequests(),
    notification: (context) => NotificationScreen(),
    dnotification: (context) => DNotificationScreen(),
    pharmacynotification: (context) => PharmacyNotificationScreen(),
    doctornotification: (context) => DoctorNotificationScreen(),
    profilescreen: (context) => ProfileScreen(),
    editprofile: (context) => EditProfileScreen(),
    changeemail: (context) => ChangeEmailScreen(),
    changephoneno: (context) => ChangePhoneNumberScreen(),
    changepassword: (context) => ChangePasswordScreen(),
    reportCodeScreen: (context) => ReportCodeScreen(),
    medicinerequest: (context) => MedicineRequestScreen(),
    pharmacySymptoms: (context) => PharmacySymptomsScreen(),
    dpharmacyListScreen: (context) => DPharmacyListScreen(),
    dupharmacyListScreen: (context) => DUPharmacyListScreen(),
    report: (context) => ReportsPage(),
    preport: (context) => PReportsPage(),
    dpatientlist: (context) => DUPatientListScreen(),
    paymentscreen: (context) => PaymentListScreen(),
    doctorlist: (context) => DddoctorListScreen(),
    writtenprescriptions: (context) => WrittenPrescriptionListScreen(),
    patientPrescriptionsScreen: (context) => PatientPrescriptionsScreen(),
    patientPaymentsScreen: (context) => PatientPaymentsScreen(),
    pharmacyCustomersListScreen: (context) => PharmacyCustomersListScreen(),
    pharmacyCouponsScreen: (context) => PharmacyCouponsListScreen(),
  };
}
