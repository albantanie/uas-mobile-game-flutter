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
enum AsteroidEnum { largeAsteroid, mediumAsteroid, smallAsteroid }

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
abstract class Asteroid extends PositionComponent
    with HasHitboxes, Collidable, HasGameRef<CaseStudy008DesignPatterns004> {
  static const double defaultSpeed = 100.00;
  static const int defaultDamage = 1;
  static const int defaultHealth = 1;
  static final defaultSize = Vector2.all(5.0);

  // velocity vector for the asteroid.
  late Vector2 _velocity;

  // speed of the asteroid
  late double _speed;

  // health of the asteroid
  late int? _health;

  // damage that the asteroid does
  late int? _damage;

  // resolution multiplier
  late final Vector2 _resolutionMultiplier;

  //
  // default constructor with default values
  Asteroid(Vector2 position, Vector2 velocity, Vector2 resolutionMultiplier)
      : _velocity = velocity.normalized(),
        _health = defaultHealth,
        _damage = defaultDamage,
        _resolutionMultiplier = resolutionMultiplier,
        super(
          size: defaultSize,
          position: position,
          anchor: Anchor.center,
        );

  //
  // named constructor
  Asteroid.fullInit(
      Vector2 position, Vector2 velocity, Vector2 resolutionMultiplier,
      {Vector2? size, double? speed, int? health, int? damage})
      : _resolutionMultiplier = resolutionMultiplier,
        _velocity = velocity.normalized(),
        _speed = speed ?? defaultSpeed,
        _health = health ?? defaultHealth,
        _damage = damage ?? defaultDamage,
        super(
          size: size,
          position: position,
          anchor: Anchor.center,
        );

  ///////////////////////////////////////////////////////
  /// overrides
  ///

  @override
  void onCollision(Set<Vector2> intersectionPoints, Collidable other) {
    /// <todo> collision detection
    debugPrint("<Asteroid> <onCollision> detected... $other");

    if (other is Bullet) {
      BulletCollisionCommand(other, this).addToController(gameRef.controller);
      AsteroidCollisionCommand(this, other).addToController(gameRef.controller);
      UpdateScoreboardScoreCommand(gameRef.controller.getScoreBoard)
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

  ///////////////////////////////////////////////////////
  // getters
  //
  int? get getDamage {
    return _damage;
  }

  int? get getHealth {
    return _health;
  }

  Vector2 get getVelocity {
    return _velocity;
  }

  ////////////////////////////////////////////////////////
  // business methods
  //

  //
  // Called when the asteroid has been created.
  void onCreate() {
    debugPrint("<Asteroid> <onCreate> multiplier applied");
    // apply the multiplier to the size and position
    size = Utils.vector2Multiply(size, _resolutionMultiplier);
    debugPrint(
        "<Asteroid> <onLoad> size: $size, multiplier: $_resolutionMultiplier");
    size.y = size.x;
    position = Utils.vector2Multiply(position, _resolutionMultiplier);
    debugPrint("<Asteroid> <onCreate> size: ${size.x}, ${size.y}");
    addHitbox(HitboxCircle(normalizedRadius: 2.0));
  }

  //
  // Called when the asteroid is being destroyed.
  void onDestroy();

  //
  // Called when the asteroid has been hit. The ‘other’ is what the asteroid
  // hit, or was hit by.
  void onHit(Collidable other);

  //
  // getter to check of this asteroid can be split
  bool canBeSplit() {
    return getSplitAsteroids().isNotEmpty;
  }

  // should return the list of the astroid types to split this asteroid into
  // or empty list if there is none (i.e. no split)
  // You will override this method to return a non-empty list if valid enum
  // values for when the astroid gets split when it is hit
  List<AsteroidEnum> getSplitAsteroids() {
    return List.empty();
  }

  Vector2 getNextPosition() {
    return Utils.wrapPosition(gameRef.size, position);
  }

  @override

  /// We are defining our own stringify method so that we can see our
  /// values when debugging.
  ///
  String toString() {
    return 'speed: $_speed , position: $position , velocity: $_velocity, multiplier: $_resolutionMultiplier';
  }
}

/// This class creates a small asteroid implementation of the [Asteroid] contract and
/// renders the asteroid as a simple green circle.
/// Speed has been defaulted to 150 p/s but can be changed through the
/// constructor. It is set with a damage of 1 which is the lowest damage and
/// with health of 1 which means that it will be destroyed on impact since it
/// is also the lowest health you can have.
///
class SmallAsteroid extends Asteroid {
  static const double defaultSpeed = 150.0;
  static final Vector2 defaultSize = Vector2(16.0, 16.0);
  // color of the asteroid
  static final _paint = Paint()..color = Colors.green;

  SmallAsteroid(
      Vector2 position, Vector2 velocity, Vector2 resolutionMultiplier)
      : super.fullInit(position, velocity, resolutionMultiplier,
            speed: defaultSpeed,
            health: Asteroid.defaultHealth,
            damage: Asteroid.defaultDamage,
            size: defaultSize);

  //
  // named constructor
  SmallAsteroid.fullInit(
      Vector2 position,
      Vector2 velocity,
      Vector2 resolutionMultiplier,
      Vector2? size,
      double? speed,
      int? health,
      int? damage)
      : super.fullInit(position, velocity, resolutionMultiplier,
            size: size,
            speed: speed ?? defaultSpeed,
            health: health,
            damage: damage);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // _velocity is a unit vector so we need to make it account for the actual
    // speed.
    debugPrint("<Asteroid> <onLoad> <small>: speed: $_speed");
    debugPrint("<Asteroid> <onLoad> <small>: size: $size");
    _velocity = (_velocity)..scaleTo(_speed);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final localCenter = (scaledSize / 2).toOffset();
    canvas.drawCircle(localCenter, size.x, _paint);
    renderHitboxes(canvas);
  }

  @override
  void update(double dt) {
    getNextPosition().add(_velocity * dt);
  }

  @override
  void onCreate() {
    // we are goin to fully override the creation of the asteroid
    // we will adjust the size as per the multiplier but we will
    // utilise the actual position provided since this position is initialized
    // within the context of the game and not the JSON file
    debugPrint("<SmallAsteroid> <onCreate> multiplier applied");
    // apply the multiplier to the size and position
    size = Utils.vector2Multiply(size, _resolutionMultiplier);
    debugPrint(
        "<SmallAsteroid> <onLoad> size: $size, multiplier: $_resolutionMultiplier");
    size.y = size.x;
    debugPrint("<SmallAsteroid> <onCreate> size: ${size.x}, ${size.y}");
    addHitbox(HitboxCircle(normalizedRadius: 2.0));
    debugPrint("SmallAsteroid onCreate called");
  }

  @override
  void onDestroy() {
    debugPrint("SmallAsteroid onDestroy called");
  }

  @override
  void onHit(Collidable other) {
    debugPrint("SmallAsteroid onHit called");
  }
}

/// This class creates a medium asteroid implementation of the [Asteroid] contract and
/// renders the asteroid as a simple red circle.
/// Speed has been defaulted to 150 p/s but can be changed through the
/// constructor. It is set with a damage of 1 which is the lowest damage and
/// with health of 1 which means that it will be destroyed on impact since it
/// is also the lowest health you can have.
///
class MediumAsteroid extends Asteroid {
  static const double defaultSpeed = 100.0;
  static final Vector2 defaultSize = Vector2(32.0, 32.0);
  // color of the asteroid
  static final _paint = Paint()..color = Colors.blue;

  MediumAsteroid(
      Vector2 position, Vector2 velocity, Vector2 resolutionMultiplier)
      : super.fullInit(position, velocity, resolutionMultiplier,
            speed: defaultSpeed,
            health: Asteroid.defaultHealth,
            damage: Asteroid.defaultDamage,
            size: defaultSize);

  //
  // named constructor
  MediumAsteroid.fullInit(
      Vector2 position,
      Vector2 velocity,
      Vector2 resolutionMultiplier,
      Vector2? size,
      double? speed,
      int? health,
      int? damage)
      : super.fullInit(position, velocity, resolutionMultiplier,
            size: size,
            speed: speed ?? defaultSpeed,
            health: health,
            damage: damage);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // _velocity is a unit vector so we need to make it account for the actual
    // speed.
    debugPrint("MediumAsteroid onLoad called: speed: $_speed");
    _velocity = (_velocity)..scaleTo(_speed);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final localCenter = (scaledSize / 2).toOffset();
    canvas.drawCircle(localCenter, size.x, _paint);
    renderHitboxes(canvas);
  }

  @override
  void update(double dt) {
    getNextPosition().add(_velocity * dt);
  }

  @override
  void onCreate() {
    // we are goin to fully override the creation of the asteroid
    // we will adjust the size as per the multiplier but we will
    // utilise the actual position provided since this position is initialized
    // within the context of the game and not the JSON file
    debugPrint("<MediumAsteroid> <onCreate> multiplier applied");
    // apply the multiplier to the size and position
    size = Utils.vector2Multiply(size, _resolutionMultiplier);
    debugPrint(
        "<MediumAsteroid> <onLoad> size: $size, multiplier: $_resolutionMultiplier");
    size.y = size.x;
    debugPrint("<MediumAsteroid> <onCreate> size: ${size.x}, ${size.y}");
    addHitbox(HitboxCircle(normalizedRadius: 2.0));
    debugPrint("MediumAsteroid onCreate called");
  }

  @override
  void onDestroy() {
    debugPrint("MediumAsteroid onDestroy called");
  }

  @override
  void onHit(Collidable other) {
    debugPrint("MediumAsteroid onHit called");
  }

  @override

  /// split this asteroid into 2 small asteroids
  ///
  List<AsteroidEnum> getSplitAsteroids() {
    return [AsteroidEnum.smallAsteroid, AsteroidEnum.smallAsteroid];
  }
}

/// This class creates a medium asteroid implementation of the [Asteroid] contract and
/// renders the asteroid as a simple red circle.
/// Speed has been defaulted to 150 p/s but can be changed through the
/// constructor. It is set with a damage of 1 which is the lowest damage and
/// with health of 1 which means that it will be destroyed on impact since it
/// is also the lowest health you can have.
///
class LargeAsteroid extends Asteroid {
  static const double defaultSpeed = 50.0;
  static final Vector2 defaultSize = Vector2(64.0, 64.0);
  // color of the asteroid
  static final _paint = Paint()..color = Colors.red;

  LargeAsteroid(
      Vector2 position, Vector2 velocity, Vector2 resolutionMultiplier)
      : super.fullInit(position, velocity, resolutionMultiplier,
            speed: defaultSpeed,
            health: Asteroid.defaultHealth,
            damage: Asteroid.defaultDamage,
            size: defaultSize);

  //
  // named constructor
  LargeAsteroid.fullInit(
      Vector2 position,
      Vector2 velocity,
      Vector2 resolutionMultiplier,
      Vector2? size,
      double? speed,
      int? health,
      int? damage)
      : super.fullInit(position, velocity, resolutionMultiplier,
            size: size,
            speed: speed ?? defaultSpeed,
            health: health,
            damage: damage);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // _velocity is a unit vector so we need to make it account for the actual
    // speed.

    _velocity = (_velocity)..scaleTo(_speed);
    debugPrint(
        "LargeAsteroid onLoad called: speed: $_speed, velocity: $_velocity, position: [${position.x}, ${position.y}]");
  }

  @override

  /// we will render the asteroid as a ball initially until we create a specific
  /// Asteroid shape render
  void render(Canvas canvas) {
    super.render(canvas);
    final localCenter = (scaledSize / 2).toOffset();
    canvas.drawCircle(localCenter, size.x, _paint);
    renderHitboxes(canvas);
  }

  @override
  void update(double dt) {
    getNextPosition().add(_velocity * dt);
  }

  @override
  void onCreate() {
    super.onCreate();
    debugPrint("LargeAsteroid onCreate called");
  }

  @override
  void onDestroy() {
    debugPrint("LargeAsteroid onDestroy called");
  }

  @override
  void onHit(Collidable other) {
    debugPrint("LargeAsteroid onHit called");
  }

  @override

  /// split this asteroid into 2 medium asteroids
  ///
  List<AsteroidEnum> getSplitAsteroids() {
    return [AsteroidEnum.mediumAsteroid, AsteroidEnum.mediumAsteroid];
  }
}

/// This is a Factory Method Design pattern example implementation for Asteroids
/// in our game.
///
/// The class will return an instance of the specific asteroid asked for based
/// on a valid asteroid type choice.
class AsteroidFactory {
  /// private constructor to prevent instantiation
  AsteroidFactory._();

  /// main factory method to create instaces of Bullet children
  static Asteroid create(AsteroidBuildContext context) {
    Asteroid result;

    /// collect all the Asteroid definitions here
    switch (context.asteroidType) {
      case AsteroidEnum.smallAsteroid:
        {
          if (context.size != AsteroidBuildContext.defaultSize) {
            result = SmallAsteroid.fullInit(
                context.position,
                context.velocity,
                context.multiplier,
                context.size,
                context.speed,
                context.health,
                context.damage);
          } else {
            result = SmallAsteroid(
                context.position, context.velocity, context.multiplier);
          }
        }
        break;

      case AsteroidEnum.mediumAsteroid:
        {
          if (context.size != AsteroidBuildContext.defaultSize) {
            result = MediumAsteroid.fullInit(
                context.position,
                context.velocity,
                context.multiplier,
                context.size,
                context.speed,
                context.health,
                context.damage);
          } else {
            result = MediumAsteroid(
                context.position, context.velocity, context.multiplier);
          }
        }
        break;

      case AsteroidEnum.largeAsteroid:
        {
          if (context.size != AsteroidBuildContext.defaultSize) {
            debugPrint(
                "<AsteroidFactory> <create> fullInit: speed: ${context.speed}");
            result = LargeAsteroid.fullInit(
                context.position,
                context.velocity,
                context.multiplier,
                context.size,
                context.speed,
                context.health,
                context.damage);
          } else {
            debugPrint("<AsteroidFactory> <create> default");
            result = LargeAsteroid(
                context.position, context.velocity, context.multiplier);
          }
        }
        break;
    }

    ///
    /// trigger any necessary behavior *before* the instance is handed to the
    /// caller.
    result.onCreate();

    return result;
  }
}

/// This is a simple data holder for the context data wehen we create a new
/// Asteroid instace through the Factory method using the [AsteroidFactory]
///
/// We have a number of default values here as well in case callers do not
/// define all the entries.
class AsteroidBuildContext {
  static const double defaultSpeed = 0.0;
  static const int defaultHealth = 1;
  static const int defaultDamage = 1;
  static final Vector2 deaultVelocity = Vector2.zero();
  static final Vector2 deaultPosition = Vector2(-1, -1);
  static final Vector2 defaultSize = Vector2.zero();
  static final AsteroidEnum defaultAsteroidType = AsteroidEnum.values[0];
  static final Vector2 defaultMultiplier = Vector2.all(1.0);

  /// helper method for parsing out strings into corresponding enum values
  ///
  static AsteroidEnum asteroidFromString(String value) {
    debugPrint('${AsteroidEnum.values}');
    return AsteroidEnum.values.firstWhere(
        (e) => e.toString().split('.')[1].toUpperCase() == value.toUpperCase());
  }

  double speed = defaultSpeed;
  Vector2 velocity = deaultVelocity;
  Vector2 position = deaultPosition;
  Vector2 size = defaultSize;
  int health = defaultHealth;
  int damage = defaultDamage;
  Vector2 multiplier = defaultMultiplier;
  AsteroidEnum asteroidType = defaultAsteroidType;

  AsteroidBuildContext();

  @override

  /// We are defining our own stringify method so that we can see our
  /// values when debugging.
  ///
  String toString() {
    return 'name: $asteroidType , speed: $speed , position: $position , velocity: $velocity, multiplier: $multiplier';
  }
}
