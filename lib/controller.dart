import 'package:component_001/asteroid.dart';
import 'package:component_001/command.dart';
import 'package:component_001/scoreboard.dart';
import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_bonus.dart';
import 'json_utils.dart';
import 'spaceship.dart';
import 'main.dart';

/// The controller is the center piece of the game management.
/// It is responsible for dispatching commands to be executed as well as
/// keeping the state of the game organized.
///
/// The state consists of all the game elements that participate in the
/// messaging.
///
/// The controller delegates the management of the commands to the [Broker]
/// which in turns schedules the execution of all the pending commands
class Controller extends Component
    with HasGameRef<CaseStudy008DesignPatterns004> {
  /// the number of lives that a player starts with (which is the start life
  /// and 3 extra lives)
  static const defaultNumberOfLives = 4;
  static const defaultStartLevel = 0;

  //
  // pause between levels or new lives in seconds
  static const timeoutPauseInSeconds = 3;
  int _pauseCountdown = 0;
  bool _levelDoneFlag = false;
  int _respawnCountdown = 0;
  bool _playerDiedFlag = false;

  /// the broker which is a dedicated helper that executes all the commands
  /// on behalf o teh controller
  final Broker _broker = Broker();

  /// state data
  ///
  ///

  /// joystick
  ///
  late final JoystickComponent _joystick;

  /// all the game levels loaded from JSON
  late List<GameLevel> _gameLevels;
  int _currentGameLevelIndex = 0;

  /// a stack used to hold all the objects from the current level. Once this
  /// list/stack is empty we can go to the next level.
  List currLevelObjectStack = List.empty(growable: true);

  /// JSON Data from initialization
  late dynamic jsonData;

  /// default resolution to which levels are tethered
  ///
  /// resolution multiplier is used to calculet the necessary changes in
  /// position, size and velocity of different objects so that they are
  /// correctly displayed in different reslutions
  late Vector2 _baseResolution;
  final Vector2 _resolutionMultiplier = Vector2.all(1.0);

  /// Scoreboard data
  ///
  late final ScoreBoard _scoreboard;

  /// state data methods
  ///

  //
  // The player being controlled by Joystick
  late SpaceShip player;

  //
  // Easy access to Image manipulation ofr the game engine
  late Images images;

  SpaceShip getSpaceship() {
    return player;
  }

  Images getImagesBroker() {
    return gameRef.images;
  }

  /// initialization 'hook' this should be called right after the Controller
  /// has been created
  ///
  /// It will initialize the inner state of the
  Future<void> init() async {
    debugPrint('{controller} <initializing...>');

    /// read JSON data
    ///
    jsonData = await JSONUtils.readJSONInitData();

    /// read in the resolution and calculate the resolution multiplier
    ///
    _baseResolution = JSONUtils.extractBaseGameResolution(jsonData);

    /// calculate the multipier
    _resolutionMultiplier.x = gameRef.size.x / _baseResolution.x;
    _resolutionMultiplier.y = gameRef.size.y / _baseResolution.y;

    debugPrint(
        '{controller} <resolution>: [${gameRef.size.x}, ${gameRef.size.y}], $_baseResolution, $_resolutionMultiplier');

    /// read the JSON data about the game levels and other game-related data
    ///
    _gameLevels = JSONUtils.extractGameLevels(jsonData);
    debugPrint('{controller} <levels>: $_gameLevels');

    /// initialize socreboard
    ///
    _scoreboard =
        ScoreBoard(defaultNumberOfLives, defaultStartLevel, _gameLevels.length);

    /// read in the high score if it exists and create the scoreboard data
    ///
    /// We are using an external package for this which you can find here:
    /// https://pub.dev/packages/shared_preferences/install
    ///

    /// Obtain shared preferences.
    final prefs = await SharedPreferences.getInstance();
    // Try reading data from the 'highScore' key. If it doesn't exist, returns null.
    int? userHighScore = prefs.getInt('highScore');
    if (userHighScore != null) {
      _scoreboard.highScore = userHighScore;
    }
    debugPrint('{controller} <scoreboard>: $_scoreboard');
    //
    // initialize sub-components
    add(_scoreboard);

    //
    // joystick knob and background skin styles
    final knobPaint = BasicPalette.green.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.green.withAlpha(100).paint();
    //
    // Actual Joystick component creation
    _joystick = JoystickComponent(
      knob: CircleComponent(radius: 15, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 20, bottom: 20),
    );

    ///
    /// we add the player and joystick to the controller's tree of components
    spawnNewPlayer();
    add(_joystick);

    debugPrint('{controller} <initializing... done>');
  }

  /// timer hook
  /// We will monitor here the exact passage of time in seconds for the game
  void timerNotification() {
    debugPrint('{controller} <timer hook executing...>');

    /// Update time passage in scoreboard
    ///
    UpdateScoreboardTimePassageInfoCommand(_scoreboard).addToController(this);

    /// Check for Bonus spawn
    ///
    debugPrint(
        '{controller} <timer hook executing...> <bonus spawn> level: ${_scoreboard.getCurrentLevel} since start: ${_scoreboard.getTimeSinceStartOfLevel}');
    if (_scoreboard.getCurrentLevel > 0) {
      int currTimeTick = _scoreboard.getTimeSinceStartOfLevel;
      if (_gameLevels[_scoreboard.getCurrentLevel - 1]
          .shouldSpawnBonus(currTimeTick)) {
        GameBonusBuildContext? context =
            _gameLevels[_scoreboard.getCurrentLevel - 1].getBonus(currTimeTick);
        debugPrint(
            '{controller} <timer hook executing...> <found bonus context> $context');
        if (context != null) {
          /// build the bonus and add it to the game
          ///
          GameBonus? bonus = GameBonusFactory.create(context);
          debugPrint(
              '{controller} <timer hook executing...> <created bonus> $bonus');
          currLevelObjectStack.add(bonus);
          add(bonus!);
        }
      }
    }

    /// Test for new level generation
    ///
    if (isCurrLevelFinished()) {
      debugPrint('{controller} <timer hook loading next level>');
      // load next level if it exists
      loadNextGameLevel();
    }

    /// Test for player respawn
    ///
    if (shouldRespawnPlayer()) {
      debugPrint('{controller} <timer hook respawning>');
      // respawn the player
      spawnNewPlayer();
    }

    debugPrint('{controller} <timer hook... done>');
  }

  /// at each game update cycle the controller will instruct the broker
  /// to process all outstanding commands
  @override
  void update(double dt) {
    /// execute all the commands
    ///
    _broker.process();
    super.update(dt);

    debugPrint("<controller update> number of children: ${children.length}");
  }

  @override
  Future<void>? onLoad() {
    debugPrint("<controller onload> loading resources...");
    return super.onLoad();
  }

  /// schedule a [command] for processing by delgating it to the broker
  void addCommand(Command command) {
    _broker.addCommand(command);
  }

  /// getters
  ///
  List<GameLevel> get getLevels {
    return _gameLevels;
  }

  Vector2 get getBaseResolution {
    return _baseResolution;
  }

  Vector2 get getResoltionMultiplier {
    return _resolutionMultiplier;
  }

  ScoreBoard get getScoreBoard {
    return _scoreboard;
  }

  /// Helper Methods
  ///

  /// this method loads the next game level and displays it on screen
  ///
  void loadNextGameLevel() {
    // reset data
    List<Asteroid> asteroids = List.empty(growable: true);
    List<GameBonus> gamebonuses = List.empty(growable: true);

    debugPrint('{controller} <level load> <clearing objects stack...>');
    // clear the object stack just in case its not empty
    currLevelObjectStack.clear();

    debugPrint(
        '{controller} <level load> <current level: $_currentGameLevelIndex>');
    debugPrint(
        '{controller} <level load> <levels length: ${_gameLevels.length}>');

    // make sure that there are more levels left
    //
    if (_currentGameLevelIndex < _gameLevels.length) {
      // load the asteroid elements
      //
      for (var asteroid in _gameLevels[_currentGameLevelIndex].asteroidConfig) {
        // add the multiplier to the asteroid context
        //
        asteroid.multiplier = _resolutionMultiplier;
        // create each asteroid
        //
        Asteroid newAsteroid = AsteroidFactory.create(asteroid);
        asteroids.add(newAsteroid);
        //
        //
        currLevelObjectStack.add(asteroids.last);
        debugPrint(
            '{controller} <level load> <adding object ${asteroids.last}>');
      }
      // add all the asteroids to the component tree so that they are part of
      // the game play
      addAll(asteroids);
      // load the game bonus elements

      // update the level counter
      _currentGameLevelIndex++;
      UpdateScoreboardLevelInfoCommand(getScoreBoard).addToController(this);
    }
  }

  void spawnNewPlayer() {
    //
    // creating the player that will be controlled by our joystick
    PlayerBuildContext context = PlayerBuildContext()
      ..spaceShipType = SpaceShipEnum.simpleSpaceShip
      ..joystick = _joystick
      ..multiplier = getResoltionMultiplier;
    player = SpaceShipFactory.create(context);
    add(player);
  }

  /// check if the current level is done.
  ///
  /// We also adda a'barrier' of a couple seconds to pause teh level generation
  /// so that the player has a few seconds in between levels
  ///
  bool isCurrLevelFinished() {
    if (currLevelObjectStack.isEmpty) {
      if (_levelDoneFlag == false) {
        _levelDoneFlag = true;
        _pauseCountdown = timeoutPauseInSeconds;
        return false;
      }
      if (_levelDoneFlag == true) {
        if (_pauseCountdown == 0) {
          _levelDoneFlag = false;
          return true;
        } else {
          _pauseCountdown--;
          return false;
        }
      }
      return false;
    } else {
      return false;
    }
  }

  /// check if the current level is done.
  ///
  /// We also adda a'barrier' of a couple seconds to pause teh level generation
  /// so that the player has a few seconds in between levels
  ///
  bool shouldRespawnPlayer() {
    if (!children.any((element) => element is SpaceShip)) {
      if (_playerDiedFlag == false) {
        _playerDiedFlag = true;
        _respawnCountdown = timeoutPauseInSeconds;
        return false;
      }
      if (_playerDiedFlag == true && _scoreboard.getLivesLeft > 0) {
        if (_respawnCountdown == 0) {
          _playerDiedFlag = false;
          return true;
        } else {
          _respawnCountdown--;
          return false;
        }
      }
      return false;
    } else {
      return false;
    }
  }
}

/// This is a single game level which can hold asteroid position and velocity
/// data, as well as UFO Bonus data which woudl be time-stamped to the specific
/// moment when it should how up in that level.
///
class GameLevel {
  List<AsteroidBuildContext> asteroidConfig = [];
  List<GameBonusBuildContext> gameBonusConfig = [];
  final Map<int, GameBonusBuildContext> _gameBonusMap = {};

  GameLevel();

  void init() {
    debugPrint('<GameLevel> <init> bonus length: ${gameBonusConfig.length}');
    for (GameBonusBuildContext bonus in gameBonusConfig) {
      _gameBonusMap[bonus.timeTriggerSeconds] = bonus;
    }

    debugPrint('<GameLevel> <init> bonus: $_gameBonusMap');
    debugPrint('<GameLevel> <init> level: bonus keys: ${_gameBonusMap.keys}');
  }

  /// business methods
  ///
  bool shouldSpawnBonus(int timeTick) {
    debugPrint('<shouldSpawnBonus> <procesing...> $_gameBonusMap');
    debugPrint(
        '<shouldSpawnBonus> <time tick> $timeTick, element: ${_gameBonusMap[timeTick]}');
    if (_gameBonusMap[timeTick] != null) {
      debugPrint('<shouldSpawnBonus> <YES>');
      return true;
    } else {
      debugPrint('<shouldSpawnBonus> <NO>');
      return false;
    }
  }

  GameBonusBuildContext? getBonus(int timeTick) {
    return _gameBonusMap[timeTick];
  }

  @override

  /// We are defining our own stringify method so that we can see our
  /// values when debugging.
  ///
  String toString() {
    return 'level data: [ asteroids: $asteroidConfig ] , gameBonus: [$gameBonusConfig]';
  }
}
