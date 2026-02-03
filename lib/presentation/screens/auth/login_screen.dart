import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoading = false;
  bool _isObscure = true;

  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // 1. Validación simple
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      SnackbarUtils.show(context, "Please fill all fields", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // 2. Llamada al servicio
    final result = await _authService.login(
      _emailController.text.trim(),
      _passController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // 3. Respuesta
    if (result['success']) {
      SnackbarUtils.show(context, "Welcome back!");
      // Navegamos al Home y eliminamos el historial de login
      context.go('/library');
    } else {
      SnackbarUtils.show(
        context,
        result['message'] ?? "Login failed",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- INICIO NUEVO LOGO (NEURAL CORE) ---
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. EL RESPLANDOR (Glow)
                    Container(
                      width: 120, // Un poco más grande para el brillo
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00E676).withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.3),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),

                    // 2. EL CUERPO PRINCIPAL (Gradiente Profundo)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0F2027), // Negro azulado
                            Color(0xFF203A43), // Gris azulado metálico
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 20,
                            offset: const Offset(5, 10),
                          ),
                        ],
                      ),
                    ),

                    // 3. EL ANILLO DE ENERGÍA (Indicador de Progreso)
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: 0.75, // Simula carga/progreso
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00E676),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),

                    // 4. EL ÍCONO FLOTANTE (Con Gradiente)
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFF00E676), // Verde Neón
                            Color(0xFF29B6F6), // Azul Cian
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds);
                      },
                      child: const Icon(
                        Icons.layers_outlined, // Representa "Chunking"
                        size: 45,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                // --- FIN NUEVO LOGO ---
                const SizedBox(height: 40),

                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign in to sync your progress",
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                ),

                const SizedBox(height: 40),

                // FORMULARIO
                _buildTextField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passController,
                  label: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                ),

                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implementar recuperar contraseña
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // BOTÓN LOGIN
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: AppTheme.primaryGreen.withOpacity(0.5),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.black,
                            )
                            : const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 30),

                // LINK A REGISTRO
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.white60),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white30,
                    ),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  )
                  : null,
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
