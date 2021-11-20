'use strict';

const axios = require('axios');
const opentelemetry = require('@opentelemetry/api');
const sleep = require('util').promisify(setTimeout);
const MIN_DELAY_MS = 2500;
const MAX_DELAY_MS = 5000;

const tracer = opentelemetry.trace.getTracer('example-basic-tracer-node');
module.exports.handler = async (event) => {
  const headers = event.headers;
  const faults = 'x-fault' in headers ? headers['x-fault'] : '00';

  if (faults.length != 2) {
    console.log(`Invalid fault length specified. Skipping fault injection`);
  }

  let is_latency_fault = faults[0] === '1';
  let is_internal_server_fault = faults[1] === '1';

  let timeout_ms = is_latency_fault
    ? Math.random() * (MAX_DELAY_MS - MIN_DELAY_MS) + MIN_DELAY_MS
    : 0;
  await sleep(timeout_ms);

  if (is_internal_server_fault) {
    return {
      statusCode: 502,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: 'internal server error',
      }),
    };
  }
  const todoItem = await axios('https://jsonplaceholder.typicode.com/todos/1');

  const parentSpan = opentelemetry.trace.getSpan(
    opentelemetry.context.active()
  );

  let event_type = 'CONST';
  parentSpan.setAttribute('event_type', event_type);
  parentSpan.updateName('tracer-override');

  const span = tracer.startSpan('handleRequest', {
    kind: 1,
    attributes: { requestItems: 100 },
  });
  span.end();
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(
      {
        message: `The event type = ${event_type}`,
      },
      null,
      2
    ),
  };
};
