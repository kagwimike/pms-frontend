import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class MaintenanceSection extends StatelessWidget {
  const MaintenanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Complete maintenance control.',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 80),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 900;
                  
                  if (isMobile) {
                    return Column(
                      children: [
                        _buildWorkflowStep('Tenant reports issue'),
                        _buildArrow(),
                        _buildWorkflowStep('Manager reviews'),
                        _buildArrow(),
                        _buildWorkflowStep('Vendor assigned'),
                        _buildArrow(),
                        _buildWorkflowStep('Vendor works'),
                        _buildArrow(),
                        _buildWorkflowStep('Inspection'),
                        _buildArrow(),
                        _buildWorkflowStep('Issue resolved', isFinal: true),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWorkflowStep('Tenant\nreports'),
                      _buildArrow(horizontal: true),
                      _buildWorkflowStep('Manager\nreviews'),
                      _buildArrow(horizontal: true),
                      _buildWorkflowStep('Vendor\nassigned'),
                      _buildArrow(horizontal: true),
                      _buildWorkflowStep('Vendor\nworks'),
                      _buildArrow(horizontal: true),
                      _buildWorkflowStep('Inspection'),
                      _buildArrow(horizontal: true),
                      _buildWorkflowStep('Resolved', isFinal: true),
                    ],
                  );
                },
              ),
              const SizedBox(height: 80),
              
              // Maintenance UI placeholder
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width > 768 ? 400 : 250,
                decoration: BoxDecoration(
                  color: AppTheme.bgGreyGreen,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/feature_maintenance.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowStep(String text, {bool isFinal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isFinal ? AppTheme.teal : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isFinal ? AppTheme.teal : AppTheme.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isFinal ? Colors.white : AppTheme.navy,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildArrow({bool horizontal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: horizontal ? 0 : 16,
        horizontal: horizontal ? 16 : 0,
      ),
      child: Icon(
        horizontal ? Icons.arrow_forward_rounded : Icons.arrow_downward_rounded,
        color: AppTheme.mutedText.withValues(alpha: 0.5),
        size: 24,
      ),
    );
  }
}
