import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CaretakerReportsScreen extends StatefulWidget {
  const CaretakerReportsScreen({super.key});

  @override
  State<CaretakerReportsScreen> createState() => _CaretakerReportsScreenState();
}

class _CaretakerReportsScreenState extends State<CaretakerReportsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  
  Map<String, dynamic> _reports = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await _api.getCaretakerReports();
      if (mounted) {
        setState(() {
          _reports = res['data'] ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load reports', style: GoogleFonts.bricolageGrotesque(fontSize: 18)),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadReports, child: const Text('Retry')),
          ],
        ),
      );
    }

    final incidents = _reports['incidents'] ?? {};
    final maintenance = _reports['maintenance'] ?? {};
    final vendors = (_reports['vendors'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 32),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SLA & Performance Reports',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track SLAs, overdue tasks, and vendor performance.',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 32),
            
            // SLA Summary Section
            Text(
              'SLA Summary (Overdue > 48 Hours)',
              style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.navy),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard(
                  'Overdue Incidents', 
                  incidents['overdue']?.toString() ?? '0',
                  icon: Icons.warning_amber_rounded,
                  isWarning: (incidents['overdue'] ?? 0) > 0,
                ),
                _buildStatCard(
                  'Overdue Maintenance', 
                  maintenance['overdue']?.toString() ?? '0',
                  icon: Icons.handyman_outlined,
                  isWarning: (maintenance['overdue'] ?? 0) > 0,
                ),
                _buildStatCard(
                  'Open Incidents', 
                  incidents['open']?.toString() ?? '0',
                  icon: Icons.report_problem_outlined,
                  isWarning: false,
                ),
                _buildStatCard(
                  'Resolved Incidents', 
                  incidents['resolved']?.toString() ?? '0',
                  icon: Icons.check_circle_outline,
                  isWarning: false,
                  color: AppTheme.teal,
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Vendor Performance Section
            Text(
              'Vendor Performance',
              style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.navy),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: vendors.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(child: Text('No vendors found.', style: GoogleFonts.dmSans(color: AppTheme.mutedText))),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: vendors.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final v = vendors[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.brass.withValues(alpha: 0.2),
                            child: const Icon(Icons.engineering_outlined, color: AppTheme.brass),
                          ),
                          title: Text(v['name'] ?? 'Unknown Vendor', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 16)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPill('${v['active_jobs']} Active', Colors.blue),
                              const SizedBox(width: 8),
                              _buildPill('${v['completed_jobs']} Done', AppTheme.teal),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _buildStatCard(String title, String value, {required IconData icon, bool isWarning = false, Color color = AppTheme.navy}) {
    final cardColor = isWarning ? Colors.red : color;
    
    return Container(
      width: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isWarning ? Colors.red.withValues(alpha: 0.3) : AppTheme.border),
        boxShadow: [
          BoxShadow(color: isWarning ? Colors.red.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cardColor, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: cardColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
