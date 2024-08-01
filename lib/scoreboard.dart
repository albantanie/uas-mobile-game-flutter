import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'command.dart';
import 'main.dart';

/// Simple class representing the running scoreboard for the game.
/// We also have the high-score here to shows the user their best score
///
class ScoreBoard extends PositionComponent
    with HasGameRef<CaseStudy008DesignPatterns004> {
  int _highScore = 0;
  int _numOfShotsFired = 0;
  int _score = 0;
  int _livesLeft = 0;
  int _currentLevel = 0;
  int _maxLevels = 0;
  int _timeSinceStartInSeconds = 0;
  int _timeSinceStartofLevelInSeconds = 0;

  //
  // Number of lives left
  final TextPaint _livesLeftTextPaint = TextPaint(
    style: const TextStyle(
      fontSize: 12.0,
      fontFamily: 'Awesome Font',
      color: Colors.red,
    ),
  );

  //
  // passage of time in seconds
  final TextPaint _passageOfTimePaint = TextPaint(
    style: const TextStyle(
      fontSize: 12.0,
      fontFamily: 'Awesome Font',
      color: Colors.grey,
    ),
  );

  //
  // Score
  final TextPaint _scorePaint = TextPaint(
    style: const TextStyle(
      fontSize: 12.0,
      fontFamily: 'Awesome Font',
      color: Colors.green,
    ),
  );

  //
  // High Score
  final TextPaint _highScorePaint = TextPaint(
    style: const TextStyle(
      fontSize: 12.0,
      fontFamily: 'Awesome Font',
      color: Colors.red,
    ),
  );

  //
  // Score
  final TextPaint _shotsFiredPaint = TextPaint(
    style: const TextStyle(
      fontSize: 12.0,
      fontFamily: 'Awesome Font',
      color: Colors.blue,
    ),
  );

  //
  // Score
  final TextPaint _levelInfoPaint = TextPaint(
    style: const TextStyle(
      fontSize: 12.0,
      fontFamily: 'Awesome Font',
      color: Colors.amber,
    ),
  );

  ScoreBoard(int livesLeft, int currentLevel, int maxLevels)
      : _livesLeft = livesLeft,
        _currentLevel = currentLevel,
        _maxLevels = maxLevels,
        super(priority: 100);

  /// setters
  ///
  ///

  set highScore(int highScore) {
    if (highScore > 0) {
      _highScore = highScore;
    }
  }

  set lives(int lives) {
    if (lives > 0) {
      _livesLeft = lives;
    }
  }

  set level(int level) {
    if (level > 0) {
      _currentLevel = level;
      _timeSinceStartofLevelInSeconds = 0;
    }
  }

  /// getters
  ///

  int get getLivesLeft {
    return _livesLeft;
  }

  int get getCurrentLevel {
    return _currentLevel;
  }

  int get getTimeSinceStart {
    return _timeSinceStartInSeconds;
  }

  int get getTimeSinceStartOfLevel {
    return _timeSinceStartofLevelInSeconds;
  }

  int get getScore {
    return _score;
  }

  int get getHighScore {
    return _highScore;
  }

  /// bussiness methods
  ///

  void addBulletFired() {
    _numOfShotsFired++;
  }

  void addBulletsFired(int numOfBullets) {
    if (numOfBullets > 0) {
      _numOfShotsFired += numOfBullets;
    }
  }

  void addScorePoints(int points) {
    if (points > 0) {
      _score += points;
    }
  }

  void removeLife() {
    if (_livesLeft > 0) {
      _livesLeft--;
    }
    if (_livesLeft <= 0) {
      GameOverCommand().addToController(gameRef.controller);
    }
  }

  void addExtraLife() {
    _livesLeft++;
  }

  void addTimeTick() {
    _timeSinceStartInSeconds++;
    _timeSinceStartofLevelInSeconds++;
  }

  void resetLevelTimer() {
    _timeSinceStartofLevelInSeconds = 0;
  }

  void progressLevel() {
    _currentLevel++;
  }

  /// Overrides
  ///

  @override
  void render(Canvas canvas) {
    //
    // render the number of lives left or 'GAME OVER' if we are out
    _livesLeftTextPaint.render(
      canvas,
      formatNumberOfLives(),
      Vector2(20, 16),
    );

    //
    // render the angle in radians for reference
    _scorePaint.render(
      canvas,
      'Score: ${_score.toString()}',
      Vector2(gameRef.size.x - 100, 16),
    );

    //
    // render the angle in radians for reference
    _highScorePaint.render(
      canvas,
      'High Score: ${_highScore.toString()}',
      Vector2(gameRef.size.x - 100, 32),
    );

    //
    // render the angle in radians for reference
    _shotsFiredPaint.render(
      canvas,
      'Shots Fired: ${_numOfShotsFired.toString()}',
      Vector2(20, 32),
    );

    //
    // render the angle in radians for reference
    _levelInfoPaint.render(
      canvas,
      '${formatLevelData()}',
      Vector2(gameRef.size.x - 100, 48),
    );

    //
    // render the passage of time
    _passageOfTimePaint.render(
      canvas,
      'time: $_timeSinceStartInSeconds',
      Vector2(gameRef.size.x - 100, 64),
    );
  }

  @override

  /// We are defining our own stringify method so that we can see our
  /// values when debugging.
  ///
  String toString() {
    return 'highScore: $_highScore , numOfShotsFired: $_numOfShotsFired , '
        'score: $_score , livesLeft: $_livesLeft, currentLevel: $_currentLevel, '
        ' time since start: $_timeSinceStartInSeconds, timer for this level: $_timeSinceStartofLevelInSeconds  ';
  }

  /// Helper Methods
  ///
  String formatNumberOfLives() {
    if (_livesLeft > 0) {
      return 'Lives Left: ' + _livesLeft.toString();
    } else {
      return "GAME OVER";
    }
  }

  String formatLevelData() {
    String result = '';

    if (_currentLevel > 0) {
      result = 'Level: ' + _currentLevel.toString();
    } else {
      result = "Level: -";
    }

    return result + ' of ' + _maxLevels.toString();
    ;
  }
}
