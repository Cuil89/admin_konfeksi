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

  group('Konveksi Notebook & Cash Denomination Tests', () {
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

    test('Photo ledger 18 workers data match exact financial totals', () {
      final records = store.konveksiRecords;
      expect(records.length, 18);

      // Verify exact totals matching handwritten photo
      expect(store.konveksiTotalDays, 100.5);
      expect(store.konveksiTotalOvertime, 595000);
      expect(store.konveksiTotalLoanDeduction, 350000);
      expect(store.konveksiTotalNet, 6873000);

      // Spot check workers
      final acep = records.firstWhere((r) => r.name == 'Acep');
      expect(acep.days, 6.0);
      expect(acep.baseWage, 700000);
      expect(acep.overtime, 40000);
      expect(acep.loanDeduction, 0);
      expect(acep.netWage, 740000);

      final dian = records.firstWhere((r) => r.name == 'Dian');
      expect(dian.days, 4.5);
      expect(dian.baseWage, 390000);
      expect(dian.overtime, 10000);
      expect(dian.netWage, 400000);

      final ucup = records.firstWhere((r) => r.name == 'Ucup');
      expect(ucup.days, 5.5);
      expect(ucup.baseWage, 458000);
      expect(ucup.overtime, 40000);
      expect(ucup.loanDeduction, 50000);
      expect(ucup.netWage, 448000);

      final nengsih = records.firstWhere((r) => r.name == 'Nengsih');
      expect(nengsih.days, 6.0);
      expect(nengsih.baseWage, 360000);
      expect(nengsih.overtime, 40000);
      expect(nengsih.loanDeduction, 150000);
      expect(nengsih.netWage, 250000);
    });

    test('Cash denominations calculator breaks down net cash perfectly for bank tellers', () {
      final denoms = store.konveksiCashDenominations;
      final sumDenoms = denoms.fold<int>(0, (sum, d) => sum + d.total);
      expect(sumDenoms, store.konveksiTotalNet);
      expect(sumDenoms, 6873000);

      // Verify no invalid negative or zero bank notes in breakdown list
      for (final d in denoms) {
        expect(d.nominal, greaterThan(0));
        expect(d.count, greaterThanOrEqualTo(0));
        expect(d.total, d.nominal * d.count);
      }
    });

    test('Konveksi record CRUD and day steppers work seamlessly', () {
      final initialCount = store.konveksiRecords.length;
      final ucup = store.konveksiRecords.firstWhere((r) => r.name == 'Ucup');

      // Update days (e.g. +0.5 days stepper)
      store.updateKonveksiRecord(ucup.copyWith(days: 6.0));
      final updatedUcup = store.konveksiRecords.firstWhere((r) => r.id == ucup.id);
      expect(updatedUcup.days, 6.0);

      // Add new worker
      final newId = store.addKonveksiRecord(
        name: 'Budi Santoso',
        days: 5.5,
        dailyRate: 60000,
        overtime: 30000,
        loanDeduction: 0,
        remainingLoan: 0,
        department: 'Finishing / QC',
      );
      expect(store.konveksiRecords.length, initialCount + 1);
      final budi = store.konveksiRecords.firstWhere((r) => r.id == newId);
      expect(budi.name, 'Budi Santoso');
      expect(budi.baseWage, 330000); // 5.5 * 60,000 = 330,000
      expect(budi.netWage, 360000); // 330,000 + 30,000

      // Delete worker
      store.deleteKonveksiRecord(newId);
      expect(store.konveksiRecords.length, initialCount);

      // Reset to original photo
      store.resetKonveksiToPhoto();
      expect(store.konveksiRecords.length, 18);
      expect(store.konveksiTotalNet, 6873000);
    });
  });
}

