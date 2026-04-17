import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'dart:io' show Platform;
import 'models/game_stats.dart';
import 'screens/stats_screen.dart';

void main() {
  runApp(const NumberGuessingGameApp());
}

class NumberGuessingGameApp extends StatelessWidget {
  const NumberGuessingGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Guessing Game',
      theme: ThemeData(
        primaryColor: const Color(0xFF6A11CB),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  int secretNumber = 0;
  int attempts = 0;
  bool isGameWon = false;
  bool isGameLost = false;
  String message = 'Guess a number between 1 and 100';
  final TextEditingController _controller = TextEditingController();

  Difficulty currentDifficulty = Difficulty.medium;
  GameStats stats = GameStats();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  late AnimationController _bgAnimationController;
  late Animation<double> _bgAnimation;

  final math.Random _random = math.Random.secure();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _resetGame();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _bgAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _bgAnimation = CurvedAnimation(
      parent: _bgAnimationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString('gameStats');
    if (statsJson != null) {
      setState(() {
        stats = GameStats.fromJson(json.decode(statsJson));
      });
    }
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gameStats', json.encode(stats.toJson()));
  }

  Future<void> _resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gameStats');
    setState(() {
      stats = GameStats();
    });
  }

  void _resetGame() {
    setState(() {
      secretNumber = 1 + _random.nextInt(currentDifficulty.maxNumber);
      attempts = 0;
      isGameWon = false;
      isGameLost = false;
      message = 'Guess a number between 1 and ${currentDifficulty.maxNumber}';
      _controller.clear();
    });
  }

  Future<void> _playSound(String fileName) async {
    if (!isSoundEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> _vibrate() async {
    if (Platform.isAndroid || Platform.isIOS) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 300, amplitude: 128);
      } else {
        HapticFeedback.vibrate();
      }
    }
  }

  void _checkGuess() {
    final guess = int.tryParse(_controller.text);
    if (guess == null) return;

    if (guess < 1 || guess > currentDifficulty.maxNumber) {
      setState(() {
        message = '⚠️ Enter a number between 1 and ${currentDifficulty.maxNumber}';
      });
      _shakeController.forward(from: 0.0);
      _vibrate();
      return;
    }

    setState(() {
      attempts++;
      stats.totalAttempts++;

      if (guess == secretNumber) {
        message = '🎉 Correct! It was $secretNumber';
        isGameWon = true;

        stats.totalGames++;
        stats.totalWins++;
        stats.difficultyWins[currentDifficulty.name] =
            (stats.difficultyWins[currentDifficulty.name] ?? 0) + 1;

        if (attempts < stats.bestScore) {
          stats.bestScore = attempts;
        }

        _saveStats();

        if (Platform.isAndroid || Platform.isIOS) {
          HapticFeedback.heavyImpact();
        }
        _playSound('correct.mp3');
      } else if (attempts >= currentDifficulty.maxAttempts) {
        message = '❌ Wrong! It was $secretNumber';
        isGameLost = true;

        stats.totalGames++;
        stats.totalLosses++;
        stats.difficultyLosses[currentDifficulty.name] =
            (stats.difficultyLosses[currentDifficulty.name] ?? 0) + 1;

        _saveStats();

        _shakeController.forward(from: 0.0);
        _vibrate();
        _playSound('wrong.mp3');
      } else {
        _shakeController.forward(from: 0.0);
        _vibrate();
        _playSound('wrong.mp3');
        message = guess < secretNumber ? 'Too Low! Try again.' : 'Too High! Try again.';
      }
    });
    _controller.clear();
  }

  void _shareScore() {
    final text = '''🎮 Number Guessing Game 🎮

🎯 I guessed the number in $attempts attempts!
📊 Difficulty: ${currentDifficulty.label}
🏆 My best score: ${stats.bestScore == 999 ? 'N/A' : stats.bestScore} attempts
📈 Total wins: ${stats.totalWins}

Can you beat my score? Download the app!''';

    Share.share(text);
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Difficulty.values.map((diff) {
            return RadioListTile<Difficulty>(
              title: Text(diff.label),
              value: diff,
              groupValue: currentDifficulty,
              onChanged: (value) {
                setState(() {
                  currentDifficulty = value!;
                  _resetGame();
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xFF6A11CB), const Color(0xFF2575FC), _bgAnimation.value)!,
                      Color.lerp(const Color(0xFF2575FC), const Color(0xFF6A11CB), _bgAnimation.value)!,
                    ],
                  ),
                ),
              );
            },
          ),

          const FloatingSymbolsBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.bar_chart, color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StatsScreen(
                            stats: stats,
                            onReset: _resetStats,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),

                  GestureDetector(
                    onTap: isGameWon || isGameLost ? null : _showDifficultyDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            currentDifficulty.label,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: Colors.white),
                        ],
                      ),
                    ),
                  ),

                  IconButton(
                    icon: Icon(
                      isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        isSoundEnabled = !isSoundEnabled;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    double dx = math.sin(_shakeAnimation.value * 10 * math.pi) * 8;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Card(
                      elevation: 12,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) => FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: Text(
                                message,
                                key: ValueKey<String>(message),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 32),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: isGameWon 
                                  ? _buildWinUI() 
                                  : isGameLost 
                                      ? _buildLoseUI() 
                                      : _buildInputUI(),
                            ),

                            const SizedBox(height: 24),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Attempts: $attempts',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (!isGameWon && !isGameLost)
                                  Text(
                                    'Remaining: ${currentDifficulty.maxAttempts - attempts}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: attempts >= currentDifficulty.maxAttempts - 5 
                                          ? Colors.red.shade300
                                          : Colors.white.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputUI() {
    return Column(
      key: const ValueKey('input'),
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: '?',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white, width: 2.5),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onSubmitted: (_) => _checkGuess(),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _checkGuess,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6A11CB),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'CHECK',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWinUI() {
    return Column(
      key: const ValueKey('win'),
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 80),
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          height: 60,
          child: OutlinedButton.icon(
            onPressed: _shareScore,
            icon: const Icon(Icons.share),
            label: const Text(
              'SHARE SCORE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent[400],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'PLAY AGAIN',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoseUI() {
    return Column(
      key: const ValueKey('lose'),
      children: [
        const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 80),
        const SizedBox(height: 24),
        
        Text(
          'Out of attempts!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[400],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'RETRY',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    _bgAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}

class FloatingSymbolsBackground extends StatelessWidget {
  const FloatingSymbolsBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final symbols = ['+', '-', '×', '÷', '%', '√', 'π', '∑', '∫', '∆'];
    return Stack(
      children: List.generate(12, (index) {
        final random = math.Random();
        return FloatingSymbol(
          symbol: symbols[random.nextInt(symbols.length)],
          initialPosition: Offset(
            random.nextDouble() * MediaQuery.of(context).size.width,
            random.nextDouble() * MediaQuery.of(context).size.height,
          ),
          duration: Duration(seconds: 15 + random.nextInt(15)),
        );
      }),
    );
  }
}

class FloatingSymbol extends StatefulWidget {
  final String symbol;
  final Offset initialPosition;
  final Duration duration;

  const FloatingSymbol({
    super.key,
    required this.symbol,
    required this.initialPosition,
    required this.duration,
  });

  @override
  State<FloatingSymbol> createState() => _FloatingSymbolState();
}

class _FloatingSymbolState extends State<FloatingSymbol> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  late double _opacity;
  late double _size;
  late double _rotationSpeed;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _opacity = 0.03 + random.nextDouble() * 0.12;
    _size = 18.0 + random.nextDouble() * 32.0;
    _rotationSpeed = (random.nextDouble() - 0.5) * 2;

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<Offset>(
      begin: widget.initialPosition,
      end: Offset(
        widget.initialPosition.dx + (random.nextDouble() - 0.5) * 150,
        widget.initialPosition.dy - 1000,
      ),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double screenHeight = MediaQuery.of(context).size.height;
        double yPos = _animation.value.dy % (screenHeight + 100) - 50;

        return Positioned(
          left: _animation.value.dx % MediaQuery.of(context).size.width,
          top: yPos,
          child: Transform.rotate(
            angle: _controller.value * 2 * math.pi * _rotationSpeed,
            child: Opacity(
              opacity: _opacity,
              child: Text(
                widget.symbol,
                style: TextStyle(
                  fontSize: _size,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
