import http from 'k6/http';
import { Counter } from 'k6/metrics';

const response_2xx = new Counter('2xx_response');
const response_4xx = new Counter('4xx_response');
const response_5xx = new Counter('5xx_response');
const response_unknown = new Counter('unknown_response');
export default function () {
  const target_host = `${__ENV.TARGET_URL}`;

  const batch_items = [
      ['GET', `${target_host}/proxy?target=ecs`],
      ['GET', `${target_host}/proxy?target=ec2`],
      ['GET', `${target_host}/proxy?target=lambda`],
  ]
  const batch_responses = http.batch(batch_items);
  for (let i = 0; i < batch_items.length; i++) {
    const resp = batch_responses[i];
    const status_type = Math.floor(resp.status / 100);
    switch (status_type) {
      case 2:
        response_2xx.add(1);
        break;
      case 4:
        response_4xx.add(1);
        break;
      case 5:
        response_5xx.add(1);
        break;
      default:
        response_unknown.add(1);
    }
  }
}
