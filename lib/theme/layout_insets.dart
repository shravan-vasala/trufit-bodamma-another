import 'package:flutter/material.dart';

/// Clearance for the floating pill bottom nav in [ScaffoldWithNavBar].
///
/// Body uses [extendBody], so scrollables must leave this much room at the
/// bottom or the last content sits under the nav and cannot be reached.
const double kFloatingNavClearance = 100;

/// Extra space below page content inside tab shells (nav + breathing room).
const double kShellScrollBottomPadding = kFloatingNavClearance + 16;

EdgeInsets shellScrollPadding(BuildContext context, {double horizontal = 0}) {
  return EdgeInsets.fromLTRB(
    horizontal,
    0,
    horizontal,
    kShellScrollBottomPadding,
  );
}
