import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class WorkspaceOnboardingScreen extends StatefulWidget {
  const WorkspaceOnboardingScreen({super.key});

  @override
  State<WorkspaceOnboardingScreen> createState() => _WorkspaceOnboardingScreenState();
}

class _WorkspaceOnboardingScreenState extends State<WorkspaceOnboardingScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  int _activeStep = 0; // 0 to 4

  // Real-time backend status checks for the 5 steps
  final bool _step1Completed = true; // Workspace Profile created on registration
  bool _step2Completed = false; // Bank Account & Paybill added
  bool _step3Completed = false; // Property & Units created
  bool _step4Completed = false; // Tenant & Lease activated
  bool _step5Completed = false; // Team / Caretaker invited

  // Existing records from backend
  List<dynamic> _bankAccounts = [];
  List<dynamic> _properties = [];
  List<dynamic> _units = [];
  List<dynamic> _leases = [];
  List<dynamic> _teamMembers = [];

  // Form states for Step 1
  final _step1FormKey = GlobalKey<FormState>();
  final _agencyNameController = TextEditingController();
  String _selectedCounty = 'Nairobi';
  final _officeAddressController = TextEditingController();
  final _kraPinController = TextEditingController();

  // Form states for Step 2 (Bank)
  final _step2FormKey = GlobalKey<FormState>();
  String _selectedBankCode = 'EQUITY';
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _paybillController = TextEditingController(text: '247247');
  final _branchController = TextEditingController(text: 'Nairobi Main');
  bool _isSavingBank = false;

  // Form states for Step 3 (Property & Unit)
  final _step3FormKey = GlobalKey<FormState>();
  final _propertyNameController = TextEditingController();
  final _propertyAddressController = TextEditingController();
  String _propertyType = 'APARTMENT';
  final _unitNumberController = TextEditingController(text: 'A1');
  String _unitType = '2 Bedroom';
  final _unitRentController = TextEditingController(text: '35000');
  bool _isSavingProperty = false;

  // Form states for Step 4 (Tenant & Lease)
  final _step4FormKey = GlobalKey<FormState>();
  final _tenantFirstNameController = TextEditingController();
  final _tenantLastNameController = TextEditingController();
  final _tenantPhoneController = TextEditingController();
  final _tenantIdController = TextEditingController();
  final _leaseRentController = TextEditingController(text: '35000');
  final _leaseDepositController = TextEditingController(text: '35000');
  int? _selectedLeaseUnitId;
  bool _isSavingLease = false;

  // Form states for Step 5 (Team & Caretaker)
  final _step5FormKey = GlobalKey<FormState>();
  final _staffNameController = TextEditingController();
  final _staffPhoneController = TextEditingController();
  final _staffEmailController = TextEditingController();
  String _staffRole = 'CARETAKER';
  bool _isSavingStaff = false;

  // All 47 counties of Kenya (alphabetical)
  final List<String> _counties = const [
    'Baringo',
    'Bomet',
    'Bungoma',
    'Busia',
    'Elgeyo-Marakwet',
    'Embu',
    'Garissa',
    'Homa Bay',
    'Isiolo',
    'Kajiado',
    'Kakamega',
    'Kericho',
    'Kiambu',
    'Kilifi',
    'Kirinyaga',
    'Kisii',
    'Kisumu',
    'Kitui',
    'Kwale',
    'Laikipia',
    'Lamu',
    'Machakos',
    'Makueni',
    'Mandera',
    'Marsabit',
    'Meru',
    'Migori',
    'Mombasa',
    'Murang\'a',
    'Nairobi',
    'Nakuru',
    'Nandi',
    'Narok',
    'Nyamira',
    'Nyandarua',
    'Nyeri',
    'Samburu',
    'Siaya',
    'Taita-Taveta',
    'Tana River',
    'Tharaka-Nithi',
    'Trans Nzoia',
    'Turkana',
    'Uasin Gishu',
    'Vihiga',
    'Wajir',
    'West Pokot',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllWorkspaceData();
  }

  @override
  void dispose() {
    _agencyNameController.dispose();
    _officeAddressController.dispose();
    _kraPinController.dispose();

    _accountNameController.dispose();
    _accountNumberController.dispose();
    _paybillController.dispose();
    _branchController.dispose();

    _propertyNameController.dispose();
    _propertyAddressController.dispose();
    _unitNumberController.dispose();
    _unitRentController.dispose();

    _tenantFirstNameController.dispose();
    _tenantLastNameController.dispose();
    _tenantPhoneController.dispose();
    _tenantIdController.dispose();
    _leaseRentController.dispose();
    _leaseDepositController.dispose();

    _staffNameController.dispose();
    _staffPhoneController.dispose();
    _staffEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadAllWorkspaceData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.user;
      if (user != null) {
        _agencyNameController.text = user.username;
        _accountNameController.text = '${user.username} Rental Holding A/C';
      }

      final bankRes = await _apiService.getBankAccounts();
      final propRes = await _apiService.getProperties(limit: 50);
      final unitRes = await _apiService.getUnits(limit: 50);
      final leaseRes = await _apiService.getLeases(limit: 50);
      final usersRes = await _apiService.getUsers(limit: 100);

      final banks = ApiService.extractList(bankRes);
      final props = ApiService.extractList(propRes);
      final units = ApiService.extractList(unitRes);
      final leases = ApiService.extractList(leaseRes);
      final allUsers = ApiService.extractList(usersRes);

      final team = allUsers.where((u) {
        final role = u['role']?.toString().toUpperCase();
        return role == 'CARETAKER' || role == 'AGENT' || role == 'ADMIN';
      }).toList();

      if (mounted) {
        setState(() {
          _bankAccounts = banks;
          _properties = props;
          _units = units;
          _leases = leases;
          _teamMembers = team;

          _step2Completed = banks.isNotEmpty;
          _step3Completed = props.isNotEmpty && units.isNotEmpty;
          _step4Completed = leases.isNotEmpty;
          _step5Completed = team.isNotEmpty;

          // Set active step to first incomplete step
          if (!_step2Completed) {
            _activeStep = 1;
          } else if (!_step3Completed) {
            _activeStep = 2;
          } else if (!_step4Completed) {
            _activeStep = 3;
          } else if (!_step5Completed) {
            _activeStep = 4;
          } else {
            _activeStep = 0; // All done!
          }

          if (units.isNotEmpty && _selectedLeaseUnitId == null) {
            _selectedLeaseUnitId = units.first['id'];
          }

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _completedStepsCount {
    int count = 1; // Step 1 is always completed upon account creation
    if (_step2Completed) count++;
    if (_step3Completed) count++;
    if (_step4Completed) count++;
    if (_step5Completed) count++;
    return count;
  }

  double get _completionPercentage => _completedStepsCount / 5.0;

  Future<void> _launchWhatsAppSupport() async {
    final uri = Uri.parse(
      'https://wa.me/254702263303?text=${Uri.encodeComponent('Hi PMS Pro Support, I need help configuring my 5-step workspace onboarding.')}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  // ─── Step 2 Action: Save Bank Account ───
  Future<void> _handleSaveBank() async {
    if (!_step2FormKey.currentState!.validate()) return;
    setState(() => _isSavingBank = true);

    try {
      await _apiService.createBankAccount({
        'bank_name': _selectedBankCode,
        'account_name': _accountNameController.text.trim(),
        'account_number': _accountNumberController.text.trim(),
        'paybill_number': _paybillController.text.trim().isNotEmpty ? _paybillController.text.trim() : null,
        'branch_name': _branchController.text.trim().isNotEmpty ? _branchController.text.trim() : null,
        'is_primary': true,
        'currency': 'KES',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppTheme.teal, content: Text('Bank collection account saved successfully!')),
      );
      await _loadAllWorkspaceData();
      setState(() => _activeStep = 2); // move to step 3
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSavingBank = false);
    }
  }

  // ─── Step 3 Action: Save Property & Unit ───
  Future<void> _handleSavePropertyAndUnit() async {
    if (!_step3FormKey.currentState!.validate()) return;
    setState(() => _isSavingProperty = true);

    try {
      final propRes = await _apiService.createProperty({
        'name': _propertyNameController.text.trim(),
        'address': _propertyAddressController.text.trim(),
        'city': _selectedCounty,
        'country': 'Kenya',
        'property_type': _propertyType,
      });
      final propData = ApiService.extractMap(propRes);
      final newPropId = propData['id'] ?? propData['property']?['id'];

      if (newPropId != null) {
        await _apiService.createUnit({
          'property_id': newPropId,
          'unit_number': _unitNumberController.text.trim(),
          'unit_type': _unitType,
          'rent_price': double.tryParse(_unitRentController.text.trim()) ?? 35000,
          'status': 'VACANT',
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppTheme.teal, content: Text('Property & Initial Unit created successfully!')),
      );
      await _loadAllWorkspaceData();
      setState(() => _activeStep = 3); // move to step 4
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSavingProperty = false);
    }
  }

  // ─── Step 4 Action: Save Tenant & Lease ───
  Future<void> _handleSaveTenantAndLease() async {
    if (!_step4FormKey.currentState!.validate()) return;
    if (_selectedLeaseUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Please select a unit for the lease')),
      );
      return;
    }

    setState(() => _isSavingLease = true);

    try {
      final phone = _tenantPhoneController.text.trim();
      final username = 'tenant_${phone.replaceAll(RegExp(r'[^0-9]'), '')}';

      final tenantRes = await _apiService.createTenant({
        'username': username,
        'email': '$username@pmspro.co.ke',
        'password': 'TempPassword@123',
        'phone': phone,
        'firstName': _tenantFirstNameController.text.trim(),
        'lastName': _tenantLastNameController.text.trim(),
        'tenantIdPassport': _tenantIdController.text.trim(),
      });
      final tenantData = ApiService.extractMap(tenantRes);
      final tenantId = tenantData['user']?['id'] ?? tenantData['id'];

      final now = DateTime.now();
      final oneYearLater = DateTime(now.year + 1, now.month, now.day);

      await _apiService.createLease({
        'unit_id': _selectedLeaseUnitId,
        'tenant_id': tenantId,
        'rent_amount': double.tryParse(_leaseRentController.text.trim()) ?? 35000,
        'deposit_amount': double.tryParse(_leaseDepositController.text.trim()) ?? 35000,
        'start_date': DateFormat('yyyy-MM-dd').format(now),
        'end_date': DateFormat('yyyy-MM-dd').format(oneYearLater),
        'billing_day': 1,
        'status': 'ACTIVE',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppTheme.teal, content: Text('Tenant onboarded & Lease activated!')),
      );
      await _loadAllWorkspaceData();
      setState(() => _activeStep = 4); // move to step 5
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSavingLease = false);
    }
  }

  // ─── Step 5 Action: Invite Caretaker / Team Member ───
  Future<void> _handleSaveTeamMember() async {
    if (!_step5FormKey.currentState!.validate()) return;
    setState(() => _isSavingStaff = true);

    try {
      final phone = _staffPhoneController.text.trim();
      final email = _staffEmailController.text.trim().isNotEmpty
          ? _staffEmailController.text.trim()
          : 'staff_${phone.replaceAll(RegExp(r'[^0-9]'), '')}@pmspro.co.ke';
      final username = _staffNameController.text.trim().replaceAll(' ', '_').toLowerCase();

      await _apiService.createTeamMember({
        'username': username,
        'email': email,
        'phone': phone,
        'password': 'StaffPassword@123',
        'role': _staffRole,
        'firstName': _staffNameController.text.trim(),
        'lastName': '',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppTheme.teal, content: Text('Team member added to PMS Pro workspace!')),
      );
      await _loadAllWorkspaceData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSavingStaff = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: AppTheme.bgGreyGreen,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.brass,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.rocket_launch, color: Color(0xFF10231D), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'PMS Pro Workspace Launchpad',
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton.icon(
              onPressed: _launchWhatsAppSupport,
              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 18),
              label: Text(
                isMobile ? 'Support' : 'WhatsApp Support (0702263303)',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top Progress Card ──
                      _buildOverallProgressCard(isMobile),

                      const SizedBox(height: 24),

                      // ── Step Navigation Pills ──
                      _buildStepSelector(isMobile),

                      const SizedBox(height: 20),

                      // ── Active Step Container ──
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildActiveStepContent(isMobile),
                      ),

                      const SizedBox(height: 32),

                      // ── Footer with WhatsApp Direct Help ──
                      _buildSupportFooter(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ─── Top Progress Banner ───
  Widget _buildOverallProgressCard(bool isMobile) {
    final pct = (_completionPercentage * 100).toInt();
    final isDone = _completedStepsCount == 5;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDone ? AppTheme.teal : AppTheme.border, width: isDone ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isDone ? 'PMS Pro Workspace Fully Activated! 🚀' : 'Complete Your 5-Step Workspace Setup',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDone ? AppTheme.teal : Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$pct% READY',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDone
                          ? 'All 5 operational pillars are live. Your properties, accounts, leases, and staff are active.'
                          : '$_completedStepsCount of 5 steps completed. Follow the guided steps below to configure your system.',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText),
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/owner-dashboard'),
                  icon: const Icon(Icons.dashboard_outlined, size: 16),
                  label: const Text('Go to Dashboard'),
                  style: AppTheme.actionButtonStyle,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _completionPercentage,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? AppTheme.teal : const Color(0xFF0F6B4F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step Selector Tabs ───
  Widget _buildStepSelector(bool isMobile) {
    final steps = [
      {'num': '1', 'title': 'Profile', 'done': _step1Completed},
      {'num': '2', 'title': 'Bank & M-Pesa', 'done': _step2Completed},
      {'num': '3', 'title': 'Properties', 'done': _step3Completed},
      {'num': '4', 'title': 'Leases', 'done': _step4Completed},
      {'num': '5', 'title': 'Team', 'done': _step5Completed},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isSelected = _activeStep == index;
          final isDone = step['done'] as bool;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => setState(() => _activeStep = index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.navy
                      : (isDone ? const Color(0xFFF0FDF4) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.navy
                        : (isDone ? AppTheme.teal.withValues(alpha: 0.4) : AppTheme.border),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : (isDone ? AppTheme.teal : const Color(0xFFE2E8F0)),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text(
                                step['num'].toString(),
                                style: GoogleFonts.dmSans(
                                  color: isSelected ? Colors.white : AppTheme.navy,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      step['title'].toString(),
                      style: GoogleFonts.dmSans(
                        color: isSelected
                            ? Colors.white
                            : (isDone ? AppTheme.teal : AppTheme.navy),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Active Step Card ───
  Widget _buildActiveStepContent(bool isMobile) {
    switch (_activeStep) {
      case 0:
        return _buildStep1Profile(isMobile);
      case 1:
        return _buildStep2Banking(isMobile);
      case 2:
        return _buildStep3Properties(isMobile);
      case 3:
        return _buildStep4Leases(isMobile);
      case 4:
        return _buildStep5Team(isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 1: WORKSPACE & AGENCY PROFILE
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep1Profile(bool isMobile) {
    final user = _authService.user;
    return _buildStepWrapper(
      stepNumber: 1,
      title: 'Workspace Identity & Agency Settings',
      subtitle: 'Confirm your business name, county, and tax compliance settings.',
      isDone: _step1Completed,
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: AppTheme.teal, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administrator Account Active',
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 13),
                        ),
                        Text(
                          'Logged in as ${user?.username ?? 'Admin'} (${user?.email ?? 'official@pmspro.co.ke'}) • Role: ${user?.role ?? 'OWNER'}',
                          style: GoogleFonts.dmSans(color: AppTheme.mutedText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: TextFormField(
                    controller: _agencyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Agency / Estate Management Name',
                      hintText: 'e.g. Apex Property Managers Ltd',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Agency name required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCounty,
                    isExpanded: true,
                    menuMaxHeight: 320,
                    decoration: const InputDecoration(
                      labelText: 'County / Region',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    items: _counties.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCounty = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _officeAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Physical Office (Optional)',
                      hintText: 'e.g. Westlands, Nairobi',
                      prefixIcon: Icon(Icons.map),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _kraPinController,
                    decoration: const InputDecoration(
                      labelText: 'KRA PIN / Tax Identifier (Optional)',
                      hintText: 'e.g. P051234567Z',
                      prefixIcon: Icon(Icons.pin),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '✓ Step 1 verified and recorded.',
                  style: GoogleFonts.dmSans(color: AppTheme.teal, fontWeight: FontWeight.w700),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _activeStep = 1),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Proceed to Step 2: Banking'),
                  style: AppTheme.actionButtonStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 2: BANK & M-PESA SETUP
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep2Banking(bool isMobile) {
    return _buildStepWrapper(
      stepNumber: 2,
      title: 'Commercial Bank Account & M-Pesa Rails',
      subtitle: 'Configure your primary rent reception account (Equity, Co-op, KCB, NCBA, Stanbic) & Paybills.',
      isDone: _step2Completed,
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_bankAccounts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.teal, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Bank Account Linked',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 14),
                          ),
                          Text(
                            '${_bankAccounts.first['bank_name']} — ${_bankAccounts.first['account_name']} (A/C: ${_bankAccounts.first['account_number']})',
                            style: GoogleFonts.dmSans(color: AppTheme.mutedText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _activeStep = 2),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white),
                      child: const Text('Next: Step 3'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              _bankAccounts.isNotEmpty ? 'Add Another Receiving Bank Account' : 'Set Up Primary Reception Account',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.navy),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedBankCode,
                    decoration: const InputDecoration(labelText: 'Commercial Bank', prefixIcon: Icon(Icons.account_balance)),
                    items: const [
                      DropdownMenuItem(value: 'EQUITY', child: Text('Equity Bank Kenya')),
                      DropdownMenuItem(value: 'COOP', child: Text('Co-operative Bank of Kenya')),
                      DropdownMenuItem(value: 'KCB', child: Text('KCB Bank Kenya')),
                      DropdownMenuItem(value: 'NCBA', child: Text('NCBA Bank Kenya')),
                      DropdownMenuItem(value: 'STANBIC', child: Text('Stanbic Bank Kenya')),
                      DropdownMenuItem(value: 'ABSA', child: Text('Absa Bank Kenya')),
                      DropdownMenuItem(value: 'DTB', child: Text('Diamond Trust Bank (DTB)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedBankCode = val;
                          if (val == 'EQUITY') _paybillController.text = '247247';
                          if (val == 'COOP') _paybillController.text = '400200';
                          if (val == 'KCB') _paybillController.text = '522522';
                          if (val == 'NCBA') _paybillController.text = '888888';
                          if (val == 'STANBIC') _paybillController.text = '600100';
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _accountNumberController,
                    decoration: const InputDecoration(labelText: 'Account Number', hintText: '0180293847291', prefixIcon: Icon(Icons.tag)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Account number required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _accountNameController,
                    decoration: const InputDecoration(labelText: 'Account Name', hintText: 'PMS Pro Client Holding A/C'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Account name required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _paybillController,
                    decoration: const InputDecoration(labelText: 'Paybill / Till Number', hintText: 'e.g. 247247'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _activeStep = 0),
                  child: const Text('Back to Step 1'),
                ),
                ElevatedButton.icon(
                  onPressed: _isSavingBank ? null : _handleSaveBank,
                  icon: _isSavingBank ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 16),
                  label: Text(_isSavingBank ? 'Saving Account...' : 'Save Bank & Proceed'),
                  style: AppTheme.actionButtonStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 3: PROPERTY & UNIT SETUP
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep3Properties(bool isMobile) {
    return _buildStepWrapper(
      stepNumber: 3,
      title: 'Properties & Rental Units Portfolio',
      subtitle: 'Add your first building, estate, or commercial complex, along with its initial rental unit.',
      isDone: _step3Completed,
      child: Form(
        key: _step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_properties.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.teal, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_properties.length} Properties & ${_units.length} Units registered in your PMS Pro workspace.',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 13),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _activeStep = 3),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white),
                      child: const Text('Next: Step 4'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text('Property Details', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.navy)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: TextFormField(
                    controller: _propertyNameController,
                    decoration: const InputDecoration(labelText: 'Property Name', hintText: 'e.g. Kilimani Heights Apartments', prefixIcon: Icon(Icons.home_work)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Property name required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<String>(
                    initialValue: _propertyType,
                    decoration: const InputDecoration(labelText: 'Property Category'),
                    items: const [
                      DropdownMenuItem(value: 'APARTMENT', child: Text('Apartment / Flat')),
                      DropdownMenuItem(value: 'COMMERCIAL', child: Text('Commercial Space')),
                      DropdownMenuItem(value: 'RESIDENTIAL', child: Text('Residential Villa')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _propertyType = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _propertyAddressController,
              decoration: const InputDecoration(labelText: 'Address & Neighborhood', hintText: 'e.g. Dennis Pritt Rd, Kilimani, Nairobi', prefixIcon: Icon(Icons.location_on)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Address required' : null,
            ),
            const SizedBox(height: 18),
            Text('Initial Rental Unit', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.navy)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _unitNumberController,
                    decoration: const InputDecoration(labelText: 'Unit Door / No.', hintText: 'A1'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Unit number required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<String>(
                    initialValue: _unitType,
                    decoration: const InputDecoration(labelText: 'Unit Type'),
                    items: const [
                      DropdownMenuItem(value: '1 Bedroom', child: Text('1 Bedroom')),
                      DropdownMenuItem(value: '2 Bedroom', child: Text('2 Bedroom')),
                      DropdownMenuItem(value: '3 Bedroom', child: Text('3 Bedroom')),
                      DropdownMenuItem(value: 'Studio', child: Text('Studio')),
                      DropdownMenuItem(value: 'Bedsitter', child: Text('Bedsitter')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _unitType = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _unitRentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rent Price (KSh)', hintText: '35000'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Rent required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _activeStep = 1),
                  child: const Text('Back to Step 2'),
                ),
                ElevatedButton.icon(
                  onPressed: _isSavingProperty ? null : _handleSavePropertyAndUnit,
                  icon: _isSavingProperty ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 16),
                  label: Text(_isSavingProperty ? 'Saving Property...' : 'Save Property & Proceed'),
                  style: AppTheme.actionButtonStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 4: TENANT & LEASE ACTIVATION
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep4Leases(bool isMobile) {
    return _buildStepWrapper(
      stepNumber: 4,
      title: 'Tenant & Lease Activation',
      subtitle: 'Onboard your first resident with contact details and activate their lease contract.',
      isDone: _step4Completed,
      child: Form(
        key: _step4FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_leases.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.teal, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_leases.length} Active Leases managing rent billing in your workspace.',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 13),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _activeStep = 4),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white),
                      child: const Text('Next: Step 5'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text('Resident Personal Details', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.navy)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tenantFirstNameController,
                    decoration: const InputDecoration(labelText: 'First Name', hintText: 'James'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'First name required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tenantLastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name', hintText: 'Kariuki'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Last name required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tenantPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'M-Pesa Phone Number', hintText: '0712345678', prefixIcon: Icon(Icons.phone_android)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Phone required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tenantIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'National ID / Passport', hintText: '29384756'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'National ID required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Lease Contract Terms', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.navy)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<int?>(
                    initialValue: _selectedLeaseUnitId,
                    decoration: const InputDecoration(labelText: 'Select Assigned Unit'),
                    items: _units.map((u) {
                      return DropdownMenuItem<int?>(
                        value: u['id'],
                        child: Text('Unit ${u['unit_number']} (${u['status'] ?? 'VACANT'})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedLeaseUnitId = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _leaseRentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rent (KSh/Mo)'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Rent required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _leaseDepositController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Deposit (KSh)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _activeStep = 2),
                  child: const Text('Back to Step 3'),
                ),
                ElevatedButton.icon(
                  onPressed: _isSavingLease ? null : _handleSaveTenantAndLease,
                  icon: _isSavingLease ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 16),
                  label: Text(_isSavingLease ? 'Activating Lease...' : 'Activate Lease & Proceed'),
                  style: AppTheme.actionButtonStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 5: TEAM & CARETAKER DELEGATION
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep5Team(bool isMobile) {
    return _buildStepWrapper(
      stepNumber: 5,
      title: 'Staff & Caretaker Delegation',
      subtitle: 'Invite field caretakers, letting agents, and accountants with role-based access.',
      isDone: _step5Completed,
      child: Form(
        key: _step5FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_teamMembers.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.teal, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_teamMembers.length} Staff members & caretakers invited to your PMS Pro workspace.',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 13),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/owner-dashboard'),
                      style: AppTheme.actionButtonStyle,
                      child: const Text('Go to Dashboard 🚀'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text('Invite Team Member', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.navy)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: TextFormField(
                    controller: _staffNameController,
                    decoration: const InputDecoration(labelText: 'Full Name', hintText: 'e.g. Samuel Ochieng', prefixIcon: Icon(Icons.person)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<String>(
                    initialValue: _staffRole,
                    decoration: const InputDecoration(labelText: 'Assigned Role'),
                    items: const [
                      DropdownMenuItem(value: 'CARETAKER', child: Text('Caretaker / Field Mgr')),
                      DropdownMenuItem(value: 'AGENT', child: Text('Letting / Leasing Agent')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Finance Accountant')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _staffRole = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _staffPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number', hintText: '0712345678', prefixIcon: Icon(Icons.phone)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Phone required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _staffEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address (Optional)', hintText: 'staff@pmspro.co.ke', prefixIcon: Icon(Icons.email)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _activeStep = 3),
                  child: const Text('Back to Step 4'),
                ),
                ElevatedButton.icon(
                  onPressed: _isSavingStaff ? null : _handleSaveTeamMember,
                  icon: _isSavingStaff ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.person_add, size: 16),
                  label: Text(_isSavingStaff ? 'Inviting Member...' : 'Invite Member & Complete'),
                  style: AppTheme.actionButtonStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step Wrapper Template ───
  Widget _buildStepWrapper({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDone ? AppTheme.teal : AppTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDone ? AppTheme.teal : AppTheme.navy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STEP $stepNumber OF 5',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (isDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 12, color: AppTheme.teal),
                      const SizedBox(width: 4),
                      Text(
                        'COMPLETED',
                        style: GoogleFonts.dmSans(color: AppTheme.teal, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ─── Support Footer ───
  Widget _buildSupportFooter() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.headset_mic, color: Color(0xFF25D366), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Assistance With Your PMS Pro Workspace?',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 14),
                ),
                Text(
                  'Our dedicated onboarding desk is available via WhatsApp or direct phone: 0702263303',
                  style: GoogleFonts.dmSans(color: AppTheme.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _launchWhatsAppSupport,
            icon: const Icon(Icons.chat, size: 16),
            label: const Text('WhatsApp 0702263303'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
