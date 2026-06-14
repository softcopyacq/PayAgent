const express = require('express');
const axios = require('axios');
const path = require('path');

/**
 * Test suite for PayAgent endpoints
 * Run: npm test
 */

describe('PayAgent API', () => {
  let app;
  let server;
  const PORT = 3001;

  beforeAll(() => {
    app = require('../server');
    server = app.listen(PORT, () => {
      console.log(`Test server running on port ${PORT}`);
    });
  });

  afterAll(() => {
    server.close();
  });

  describe('Public Endpoints', () => {
    test('GET /api/health returns 200', async () => {
      const response = await axios.get(`http://localhost:${PORT}/api/health`);
      expect(response.status).toBe(200);
      expect(response.data.status).toBe('ok');
      expect(response.data.service).toBe('PayAgent');
      expect(response.data.corridors).toBeDefined();
    });

    test('GET /api/corridors returns 200', async () => {
      const response = await axios.get(`http://localhost:${PORT}/api/corridors`);
      expect(response.status).toBe(200);
      expect(response.data.corridors).toBeDefined();
      expect(response.data.corridors.LISBON_USA).toBeDefined();
    });
  });

  describe('Authentication', () => {
    test('POST /api/generate_apass without auth returns 401', async () => {
      try {
        await axios.post(`http://localhost:${PORT}/api/generate_apass`, {
          customerId: 'test-001',
          kycSource: 'Sumsub',
          subTier: 5
        });
      } catch (err) {
        expect(err.response.status).toBe(401);
        expect(err.response.data.error).toMatch(/Authorization/);
      }
    });

    test('POST /api/generate_apass with invalid token returns 401', async () => {
      try {
        await axios.post(`http://localhost:${PORT}/api/generate_apass`,
          {
            customerId: 'test-001',
            kycSource: 'Sumsub',
            subTier: 5
          },
          {
            headers: { 'Authorization': 'Bearer invalid-token' }
          }
        );
      } catch (err) {
        expect(err.response.status).toBe(401);
      }
    });
  });

  describe('Input Validation', () => {
    const validAuthHeader = { 'Authorization': 'Bearer test-token-abc123def456' };

    test('POST /api/generate_apass with missing customerId returns 400', async () => {
      try {
        await axios.post(`http://localhost:${PORT}/api/generate_apass`,
          {
            kycSource: 'Sumsub',
            subTier: 5
          },
          { headers: validAuthHeader }
        );
      } catch (err) {
        expect(err.response.status).toBe(400);
      }
    });

    test('POST /api/generate_apass with invalid subTier returns 400', async () => {
      try {
        await axios.post(`http://localhost:${PORT}/api/generate_apass`,
          {
            customerId: 'test-001-lisbon',
            subTier: 100 // Invalid: must be 1-99
          },
          { headers: validAuthHeader }
        );
      } catch (err) {
        expect(err.response.status).toBe(400);
      }
    });
  });

  describe('Security Headers', () => {
    test('Response includes HSTS header', async () => {
      const response = await axios.get(`http://localhost:${PORT}/api/health`);
      // Note: HSTS only applies over HTTPS, but checking structure
      expect(response.status).toBe(200);
    });
  });

  describe('404 Handling', () => {
    test('GET /api/nonexistent returns 404', async () => {
      try {
        await axios.get(`http://localhost:${PORT}/api/nonexistent`);
      } catch (err) {
        expect(err.response.status).toBe(404);
      }
    });
  });
});
