import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:payrole/core/format.dart';
import 'package:payrole/data/app_store.dart';
import 'package:payrole/data/secure_vault.dart';
import 'package:payrole/main.dart';
import 'package:payrole/security/auth_state.dart';
import 'package:payrole/security/pin_hasher.dart';

void main() {
  group('Payrole UI Responsive & Integrity Tests', () {
    late MemoryVault vault;
    late AppStore store;
    late AuthState authState;

    setUp(() async {
      vault = MemoryVault();
      store = AppStore(vault);
      authState = AuthState(vault);

      await store.load();
      await authState.initialize();
    });

    tearDown(() async {
      await store.flush();
    });

    testWidgets('Desktop viewport (1280x800) renders cleanly with 0 overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(PayroleApp(store: store, authState: authState));
      await tester.pumpAndSettle();

      // Check key desktop widgets
      expect(find.text('payrole'), findsOneWidget);
      expect(find.text('Penggajian'), findsWidgets);
      expect(find.text('Rp88.000.000'), findsWidgets);
      expect(find.text('Rp80.000.000'), findsWidgets);
      expect(find.text('Rp12.000.000'), findsWidgets);
      expect(find.text('Rp4.000.000'), findsWidgets);
      expect(find.text('Bon dan hutang karyawan'), findsOneWidget);
      expect(find.text('Aditya Pratama'), findsOneWidget);
      expect(find.text('Dimas Saputra'), findsWidgets);

      await store.flush();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Tablet viewport (768x1024) renders cleanly with 0 overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(PayroleApp(store: store, authState: authState));
      await tester.pumpAndSettle();

      expect(find.text('Penggajian'), findsWidgets);
      expect(find.text('Rp88.000.000'), findsWidgets);

      await store.flush();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Mobile viewport (360x780) renders cleanly with 0 overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(PayroleApp(store: store, authState: authState));
      await tester.pumpAndSettle();

      // Mobile renders app bar with drawer icon and payroll content
      expect(find.text('Penggajian'), findsWidgets);
      expect(find.text('Rp88.000.000'), findsWidgets);

      // Verify that no RenderFlex overflow exception occurred
      expect(tester.takeException(), isNull);

      await store.flush();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Navigation switches pages smoothly with 0 errors',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(PayroleApp(store: store, authState: authState));
      await tester.pumpAndSettle();

      // Navigate to Ringkasan
      await tester.tap(find.text('Ringkasan'));
      await tester.pumpAndSettle();
      expect(find.text('Total Karyawan'), findsOneWidget);
      expect(find.text('Sudah dibayar'), findsWidgets);
      expect(find.text('Rp61.550.000'), findsWidgets);
      expect(find.text('Rp26.450.000'), findsWidgets);

      // Navigate to Karyawan
      await tester.tap(find.text('Karyawan'));
      await tester.pumpAndSettle();
      expect(find.text('Tambah Karyawan'), findsOneWidget);

      // Navigate to Kehadiran
      await tester.tap(find.text('Kehadiran'));
      await tester.pumpAndSettle();
      expect(find.text('Kelola presensi harian karyawan dan izin kerja.'), findsOneWidget);

      // Navigate to Reimbursement
      await tester.tap(find.text('Reimbursement'));
      await tester.pumpAndSettle();
      expect(find.text('Klaim pengeluaran operasional dan medis karyawan.'), findsOneWidget);

      // Navigate to Laporan
      await tester.tap(find.text('Laporan'));
      await tester.pumpAndSettle();
      expect(find.text('Laporan & Analitik'), findsOneWidget);

      // Navigate to Pengaturan
      await tester.tap(find.text('Pengaturan'));
      await tester.pumpAndSettle();
      expect(find.text('Konfigurasi data perusahaan, tanggal pembayaran gaji, dan keamanan cyber.'), findsOneWidget);

      // Navigate to Pusat bantuan
      await tester.tap(find.text('Pusat bantuan'));
      await tester.pumpAndSettle();
      expect(find.text('Pusat Bantuan'), findsOneWidget);

      expect(tester.takeException(), isNull);

      await store.flush();
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('Mathematical & Business Logic Tests', () {
    late MemoryVault vault;
    late AppStore store;

    setUp(() async {
      vault = MemoryVault();
      store = AppStore(vault);
      await store.load();
    });

    tearDown(() async {
      await store.flush();
    });

    test('Exact baseline payroll math: 80jt + 12jt - 4jt = 88jt', () {
      final totals = store.totals;
      expect(totals.count, 8);
      expect(totals.base, 80000000);
      expect(totals.allowance, 12000000);
      expect(totals.gross, 92000000);
      expect(totals.deduction, 4000000);
      expect(totals.net, 88000000);

      // Status breakdown
      expect(totals.paidCount, 5);
      expect(totals.paidAmount, 61550000);
      expect(totals.readyCount, 2);
      expect(totals.readyAmount, 18700000);
      expect(totals.reviewCount, 1);
      expect(totals.reviewAmount, 7750000);
      expect(totals.unpaidAmount, 26450000);
    });

    test('Kasbon remaining and status logic', () {
      final loans = store.loans;
      expect(loans.length, 4);

      // BON-001 (ND-008): 1.5jt - 250k = 1.25jt (Belum lunas)
      final l1 = loans.firstWhere((l) => l.id == 'BON-001');
      expect(l1.remaining, 1250000);
      expect(l1.isPaidOff, isFalse);
      expect(l1.statusLabel, 'Belum lunas');

      // BON-004 (ND-006): 300k - 300k = 0 (Lunas)
      final l4 = loans.firstWhere((l) => l.id == 'BON-004');
      expect(l4.remaining, 0);
      expect(l4.isPaidOff, isTrue);
      expect(l4.statusLabel, 'Lunas');
    });

    test('Kasbon sync toggle updates payroll deductions accurately', () {
      // Find BON-001 for Dimas Saputra (ND-008)
      expect(store.loanDeductionFor('ND-008'), 0); // initially syncToPayroll is false

      // Toggle sync to payroll
      store.setLoanSync('BON-001', true);
      expect(store.loanDeductionFor('ND-008'), 250000);

      // Verify line for Dimas now includes the loan deduction
      final dimas = store.employeeById('ND-008')!;
      final line = store.lineFor(dimas);
      expect(line.loanDeduction, 250000);
      expect(line.statutory, 250000); // 70k + 180k + 0 = 250k
      expect(line.deduction, 500000); // 250k + 250k = 500k
      expect(line.net, 7500000); // 8jt gross - 500k = 7.5jt

      // Toggle back off
      store.setLoanSync('BON-001', false);
      expect(store.loanDeductionFor('ND-008'), 0);
    });

    test('Indonesian currency formatter conforms to spec', () {
      expect(Fmt.rupiah(88000000), 'Rp88.000.000');
      expect(Fmt.rupiah(80000000), 'Rp80.000.000');
      expect(Fmt.rupiah(0), 'Rp0');
      expect(Fmt.compact(88000000), '88 jt');
      expect(Fmt.compact(61550000), '61,5 jt');
    });
  });

  group('Cybersecurity & Cryptography Tests', () {
    test('PBKDF2 derives reproducible key with same salt & PIN', () {
      final salt = PinHasher.randomSalt();
      final key1 = PinHasher.deriveSync('246813', salt, 1000);
      final key2 = PinHasher.deriveSync('246813', salt, 1000);
      final key3 = PinHasher.deriveSync('999999', salt, 1000);

      expect(PinHasher.constantTimeEquals(key1, key2), isTrue);
      expect(PinHasher.constantTimeEquals(key1, key3), isFalse);
    });

    test('Constant-time equals handles different lengths safely', () {
      expect(PinHasher.constantTimeEquals([1, 2, 3], [1, 2]), isFalse);
      expect(PinHasher.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    });

    test('PIN weakness validation catches weak patterns', () {
      expect(PinHasher.weaknessOf('12345'), isNotNull); // not 6 digits
      expect(PinHasher.weaknessOf('111111'), isNotNull); // same digits
      expect(PinHasher.weaknessOf('123456'), isNotNull); // sequential up
      expect(PinHasher.weaknessOf('654321'), isNotNull); // sequential down
      expect(PinHasher.weaknessOf('121212'), isNotNull); // common
      expect(PinHasher.weaknessOf('582914'), isNull); // good PIN
    });

    test('AuthState lockout increases with failed attempts', () async {
      final vault = MemoryVault();
      final auth = AuthState(vault);
      await auth.initialize();

      // Set a valid PIN
      await auth.setPin('582914');
      expect(auth.isPinSet, isTrue);
      expect(auth.isPinRequired, isTrue);

      // Lock session
      auth.lockSession();
      expect(auth.isUnlocked, isFalse);

      // Try wrong PIN 5 times to trigger lockout
      for (var i = 0; i < 5; i++) {
        expect(await auth.verifyPin('000000'), isFalse);
      }

      expect(auth.failedAttempts, 5);
      expect(auth.isLockedOut, isTrue);
      expect(auth.remainingLockoutSeconds, greaterThan(0));

      // Correct PIN fails while locked out
      expect(await auth.verifyPin('582914'), isFalse);
    });
  });
}
