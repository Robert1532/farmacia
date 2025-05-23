import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../utils/app_colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProviderFirebase>(context, listen: false);
      final isAdmin = authProvider.isAdmin;
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderFirebase>(context);
    final currentUser = authProvider.currentUser;
    final isAdmin = authProvider.isAdmin;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !isAdmin
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Acceso Restringido',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No tienes permisos de administrador para acceder a esta sección.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Volver'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del administrador
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.primary,
                                radius: 30,
                                child: Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bienvenido, ${currentUser?.name ?? "Administrador"}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currentUser?.email ?? "",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Secciones de administración
                      const Text(
                        'Gestión del Sistema',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tarjetas de opciones
                      GridView.count(
                        crossAxisCount: screenWidth < 600 ? 2 : 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildAdminCard(
                            context,
                            'Dashboard',
                            Icons.dashboard,
                            Colors.purple,
                            () {
                              Navigator.pushNamed(context, '/admin/dashboard');
                            },
                          ),
                          _buildAdminCard(
                            context,
                            'Usuarios',
                            Icons.people,
                            Colors.blue,
                            () {
                              Navigator.pushNamed(context, '/admin/users');
                            },
                          ),
                          _buildAdminCard(
                            context,
                            'Ventas Mensuales',
                            Icons.bar_chart,
                            Colors.green,
                            () {
                              Navigator.pushNamed(context, '/admin/reports/monthly-sales');
                            },
                          ),
                          _buildAdminCard(
                            context,
                            'Inventario',
                            Icons.inventory,
                            Colors.orange,
                            () {
                              Navigator.pushNamed(context, '/admin/reports/inventory');
                            },
                          ),
                          _buildAdminCard(
                            context,
                            'Reportes',
                            Icons.assessment,
                            Colors.teal,
                            () {
                              Navigator.pushNamed(context, '/admin/reports');
                            },
                          ),
                          
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
