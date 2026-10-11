import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleExperienceSection extends StatefulWidget {
  const RoleExperienceSection({super.key});

  @override
  State<RoleExperienceSection> createState() => _RoleExperienceSectionState();
}

class _RoleExperienceSectionState extends State<RoleExperienceSection> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _roles = [
    {
      'title': 'Property Manager',
      'features': ['Portfolio overview', 'Rent collection', 'Tenant management', 'Maintenance', 'Reporting', 'Communication'],
    },
    {
      'title': 'Property Owner',
      'features': ['Portfolio performance', 'Income', 'Occupancy', 'Property activity', 'Reports'],
    },
    {
      'title': 'Caretaker',
      'features': ['Tenant communication', 'Maintenance', 'Inspections', 'Property operations'],
    },
    {
      'title': 'Tenant',
      'features': ['Rent', 'Payments', 'Lease', 'Maintenance requests', 'Documents', 'Communication'],
    },
    {
      'title': 'Maintenance Vendor',
      'features': ['Assigned jobs', 'Job status', 'Work details', 'Communication', 'Completion records'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.navy,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'One platform. Every role.',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 64),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;

                  if (isMobile) {
                    return Column(
                      children: _roles.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final role = entry.value;
                        final isSelected = _selectedIndex == idx;
                        return Column(
                          children: [
                            InkWell(
                              onTap: () => setState(() => _selectedIndex = idx),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.teal : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? AppTheme.teal : Colors.white24),
                                ),
                                child: Text(
                                  role['title'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (role['features'] as List<String>).map((f) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: AppTheme.teal, size: 20),
                                        const SizedBox(width: 12),
                                        Text(f, style: const TextStyle(color: Colors.white, fontSize: 16)),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }).toList(),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _roles.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final role = entry.value;
                            final isSelected = _selectedIndex == idx;
                            return InkWell(
                              onTap: () => setState(() => _selectedIndex = idx),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.teal : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  role['title'],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 64),
                      // Content
                      Expanded(
                        flex: 7,
                        child: Container(
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _roles[_selectedIndex]['title'] + ' Experience',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Wrap(
                                spacing: 24,
                                runSpacing: 24,
                                children: (_roles[_selectedIndex]['features'] as List<String>).map((f) => SizedBox(
                                  width: 250,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: AppTheme.teal, size: 24),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          f,
                                          style: const TextStyle(color: Colors.white, fontSize: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
