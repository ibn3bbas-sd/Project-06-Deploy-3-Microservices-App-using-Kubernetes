const express = require('express');
const axios = require('axios');
const promClient = require('prom-client');
const app = express();

// Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});
register.registerMetric(httpRequestDuration);

app.use(express.json());

// Health checks
app.get('/health/live', (req, res) => {
  res.status(200).json({ status: 'alive' });
});

app.get('/health/ready', async (req, res) => {
  try {
    // Check dependencies
    await axios.get(`http://${process.env.AUTH_SERVICE_HOST}:${process.env.AUTH_SERVICE_PORT}/health/live`);
    res.status(200).json({ status: 'ready' });
  } catch (error) {
    res.status(503).json({ status: 'not ready', error: error.message });
  }
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Main API endpoint
app.post('/api/process', async (req, res) => {
  const end = httpRequestDuration.startTimer();
  try {
    // Validate token with auth service
    const authHeader = req.headers.authorization;
    const authResponse = await axios.post(
      `http://${process.env.AUTH_SERVICE_HOST}:${process.env.AUTH_SERVICE_PORT}/validate`,
      { token: authHeader }
    );

    if (!authResponse.data.valid) {
      end({ method: 'POST', route: '/api/process', status_code: 401 });
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Process request
    const result = { 
      message: 'Request processed successfully',
      user: authResponse.data.user,
      timestamp: new Date().toISOString()
    };

    end({ method: 'POST', route: '/api/process', status_code: 200 });
    res.json(result);
  } catch (error) {
    end({ method: 'POST', route: '/api/process', status_code: 500 });
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`API Service listening on port ${PORT}`);
});