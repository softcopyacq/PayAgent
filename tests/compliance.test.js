/**
 * Test: Travel Rule Assessment
 */

const crypto = require('crypto');

// Replicate server's assessment logic
const TRAVEL_RULE_THRESHOLD_USD = 1000;

function assessTravelRule(amount, currency = 'USD') {
  const usdAmount = parseFloat(amount);
  return {
    required:   usdAmount >= TRAVEL_RULE_THRESHOLD_USD,
    threshold:  TRAVEL_RULE_THRESHOLD_USD,
    amount:     usdAmount,
    regulation: 'FATF Recommendation 16',
    frameworks: ['FinCEN (US)', 'TFR (EU/MiCA)', 'CBK (KE)'],
  };
}

describe('Travel Rule Logic', () => {
  test('Amount < $1,000 does not require Travel Rule', () => {
    const result = assessTravelRule(500);
    expect(result.required).toBe(false);
  });

  test('Amount = $1,000 requires Travel Rule', () => {
    const result = assessTravelRule(1000);
    expect(result.required).toBe(true);
  });

  test('Amount > $1,000 requires Travel Rule', () => {
    const result = assessTravelRule(5000);
    expect(result.required).toBe(true);
    expect(result.amount).toBe(5000);
  });

  test('Travel Rule result includes all frameworks', () => {
    const result = assessTravelRule(2000);
    expect(result.frameworks).toContain('FinCEN (US)');
    expect(result.frameworks).toContain('TFR (EU/MiCA)');
    expect(result.frameworks).toContain('CBK (KE)');
  });
});
