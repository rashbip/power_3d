// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'power3d_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$power3DManagerHash() => r'd7e64d3fed816afda2a2fdbfa8152e520ee3cda8';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$Power3DManager
    extends BuildlessAutoDisposeNotifier<Power3DState> {
  late final String viewerId;

  Power3DState build(String viewerId);
}

/// See also [Power3DManager].
@ProviderFor(Power3DManager)
const power3DManagerProvider = Power3DManagerFamily();

/// See also [Power3DManager].
class Power3DManagerFamily extends Family<Power3DState> {
  /// See also [Power3DManager].
  const Power3DManagerFamily();

  /// See also [Power3DManager].
  Power3DManagerProvider call(String viewerId) {
    return Power3DManagerProvider(viewerId);
  }

  @override
  Power3DManagerProvider getProviderOverride(
    covariant Power3DManagerProvider provider,
  ) {
    return call(provider.viewerId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'power3DManagerProvider';
}

/// See also [Power3DManager].
class Power3DManagerProvider
    extends AutoDisposeNotifierProviderImpl<Power3DManager, Power3DState> {
  /// See also [Power3DManager].
  Power3DManagerProvider(String viewerId)
    : this._internal(
        () => Power3DManager()..viewerId = viewerId,
        from: power3DManagerProvider,
        name: r'power3DManagerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$power3DManagerHash,
        dependencies: Power3DManagerFamily._dependencies,
        allTransitiveDependencies:
            Power3DManagerFamily._allTransitiveDependencies,
        viewerId: viewerId,
      );

  Power3DManagerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.viewerId,
  }) : super.internal();

  final String viewerId;

  @override
  Power3DState runNotifierBuild(covariant Power3DManager notifier) {
    return notifier.build(viewerId);
  }

  @override
  Override overrideWith(Power3DManager Function() create) {
    return ProviderOverride(
      origin: this,
      override: Power3DManagerProvider._internal(
        () => create()..viewerId = viewerId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        viewerId: viewerId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<Power3DManager, Power3DState>
  createElement() {
    return _Power3DManagerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is Power3DManagerProvider && other.viewerId == viewerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, viewerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin Power3DManagerRef on AutoDisposeNotifierProviderRef<Power3DState> {
  /// The parameter `viewerId` of this provider.
  String get viewerId;
}

class _Power3DManagerProviderElement
    extends AutoDisposeNotifierProviderElement<Power3DManager, Power3DState>
    with Power3DManagerRef {
  _Power3DManagerProviderElement(super.provider);

  @override
  String get viewerId => (origin as Power3DManagerProvider).viewerId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
