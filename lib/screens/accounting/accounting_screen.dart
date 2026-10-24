import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'tabs/accounting_dashboard_tab.dart';
import 'tabs/chart_of_accounts_tab.dart';
import 'tabs/general_ledger_tab.dart';
import 'tabs/journal_entries_tab.dart';
import 'tabs/financial_reports_tab.dart';
import 'tabs/subledgers_tab.dart';
import 'tabs/accounting_periods_tab.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabLabels = [
    'Overview',
    'Chart of Accounts',
    'General Ledger',
    'Journals',
    'Financial Reports',
    'Subledgers',
    'Periods',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGreyGreen,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Professional Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.navy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Double-Entry Accounting & Ledger',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.navy,
                          ),
                        ),
                        Text(
                          'Compliant general ledger, chart of accounts, and financial reporting',
                          style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: AppTheme.teal),
                      const SizedBox(width: 6),
                      Text(
                        'BALANCED & AUDITED',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sub-Tab Navigation Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.navy,
              unselectedLabelColor: AppTheme.mutedText,
              indicatorColor: AppTheme.teal,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: _tabLabels.map((lbl) => Tab(text: lbl)).toList(),
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AccountingDashboardTab(
                  onNavigateToJournals: () => _tabController.animateTo(3),
                  onNavigateToReports: () => _tabController.animateTo(4),
                ),
                const ChartOfAccountsTab(),
                const GeneralLedgerTab(),
                const JournalEntriesTab(),
                const FinancialReportsTab(),
                const SubledgersTab(),
                const AccountingPeriodsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
