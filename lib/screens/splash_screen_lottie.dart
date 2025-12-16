class SplashScreenLottie extends StatefulWidget {
  const SplashScreenLottie({super.key});

  @override
  State<SplashScreenLottie> createState() => _SplashScreenLottieState();
}

class _SplashScreenLottieState extends State<SplashScreenLottie> {
  @override
  void initState() {
    super.initState();
    _navigateAfterAnimation();
  }

  Future<void> _navigateAfterAnimation() async {
    await Future.delayed(const Duration(milliseconds: 3500));

    if (!mounted) return;

    final authService = AuthService();
    final user = authService.currentUser;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            user != null ? const DashboardScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Dark blue
              Color(0xFF1E293B), // Slate
              Color(0xFF0F766E), // Teal
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              // Uncomment when you add the Lottie file
              /* 
              Lottie.asset(
                'assets/animations/splash.json',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
              */

              // Placeholder animation
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.emerald.shade400,
                      Colors.teal.shade400,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.emerald.withOpacity(0.5),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 100,
                  color: Colors.white,
                ),
              )
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .shimmer(
                      duration: 2000.ms, color: Colors.white.withOpacity(0.3))
                  .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.0, 1.0),
                      duration: 1500.ms),

              const SizedBox(height: 50),

              // App Title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFF10B981)],
                ).createShader(bounds),
                child: Text(
                  'EasyMoney',
                  style: GoogleFonts.poppins(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 800.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 10),

              Text(
                'Manage Your Finances Smartly',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
