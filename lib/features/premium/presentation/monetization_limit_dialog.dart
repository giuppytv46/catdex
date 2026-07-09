import 'package:catdex/features/premium/presentation/catdex_premium_paywall.dart';
import 'package:catdex/features/premium/presentation/monetization_limit_kind.dart';
import 'package:flutter/material.dart';

export 'package:catdex/features/premium/presentation/monetization_limit_kind.dart';

const monetizationLimitMessage =
    'Passa a CatDex Premium o ottieni crediti extra per continuare.';

Future<void> showMonetizationLimitDialog(
  BuildContext context, {
  required MonetizationLimitKind kind,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (context) {
      return CatDexPremiumPaywall(reason: kind);
    },
  );
}
