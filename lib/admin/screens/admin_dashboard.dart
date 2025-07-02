import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ndri_dairy_risk/admin/screens/view_submission.dart';

import '../models/survey_submission.dart';
import '../services/firestore_service.dart';

enum DashboardSection { users, submissions }

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  int _totalUsers = 0;
  int _totalSubmissions = 0;
  List<String> _allUsers = [];
  List<SurveySubmission> _allSubmissions = [];
  DashboardSection _selectedSection = DashboardSection.submissions;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final submissions = await _firestoreService.getAllSurveySubmissions().first;
    final Set<String> uniqueUsers = {};
    for (final sub in submissions) {
      if (sub.name.isNotEmpty) {
        uniqueUsers.add(sub.name.trim());
      }
    }
    setState(() {
      _totalUsers = uniqueUsers.length;
      _totalSubmissions = submissions.length;
      _allUsers = uniqueUsers.toList();
      _allSubmissions = submissions;
    });
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 28),
            SizedBox(width: 12),
            Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 960;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        children: [
          _SideMenu(
            selected: _selectedSection,
            onSelect: (section) => setState(() => _selectedSection = section),
            onLogout: _logout,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 42 : 18, vertical: 22),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0e86d4), Color(0xFF01949a)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 16,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 26,
                        child: Image.asset('assets/logo.png',
                            height: 30, width: 30, errorBuilder: (c, o, s) {
                          return Icon(Icons.public,
                              color: Color(0xFF0e86d4), size: 24);
                        }),
                      ),
                      const SizedBox(width: 18),
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26.0, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatGlassCard(
                          label: 'Total Users',
                          value: _totalUsers,
                          icon: Icons.group,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          glowColor: Colors.greenAccent.withOpacity(0.13),
                        ),
                      ),
                      const SizedBox(width: 26),
                      Expanded(
                        child: _StatGlassCard(
                          label: 'Total Submissions',
                          value: _totalSubmissions,
                          icon: Icons.assignment_turned_in_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0e86d4), Color(0xFF01949a)],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                          glowColor: Colors.blueAccent.withOpacity(0.13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const SizedBox(height: 26),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeInOutCubic,
                    child: Container(
                      key: ValueKey(_selectedSection),
                      margin: EdgeInsets.symmetric(
                          horizontal: isWide ? 40 : 10, vertical: 0),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueGrey.withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _buildSectionContent(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent() {
    if (_selectedSection == DashboardSection.users) {
      return _allUsers.isEmpty
          ? Center(
              child: Text('No users found.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 19)))
          : ListView.separated(
              itemCount: _allUsers.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(
                    child:
                        Icon(Icons.person, color: Colors.blueAccent, size: 28)),
                title: Text(_allUsers[i],
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ),
            );
    } else {
      if (_allSubmissions.isEmpty) {
        return Center(
            child: Text('No submissions found.',
                style: TextStyle(color: Colors.grey[700], fontSize: 19)));
      }
      return ListView.separated(
        itemCount: _allSubmissions.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (_, i) {
          final s = _allSubmissions[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[50],
              child: Icon(Icons.assignment_turned_in_rounded,
                  color: Colors.green[700], size: 26),
            ),
            title: Text(s.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
            subtitle: Text(
                'Submitted on: ${s.timestamp != null ? s.timestamp.toString().split(' ').first : 'Unknown'}'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ViewSubmissionPage(submission: s),
                ),
              );
            },
          );
        },
      );
    }
  }
}

class _SideMenu extends StatelessWidget {
  final DashboardSection selected;
  final ValueChanged<DashboardSection> onSelect;
  final VoidCallback onLogout;

  const _SideMenu({
    required this.selected,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 960;
    return Container(
      width: isWide ? 220 : 70,
      color: const Color(0xFF093554),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 38),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Image.asset('assets/images/app_logo.webp',
                    errorBuilder: (c, o, s) {
                  return Icon(Icons.public, color: Color(0xFF0e86d4), size: 27);
                }),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (isWide)
            Center(
              child: Text(
                "Risk Climate",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          const SizedBox(height: 44),
          _MenuItem(
            icon: Icons.person,
            label: "Users",
            isSelected: selected == DashboardSection.users,
            onTap: () => onSelect(DashboardSection.users),
          ),
          _MenuItem(
            icon: Icons.assignment_turned_in,
            label: "Submissions",
            isSelected: selected == DashboardSection.submissions,
            onTap: () => onSelect(DashboardSection.submissions),
          ),
          Spacer(),
          _MenuItem(
            icon: Icons.logout,
            label: "Logout",
            isSelected: false,
            onTap: onLogout,
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 960;
    return Material(
      color: isSelected ? Colors.white.withOpacity(0.17) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              EdgeInsets.symmetric(vertical: 15, horizontal: isWide ? 23 : 0),
          child: Row(
            mainAxisAlignment:
                isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 25),
              if (isWide) ...[
                SizedBox(width: 15),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.96),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatGlassCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;

  const _StatGlassCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.glowColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 300;
        return Container(
          constraints: const BoxConstraints(minHeight: 150, maxHeight: 230),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: Colors.white.withOpacity(0.96),
                  size: isSmall ? 36 : 44),
              const SizedBox(height: 12),
              Text(
                '$value',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 36 : 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  shadows: const [
                    Shadow(color: Colors.black26, blurRadius: 10)
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.98),
                    fontSize: isSmall ? 17 : 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
