import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';

final partnerOffersProvider = Provider<List<PartnerOffer>>((ref) {
  // Static offers; in production fetch from backend
  return const [
    PartnerOffer(
      id: 'offer_bank_1',
      type: PartnerType.bank,
      name: 'Partner Bank - High Yield Savings',
      ctaUrl: 'https://example.com/bank-signup',
      triggerModuleId: 'savings_emergency',
    ),
    PartnerOffer(
      id: 'offer_insurance_1',
      type: PartnerType.insurance,
      name: 'Sun Life - Starter Plan',
      ctaUrl: 'https://example.com/sunlife',
      triggerModuleId: 'with_insurance_case',
    ),
    PartnerOffer(
      id: 'offer_insurance_2',
      type: PartnerType.insurance,
      name: 'AXA - Youth Essential',
      ctaUrl: 'https://example.com/axa',
      triggerModuleId: 'insurance_risk',
    ),
  ];
});
