## Load Test

These load tests use [K6](https://k6.io/) to generate load. This load test configuration generates ~10 requests/second (~1200 total).

```bash 
k6 run index.js --vus 5 --duration 120s -e TARGET_URL=https://demo.app-domain.com
```