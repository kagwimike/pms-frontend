import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/google_auth/google_sign_in_section.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();

  // Active step: 0 to 4 (Step 1 to Step 5)
  int _currentStep = 0;

  // Selected Role: 'AGENT', 'LANDLORD', 'TENANT'
  String _selectedRoleType = 'AGENT';

  // ── Step 1: Admin & Agency / Landlord Identity ──
  final _step1FormKey = GlobalKey<FormState>();
  final _agencyNameController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _kraPinController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedCounty = 'Nairobi';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  // ── Step 2: Bank Collection & M-Pesa Setup ──
  final _step2FormKey = GlobalKey<FormState>();
  String _selectedBankCode = 'EQUITY';
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _paybillController = TextEditingController(text: '247247');
  final _branchController = TextEditingController(text: 'Nairobi Main');

  // ── Step 3: First Property & Rental Portfolio ──
  final _step3FormKey = GlobalKey<FormState>();
  final _propertyNameController = TextEditingController();
  final _propertyAddressController = TextEditingController();
  String _propertyType = 'APARTMENT';
  final _unitNumberController = TextEditingController(text: 'A1');
  String _unitType = '2 Bedroom';
  final _unitRentController = TextEditingController(text: '35000');

  // ── Step 4: Resident & Lease Activation ──
  final _step4FormKey = GlobalKey<FormState>();
  final _tenantFirstNameController = TextEditingController();
  final _tenantLastNameController = TextEditingController();
  final _tenantPhoneController = TextEditingController();
  final _tenantIdController = TextEditingController();
  final _leaseRentController = TextEditingController(text: '35000');
  final _leaseDepositController = TextEditingController(text: '35000');

  // ── Step 5: Staff & Caretaker Delegation ──
  final _step5FormKey = GlobalKey<FormState>();
  final _staffNameController = TextEditingController();
  final _staffPhoneController = TextEditingController();
  final _staffEmailController = TextEditingController();
  String _staffRole = 'CARETAKER';

  bool _isSubmitting = false;

  final List<String> _counties = [
    'Nairobi',
    'Mombasa',
    'Kiambu',
    'Nakuru',
    'Kisumu',
    'Eldoret (Uasin Gishu)',
    'Machakos',
    'Kajiado',
    'Kilifi',
    'Nyeri',
    'Other County',
  ];

  final List<Map<String, String>> _kenyanBanks = [
    {'code': 'EQUITY', 'name': 'Equity Bank Kenya', 'paybill': '247247'},
    {'code': 'COOP', 'name': 'Co-operative Bank of Kenya', 'paybill': '400200'},
    {'code': 'KCB', 'name': 'KCB Bank Kenya', 'paybill': '522522'},
    {'code': 'NCBA', 'name': 'NCBA Bank Kenya', 'paybill': '888880'},
    {'code': 'STANBIC', 'name': 'Stanbic Bank Kenya', 'paybill': '544700'},
    {'code': 'ABSA', 'name': 'ABSA Bank Kenya', 'paybill': '303030'},
    {'code': 'DTB', 'name': 'Diamond Trust Bank (DTB)', 'paybill': '516600'},
    {'code': 'IM', 'name': 'I&M Bank Kenya', 'paybill': '542542'},
    {'code': 'FAMILY', 'name': 'Family Bank Kenya', 'paybill': '222111'},
    {'code': 'MPESA', 'name': 'M-Pesa Business Buy Goods / Till', 'paybill': ''},
  ];

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (_authService.isLoggedIn && mounted) {
      _navigateToDashboard();
    }
  }

  void _navigateToDashboard() {
    final role = _authService.user?.role ?? 'OWNER';
    _showToast('Welcome to PMS Pro! Logged in with Google.');
    if (role == 'OWNER' || role == 'ADMIN') {
      Navigator.of(context).pushReplacementNamed('/owner-dashboard');
    } else if (role == 'TENANT') {
      Navigator.of(context).pushReplacementNamed('/tenant-dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/owner-dashboard');
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    _agencyNameController.dispose();
    _officeAddressController.dispose();
    _kraPinController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

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

  void _onBankSelected(String? code) {
    if (code == null) return;
    setState(() {
      _selectedBankCode = code;
      final found = _kenyanBanks.firstWhere((b) => b['code'] == code, orElse: () => {'paybill': ''});
      if (found['paybill'] != null && found['paybill']!.isNotEmpty) {
        _paybillController.text = found['paybill']!;
      }
    });
  }

  Future<void> _launchSupportWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/254702263303?text=${Uri.encodeComponent('Hi PMS Pro Support, I need help setting up my 5-step PMS Pro workspace.')}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  // ── Step Navigation Handlers ──
  void _goToNextStep() {
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) {
        _showToast('Please correct highlighted errors in the form.', isError: true);
        return;
      }
      if (!_agreedToTerms) {
        _showToast('Please agree to the PMS Pro Terms of Service to continue.', isError: true);
        return;
      }

      // If Tenant role is chosen, register directly without agency steps
      if (_selectedRoleType == 'TENANT') {
        _handleTenantRegister();
        return;
      }

      // Auto-suggest bank account name if not filled
      if (_accountNameController.text.trim().isEmpty) {
        final agency = _agencyNameController.text.trim();
        final name = agency.isNotEmpty ? agency : '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
        _accountNameController.text = '$name Rent Collection A/C';
      }

      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      // Sync unit rent to Step 4 lease rent
      if (_unitRentController.text.trim().isNotEmpty) {
        _leaseRentController.text = _unitRentController.text.trim();
        _leaseDepositController.text = _unitRentController.text.trim();
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      setState(() => _currentStep = 4);
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _skipStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.red.shade700 : AppTheme.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }


  // ── Single-Step Direct Registration for Residents / Tenants ──
  Future<void> _handleTenantRegister() async {
    setState(() => _isSubmitting = true);
    final success = await _authService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: 'TENANT',
      phone: _phoneController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      tenantIdPassport: _nationalIdController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showToast('Welcome to PMS Pro! Tenant account created.');
      Navigator.of(context).pushReplacementNamed('/tenant-dashboard');
    } else {
      _showToast(_authService.error ?? 'Tenant registration failed.', isError: true);
    }
  }

  // ── 5-Step Full Workspace Registration Submission ──
  Future<void> _handleFullWorkspaceSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      // 1. Register Owner / Agency Account
      final regSuccess = await _authService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: 'OWNER',
        phone: _phoneController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        tenantIdPassport: _nationalIdController.text.trim(),
      );

      if (!regSuccess) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _showToast(_authService.error ?? 'Registration failed. Please check your credentials.', isError: true);
        return;
      }

      // 2. Step 2: Commercial Bank Account & M-Pesa Setup (If filled)
      final accountNo = _accountNumberController.text.trim();
      if (accountNo.isNotEmpty) {
        try {
          await _apiService.createBankAccount({
            'bank_name': _selectedBankCode,
            'account_name': _accountNameController.text.trim().isNotEmpty
                ? _accountNameController.text.trim()
                : '${_agencyNameController.text.trim()} Rent Collection',
            'account_number': accountNo,
            'paybill_number': _paybillController.text.trim().isNotEmpty ? _paybillController.text.trim() : null,
            'branch_name': _branchController.text.trim().isNotEmpty ? _branchController.text.trim() : 'Nairobi Main',
            'is_primary': true,
            'currency': 'KES',
          });
        } catch (e) {
          debugPrint('Step 2 Bank creation note: $e');
        }
      }

      // 3. Step 3: First Property & Rental Unit (If filled)
      int? createdUnitId;
      final propName = _propertyNameController.text.trim();
      if (propName.isNotEmpty) {
        try {
          final propRes = await _apiService.createProperty({
            'name': propName,
            'address': _propertyAddressController.text.trim().isNotEmpty
                ? _propertyAddressController.text.trim()
                : _selectedCounty,
            'city': _selectedCounty,
            'country': 'Kenya',
            'property_type': _propertyType,
          });
          final propData = ApiService.extractMap(propRes);
          final propId = propData['id'] ?? propData['property']?['id'];

          if (propId != null) {
            final unitRes = await _apiService.createUnit({
              'property_id': propId,
              'unit_number': _unitNumberController.text.trim().isNotEmpty ? _unitNumberController.text.trim() : 'A1',
              'unit_type': _unitType,
              'rent_price': double.tryParse(_unitRentController.text.trim()) ?? 35000,
              'status': 'VACANT',
            });
            final unitData = ApiService.extractMap(unitRes);
            createdUnitId = unitData['id'] ?? unitData['unit']?['id'];
          }
        } catch (e) {
          debugPrint('Step 3 Property creation note: $e');
        }
      }

      // 4. Step 4: Resident & Lease Activation (If filled)
      final tPhone = _tenantPhoneController.text.trim();
      final tFirst = _tenantFirstNameController.text.trim();
      if (tPhone.isNotEmpty && tFirst.isNotEmpty) {
        try {
          final cleanPhone = tPhone.replaceAll(RegExp(r'[^0-9]'), '');
          final tUsername = 'tenant_$cleanPhone';
          final tLast = _tenantLastNameController.text.trim();
          final tId = _tenantIdController.text.trim();

          final tenantRes = await _apiService.createTenant({
            'username': tUsername,
            'email': '$tUsername@pmspro.co.ke',
            'password': 'TempPassword@123',
            'phone': tPhone,
            'firstName': tFirst,
            'lastName': tLast.isNotEmpty ? tLast : 'Resident',
            'tenantIdPassport': tId.isNotEmpty ? tId : '000000',
          });
          final tData = ApiService.extractMap(tenantRes);
          final tenantUserId = tData['user']?['id'] ?? tData['id'];

          if (createdUnitId != null && tenantUserId != null) {
            final now = DateTime.now();
            final oneYearLater = DateTime(now.year + 1, now.month, now.day);
            await _apiService.createLease({
              'unit_id': createdUnitId,
              'tenant_id': tenantUserId,
              'rent_amount': double.tryParse(_leaseRentController.text.trim()) ?? 35000,
              'deposit_amount': double.tryParse(_leaseDepositController.text.trim()) ?? 35000,
              'start_date': DateFormat('yyyy-MM-dd').format(now),
              'end_date': DateFormat('yyyy-MM-dd').format(oneYearLater),
              'billing_day': 1,
              'status': 'ACTIVE',
            });
          }
        } catch (e) {
          debugPrint('Step 4 Tenant/Lease creation note: $e');
        }
      }

      // 5. Step 5: Staff & Caretaker Delegation (If filled)
      final sName = _staffNameController.text.trim();
      final sPhone = _staffPhoneController.text.trim();
      if (sName.isNotEmpty && sPhone.isNotEmpty) {
        try {
          final cleanStaffPhone = sPhone.replaceAll(RegExp(r'[^0-9]'), '');
          final sEmail = _staffEmailController.text.trim().isNotEmpty
              ? _staffEmailController.text.trim()
              : 'staff_$cleanStaffPhone@pmspro.co.ke';
          final sUsername = sName.replaceAll(' ', '_').toLowerCase();

          await _apiService.createTeamMember({
            'username': sUsername,
            'email': sEmail,
            'phone': sPhone,
            'password': 'StaffPassword@123',
            'role': _staffRole,
            'firstName': sName,
            'lastName': '',
          });
        } catch (e) {
          debugPrint('Step 5 Staff creation note: $e');
        }
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      _showToast('Welcome to PMS Pro! Workspace successfully initialized.');
      Navigator.of(context).pushReplacementNamed('/owner-dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showToast('Workspace created with notes: $e');
      Navigator.of(context).pushReplacementNamed('/owner-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B17),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 950;
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF091713),
                  Color(0xFF102820),
                  Color(0xFF16372C),
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 32,
                  vertical: 24,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 35,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Branding & Value Highlights Panel
        Expanded(
          flex: 4,
          child: _buildBrandingSidebar(),
        ),
        // Right Multi-Step Registration Form Panel
        Expanded(
          flex: 8,
          child: _buildWizardPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMobileHeader(),
        _buildWizardPanel(),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B211B), Color(0xFF12392E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8A317), Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.domain_add, color: Color(0xFF10231D), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PMS Pro',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Property Management System',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8A317).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8A317).withValues(alpha: 0.5)),
            ),
            child: Text(
              '★ 5-STEP WORKSPACE SETUP ON REGISTRATION',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFBBF24),
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingSidebar() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF091C17),
            Color(0xFF103026),
            Color(0xFF143F33),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PMS Pro Brand Header
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8A317), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8A317).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.domain_add, color: Color(0xFF0F2620), size: 26),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'PMS PRO',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'KENYA',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFBBF24),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Property Management System',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 5-Step Overview Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8A317).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE8A317).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: Color(0xFFFBBF24), size: 15),
                const SizedBox(width: 8),
                Text(
                  'COMPLETE WORKSPACE ONBOARDING',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFBBF24),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Headline
          Text(
            'Launch Your Complete Rental Operations In 5 Quick Steps',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Configure your Kenya bank reconciliation, property portfolio, first resident lease, and maintenance staff right during sign up.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // 5 Steps Visual Tracker on Sidebar
          _buildSidebarStepTrackerItem(1, 'Administrator & Agency', 'Legal identity, KRA PIN & credentials', _currentStep >= 0),
          const SizedBox(height: 14),
          _buildSidebarStepTrackerItem(2, 'Bank & M-Pesa Setup', 'Equity, Co-op, KCB, Paybill auto-sync', _currentStep >= 1),
          const SizedBox(height: 14),
          _buildSidebarStepTrackerItem(3, 'Property & Units', 'Apartments, units & rent pricing', _currentStep >= 2),
          const SizedBox(height: 14),
          _buildSidebarStepTrackerItem(4, 'Resident & Lease', 'First tenant onboarding & deposit', _currentStep >= 3),
          const SizedBox(height: 14),
          _buildSidebarStepTrackerItem(5, 'Staff & Caretaker', 'Field officer & maintenance delegation', _currentStep >= 4),

          const SizedBox(height: 36),

          // Support Card with WhatsApp 0702263303
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PMS Pro Setup Support',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Direct line: 0702263303',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _launchSupportWhatsApp,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'WHATSAPP',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarStepTrackerItem(int stepNumber, String title, String subtitle, bool isReached) {
    final isCurrent = _currentStep == (stepNumber - 1);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isCurrent
                ? const Color(0xFFE8A317)
                : isReached
                    ? const Color(0xFF0F6B4F)
                    : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? const Color(0xFFFBBF24) : Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isReached && !isCurrent
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isCurrent ? const Color(0xFF10231D) : Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrent ? const Color(0xFFFBBF24) : Colors.white.withValues(alpha: isReached ? 0.95 : 0.55),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWizardPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Stepper Navigation Header
          _buildTopStepperIndicator(),

          const SizedBox(height: 28),

          // Active Step View
          if (_currentStep == 0)
            _buildStep1IdentityView()
          else if (_currentStep == 1)
            _buildStep2BankView()
          else if (_currentStep == 2)
            _buildStep3PropertyView()
          else if (_currentStep == 3)
            _buildStep4ResidentView()
          else
            _buildStep5StaffAndLaunchView(),

          const SizedBox(height: 24),

          // Sign In Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have a PMS Pro account? ',
                style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    'Sign In to Dashboard',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF0F6B4F),
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Center(
            child: Text(
              'PMS Pro Cloud Platform • Nairobi, Kenya • Direct Support: 0702263303',
              style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF9CA3AF)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Horizontal Stepper Indicator ──
  Widget _buildTopStepperIndicator() {
    final stepTitles = ['Identity', 'Bank Setup', 'Properties', 'Resident', 'Staff'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;
          return Row(
            children: List.generate(5, (index) {
              final isCurrent = _currentStep == index;
              final isCompleted = _currentStep > index;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          // Allow jumping back to earlier steps
                          if (index < _currentStep) {
                            setState(() => _currentStep = index);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent
                                    ? const Color(0xFF0F6B4F)
                                    : isCompleted
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFE5E7EB),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                                    : Text(
                                        '${index + 1}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isCurrent ? Colors.white : const Color(0xFF6B7280),
                                        ),
                                      ),
                              ),
                            ),
                            if (!isCompact) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  stepTitles[index],
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                    color: isCurrent ? const Color(0xFF0F6B4F) : const Color(0xFF4B5563),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (index < 4)
                      Container(
                        width: isCompact ? 10 : 20,
                        height: 2,
                        color: _currentStep > index ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                      ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // ── STEP 1: IDENTITY & CREDENTIALS ──
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildStep1IdentityView() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 1 of 5: Workspace Identity',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10231D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Select your operational role and provide administrator credentials.',
                      style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F6B4F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STEP 1 / 5',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F6B4F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Google Fast-Track Button
          GoogleSignInSection(
            isSignUp: true,
            role: _selectedRoleType == 'LANDLORD' ? 'OWNER' : _selectedRoleType,
            onSuccess: () => _navigateToDashboard(),
            onError: (msg) => _showToast(msg, isError: true),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or register manually below', style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF9CA3AF))),
              ),
              const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
            ],
          ),
          const SizedBox(height: 20),

          // Role cards (Agent, Landlord, Tenant)
          _buildSectionHeader('SELECT YOUR ACCOUNT TYPE', Icons.badge_outlined),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              if (isNarrow) {
                return Column(
                  children: [
                    _buildRoleCard('AGENT', 'Rental Agency', 'Managing multiple properties', Icons.real_estate_agent_outlined),
                    const SizedBox(height: 8),
                    _buildRoleCard('LANDLORD', 'Property Owner', 'Managing own rental buildings', Icons.holiday_village_outlined),
                    const SizedBox(height: 8),
                    _buildRoleCard('TENANT', 'Tenant / Resident', 'Accessing lease & paying rent', Icons.person_pin_circle_outlined),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildRoleCard('AGENT', 'Rental Agency', 'Multi-estate realtors', Icons.real_estate_agent_outlined),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRoleCard('LANDLORD', 'Landlord', 'Individual owner', Icons.holiday_village_outlined),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRoleCard('TENANT', 'Tenant', 'Resident portal', Icons.person_pin_circle_outlined),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Agency / Business details (Only if not tenant)
          if (_selectedRoleType != 'TENANT') ...[
            _buildSectionHeader(
              _selectedRoleType == 'AGENT' ? 'AGENCY / COMPANY DETAILS' : 'ESTATE / PORTFOLIO DETAILS',
              Icons.business_outlined,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: TextFormField(
                    controller: _agencyNameController,
                    decoration: _inputDecoration(
                      label: _selectedRoleType == 'AGENT' ? 'Agency / Company Name' : 'Portfolio / Estate Name',
                      hint: _selectedRoleType == 'AGENT' ? 'e.g. Apex Realty & Lettings Ltd' : 'e.g. Skyline Properties',
                      icon: Icons.storefront_outlined,
                    ),
                    validator: (val) {
                      if (_selectedRoleType == 'AGENT' && (val == null || val.trim().isEmpty)) {
                        return 'Agency name is required for rental agencies';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCounty,
                    decoration: _inputDecoration(
                      label: 'County / City',
                      hint: 'County',
                      icon: Icons.location_on_outlined,
                    ),
                    items: _counties.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.dmSans(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCounty = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _officeAddressController,
                    decoration: _inputDecoration(
                      label: 'Physical Office Address (Optional)',
                      hint: 'e.g. Kilimani, Argwings Kodhek Rd',
                      icon: Icons.map_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _kraPinController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputDecoration(
                      label: 'KRA PIN / Tax ID (Optional)',
                      hint: 'e.g. P051234567Z',
                      icon: Icons.account_balance_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Personal Admin Info
          _buildSectionHeader(
            _selectedRoleType == 'TENANT' ? 'RESIDENT PERSONAL DETAILS' : 'ADMINISTRATOR PROFILE',
            Icons.person_outline,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: _inputDecoration(label: 'First Name', hint: 'e.g. Kevin', icon: Icons.person_outline),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'First name required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration(label: 'Last Name', hint: 'e.g. Mwangi', icon: Icons.person_outline),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Last name required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration(label: 'Username', hint: 'e.g. kevin_realtor', icon: Icons.alternate_email),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Username required';
                    if (val.trim().length < 3) return 'Min 3 chars';
                    if (val.contains(' ')) return 'No spaces allowed';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _nationalIdController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(label: 'National ID / Passport', hint: 'e.g. 29384756', icon: Icons.credit_card_outlined),
                  validator: (val) => (val == null || val.trim().length < 6) ? 'Valid ID number required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(label: 'Email Address', hint: 'official@domain.com', icon: Icons.mail_outline),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email required';
                    if (!val.contains('@') || !val.contains('.')) return 'Invalid email';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(label: 'Phone Number (M-Pesa)', hint: '0712345678', icon: Icons.phone_android_outlined),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Phone required';
                    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                    if (clean.length < 9) return 'Invalid phone number';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Security
          _buildSectionHeader('SECURITY & PASSWORD', Icons.lock_outline),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(label: 'Password', hint: 'Min. 8 characters', icon: Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) => (val == null || val.length < 8) ? 'Must be at least 8 chars' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: _inputDecoration(label: 'Confirm Password', hint: 'Re-enter password', icon: Icons.lock_reset_outlined).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (val) => (val != _passwordController.text) ? 'Passwords do not match' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Terms Checkbox
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _agreedToTerms,
                    onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                    activeColor: const Color(0xFF0F6B4F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'I acknowledge and agree to PMS Pro Terms of Service, Privacy Policy and Kenya Data Protection Act regulations.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _goToNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6B4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 12),
                        Text('CREATING TENANT ACCOUNT...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedRoleType == 'TENANT' ? 'COMPLETE TENANT REGISTRATION' : 'CONTINUE TO BANK & M-PESA SETUP (STEP 2/5)',
                          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ════════════════════════════════════════════════════════════════════════
  // ── STEP 2: BANK & M-PESA SETUP ──
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildStep2BankView() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 2 of 5: Bank & M-Pesa Integration',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10231D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Connect your collection bank account for real-time rent reconciliation.',
                      style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F6B4F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STEP 2 / 5',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF0F6B4F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Informational Alert
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F6B4F).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0F6B4F).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_update_good, color: Color(0xFF0F6B4F), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Direct Bank Reconciliation: Payments received via M-Pesa Paybill / Till will automatically clear against tenant invoices and deposit into this ledger.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF102820), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bank Selection Dropdown
          _buildSectionHeader('PRIMARY RENT COLLECTION BANK', Icons.account_balance_outlined),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedBankCode,
            decoration: _inputDecoration(label: 'Commercial Bank', hint: 'Select Bank', icon: Icons.account_balance_outlined),
            items: _kenyanBanks.map((b) {
              return DropdownMenuItem(
                value: b['code'],
                child: Text('${b['name']!} (${b['code']!})', style: GoogleFonts.dmSans(fontSize: 13)),
              );
            }).toList(),
            onChanged: _onBankSelected,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextFormField(
                  controller: _accountNameController,
                  decoration: _inputDecoration(label: 'Account Name', hint: 'e.g. Apex Realty Rent Account', icon: Icons.badge_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(label: 'Account Number', hint: 'e.g. 01129384756', icon: Icons.numbers_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _paybillController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(label: 'Paybill / Till Number', hint: 'e.g. 247247', icon: Icons.payments_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _branchController,
                  decoration: _inputDecoration(label: 'Branch Name', hint: 'e.g. Westlands / Kilimani', icon: Icons.location_city_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _goToPreviousStep,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4B5563),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _skipStep,
                child: Text('Skip for now', style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6B7280))),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _goToNextStep,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Continue to Property Setup (Step 3/5)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6B4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ════════════════════════════════════════════════════════════════════════
  // ── STEP 3: PROPERTY & UNIT PORTFOLIO ──
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildStep3PropertyView() {
    return Form(
      key: _step3FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 3 of 5: Property & Initial Unit',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10231D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Add your first residential building, block or commercial arcade.',
                      style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F6B4F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STEP 3 / 5',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF0F6B4F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('BUILDING / PROPERTY DETAILS', Icons.apartment_outlined),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextFormField(
                  controller: _propertyNameController,
                  decoration: _inputDecoration(
                    label: 'Property / Building Name',
                    hint: 'e.g. Skyline Heights Apartments',
                    icon: Icons.domain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<String>(
                  initialValue: _propertyType,
                  decoration: _inputDecoration(label: 'Property Type', hint: 'Type', icon: Icons.category_outlined),
                  items: const [
                    DropdownMenuItem(value: 'APARTMENT', child: Text('Apartment Complex')),
                    DropdownMenuItem(value: 'COMMERCIAL', child: Text('Commercial Plaza')),
                    DropdownMenuItem(value: 'RESIDENTIAL', child: Text('Residential Houses')),
                    DropdownMenuItem(value: 'VILLA', child: Text('Gated Villa')),
                    DropdownMenuItem(value: 'MIXED_USE', child: Text('Mixed Use')),
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
            decoration: _inputDecoration(
              label: 'Property Physical Address / Road',
              hint: 'e.g. Dennis Pritt Road, Kilimani, Nairobi',
              icon: Icons.pin_drop_outlined,
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('INITIAL RENTAL UNIT', Icons.meeting_room_outlined),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _unitNumberController,
                  decoration: _inputDecoration(label: 'Unit Number / Code', hint: 'e.g. A101', icon: Icons.tag),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<String>(
                  initialValue: _unitType,
                  decoration: _inputDecoration(label: 'Unit Type', hint: 'Unit Type', icon: Icons.king_bed_outlined),
                  items: const [
                    DropdownMenuItem(value: '1 Bedroom', child: Text('1 Bedroom')),
                    DropdownMenuItem(value: '2 Bedroom', child: Text('2 Bedroom')),
                    DropdownMenuItem(value: '3 Bedroom', child: Text('3 Bedroom')),
                    DropdownMenuItem(value: 'Bedsitter', child: Text('Bedsitter / Studio')),
                    DropdownMenuItem(value: 'Office Space', child: Text('Office Suite')),
                    DropdownMenuItem(value: 'Shop', child: Text('Commercial Shop')),
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
                  decoration: _inputDecoration(label: 'Monthly Rent (KES)', hint: 'e.g. 35000', icon: Icons.attach_money),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _goToPreviousStep,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4B5563),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _skipStep,
                child: Text('Skip for now', style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6B7280))),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _goToNextStep,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Continue to Resident Setup (Step 4/5)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6B4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ════════════════════════════════════════════════════════════════════════
  // ── STEP 4: RESIDENT & LEASE ACTIVATION ──
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildStep4ResidentView() {
    return Form(
      key: _step4FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 4 of 5: First Resident & Lease',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10231D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Onboard your first resident tenant with an automated lease agreement.',
                      style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F6B4F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STEP 4 / 5',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF0F6B4F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('TENANT PERSONAL INFO', Icons.person_pin_outlined),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tenantFirstNameController,
                  decoration: _inputDecoration(label: 'Tenant First Name', hint: 'e.g. Daniel', icon: Icons.person_outline),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _tenantLastNameController,
                  decoration: _inputDecoration(label: 'Tenant Last Name', hint: 'e.g. Otieno', icon: Icons.person_outline),
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
                  decoration: _inputDecoration(label: 'Tenant Phone (M-Pesa)', hint: '0712345678', icon: Icons.phone_android_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _tenantIdController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(label: 'National ID / Passport No', hint: 'e.g. 31234567', icon: Icons.credit_card_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('LEASE FINANCIAL TERMS', Icons.receipt_long_outlined),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _leaseRentController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(label: 'Agreed Rent (KES/mo)', hint: 'e.g. 35000', icon: Icons.payments_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _leaseDepositController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(label: 'Security Deposit (KES)', hint: 'e.g. 35000', icon: Icons.savings_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _goToPreviousStep,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4B5563),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _skipStep,
                child: Text('Skip for now', style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6B7280))),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _goToNextStep,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Continue to Staff Setup (Step 5/5)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6B4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ════════════════════════════════════════════════════════════════════════
  // ── STEP 5: STAFF & CARETAKER DELEGATION & LAUNCH ──
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildStep5StaffAndLaunchView() {
    return Form(
      key: _step5FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 5 of 5: Staff Delegation & Final Review',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10231D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Appoint a caretaker or property manager, review and initialize your workspace.',
                      style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F6B4F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STEP 5 / 5',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF0F6B4F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('CARETAKER / TEAM MEMBER (OPTIONAL)', Icons.engineering_outlined),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextFormField(
                  controller: _staffNameController,
                  decoration: _inputDecoration(label: 'Staff Full Name', hint: 'e.g. Peter Kamau', icon: Icons.badge_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<String>(
                  initialValue: _staffRole,
                  decoration: _inputDecoration(label: 'Role / Designation', hint: 'Role', icon: Icons.work_outline),
                  items: const [
                    DropdownMenuItem(value: 'CARETAKER', child: Text('Caretaker / Porter')),
                    DropdownMenuItem(value: 'AGENT', child: Text('Property Agent')),
                    DropdownMenuItem(value: 'ACCOUNTANT', child: Text('Accountant')),
                    DropdownMenuItem(value: 'FIELD_OFFICER', child: Text('Field Officer')),
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
                  decoration: _inputDecoration(label: 'Staff Phone Number', hint: '0722334455', icon: Icons.phone_android_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _staffEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(label: 'Staff Email (Optional)', hint: 'staff@domain.com', icon: Icons.mail_outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary Overview Card
          _buildSectionHeader('PMS PRO WORKSPACE SUMMARY', Icons.fact_check_outlined),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  Icons.business,
                  'Agency / Portfolio',
                  _agencyNameController.text.trim().isNotEmpty
                      ? _agencyNameController.text.trim()
                      : '${_firstNameController.text.trim()} ${_lastNameController.text.trim()} ($_selectedCounty)',
                ),
                const Divider(height: 16),
                _buildSummaryRow(
                  Icons.account_balance,
                  'Collection Bank',
                  _accountNumberController.text.trim().isNotEmpty
                      ? '$_selectedBankCode Bank (${_accountNumberController.text.trim()})'
                      : 'Will configure later in dashboard',
                ),
                const Divider(height: 16),
                _buildSummaryRow(
                  Icons.apartment,
                  'Initial Property & Unit',
                  _propertyNameController.text.trim().isNotEmpty
                      ? '${_propertyNameController.text.trim()} - Unit ${_unitNumberController.text.trim()} (KES ${_unitRentController.text.trim()}/mo)'
                      : 'Will add buildings later in dashboard',
                ),
                const Divider(height: 16),
                _buildSummaryRow(
                  Icons.person,
                  'Resident Tenant',
                  _tenantFirstNameController.text.trim().isNotEmpty
                      ? '${_tenantFirstNameController.text.trim()} ${_tenantLastNameController.text.trim()} (${_tenantPhoneController.text.trim()})'
                      : 'Will onboard residents later in dashboard',
                ),
                const Divider(height: 16),
                _buildSummaryRow(
                  Icons.engineering,
                  'Caretaker Staff',
                  _staffNameController.text.trim().isNotEmpty
                      ? '${_staffNameController.text.trim()} ($_staffRole)'
                      : 'Will assign staff later in dashboard',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Launch Action Buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _goToPreviousStep,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4B5563),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleFullWorkspaceSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6B4F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                              SizedBox(width: 12),
                              Text('INITIALIZING PMS PRO WORKSPACE...'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.rocket_launch, color: Color(0xFFFBBF24), size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'INITIALIZE & LAUNCH PMS PRO WORKSPACE',
                                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.9),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F6B4F)),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF374151)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF4B5563)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0F6B4F)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F6B4F),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(String roleKey, String title, String subtitle, IconData icon) {
    final isSelected = _selectedRoleType == roleKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoleType = roleKey),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F6B4F).withValues(alpha: 0.08) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F6B4F) : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F6B4F) : const Color(0xFFE5E7EB).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? const Color(0xFF0F6B4F) : const Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF0F6B4F),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF4B5563),
      ),
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(
        fontSize: 13,
        color: const Color(0xFF9CA3AF),
      ),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F6B4F), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.6),
      ),
      errorStyle: GoogleFonts.dmSans(fontSize: 11, color: Colors.red.shade700),
    );
  }
}
