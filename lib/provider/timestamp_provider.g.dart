// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timestamp_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timestampHash() => r'a1b07ac81a891e5390aeb94905f95e19b46e000c';

/// Keeps track of time and updates every minute.
/// Automatically notifies listeners when the time changes.
///
/// Copied from [Timestamp].
@ProviderFor(Timestamp)
final timestampProvider =
    AutoDisposeNotifierProvider<Timestamp, DateTime>.internal(
  Timestamp.new,
  name: r'timestampProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$timestampHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Timestamp = AutoDisposeNotifier<DateTime>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
