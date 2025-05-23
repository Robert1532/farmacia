import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmacia/providers/auth_provider_firebase.dart';
import 'package:farmacia/providers/theme_provider.dart';
import 'package:farmacia/utils/app_colors.dart';
import 'package:farmacia/widgets/custom_button.dart';
import 'package:farmacia/widgets/confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderFirebase>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sección de apariencia
          _buildSectionHeader('Apariencia'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Tema Oscuro'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: AppColors.primaryColor,
                  ),
                  onTap: () {
                    themeProvider.toggleTheme();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: const Text('Personalizar Colores'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pushNamed(context, '/theme-settings');
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sección de cuenta
          _buildSectionHeader('Cuenta'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Editar Perfil'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Cambiar Contraseña'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showChangePasswordDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notificaciones'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pushNamed(context, '/notification-settings');
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sección de aplicación
          _buildSectionHeader('Aplicación'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Idioma'),
                  trailing: const Text('Español'),
                  onTap: () {
                    // Implementar cambio de idioma
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Moneda'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pushNamed(context, '/currency-settings');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Acerca de'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Botón de cerrar sesión
          CustomButton(
            text: 'Cerrar Sesión',
            icon: Icons.logout,
            isLoading: _isLoading,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => ConfirmDialog(
                  title: 'Cerrar Sesión',
                  content: '¿Estás seguro de que deseas cerrar sesión?',
                  confirmText: 'Cerrar Sesión',
                  cancelText: 'Cancelar',
                ),
              );

              if (confirmed == true) {
                setState(() {
                  _isLoading = true;
                });
                
                try {
                  await authProvider.logout();
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al cerrar sesión: $e')),
                  );
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña Actual',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmar Nueva Contraseña',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Las contraseñas no coinciden')),
                );
                return;
              }
              
              Navigator.pop(context, {
                'currentPassword': currentPasswordController.text,
                'newPassword': newPasswordController.text,
              });
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final authProvider = Provider.of<AuthProviderFirebase>(context, listen: false);
        await authProvider.changePassword(
          result['currentPassword']!,
          result['newPassword']!,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar la contraseña: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acerca de Farmacia App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Versión 1.0.0'),
            SizedBox(height: 8),
            Text('© 2023 Farmacia App. Todos los derechos reservados.'),
            SizedBox(height: 16),
            Text('Desarrollado con Flutter'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
