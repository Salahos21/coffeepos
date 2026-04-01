import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_models.dart';
import '../../services/supabase_helper.dart';
import '../../providers/auth_provider.dart';

class StaffTab extends StatefulWidget {
  const StaffTab({super.key});

  @override
  State<StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<StaffTab> {
  List<PosUser> users = [];
  bool isLoading = true;
  late RealtimeChannel _staffSubscription;

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userPinController = TextEditingController();
  String _selectedRole = 'Barista';

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _setupStaffRealtime();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_staffSubscription);
    _userNameController.dispose();
    _userPinController.dispose();
    super.dispose();
  }

  void _setupStaffRealtime() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.cafeId == null) return;

    _staffSubscription = Supabase.instance.client
        .channel('public:staff')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'staff',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'cafe_id',
        value: auth.cafeId,
      ),
      callback: (payload) {
        _loadStaff();
      },
    )
        .subscribe();
  }

  Future<void> _loadStaff() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.cafeId == null) return;

    try {
      final dbUsers = await SupabaseHelper.instance.getAllStaff(auth.cafeId!);
      if (mounted) {
        setState(() {
          users = dbUsers;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)));
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(controller: _userNameController, decoration: const InputDecoration(labelText: "Staff Name", border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(
          controller: _userPinController,
          decoration: const InputDecoration(labelText: "4-Digit PIN", border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedRole,
          items: ['Barista', 'Manager'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
          onChanged: (v) => setState(() => _selectedRole = v!),
          decoration: const InputDecoration(labelText: "Select Role", border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        SizedBox(height: 54, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006E3B), foregroundColor: Colors.white),
          onPressed: () async {
            if (_userNameController.text.isEmpty || _userPinController.text.length != 4) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a name and a 4-digit PIN"), backgroundColor: Colors.orange));
              return;
            }
            try {
              await SupabaseHelper.instance.insertStaff(
                  PosUser(name: _userNameController.text.trim(), role: _selectedRole, pin: _userPinController.text.trim()),
                  auth.cafeId!
              );
              _userNameController.clear();
              _userPinController.clear();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Staff added successfully!"), backgroundColor: Colors.green));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add staff: $e"), backgroundColor: Colors.red));
            }
          },
          child: const Text("Add Staff"),
        )),
        const Divider(height: 40),
        ...users.map((u) => ListTile(
          leading: CircleAvatar(backgroundColor: u.role == 'Manager' ? Colors.orange : Colors.blue, child: Icon(u.role == 'Manager' ? Icons.verified_user : Icons.person, color: Colors.white)),
          title: Text(u.name),
          subtitle: Text(u.role),
          trailing: Text("PIN: ${u.pin}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        )),
      ],
    );
  }
}