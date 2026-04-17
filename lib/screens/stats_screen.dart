import 'package:flutter/material.dart';
import '../models/game_stats.dart';

class StatsScreen extends StatelessWidget {
  final GameStats stats;
  final VoidCallback onReset;

  const StatsScreen({
    super.key,
    required this.stats,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Overall Stats Card
                    _buildStatsCard(
                      title: 'Overall Performance',
                      children: [
                        _buildStatRow('Total Games', stats.totalGames.toString()),
                        _buildStatRow('Total Wins', stats.totalWins.toString()),
                        _buildStatRow('Total Losses', stats.totalLosses.toString()),  // ← Add this
                        _buildStatRow('Win Rate', '${stats.winRate.toStringAsFixed(1)}%'),
                        _buildStatRow('Best Score', stats.bestScore == 999 ? 'N/A' : '${stats.bestScore} attempts'),
                        _buildStatRow('Avg. Attempts', stats.averageAttempts.toStringAsFixed(1)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Difficulty Breakdown
                    _buildStatsCard(
                      title: 'Wins by Difficulty',
                      children: [
                        _buildStatRow('Easy', stats.difficultyWins['easy'].toString()),
                        _buildStatRow('Medium', stats.difficultyWins['medium'].toString()),
                        _buildStatRow('Hard', stats.difficultyWins['hard'].toString()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ← Add this new card
                    _buildStatsCard(
                      title: 'Losses by Difficulty',
                      children: [
                        _buildStatRow('Easy', stats.difficultyLosses['easy'].toString()),
                        _buildStatRow('Medium', stats.difficultyLosses['medium'].toString()),
                        _buildStatRow('Hard', stats.difficultyLosses['hard'].toString()),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Reset Button
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reset Statistics?'),
                            content: const Text('This will delete all your stats permanently.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  onReset();
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text('Reset', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Reset All Statistics'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard({required String title, required List<Widget> children}) {
    return Card(
      color: Colors.white.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}