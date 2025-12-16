import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/models/user_model.dart';

/// Login/Register screen with Firebase Authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true; // true for login, false for register
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase is not initialized. Please configure Firebase first.');
      }

      if (_isLoginMode) {
        // Sign in
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Sign up - Create user in Firebase Auth
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Create user document in Firestore
        if (userCredential.user != null) {
          final user = userCredential.user!;
          final email = user.email ?? _emailController.text.trim();
          
          // Extract username from email (part before @)
          final username = email.split('@')[0];

          // Create UserModel with initial data
          final userModel = UserModel(
            uid: user.uid,
            email: email,
            username: username,
            balance: 10000, // Welcome bonus
            createdAt: DateTime.now(),
            role: 'user',
          );

          // Save to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap());
        }
      }
      // Navigation will be handled by StreamBuilder in main.dart
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Bir hata oluştu';
      
      // Map Firebase error codes to Turkish messages
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Kullanıcı bulunamadı. Lütfen kayıt olun.';
          break;
        case 'wrong-password':
          errorMessage = 'Yanlış şifre. Lütfen tekrar deneyin.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Bu e-posta zaten kullanılıyor. Giriş yapmayı deneyin.';
          break;
        case 'weak-password':
          errorMessage = 'Şifre çok zayıf. En az 6 karakter olmalıdır.';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi. Lütfen doğru formatta girin.';
          break;
        case 'user-disabled':
          errorMessage = 'Bu kullanıcı devre dışı bırakılmış.';
          break;
        case 'too-many-requests':
          errorMessage = 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'E-posta/Şifre ile giriş etkin değil. Firebase Console\'da etkinleştirin.';
          break;
        case 'network-request-failed':
          errorMessage = 'Ağ hatası. İnternet bağlantınızı kontrol edin.';
          break;
        case 'invalid-credential':
          errorMessage = 'Geçersiz kimlik bilgileri. E-posta veya şifre hatalı.';
          break;
        default:
          errorMessage = 'Hata: ${e.code}\n${e.message ?? "Bilinmeyen hata"}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.varimColors(context).yokumColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppTheme.varimColors(context).yokumColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen bir hata oluştu: ${e.toString()}'),
            backgroundColor: AppTheme.varimColors(context).yokumColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // App Logo/Title
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            varimColors.headerAccent,
                            varimColors.headerAccent.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: varimColors.headerAccent.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        'VARIM',
                        style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: 4,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'E-posta',
                        hintText: 'ornek@email.com',
                        prefixIcon: Icon(
                          Icons.email,
                          color: varimColors.varimColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: theme.colorScheme.surfaceContainerHighest,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: varimColors.varimColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainer,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen e-posta adresinizi girin';
                        }
                        if (!value.contains('@')) {
                          return 'Geçerli bir e-posta adresi girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        hintText: '••••••••',
                        prefixIcon: Icon(
                          Icons.lock,
                          color: varimColors.varimColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: theme.colorScheme.surfaceContainerHighest,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: varimColors.varimColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainer,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen şifrenizi girin';
                        }
                        if (value.length < 6) {
                          return 'Şifre en az 6 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: varimColors.varimColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: varimColors.varimColor.withValues(alpha: 0.4),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Text(
                                _isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                                style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Toggle Button
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                                _emailController.clear();
                                _passwordController.clear();
                              });
                            },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                          children: [
                            TextSpan(
                              text: _isLoginMode
                                  ? 'Hesabın yok mu? '
                                  : 'Zaten hesabın var mı? ',
                            ),
                            TextSpan(
                              text: _isLoginMode ? 'Kayıt Ol' : 'Giriş Yap',
                              style: TextStyle(
                                color: varimColors.varimColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

