import 'package:component_001/spaceship.dart';
import 'package:component_001/utils.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';

import 'bullet.dart';
import 'command.dart';
import 'main.dart';

/// Simple enum which will hold enumerated names for all our [Asteroid]-derived
/// child classes
///
/// As you add moreBullet implementation you will add a name hereso that we
/// can then easly create astroids using the [AsteroidFactory]
/// The steps are as follows:
///  - extend the astroid class with a new Asteroid implementation
///  - add a new enumeration entry
///  - add a new switch case to the [AsteroidFactory] to create this
///    new [Asteroid] instance when the enumeration entry is provided.
enum GameBonusEnum { ufoBonus }

// Bullet class is a [PositionComponent] so we get the angle and position of the
/// element.
///
/// This is an abstract class which needs to be extended to use Bullets.
/// The most important game methods come from [PositionComponent] and are the
/// update(), onLoad(), amd render() methods that need to be overridden to
/// drive the behaviour of your Bullet on screen.
///
/// You should also overide the abstract methods such as onCreate(),
/// onDestroy(), and onHit()
///
abstract class GameBonus extends PositionComponent
    with HasHitboxes, Collidable, HasGameRef<CaseStudy008DesignPatterns004> {
  static const double defaultSpeed = 100.00;
  static const int defaultDamage = 1;
  static const int defaultHealth = 1;
  static final defaultSize = Vector2.all(5.0);

  // velocity vector for the asteroid.
  late Vector2 _velocity;

  // speed of the asteroid
  late final double _speed;

  // health of the asteroid
  late final int? _health;

  // damage that the asteroid does
  late final int? _damage;

  // resolution multiplier
  late final Vector2 _resolutionMultiplier;

  // trigger time in seconds
  late final int _triggerTimeSeconds;

  //
  // default constructor with default values
  GameBonus(Vector2 position, Vector2 velocity, int triggerTimeSeconds,
      Vector2 resolutionMultiplier)
      : _velocity = velocity.normalized(),
        _speed = defaultSpeed,
        _health = defaultHealth,
        _damage = defaultDamage,
        _triggerTimeSeconds = triggerTimeSeconds,
        _resolutionMultiplier = resolutionMultiplier,
        super(
          size: defaultSize,
          position: position,
          anchor: Anchor.center,
        );

  //
  // named constructor
  GameBonus.fullInit(Vector2 position, Vector2 velocity, int triggerTimeSeconds,
      Vector2 resolutionMultiplier,
      {Vector2? size, double? speed, int? health, int? damage})
      : _velocity = velocity.normalized(),
        _speed = speed ?? defaultSpeed,
        _health = health ?? defaultHealth,
        _damage = damage ?? defaultDamage,
        _triggerTimeSeconds = triggerTimeSeconds,
        _resolutionMultiplier = resolutionMultiplier,
        super(
          size: size,
          position: position,
          anchor: Anchor.center,
        );

  ///////////////////////////////////////////////////////
  // getters
  //
  int? get getDamage {
    return _damage;
  }

  int? get getHealth {
    return _health;
  }

  int? get getTriggerTime {
    return _triggerTimeSeconds;
  }

  ////////////////////////////////////////////////////////
  // business methods
  //

  //
  // Called when the asteroid has been created.
  void onCreate();

  //
  // Called when the asteroid is being destroyed.
  void onDestroy();

  //
  // Called when the asteroid has been hit. The ‘other’ is what the asteroid
  // hit, or was hit by.
  void onHit(Collidable other);

  ////////////////////////////////////////////////////////
  // Overrides
  //
  @override
  void update(double dt) {
    _onOutOfBounds(position);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, Collidable other) {
    /// <todo> collision detection
    debugPrint("<Game Bonus> <onCollision> detected... $other");

    if (other is Bullet) {
      BulletCollisionCommand(other, this).addToController(gameRef.controller);
      GameBonusCollisionCommand(this, other)
          .addToController(gameRef.controller);
    }

    if (other is SpaceShip) {
      //parent?.remove(this);
      //parent?.add(ParticleGenerator.createSpriteParticleExplosion(
      //  images: gameRef.images,
      //  position: other.position,
      //));
      PlayerCollisionCommand(other, this).addToController(gameRef.controller);
    }
  }

  ////////////////////////////////////////////////////////////
  // Helper methods
  //

  void _onOutOfBounds(Vector2 position) {
    if (Utils.isPositionOutOfBounds(gameRef.size, position)) {
      GameBonusDestroyCommand(this).addToController(gameRef.controller);
      //FlameAudio.audioCache.play('missile_hit.wav');
    }
  }
}

/// This class creates a fast bullet implementation of the [Bullet] contract and
/// renders the bullet as a simple green square.
/// Speed has been defaulted to 150 p/s but can be changed through the
/// constructor. It is set with a damage of 1 which is the lowest damage and
/// with health of 1 which means that it will be destroyed on impact since it
/// is also the lowest health you can have.
///
class UFOGameBonus extends GameBonus {
  static final Vector2 defaultSize = Vector2(100.0, 20.0);
  // color of the asteroid
  static final _paint = Paint()..color = Colors.white;

  UFOGameBonus(Vector2 position, Vector2 velocity, int triggerTimeSeconds,
      Vector2 resolutionMultiplier)
      : super.fullInit(
            position, velocity, triggerTimeSeconds, resolutionMultiplier,
            size: defaultSize,
            speed: GameBonus.defaultSpeed,
            health: GameBonus.defaultHealth,
            damage: GameBonus.defaultDamage) {
    addHitbox(HitboxRectangle());
  }

  //
  // named constructor
  UFOGameBonus.fullInit(
      Vector2 position,
      Vector2 velocity,
      Vector2 size,
      int triggerTimeSeconds,
      resolutionMultiplier,
      double? speed,
      int? health,
      int? damage)
      : super.fullInit(
            position, velocity, triggerTimeSeconds, resolutionMultiplier,
            size: size, speed: speed, health: health, damage: damage) {
    addHitbox(HitboxRectangle());
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // _velocity is a unit vector so we need to make it account for the actual
    // speed.
    debugPrint(
        "UFOGameBonus onLoad called: speed: $_speed, position: $position, velocity: $_velocity, size: $size");
    _velocity = (_velocity)..scaleTo(_speed);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), _paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(_velocity * dt);
  }

  @override
  void onCreate() {
    debugPrint("UFOGameBonus onCreate called");
  }

  @override
  void onDestroy() {
    debugPrint("UFOGameBonus onDestroy called");
  }

  @override
  void onHit(Collidable other) {
    debugPrint("UFOGameBonus onHit called");
  }
}

/// This is a Factory Method Design pattern example implementation for Asteroids
/// in our game.
///
/// The class will return an instance of the specific asteroid aksed for based
/// on a valid asteroid type choice.
class GameBonusFactory {
  /// private constructor to prevent instantiation
  GameBonusFactory._();

  /// main factory method to create instaces of Bullet children
  static GameBonus? create(GameBonusBuildContext context) {
    GameBonus? result;

    /// collect all the Asteroid definitions here
    switch (context.gameBonusType) {
      case GameBonusEnum.ufoBonus:
        {
          if (context.size != GameBonusBuildContext.defaultSize) {
            result = UFOGameBonus.fullInit(
                context.position,
                context.velocity,
                context.size,
                context.timeTriggerSeconds,
                context.multiplier,
                context.speed,
                context.health,
                context.damage);
          } else {
            result = UFOGameBonus(
              context.position,
              context.velocity,
              context.timeTriggerSeconds,
              context.multiplier,
            );
          }
        }
        break;
    }

    return result;
  }
}

/// This is a simple data holder for the context data wehen we create a new
/// Asteroid instace through the Factory method using the [AsteroidFactory]
///
/// We have a number of default values here as well in case callers do not
/// define all the entries.
class GameBonusBuildContext {
  static const double defaultSpeed = 0.0;
  static const int defaultHealth = 1;
  static const int defaultDamage = 1;
  static final Vector2 deaultVelocity = Vector2.zero();
  static final Vector2 deaultPosition = Vector2(-1, -1);
  static final Vector2 defaultSize = Vector2.zero();
  static final Vector2 defaultMultipier = Vector2.all(1.0);
  static final GameBonusEnum defaultGameBonusType = GameBonusEnum.values[0];
  static const int defaultTimeTriggerSeconds = 0;

  double speed = defaultSpeed;
  Vector2 velocity = deaultVelocity;
  Vector2 position = deaultPosition;
  Vector2 size = defaultSize;
  int health = defaultHealth;
  int damage = defaultDamage;
  Vector2 multiplier = defaultMultipier;
  GameBonusEnum gameBonusType = defaultGameBonusType;
  int timeTriggerSeconds = defaultTimeTriggerSeconds;

  GameBonusBuildContext();

  /// helper method for parsing out strings into corresponding enum values
  ///
  static GameBonusEnum gameBonusFromString(String value) {
    debugPrint('${GameBonusEnum.values}');
    return GameBonusEnum.values.firstWhere(
        (e) => e.toString().split('.')[1].toUpperCase() == value.toUpperCase());
  }

  @override

  /// We are defining our own stringify method so that we can see our
  /// values when debugging.
  ///
  String toString() {
    return 'name: $gameBonusType , speed: $speed , position: $position , velocity: $velocity, trigger.time: $timeTriggerSeconds , multiplier: $multiplier';
  }
}
