import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/app_store.dart';
import 'data/secure_vault.dart';
import 'pages/attendance_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/employees_page.dart';
import 'pages/help_page.dart';
import 'pages/payroll_page.dart';
import 'pages/reimbursement_page.dart';
import 'pages/reports_page.dart';
import 'pages/settings_page.dart';
import 'security/auth_state.dart';
import 'widgets/modals/security_lock_overlay.dart';
import 'widgets/sidebar.dart';
import 'widgets/topbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize hardware-backed secure storage vault with memory fallback
  SecureVault vault;
  try {
    vault = PlatformSecureVault();
  } catch (_) {
    vault = MemoryVault();
  }

  final appStore = AppStore(vault);
  final authState = AuthState(vault);

  await Future.wait([
    appStore.load(),
    authState.initialize(),
  ]);

  runApp(PayroleApp(store: appStore, authState: authState));
}

class PayroleApp extends StatelessWidget {
  const PayroleApp({
    super.key,
    required this.store,
    required this.authState,
  });

  final AppStore store;
  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payrole - HRIS & Payroll Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: SecurityLockOverlay(
        authState: authState,
        child: AppShell(store: store, authState: authState),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.store,
    required this.authState,
  });

  final AppStore store;
  final AuthState authState;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  // Start on Penggajian by default to immediately match the reference screenshot!
  AppTab _currentTab = AppTab.payroll;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.store.flush();
      widget.authState.lockSession();
    }
  }

  void _onSelectTab(AppTab tab) {
    setState(() => _currentTab = tab);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileOrTablet = constraints.maxWidth < 992;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.bg,
          // Drawer for mobile / tablet screens
          drawer: isMobileOrTablet
              ? Drawer(
                  child: Sidebar(
                    currentTab: _currentTab,
                    onSelectTab: _onSelectTab,
                    companyName: widget.store.settings.companyName,
                    isDrawer: true,
                    onLogout: () => widget.authState.lockSession(),
                  ),
                )
              : null,
          body: Row(
            children: [
              // Desktop Fixed Sidebar
              if (!isMobileOrTablet)
                Sidebar(
                  currentTab: _currentTab,
                  onSelectTab: _onSelectTab,
                  companyName: widget.store.settings.companyName,
                  onLogout: () => widget.authState.lockSession(),
                ),

              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    // Topbar
                    Topbar(
                      currentTab: _currentTab,
                      isMobile: isMobileOrTablet,
                      onMenuPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      onNotificationPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tidak ada notifikasi baru. Semua data tersinkron.',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),

                    // Active Tab View
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildCurrentTab(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case AppTab.summary:
        return DashboardPage(
          key: const ValueKey('summary'),
          store: widget.store,
          onNavigateToTab: _onSelectTab,
        );
      case AppTab.employees:
        return EmployeesPage(
          key: const ValueKey('employees'),
          store: widget.store,
        );
      case AppTab.attendance:
        return AttendancePage(
          key: const ValueKey('attendance'),
          store: widget.store,
        );
      case AppTab.payroll:
        return PayrollPage(
          key: const ValueKey('payroll'),
          store: widget.store,
        );
      case AppTab.reimbursement:
        return ReimbursementPage(
          key: const ValueKey('reimbursement'),
          store: widget.store,
        );
      case AppTab.reports:
        return ReportsPage(
          key: const ValueKey('reports'),
          store: widget.store,
        );
      case AppTab.settings:
        return SettingsPage(
          key: const ValueKey('settings'),
          store: widget.store,
          authState: widget.authState,
        );
      case AppTab.help:
        return const HelpPage(
          key: ValueKey('help'),
        );
    }
  }
}
