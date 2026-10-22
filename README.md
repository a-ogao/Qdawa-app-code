# QuikDawa

QuikDawa is a Flutter app for ordering medicine from a prescription. Patients, pharmacies, doctors, and delivery riders each get their own workspace after sign-in. The tagline on the sign-in screen is **Your Health, Our Priority**.

A patient photographs or uploads a prescription, sends it to pharmacies, and compares the quotations that come back. After they accept a quote, they can pay, follow the order, and receive it by delivery or pickup. Pharmacies price those requests, including over-the-counter and symptom-based orders, then hand delivery orders to a rider. Doctors can review their patients, written prescriptions, and related orders. Riders pick up and deliver orders and confirm handover with a one-time code.

## Who uses it

- **Patients** scan or upload prescriptions, request quotations, choose a pharmacy, track orders, set medicine reminders, and view payments, coupons, and invoices.
- **Pharmacies** review quotation requests, submit prices and dosages, manage orders and customers, assign riders, confirm pickup with a code, and export prescription reports.
- **Doctors** see their patients, written prescriptions, quotations, and order status.
- **Delivery riders** accept pickup requests, update delivery progress, and mark orders delivered.

Sign-up, sign-in, phone or email verification, and password reset are shared. The app can also remember a session and unlock with biometrics.

## Run the app

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install), then from this folder:

```bash
flutter pub get
flutter run
```

Dependencies are listed in `pubspec.yaml`. Android and iOS signing files are not part of this source backup; add those locally before a release build.
