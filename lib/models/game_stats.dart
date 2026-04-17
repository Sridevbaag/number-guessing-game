class GameStats {
  int totalGames = 0;
  int totalWins = 0;
  int totalLosses = 0;  // ← Add this
  int totalAttempts = 0;
  int bestScore = 999;
  Map<String, int> difficultyWins = {
    'easy': 0,
    'medium': 0,
    'hard': 0,
  };
  Map<String, int> difficultyLosses = {  // ← Add this
    'easy': 0,
    'medium': 0,
    'hard': 0,
  };

  GameStats({
    this.totalGames = 0,
    this.totalWins = 0,
    this.totalLosses = 0,  // ← Add this
    this.totalAttempts = 0,
    this.bestScore = 999,
    Map<String, int>? difficultyWins,
    Map<String, int>? difficultyLosses,  // ← Add this
  }) {
    if (difficultyWins != null) {
      this.difficultyWins = difficultyWins;
    }
    if (difficultyLosses != null) {  // ← Add this
      this.difficultyLosses = difficultyLosses;
    }
  }

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      totalGames: json['totalGames'] ?? 0,
      totalWins: json['totalWins'] ?? 0,
      totalLosses: json['totalLosses'] ?? 0,  // ← Add this
      totalAttempts: json['totalAttempts'] ?? 0,
      bestScore: json['bestScore'] ?? 999,
      difficultyWins: Map<String, int>.from(json['difficultyWins'] ?? {}),
      difficultyLosses: Map<String, int>.from(json['difficultyLosses'] ?? {}),  // ← Add this
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalGames': totalGames,
      'totalWins': totalWins,
      'totalLosses': totalLosses,  // ← Add this
      'totalAttempts': totalAttempts,
      'bestScore': bestScore,
      'difficultyWins': difficultyWins,
      'difficultyLosses': difficultyLosses,  // ← Add this
    };
  }

  double get averageAttempts {
    if (totalWins == 0) return 0;
    return totalAttempts / totalWins;
  }

  double get winRate {
    if (totalGames == 0) return 0;
    return (totalWins / totalGames) * 100;
  }
}

enum Difficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Easy (1-50)';
      case Difficulty.medium:
        return 'Medium (1-100)';
      case Difficulty.hard:
        return 'Hard (1-500)';
    }
  }

  int get maxNumber {
    switch (this) {
      case Difficulty.easy:
        return 50;
      case Difficulty.medium:
        return 100;
      case Difficulty.hard:
        return 500;
    }
  }

  // ← Add this new property
  int get maxAttempts {
    switch (this) {
      case Difficulty.easy:
        return 20;
      case Difficulty.medium:
        return 40;
      case Difficulty.hard:
        return 60;
    }
  }

  String get name {
    return toString().split('.').last;
  }
}