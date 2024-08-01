import 'package:component_001/utils.dart';
import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

/// Simple enum which will hold enumerated names for all our [ParticleGenerator]-derived
/// child classes
///
/// We use the [ExplosionFactory] directly to create/generate our explosions. To
/// create new explosions the steps are as follows:
///
///  - create a new particle generator
///  - add a new enumeration entry
///  - add a new switch case to the [ExplosionFactory] to create this
///    new [Asteroid] instance when the enumeration entry is provided.
enum ExplosionEnum {
  largeParticleExplosion,
  mediumParticleExplosion,
  fieryExplosion,
  bonusExplosion,
}

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
abstract class Explosion {
  static const double defaultLifespan = 1.0;
  static const int defaultParticleCount = 1;
  static final Vector2 deaultPosition = Vector2(-1, -1);
  static final Vector2 defaultSize = Vector2.zero();
  static final ExplosionEnum defaultExplosionType = ExplosionEnum.values[0];
  static final Vector2 defaultMultiplier = Vector2.all(1.0);

  double _lifespan = defaultLifespan;
  late Vector2 _position = deaultPosition;
  Vector2 _size = defaultSize;
  int _particleCount = defaultParticleCount;
  late Vector2 _resolutionMultiplier = defaultMultiplier;
  Images? _images;

  //
  // default constructor with default values
  Explosion(Vector2 resolutionMultiplier, Vector2 position) {
    _resolutionMultiplier = resolutionMultiplier;
    _position = position;
  }

  //
  // named constructor
  Explosion.fullInit(Vector2 resolutionMultiplier, Vector2 position,
      {double? lifespan, int? particleCount, Vector2? size, Images? images})
      : _resolutionMultiplier = resolutionMultiplier,
        _position = position,
        _lifespan = lifespan ?? defaultLifespan,
        _particleCount = particleCount ?? defaultParticleCount,
        _size = size ?? defaultSize,
        _images = images;

  ////////////////////////////////////////////////////////
  // business methods
  //

  //
  // Called when the explosion has been created but not yet rendered.
  Future<void> onCreate();

  //
  // Called when the explosion has been hit. The ‘other’ is what the explosion hit, or was hit by.
  void onHit(Collidable other);

  //
  // Main generator method. This will create the actual particle simulation to the caller
  ParticleComponent getParticleSimulation(Vector2 position);

  //////////////////////////////////////////////////////////
  /// overrides
  ///

  @override

  /// We are defining our own stringify method so that we can see our
  /// values when debugging.
  ///
  String toString() {
    return 'particle count: $_particleCount , position: $_position , lifespan: $_lifespan, size: $_size';
  }
}

/// This class creates a particle explosion class which can be used to customize
/// particle-based explosions.
/// This is an extension of [Explosion] class which is really just a convenience
/// of being able to wrap functionality in a simple to generate particle
/// generator.
///
class ParticleExplosion360 extends Explosion {
  static const double defaultLifespan = 3.0;
  static final Vector2 defaultSize = Vector2.all(2.0);
  static const int defaultParticleCount = 45;
  // color of the particles
  static final _paint = Paint()..color = Colors.red;

  ParticleExplosion360(Vector2 resolutionMultiplier, Vector2 position)
      : super.fullInit(resolutionMultiplier, position,
            size: defaultSize,
            lifespan: defaultLifespan,
            particleCount: defaultParticleCount);

  //
  // named constructor
  ParticleExplosion360.fullInit(Vector2 resolutionMultiplier, Vector2 position,
      Vector2? size, double? lifespan, int? particleCount)
      : super.fullInit(resolutionMultiplier, position,
            size: size, lifespan: lifespan, particleCount: particleCount);

  @override
  void onHit(Collidable other) {
    debugPrint("ParticleExplosion360 onHit called");
  }

  @override
  Future<void> onCreate() async {
    debugPrint("ParticleExplosion360 onCreate called: data $this");
  }

  @override

  /// implementation of the particle generator which will return a wrapped
  /// particle simulation in a [ParticleComponent]
  ///
  /// This is a simple explosion simulation which creates circular particles
  /// which travel in all directions in a random fashion.
  ///
  ParticleComponent getParticleSimulation(Vector2 position) {
    debugPrint("<ParticleExplosion360> <simulation> data: $this");
    return ParticleComponent(
      Particle.generate(
        count: _particleCount,
        lifespan: _lifespan,
        generator: (i) => AcceleratedParticle(
          acceleration: Utils.randomVector()..scale(100),
          position: _position,
          child: CircleParticle(
            paint: Paint()..color = _paint.color,
            radius: _size.x / 2,
          ),
        ),
      ),
    );
  }
}

/// This class creates a particle explosion class which can be used to customize
/// particle-based explosions.
/// This is an extension of [Explosion] class which is really just a convenience
/// of being able to wrap functionality in a simple to generate particle
/// generator.
///
class ParticleBonusExplosion extends Explosion {
  static const double defaultLifespan = 3.0;
  static final Vector2 defaultSize = Vector2.all(2.0);
  static const int defaultParticleCount = 45;
  // color of the particles
  static final _paint = Paint()..color = Colors.white;

  ParticleBonusExplosion(Vector2 resolutionMultiplier, Vector2 position)
      : super.fullInit(resolutionMultiplier, position,
            size: defaultSize,
            lifespan: defaultLifespan,
            particleCount: defaultParticleCount);

  //
  // named constructor
  ParticleBonusExplosion.fullInit(Vector2 resolutionMultiplier,
      Vector2 position, Vector2? size, double? lifespan, int? particleCount)
      : super.fullInit(resolutionMultiplier, position,
            size: size, lifespan: lifespan, particleCount: particleCount);

  @override
  void onHit(Collidable other) {
    debugPrint("ParticleBonusExplosion onHit called");
  }

  @override
  Future<void> onCreate() async {
    debugPrint("ParticleBonusExplosion onCreate called: data $this");
  }

  @override

  /// implementation of the particle generator which will return a wrapped
  /// particle simulation in a [ParticleComponent]
  ///
  /// This is a simple explosion simulation which creates circular particles
  /// which travel in all directions in a random fashion.
  ///
  ParticleComponent getParticleSimulation(Vector2 position) {
    debugPrint("<ParticleBonusExplosion> <simulation> data: $this");
    return ParticleComponent(
      Particle.generate(
        count: _particleCount,
        lifespan: _lifespan,
        generator: (i) => AcceleratedParticle(
          acceleration: Utils.randomVector()..scale(100),
          position: _position,
          child: CircleParticle(
            paint: Paint()..color = _paint.color,
            radius: _size.x / 2,
          ),
        ),
      ),
    );
  }
}

/// This class creates a particle explosion class which can be used to customize
/// particle-based explosions.
/// This is an extension of [Explosion] class which is really just a convenience
/// of being able to wrap functionality in a simple to generate particle
/// generator.
///
class FieryExplosion extends Explosion {
  static const double defaultLifespan = 3.0;
  static final Vector2 defaultSize = Vector2.all(1.5);
  // color of the particles
  static final _paint = Paint()..color = Colors.red;

  FieryExplosion(Vector2 resolutionMultiplier, Vector2 position)
      : super.fullInit(resolutionMultiplier, position,
            size: defaultSize,
            lifespan: defaultLifespan,
            particleCount: Explosion.defaultParticleCount);

  //
  // named constructor
  FieryExplosion.fullInit(Vector2 resolutionMultiplier, Vector2 position,
      Vector2? size, double? lifespan, int? particleCount, Images? images)
      : super.fullInit(resolutionMultiplier, position,
            size: size,
            lifespan: lifespan,
            particleCount: particleCount,
            images: images);

  @override
  void onHit(Collidable other) {
    debugPrint("FieryExplosion onHit called");
  }

  @override
  Future<void> onCreate() async {
    debugPrint("FieryExplosion <onCreate> called");
    //await gameRef.images.load('boom.png');
  }

  @override

  /// implementation of the particle generator which will return a wrapped
  /// particle simulation in a [ParticleComponent]
  ///
  /// This is a simple explosion simulation which creates circular particles
  /// which travel in all directions in a random fashion.
  ///
  ParticleComponent getParticleSimulation(Vector2 position) {
    position.sub(Vector2(200, 200));
    // create the ParticleComponent
    return ParticleComponent(
      // use AcceleratedParticle as just a position holder
      AcceleratedParticle(
        lifespan: 2,
        position: position,
        child: SpriteAnimationParticle(
          animation: _getBoomAnimation(),
          size: Vector2(200, 200),
        ),
      ),
    );
  }

  ///
  /// Load up the sprite sheet with an even step time framerate
  SpriteAnimation _getBoomAnimation() {
    const columns = 8;
    const rows = 8;
    const frames = columns * rows;
    final spriteImage = _images!.fromCache('boom.png');
    final spritesheet = SpriteSheet.fromColumnsAndRows(
      image: spriteImage,
      columns: columns,
      rows: rows,
    );
    final sprites = List<Sprite>.generate(frames, spritesheet.getSpriteById);
    return SpriteAnimation.spriteList(sprites, stepTime: 0.1);
  }
}

/// This is a Factory Method Design pattern example implementation for explosions
/// for our game
///
/// The class will return an instance of the specific ParticleComponent asked for based
/// on a valid explosion type choice.
class ExplosionFactory {
  /// private constructor to prevent instantiation
  ExplosionFactory._();

  /// main factory method to create instaces of Bullet children
  static ParticleComponent create(ExplosionBuildContext context) {
    Explosion preResult;
    ParticleComponent result;

    debugPrint("<ExplosionFactory> context: $context");

    /// collect all the Asteroid definitions here
    switch (context.explosionType) {
      case ExplosionEnum.largeParticleExplosion:
        {
          preResult =
              ParticleExplosion360(context.multiplier, context.position);
        }
        break;

      case ExplosionEnum.mediumParticleExplosion:
        {
          preResult = ParticleExplosion360(context.multiplier, context.position)
            .._particleCount = 20
            .._lifespan = 1.5;
        }
        break;

      case ExplosionEnum.bonusExplosion:
        {
          preResult =
              ParticleBonusExplosion(context.multiplier, context.position)
                .._particleCount = 60
                .._lifespan = 2.0;
        }
        break;

      case ExplosionEnum.fieryExplosion:
        {
          preResult = FieryExplosion(context.multiplier, context.position)
            .._images = context.images;
        }
        break;
    }

    preResult.onCreate();
    result = preResult.getParticleSimulation(context.position);
    return result;
  }
}

/// This is a simple data holder for the context data wehen we create a new
/// Asteroid instace through the Factory method using the [AsteroidFactory]
///
/// We have a number of default values here as well in case callers do not
/// define all the entries.
class ExplosionBuildContext {
  static const double defaultLifespan = 1.0;
  static const int defaultParticleCount = 1;
  static final Vector2 deaultPosition = Vector2(-1, -1);
  static final Vector2 defaultSize = Vector2.zero();
  static final ExplosionEnum defaultExplosionType = ExplosionEnum.values[0];
  static final Vector2 defaultMultiplier = Vector2.all(1.0);

  /// helper method for parsing out strings into corresponding enum values
  ///
  static ExplosionEnum explosionFromString(String value) {
    debugPrint('${ExplosionEnum.values}');
    return ExplosionEnum.values.firstWhere(
        (e) => e.toString().split('.')[1].toUpperCase() == value.toUpperCase());
  }

  double lifespan = defaultLifespan;
  Vector2 position = deaultPosition;
  Vector2 size = defaultSize;
  int particleCount = defaultParticleCount;
  Vector2 multiplier = defaultMultiplier;
  ExplosionEnum explosionType = defaultExplosionType;
  Images? images;

  ExplosionBuildContext();

  @override

  /// We are defining our own stringify method so that we can see our
  /// values when debugging.
  ///
  String toString() {
    return 'name: $explosionType , position: $position , lifespan: $lifespan, multiplier: $multiplier';
  }
}
