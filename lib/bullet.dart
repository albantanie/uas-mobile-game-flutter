import 'package:component_001/utils.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';

import 'command.dart';
import 'main.dart';

/// Simple enum which will hold enumerated names for all our [Bullet]-derived
/// child classes
///
/// As you add moreBullet implementation you will add a name hereso that we
/// can then easly create bullets using the [BulletFactory]
/// The steps are as follows:
///  - extend the Bullet class with a new Bullet implementation
///  - add a new enumeration entry
///  - add a new switch case to the [BulletFactory] to create this new [Bullet]
///    instance when the enumeration entry is provided.
enum BulletEnum { slowBullet, fastBullet }

/// Bullet class is a [PositionComponent] so we get the angle and position of the
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
abstract class Bullet extends PositionComponent
    with HasGameRef<CaseStudy008DesignPatterns004>, HasHitboxes, Collidable {
  static const double defaultSpeed = 100.00;
  static const int defaultDamage = 1;
  static const int defaultHealth = 1;
  static final Vector2 defaulSize = Vector2.all(1.0);

  // velocity vector for the bullet.
  late Vector2 _velocity;

  // speed of the bullet
  late double _speed;

  // health of the bullet
  late int? _health;

  // damage that the bullet does
  late int? _damage;

  //
  // default constructor with default values
  Bullet(Vector2 position, Vector2 velocity)
      : _velocity = velocity.normalized(),
        _speed = defaultSpeed,
        _health = defaultHealth,
        _damage = defaultDamage,
        super(
          size: defaulSize,
          position: position,
          anchor: Anchor.center,
        );

  //
  // named constructor
  Bullet.fullInit(Vector2 position, Vector2 velocity,
      {Vector2? size, double? speed, int? health, int? damage})
      : _velocity = velocity.normalized(),
        _speed = speed ?? defaultSpeed,
        _health = health ?? defaultHealth,
        _damage = damage ?? defaultDamage,
        super(
          size: size,
          position: position,
          anchor: Anchor.center,
        );

  //
  // empty class name constructor
  Bullet.classname();

  ///////////////////////////////////////////////////////
  // getters
  //
  int? get getDamage {
    return _damage;
  }

  int? get getHealth {
    return _health;
  }

  ////////////////////////////////////////////////////////
  // Overrides
  //
  @override
  void update(double dt) {
    _onOutOfBounds(position);
  }

  ////////////////////////////////////////////////////////
  // business methods
  //

  //
  // Called when the Bullet has been created.
  void onCreate() {
    // to improve accurace of collision detection we make the hitbox
    // about 4 times larger for the bullets.
    addHitbox(HitboxRectangle(relation: Vector2(2.0, 2.0)));
    //addHitbox(HitboxRectangle());
  }

  //
  // Called when the bullet is being destroyed.
  void onDestroy();

  //
  // Called when the Bullet has been hit. The ‘other’ is what the bullet hit, or was hit by.
  void onHit(Collidable other);

  ////////////////////////////////////////////////////////////
  // Helper methods
  //

  void _onOutOfBounds(Vector2 position) {
    if (Utils.isPositionOutOfBounds(gameRef.size, position)) {
      BulletDestroyCommand(this).addToController(gameRef.controller);
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
class FastBullet extends Bullet {
  static const double defaultSpeed = 175.00;
  static final Vector2 defaultSize = Vector2.all(2.00);
  // color of the bullet
  static final _paint = Paint()..color = Colors.green;

  FastBullet(Vector2 position, Vector2 velocity)
      : super.fullInit(position, velocity,
            size: defaultSize,
            speed: defaultSpeed,
            health: Bullet.defaultHealth,
            damage: Bullet.defaultDamage);

  //
  // named constructor
  FastBullet.fullInit(Vector2 position, Vector2 velocity, Vector2? size,
      double? speed, int? health, int? damage)
      : super.fullInit(position, velocity,
            size: size, speed: speed, health: health, damage: damage);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // _velocity is a unit vector so we need to make it account for the actual
    // speed.
    print("FastBullet onLoad called: speed: $_speed");
    _velocity = (_velocity)..scaleTo(_speed);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), _paint);
    renderHitboxes(canvas);
  }

  @override
  void update(double dt) {
    position.add(_velocity * dt);
    super.update(dt);
  }

  @override
  void onCreate() {
    super.onCreate();
    print("FastBullet onCreate called");
  }

  @override
  void onDestroy() {
    print("FastBullet onDestroy called");
  }

  @override
  void onHit(Collidable other) {
    print("FastBullet onHit called");
  }
}

/// This class creates a slow bullet implementation of the [Bullet] contract and
/// renders the bullet as a simple red filled-in circle.
/// Speed has been defaulted to 50 p/s but can be changed through the
/// constructor. It is set with a damage of 1 which is the lowest damage and
/// with health of 1 which means that it will be destroyed on impact since it
/// is also the lowest health you can have.
///
class SlowBullet extends Bullet {
  static const double defaultSpeed = 50.00;
  static final Vector2 defaultSize = Vector2.all(4.0);
  // color of the bullet
  static final _paint = Paint()..color = Colors.red;

  SlowBullet(Vector2 position, Vector2 velocity)
      : super.fullInit(position, velocity,
            size: defaultSize,
            speed: defaultSpeed,
            health: Bullet.defaultHealth,
            damage: Bullet.defaultDamage);

  //
  // named constructor
  SlowBullet.fullInit(Vector2 position, Vector2 velocity, Vector2? size,
      double? speed, int? health, int? damage)
      : super.fullInit(position, velocity,
            size: size, speed: speed, health: health, damage: damage);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // _velocity is a unit vector so we need to make it account for the actual
    // speed.
    _velocity = (_velocity)..scaleTo(_speed);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, _paint);
    renderHitboxes(canvas);
    //canvas.drawCircle(size.toRect(), _paint);
  }

  @override
  void update(double dt) {
    position.add(_velocity * dt);
    super.update(dt);
  }

  @override
  void onCreate() {
    super.onCreate();
    print("SlowBullet onCreate called");
  }

  @override
  void onDestroy() {
    print("SlowBullet onDestroy called");
  }

  @override
  void onHit(Collidable other) {
    print("SlowBullet onHit called");
  }
}

/// This is a Factory Method Design pattern example implementation for Bullets
/// in our game.
///
/// The class will return an instance of the specific bullet aksed for based on
/// a valid bullet choice.
class BulletFactory {
  /// private constructor to prevent instantiation
  BulletFactory._();

  /// main factory method to create instaces of Bullet children
  static Bullet create(BulletBuildContext context) {
    Bullet result;

    /// collect all the Bullet definitions here
    switch (context.bulletType) {
      case BulletEnum.slowBullet:
        {
          if (context.speed != BulletBuildContext.defaultSpeed) {
            result = SlowBullet.fullInit(context.position, context.velocity,
                context.size, context.speed, context.health, context.damage);
          } else {
            result = SlowBullet(context.position, context.velocity);
          }
        }
        break;

      case BulletEnum.fastBullet:
        {
          if (context.speed != BulletBuildContext.defaultSpeed) {
            result = FastBullet.fullInit(context.position, context.velocity,
                context.size, context.speed, context.health, context.damage);
          } else {
            result = FastBullet(context.position, context.velocity);
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
/// Bullet instace through the Factory method using the [BulletFactory]
///
/// We have a number of default values here as well in case callers do not
/// define all the entries.
class BulletBuildContext {
  static const double defaultSpeed = 0.0;
  static const int defaultHealth = 1;
  static const int defaultDamage = 1;
  static final Vector2 deaultVelocity = Vector2.zero();
  static final Vector2 deaultPosition = Vector2(-1, -1);
  static final Vector2 defaultSize = Vector2.zero();
  static final BulletEnum defaultBulletType = BulletEnum.values[0];

  double speed = defaultSpeed;
  Vector2 velocity = deaultVelocity;
  Vector2 position = deaultPosition;
  Vector2 size = defaultSize;
  int health = defaultHealth;
  int damage = defaultDamage;
  BulletEnum bulletType = defaultBulletType;

  BulletBuildContext();
}
