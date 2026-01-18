// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deep_link_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deepLinkServiceHash() => r'29dffee0926bf780ec3d604f70899fb16d6f4f2a';

/// Provider for DeepLinkService
///
/// Copied from [deepLinkService].
@ProviderFor(deepLinkService)
final deepLinkServiceProvider = Provider<DeepLinkService>.internal(
  deepLinkService,
  name: r'deepLinkServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deepLinkServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeepLinkServiceRef = ProviderRef<DeepLinkService>;
String _$pendingInviteLinkHash() => r'53189822774b161c68548bcbba8f08b3563235dc';

/// Provider for the current pending invite link
///
/// Copied from [PendingInviteLink].
@ProviderFor(PendingInviteLink)
final pendingInviteLinkProvider =
    AutoDisposeNotifierProvider<PendingInviteLink, InviteDeepLink?>.internal(
      PendingInviteLink.new,
      name: r'pendingInviteLinkProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingInviteLinkHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PendingInviteLink = AutoDisposeNotifier<InviteDeepLink?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
