import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../screens/properties_screen.dart';
import '../screens/units_screen.dart';
import '../screens/tenants_screen.dart';
import '../screens/leases_screen.dart';
import '../screens/invoices_screen.dart';
import '../screens/maintenance_screen.dart';
import '../services/auth_service.dart';
import '../ui/widgets/responsive_helper.dart';

class QuickCreateModal extends StatelessWidget {
  const QuickCreateModal({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AuthService().user?.role ?? 'TENANT';
    
    final List<Map<String, dynamic>> allOptions = [
      {'icon': Icons.home_work_outlined, 'label': 'Property', 'roles': ['OWNER', 'ADMIN'], 'color': AppTheme.teal, 'dialog': () => const AddPropertyDialog()},
      {'icon': Icons.door_sliding_outlined, 'label': 'Unit', 'roles': ['OWNER', 'ADMIN', 'CARETAKER'], 'color': AppTheme.navy, 'dialog': () => const AddUnitDialog()},
      {'icon': Icons.person_add_outlined, 'label': 'Tenant', 'roles': ['OWNER', 'ADMIN', 'CARETAKER'], 'color': AppTheme.brass, 'dialog': () => const AddTenantDialog()},
      {'icon': Icons.description_outlined, 'label': 'Lease', 'roles': ['OWNER', 'ADMIN'], 'color': Colors.blue, 'dialog': () => const AddLeaseDialog()},
      {'icon': Icons.receipt_long_outlined, 'label': 'Invoice', 'roles': ['OWNER', 'ADMIN'], 'color': Colors.green, 'dialog': () => const AddInvoiceDialog()},
      {'icon': Icons.build_outlined, 'label': 'Maintenance', 'roles': ['OWNER', 'ADMIN', 'CARETAKER', 'TENANT'], 'color': Colors.orange, 'dialog': () => CreateMaintenanceDialog(isOwner: role != 'TENANT')},
    ];

    final createOptions = allOptions.where((opt) => (opt['roles'] as List<String>).contains(role)).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create New',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.mutedText),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'What would you like to add to your portfolio?',
              style: GoogleFonts.dmSans(color: AppTheme.mutedText, fontSize: 14),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: createOptions.length,
              itemBuilder: (context, index) {
                final option = createOptions[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    if (option['dialog'] != null) {
                      ResponsiveHelper.showResponsiveDialog(
                        context: context,
                        builder: (ctx) => option['dialog'](),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (option['color'] as Color).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (option['color'] as Color).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (option['color'] as Color).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(option['icon'], color: option['color'], size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          option['label'],
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
