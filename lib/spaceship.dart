import 'package:component_001/bullet.dart';
import 'package:component_001/main.dart';
import 'package:component_001/utils.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';

/// Simple enum which will hold enumerated names for all our [SpaceShip]-derived
/// child classes
///
/// As you add more [SpaceShip]] implementations you will add a name here so
/// that we can then easily create different types of player spaceships u
/// using the [SpaceShipFactory]
/// The steps are as follows:
///  - extend the SpaceShip class with a new SpaceShip implementation
///  - add a new enumeration entry
///  - add a new switch case to the [SpaceShipFactory] to create this
///    new [SpaceShip] instance when the enumeration entry is provided.
enum SpaceShipEnum { simpleSpaceShip }

/// The Player's speaceship
///
/// *NOTE* This class should be made abstract and should have its own factory
/// Please refer to the next batch of code where this refactor is done.
///
abstract class SpaceShip extends SpriteComponent
    with HasGameRef<CaseStudy008DesignPatterns004>, HasHitboxes, Collidable {
  // default values
  static const double defaultSpeed = 100.00;
  static const double defaultMaxSpeed = 300.00;
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

  /// Pixels/s
  late final double _maxSpeed = defaultMaxSpeed;

  /// current bullet type
  final BulletEnum _currBulletType = BulletEnum.fastBullet;

  /// Single pixel at the location of the tip of the spaceship
  /// We use it to quickly calculate the position of the rotated nose of the
  /// ship so we can get the position of where the bullets are shooting from.
  /// We make it transparent so it is not visible at all.
  static final _paint = Paint()..color = Colors.transparent;

  /// Muzzle pixel for shooting
  final RectangleComponent _muzzleComponent =
      RectangleComponent(size: Vector2(1, 1), paint: _paint);

  late final JoystickComponent _joystick;

  //
  // default constructor with default values
  SpaceShip(Vector2 resolutionMultiplier, JoystickComponent joystick)
      : _health = defaultHealth,
        _damage = defaultDamage,
        _resolutionMultiplier = resolutionMultiplier,
        _joystick = joystick,
        super(
          size: defaultSize,
          anchor: Anchor.center,
        );

  //
  // named constructor
  SpaceShip.fullInit(Vector2 resolutionMultiplier, JoystickComponent joystick,
      {Vector2? size, double? speed, int? health, int? damage})
      : _resolutionMultiplier = resolutionMultiplier,
        _joystick = joystick,
        _speed = speed ?? defaultSpeed,
        _health = health ?? defaultHealth,
        _damage = damage ?? defaultDamage,
        super(
          size: size,
          anchor: Anchor.center,
        );

  ///////////////////////////////////////////////////////
  // getters
  //
  BulletEnum get getBulletType {
    return _currBulletType;
  }

  RectangleComponent get getMuzzleComponent {
    return _muzzleComponent;
  }

  ///////////////////////////////////////////////////////
  /// Business methods
  ///
  ///

  //
  // Called when the Player has been created.
  void onCreate() {
    anchor = Anchor.center;
    size = Vector2.all(60.0);
    addHitbox(HitboxRectangle());
  }

  //
  // Called when the bullet is being destroyed.
  void onDestroy();

  //
  // Called when the Bullet has been hit. The ‘other’ is what the bullet hit, or was hit by.
  void onHit(Collidable other);

  /// Wrap the posittion getter so that any position that is out side of the
  /// screen gets wrapped around
  ///
  Vector2 getNextPosition() {
    return Utils.wrapPosition(gameRef.size, position);
  }
}

/// This class creates a fast bullet implementation of the [Bullet] contract and
/// renders the bullet as a simple green square.
/// Speed has been defaulted to 150 p/s but can be changed through the
/// constructor. It is set with a damage of 1 which is the lowest damage and
/// with health of 1 which means that it will be destroyed on impact since it
/// is also the lowest health you can have.
///
class SimpleSpaceShip extends SpaceShip {
  static const double defaultSpeed = 300.00;
  static final Vector2 defaultSize = Vector2.all(2.00);
  // color of the bullet
  static final _paint = Paint()..color = Colors.green;

  SimpleSpaceShip(Vector2 resolutionMultiplier, JoystickComponent joystick)
      : super.fullInit(resolutionMultiplier, joystick,
            size: defaultSize,
            speed: defaultSpeed,
            health: SpaceShip.defaultHealth,
            damage: SpaceShip.defaultDamage);

  //
  // named constructor
  SimpleSpaceShip.fullInit(
      Vector2 resolutionMultiplier,
      JoystickComponent joystick,
      Vector2? size,
      double? speed,
      int? health,
      int? damage)
      : super.fullInit(resolutionMultiplier, joystick,
            size: size, speed: speed, health: health, damage: damage);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    //
    // we adjust the ship size based on resolution multipier
    size =
        Utils.vector2Multiply(size, gameRef.controller.getResoltionMultiplier);
    size.y = size.x;
    debugPrint(
        "<SimpleSpaceShip> <onLoad> size: $size, multiplier: ${gameRef.controller.getResoltionMultiplier}");
    //
    // ship png comes from Kenny
    sprite = await gameRef.loadSprite('asteroids_ship.png');
    position = gameRef.size / 2;
    debugPrint('player position: $position');
    _muzzleComponent.position.x = size.x / 2;
    _muzzleComponent.position.y = size.y / 10;

    add(_muzzleComponent);
  }

  @override
  void update(double dt) {
    if (!_joystick.delta.isZero()) {
      getNextPosition().add(_joystick.relativeDelta * _maxSpeed * dt);
      angle = (_joystick.delta.screenAngle());
    }
  }

  @override
  void onCreate() {
    super.onCreate();
    print("SimpleSpaceShip onCreate called");
  }

  @override
  void onDestroy() {
    print("SimpleSpaceShip onDestroy called");
  }

  @override
  void onHit(Collidable other) {
    print("SimpleSpaceShip onHit called");
  }
}

/// This is a Factory Method Design pattern example implementation for SpaceShips
/// in our game.
///
/// The class will return an instance of the specific player asked for based on
/// a valid enum choice.
class SpaceShipFactory {
  /// private constructor to prevent instantiation
  SpaceShipFactory._();

  /// main factory method to create instaces of Bullet children
  static SpaceShip create(PlayerBuildContext context) {
    SpaceShip result;

    /// collect all the Bullet definitions here
    switch (context.spaceShipType) {
      case SpaceShipEnum.simpleSpaceShip:
        {
          if (context.speed != PlayerBuildContext.defaultSpeed) {
            result = SimpleSpaceShip.fullInit(
                context.multiplier,
                context.joystick,
                context.size,
                context.speed,
                context.health,
                context.damage);
          } else {
            result = SimpleSpaceShip(context.position, context.joystick);
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
class PlayerBuildContext {
  static const double defaultSpeed = 0.0;
  static const int defaultHealth = 1;
  static const int defaultDamage = 1;
  static final Vector2 deaultVelocity = Vector2.zero();
  static final Vector2 deaultPosition = Vector2(-1, -1);
  static final Vector2 defaultSize = Vector2.zero();
  static final SpaceShipEnum defaultSpaceShipType = SpaceShipEnum.values[0];
  static final Vector2 defaultMultiplier = Vector2.all(1.0);

  /// helper method for parsing out strings into corresponding enum values
  ///
  static SpaceShipEnum spaceShipFromString(String value) {
    debugPrint('${SpaceShipEnum.values}');
    return SpaceShipEnum.values.firstWhere(
        (e) => e.toString().split('.')[1].toUpperCase() == value.toUpperCase());
  }

  double speed = defaultSpeed;
  Vector2 velocity = deaultVelocity;
  Vector2 position = deaultPosition;
  Vector2 size = defaultSize;
  int health = defaultHealth;
  int damage = defaultDamage;
  Vector2 multiplier = defaultMultiplier;
  SpaceShipEnum spaceShipType = defaultSpaceShipType;
  late JoystickComponent joystick;

  PlayerBuildContext();

  @override

  /// We are defining our own stringify method so that we can see our
  /// values when debugging.
  ///
  String toString() {
    return 'name: $spaceShipType , speed: $speed , position: $position , velocity: $velocity, multiplier: $multiplier';
  }
}
