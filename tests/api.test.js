const axios = require('axios');

/**
 * Test suite for PayAgent endpoints
 * Run: npm test
 * 
 * Note: These tests use HTTP requests to a running server.
 * For local testing: start server in one terminal (npm run dev)
 * Then run tests in another terminal (npm test)
 */

const BASE_URL = 'http://localhost:3000/api';
const VALID_TOKEN = 'test-token-abc123def456';

describe('PayAgent API', () => {
  // Wait for server to be ready
  beforeAll(async () => {
    // Give server time to start
    await new Promise(resolve => setTimeout(resolve, 500));
  });

  describe('Public Endpoints', () => {
    test('GET /api/health returns 200', async () => {
      const response = await axios.get(`${BASE_URL}/health`);
      expect(response.status).toBe(200);
      expect(response.data.status).toBe('ok');
      expect(response.data.service).toBe('PayAgent');
      expect(response.data.corridors).toBeDefined();
      expect(Array.isArray(response.data.corridors)).toBe(true);
    });

    test('GET /api/corridors returns 200', async () => {
      const response = await axios.get(`${BASE_URL}/corridors`);
      expect(response.status).toBe(200);
      expect(response.data.corridors).toBeDefined();
      expect(response.data.corridors.LISBON_USA).toBeDefined();
      expect(response.data.corridors.USA_LISBON).toBeDefined();
    });
  });

  describe('Authentication', () => {
    test('POST /api/generate_apass without auth returns 401', async () => {
      try {
        await axios.post(`${BASE_URL}/generate_apass`, {
          customerId: 'test-001',
          kycSource: 'Sumsub',
          subTier: 5
        });
        fail('Should have thrown 401 error');
      } catch (err) {
        expect(err.response.status).toBe(401);
        expect(err.response.data.error).toBeDefined();
      }
    });

    test('POST /api/generate_apass with invalid token returns 401', async () => {
      try {
        await axios.post(
          `${BASE_URL}/generate_apass`,
          {
            customerId: 'test-001',
            kycSource: 'Sumsub',
            subTier: 5
          },
          {
            headers: { 'Authorization': 'Bearer short' }
          }
        );
        fail('Should have thrown 401 error');
      } catch (err) {
        expect(err.response.status).toBe(401);
      }
    });
  });

  describe('Input Validation', () => {
    test('POST /api/generate_apass with missing customerId returns 400', async () => {
      try {
        await axios.post(
          `${BASE_URL}/generate_apass`,
          {
            kycSource: 'Sumsub',
            subTier: 5
          },
          {
            headers: { 'Authorization': `Bearer ${VALID_TOKEN}` }
          }
        );
        fail('Should have thrown 400 error');
      } catch (err) {
        expect(err.response.status).toBe(400);
        expect(err.response.data.error).toBeDefined();
      }
    });

    test('POST /api/generate_apass with invalid subTier returns 400', async () => {
      try {
        await axios.post(
          `${BASE_URL}/generate_apass`,
          {
            customerId: 'test-001-lisbon',
            subTier: 100 // Invalid: must be 1-99
          },
          {
            headers: { 'Authorization': `Bearer ${VALID_TOKEN}` }
          }
        );
        fail('Should have thrown 400 error');
      } catch (err) {
        expect(err.response.status).toBe(400);
      }
    });
  });

  describe('404 Handling', () => {
    test('GET /api/nonexistent returns 404', async () => {
      try {
        await axios.get(`${BASE_URL}/nonexistent`);
        fail('Should have thrown 404 error');
      } catch (err) {
        expect(err.response.status).toBe(404);
      }
    });
  });

  describe('Corridor Metadata', () => {
    test('Corridors include required frameworks', async () => {
      const response = await axios.get(`${BASE_URL}/corridors`);
      const lisbon_usa = response.data.corridors.LISBON_USA;
      expect(lisbon_usa.frameworks).toContain('MiCA');
      expect(lisbon_usa.frameworks).toContain('FinCEN');
      expect(lisbon_usa.frameworks).toContain('FATF-Rec16');
    });

    test('Settlement times are defined and positive', async () => {
      const response = await axios.get(`${BASE_URL}/corridors`);
      const lisbon_usa = response.data.corridors.LISBON_USA;
      expect(lisbon_usa.settlementMs).toBeGreaterThan(0);
      expect(typeof lisbon_usa.settlementMs).toBe('number');
    });
  });
});
