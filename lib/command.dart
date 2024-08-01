import 'dart:math';

import 'package:component_001/asteroid.dart';
import 'package:component_001/bullet.dart';
import 'package:component_001/controller.dart';
import 'package:component_001/game_bonus.dart';
import 'package:component_001/particle_utils.dart';
import 'package:component_001/scoreboard.dart';
import 'package:component_001/spaceship.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Broker is just a simple deletgate to take care of processing lists of
/// commands
///
/// We keep two lists:
///  - [_commandList] holds the commands waiting to be executed
///  - [_pendingCommandList] holds all the pending commands. This list is
///    used when the main list is being processed.
class Broker {
  final _commandList = List<Command>.empty(growable: true);
  final _pendingCommandList = List<Command>.empty(growable: true);
  //
  // extra list to track any duplicate messages that should be unique
  final _duplicatesWatcher = List<Command>.empty(growable: true);

  /// explicit default constructor
  Broker();

  /// add the command to the broker to process
  void addCommand(Command command) {
    debugPrint('{Adding command}: $command');

    /// pre-condition
    if (command.mustBeUnique()) {
      if (_duplicatesWatcher
          .any((element) => element.getId() == command.getId())) {
        // the element is already in the queue so we diregard it
        debugPrint('{Adding command}: $command <duplicate found and removed>');
        return;
      } else {
        // add it to the watched list
        _duplicatesWatcher.add(command);
      }
    } // end of pre-condition

    // add the command to the queue
    _pendingCommandList.add(command);
  }

  /// process all the scheduled commands
  void process() {
    /// Process all current commands
    ///
    for (var command in _commandList) {
      // excecute each command
      debugPrint('{Executing command}: $command');
      command.execute();
    }

    /// clear the done list
    _commandList.clear();

    /// move pending into current
    _commandList.addAll(_pendingCommandList);

    /// empty out the pending
    _pendingCommandList.clear();
  }
}

/// Abstraction of a command pattern
/// All commands have access to the controller for any state related data
/// including the ability for complex commands where a command can aggregate
/// other commands.
///
/// Each command has to be added to a [Controller] for management
abstract class Command {
  /// empty constructor
  Command();

  /// The controller to which this command was added
  late Controller _controller;

  /// getter for the controller
  Controller _getController() {
    return _controller;
  }

  /// this method adds the Command to a specific controller.
  void addToController(Controller controller) {
    _controller = controller;
    controller.addCommand(this);
  }

  /// abstract execute method. All the [Command] derivations will need to put
  /// their work code in here
  void execute();

  /// An optional title for the command for any debug or printing functionality
  String getTitle();

  /// this will get some sort of command id to identify when we have duplicate
  /// commands
  /// One solution when you want to avoid duplicates is to use create the id as
  /// follows:
  ///     - use the title of the command
  ///     - append to it the ':' followed by some sort of hashcode
  String getId() {
    return "Command:0";
  }

  /// this will tell broker if the command must be unique in the existing queue
  ///
  bool mustBeUnique() {
    return false;
  }
}

/// Specific implementation of the [Command] abstraction that alerts the
/// Spaceship class that a user has tapped the screen
///
/// In this implementation we create additional commands to fire a bullet
/// and to generate the sound for the bullet firing.
class UserTapUpCommand extends Command {
  /// The receiver of this command
  SpaceShip player;

  /// default constructor
  UserTapUpCommand(this.player);

  /// work method. We simply fire a bullet in this example
  @override
  void execute() {
    debugPrint(
        '<UserTapUpCommand> player is alive: ${_getController().contains(player)}');
    // only fire the bullet if the player is alive
    if (_getController().contains(player)) {
      BulletFiredCommand().addToController(_getController());
      BulletFiredSoundCommand().addToController(_getController());
    }
  }

  @override
  String getTitle() {
    return "UserTapUpCommand";
  }
}

/// Implementation of the [Command] to create a new bullet and add it to the
/// game
class BulletFiredCommand extends Command {
  /// deault constructor
  BulletFiredCommand();

  /// work method. We create a bullet based on the Spaceship location and angle
  /// We currently hardcode the bullet type but this could be looked up from
  /// the speceship.
  @override
  void execute() {
    //
    // velocity vector pointing straight up.
    // Represents 0 radians which is 0 desgrees
    var velocity = Vector2(0, -1);
    // rotate this vector to the same angle as the player
    velocity.rotate(_getController().getSpaceship().angle);
    // create a bullet with the specific angle and add it to the game
    BulletBuildContext context = BulletBuildContext()
      ..bulletType = _getController().getSpaceship().getBulletType
      ..position =
          _getController().getSpaceship().getMuzzleComponent.absolutePosition
      ..velocity = velocity
      ..size = Vector2(4, 4);
    Bullet myBullet = BulletFactory.create(context);
    // add the bullet to the controller's game tree
    _getController().add(myBullet);
    // let the scoreboard know to update the number of shots fired
    UpdateScoreboardShotFiredCommand(_getController().getScoreBoard)
        .addToController(_getController());
  }

  @override
  String getTitle() {
    return "BulletFiredCommand";
  }
}

/// Implementation of the [Command] to create a new bullet and add it to the
/// game
class BulletDestroyCommand extends Command {
  /// the bullet being operated on
  late Bullet targetBullet;

  /// deault constructor
  BulletDestroyCommand(Bullet bullet) {
    targetBullet = bullet;
  }

  /// work method. We create a bullet based on the Spaceship location and angle
  /// We currently hardcode the bullet type but this could be looked up from
  /// the speceship.
  @override
  void execute() {
    // let the bullet know its being destroyed.
    targetBullet.onDestroy();
    debugPrint('<BulletDestroyCommand> execute id: ${targetBullet.hashCode}');
    // remove the bullet from the game
    if (_getController().children.any((element) => targetBullet == element)) {
      debugPrint(
          '<BulletDestroyCommand> removing id: ${targetBullet.hashCode}');
      _getController().remove(targetBullet);
    }
  }

  @override
  String getTitle() {
    return "BulletDestroyCommand";
  }
}

/// Implementation of the [Command] to create a fireing and after-shot bullet
/// sounds
class BulletFiredSoundCommand extends Command {
  BulletFiredSoundCommand();

  @override
  void execute() {
    // sounds used for the shot
    FlameAudio.play('missile_shot.wav', volume: 0.5);
    // layered sounds for missile transition/flyby
    FlameAudio.play('missile_flyby.wav', volume: 0.2);
  }

  @override
  String getTitle() {
    return "BulletFiredSoundCommand";
  }
}

/// Implementation of the [Command] to notify a bullet that it has been hit
///
class BulletCollisionCommand extends Command {
  /// the bullet being operated on
  late Bullet targetBullet;
  late Collidable collisionObject;

  /// deault constructor
  BulletCollisionCommand(Bullet bullet, Collidable other) {
    targetBullet = bullet;
    collisionObject = other;
  }

  /// work method. We create a bullet based on the Spaceship location and angle
  /// We currently hardcode the bullet type but this could be looked up from
  /// the speceship.
  @override
  void execute() {
    // let the bullet know its being destroyed.
    targetBullet.onDestroy();
    // remove the bullet from the game
    _getController().remove(targetBullet);
  }

  @override
  String getTitle() {
    return "BulletCollisionCommand";
  }

  @override
  String getId() {
    return getTitle() + ':' + targetBullet.hashCode.toString();
  }

  @override
  bool mustBeUnique() {
    return true;
  }
}

/// Implementation of the [Command] to notify a bullet that it has been hit
///
class AsteroidCollisionCommand extends Command {
  /// the bullet being operated on
  late Asteroid _targetAsteroid;
  late Collidable _collisionObject;
  Vector2? _collisionPosition;

  /// deault constructor
  AsteroidCollisionCommand(Asteroid asteroid, Collidable other) {
    _targetAsteroid = asteroid;
    _collisionObject = other;
    _collisionPosition = _targetAsteroid.position.clone();
  }

  /// in this work method we check if the asteroid should be split into
  /// small asteroids. We also remov this object from the stack and add any
  /// new asteroids to the stack
  @override
  void execute() {
    // check if this is still on the stack
    if (_getController().currLevelObjectStack.contains(_targetAsteroid)) {
      _getController().currLevelObjectStack.remove(_targetAsteroid);

      // check if the asteroid is splittable
      bool canBeSplit = _targetAsteroid.canBeSplit();
      //
      // if it can be split then split it by doing the following:
      // calculate the velocity of the new asteroids
      // then use the factory to create the new asteroids
      // and then add them to the stack and the game
      //

      if (canBeSplit) {
        //
        // create the smaller colllsion explosion
        ExplosionOfSplitAsteroidRenderCommand(_targetAsteroid)
            .addToController(_getController());
        //
        // calculate the vectors for the new asteroids
        //
        //

        // clone the vector target data so that we have a safe copy
        Vector2 asteroidAVelocity = _targetAsteroid.getVelocity.clone();
        Vector2 asteroidBVelocity = _targetAsteroid.getVelocity.clone();
        // rotate the vector by 45 degrees clockwise and anti-clockwise
        asteroidAVelocity.rotate(pi / 4);
        asteroidBVelocity.rotate(-pi / 4);

        debugPrint(
            "<AsteroidCollisionCommand> <command> asteroid A: velocity angle ${asteroidAVelocity.angleToSigned(Vector2(0, -1))}");
        // create the context for the asteroid creation
        AsteroidBuildContext contextA = AsteroidBuildContext()
          ..asteroidType = _targetAsteroid.getSplitAsteroids()[0]
          ..position = _collisionPosition!
          ..velocity = asteroidAVelocity
          ..multiplier = _getController().getResoltionMultiplier;

        AsteroidBuildContext contextB = AsteroidBuildContext()
          ..asteroidType = _targetAsteroid.getSplitAsteroids()[1]
          ..position = _collisionPosition!
          ..velocity = asteroidBVelocity
          ..multiplier = _getController().getResoltionMultiplier;
        // create the two new asteroids
        Asteroid asteroidA = AsteroidFactory.create(contextA);
        Asteroid asteroidB = AsteroidFactory.create(contextB);
        debugPrint(
            "<AsteroidCollisionCommand> <command> asteroid a ${asteroidA.hashCode}: ${asteroidA.toString()}");
        debugPrint(
            "<AsteroidCollisionCommand> <command> asteroid b ${asteroidB.hashCode}: ${asteroidB.toString()}");

        //
        // add them to the stack and the game
        _getController().currLevelObjectStack.addAll([asteroidA, asteroidB]);
        _getController().addAll([asteroidA, asteroidB]);
      } else {
        // since it cannot be split we will generate a larger explosion
        //
        // create the larger colllsion explosion
        ExplosionOfDestroyedAsteroidRenderCommand(_targetAsteroid)
            .addToController(_getController());
      }

      debugPrint(
          "<AsteroidCollisionCommand> <command> ${_targetAsteroid.hashCode} canBeSplit: $canBeSplit");
      // let the asteroid know its being destroyed.
      _targetAsteroid.onDestroy();
      // remove the target asteroid  from the game
      _getController().remove(_targetAsteroid);
    } else {
      // this is an incorrect collision which we dismiss
      return;
    }
  }

  @override
  String getTitle() {
    return "BulletCollisionCommand";
  }
}

/// Implementation of the [Command] to notify the scoreboard that shots should
/// be updated
class UpdateScoreboardShotFiredCommand extends Command {
  /// the receiver
  late ScoreBoard _scoreboard;

  UpdateScoreboardShotFiredCommand(scoreBoard) {
    _scoreboard = scoreBoard;
  }

  @override
  void execute() {
    // update the scoreboard
    _scoreboard.addBulletFired();
    debugPrint('<Scoreboard> $_scoreboard');
  }

  @override
  String getTitle() {
    return "UpdateShotFiredCommand";
  }
}

/// Implementation of the [Command] to notify the scoreboard that shots should
/// be updated
class UpdateScoreboardScoreCommand extends Command {
  /// the receiver
  late ScoreBoard _scoreboard;

  UpdateScoreboardScoreCommand(scoreBoard) {
    _scoreboard = scoreBoard;
  }

  @override
  void execute() {
    // update the scoreboard
    _scoreboard.addScorePoints(1);
    debugPrint('<Scoreboard> $_scoreboard');
  }

  @override
  String getTitle() {
    return "UpdateScoreboardScoreCommand";
  }
}

/// Implementation of the [Command] to notify the scoreboard that level should
/// be updated
class UpdateScoreboardLevelInfoCommand extends Command {
  /// the receiver
  late ScoreBoard _scoreboard;

  UpdateScoreboardLevelInfoCommand(scoreBoard) {
    _scoreboard = scoreBoard;
  }

  @override
  void execute() {
    // update the scoreboard
    _scoreboard.progressLevel();
    _scoreboard.resetLevelTimer();
    debugPrint('<Scoreboard> $_scoreboard');
  }

  @override
  String getTitle() {
    return "UpdateScoreboardLevelInfoCommand";
  }
}

/// Implementation of the [Command] to notify the scoreboard about passage of
/// time, we are assuming here of adding 1 second
class UpdateScoreboardTimePassageInfoCommand extends Command {
  /// the receiver
  late ScoreBoard _scoreboard;

  UpdateScoreboardTimePassageInfoCommand(scoreBoard) {
    _scoreboard = scoreBoard;
  }

  @override
  void execute() {
    // update the scoreboard
    _scoreboard.addTimeTick();
    debugPrint('<Scoreboard> $_scoreboard');
  }

  @override
  String getTitle() {
    return "UpdateScoreboardTimePassageInfoCommand";
  }
}

/// Implementation of the [Command] to notify a player that it has been hit
///
class PlayerCollisionCommand extends Command {
  /// the bullet being operated on
  late SpaceShip targetPlayer;
  late Collidable collisionObject;

  /// deault constructor
  PlayerCollisionCommand(SpaceShip player, Collidable other) {
    targetPlayer = player;
    collisionObject = other;
  }

  /// work method. We create a bullet based on the Spaceship location and angle
  /// We currently hardcode the bullet type but this could be looked up from
  /// the speceship.
  @override
  void execute() {
    //
    // test if this was already captured
    if (_getController().children.contains(targetPlayer)) {
      // let the bullet know its being destroyed.
      targetPlayer.onDestroy();
      FlameAudio.audioCache.play('missile_hit.wav', volume: 0.7);
      // render the camera shake effect for a short duration
      _getController().gameRef.camera.shake(duration: 0.5, intensity: 5);
      // remove the bullet from the game
      _getController().remove(targetPlayer);
      // generate explosion render
      ExplosionOfSpacehipRenderCommand().addToController(_getController());
      // remove the life
      PlayerRemoveLifeCommand().addToController(_getController());
    } else {
      // we already dealt with this collision
    }
  }

  @override
  String getTitle() {
    return "BulletCollisionCommand";
  }
}

/// Implementation of the [Command] to notify a player that it has been hit
///
class PlayerRemoveLifeCommand extends Command {
  /// deault constructor
  PlayerRemoveLifeCommand();

  /// work method. We create a bullet based on the Spaceship location and angle
  /// We currently hardcode the bullet type but this could be looked up from
  /// the speceship.
  @override
  void execute() {
    // remove the bullet from the game
    _getController().getScoreBoard.removeLife();
  }

  @override
  String getTitle() {
    return "RemovePlayerLifeCommand";
  }
}

/// Implementation of the [Command] to notify the controller that the game is
/// done
///
class GameOverCommand extends Command {
  /// deault constructor
  GameOverCommand();

  /// work method. We create a bullet based on the Spaceship location and angle
  /// We currently hardcode the bullet type but this could be looked up from
  /// the speceship.
  @override
  void execute() async {
    if (_getController().getScoreBoard.getScore >
        _getController().getScoreBoard.getHighScore) {
      // Save an integer value to 'highScore' key.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _getController().getScoreBoard.getScore);
    }
  }

  @override
  String getTitle() {
    return "GameOverCommand";
  }
}

/// Implementation of the [Command] to destroy the instance of game bonus
/// game
class GameBonusDestroyCommand extends Command {
  /// the bullet being operated on
  late GameBonus targetBonus;

  /// deault constructor
  GameBonusDestroyCommand(GameBonus bonus) {
    targetBonus = bonus;
  }

  /// work method. We create a bullet based on the Spaceship location and angle
  /// We currently hardcode the bullet type but this could be looked up from
  /// the speceship.
  @override
  void execute() {
    // let the bullet know its being destroyed.
    targetBonus.onDestroy();
    // remove the bonus from the game and form the stack
    if (_getController()
        .currLevelObjectStack
        .any((element) => targetBonus == element)) {
      _getController().currLevelObjectStack.remove(targetBonus);
    }
    if (_getController().children.any((element) => targetBonus == element)) {
      _getController().remove(targetBonus);
    }
  }

  @override
  String getTitle() {
    return "GameBonusDestroyCommand";
  }
}

/// Implementation of the [Command] to notify a bullet that it has been hit
///
class GameBonusCollisionCommand extends Command {
  /// the bullet being operated on
  late GameBonus target;
  late Collidable collisionObject;

  /// deault constructor
  GameBonusCollisionCommand(GameBonus gameBonus, Collidable other) {
    target = gameBonus;
    collisionObject = other;
  }

  /// in this work method we check if the game bonus should be split into
  /// small asteroids. We also remov this object from the stack and add any
  /// new asteroids to the stack
  @override
  void execute() {
    // create the larger colllsion explosion
    ExplosionOfGameBonusRenderCommand(target).addToController(_getController());
    if (collisionObject is Bullet) {
      // let the scoreboard know to update the score
      UpdateScoreboardScoreCommand(_getController().getScoreBoard)
          .addToController(_getController());
    }
    _getController().remove(collisionObject);
    // check if this is still on the stack
    if (_getController().currLevelObjectStack.contains(target)) {
      _getController().currLevelObjectStack.remove(target);

      // let the target know its being destroyed.
      target.onDestroy();

      // remove the target from the game
      _getController().remove(target);
    } else {
      // this is an incorrect collision which we dismiss
      return;
    }
  }

  @override
  String getTitle() {
    return "GameBonusCollisionCommand";
  }
}

/// Implementation of the [Command] to create an explosion and add it to the
/// game
class ExplosionOfSpacehipRenderCommand extends Command {
  /// deault constructor
  ExplosionOfSpacehipRenderCommand();

  /// work method. We create a an explosion based on the colllsion object where
  /// we want the explosion to show up.
  @override
  void execute() {
    // create the specific explosition for the specehip and add it to the game
    ExplosionBuildContext context = ExplosionBuildContext()
      ..position = _getController().getSpaceship().position
      ..images = _getController().getImagesBroker()
      ..explosionType = ExplosionEnum.fieryExplosion;
    ParticleComponent explosion = ExplosionFactory.create(context);
    // add the bullet to the controller's game tree
    _getController().add(explosion);
  }

  @override
  String getTitle() {
    return "ExplosionOfSpacehipRenderCommand";
  }
}

/// Implementation of the [Command] to create an explosion and add it to the
/// game
class ExplosionOfDestroyedAsteroidRenderCommand extends Command {
  /// the asteroid being operated on
  late Asteroid _target;

  /// deault constructor
  ExplosionOfDestroyedAsteroidRenderCommand(target) {
    _target = target;
  }

  /// work method. We create a an explosion based on the colllsion object where
  /// we want the explosion to show up.
  @override
  void execute() {
    // create the specific explosition for the specehip and add it to the game
    ExplosionBuildContext context = ExplosionBuildContext()
      ..position = _target.position
      ..explosionType = ExplosionEnum.largeParticleExplosion;
    ParticleComponent explosion = ExplosionFactory.create(context);
    // add the bullet to the controller's game tree
    _getController().add(explosion);
  }

  @override
  String getTitle() {
    return "ExplosionOfDestroyedAsteroidRenderCommand";
  }
}

/// Implementation of the [Command] to create an explosion and add it to the
/// game
class ExplosionOfSplitAsteroidRenderCommand extends Command {
  /// the asteroid being operated on
  late Asteroid _target;

  /// deault constructor
  ExplosionOfSplitAsteroidRenderCommand(target) {
    _target = target;
  }

  /// work method. We create a an explosion based on the colllsion object where
  /// we want the explosion to show up.
  @override
  void execute() {
    // create the specific explosition for the specehip and add it to the game
    ExplosionBuildContext context = ExplosionBuildContext()
      ..position = _target.position
      ..explosionType = ExplosionEnum.mediumParticleExplosion;
    ParticleComponent explosion = ExplosionFactory.create(context);
    // add the bullet to the controller's game tree
    _getController().add(explosion);
  }

  @override
  String getTitle() {
    return "ExplosionOfSplitAsteroidRenderCommand";
  }
}

/// Implementation of the [Command] to create an explosion and add it to the
/// game
class ExplosionOfGameBonusRenderCommand extends Command {
  /// the asteroid being operated on
  late GameBonus _target;

  /// deault constructor
  ExplosionOfGameBonusRenderCommand(target) {
    _target = target;
  }

  /// work method. We create a an explosion based on the colllsion object where
  /// we want the explosion to show up.
  @override
  void execute() {
    // create the specific explosition for the specehip and add it to the game
    ExplosionBuildContext context = ExplosionBuildContext()
      ..position = _target.position
      ..explosionType = ExplosionEnum.bonusExplosion;
    ParticleComponent explosion = ExplosionFactory.create(context);
    // add the bullet to the controller's game tree
    _getController().add(explosion);
  }

  @override
  String getTitle() {
    return "ExplosionOfGameBonusRenderCommand";
  }
}
