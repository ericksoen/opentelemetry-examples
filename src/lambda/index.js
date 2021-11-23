'use strict';

const axios = require('axios');
const opentelemetry = require('@opentelemetry/api');
const sleep = require('util').promisify(setTimeout);
const MIN_DELAY_MS = 750;
const MAX_DELAY_MS = 1200;

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

  const todo_id = 1;
  const todoItem = await axios(
    `https://jsonplaceholder.typicode.com/todos/${todo_id}`
  );

  const parentSpan = opentelemetry.trace.getSpan(
    opentelemetry.context.active()
  );

  parentSpan.updateName('resolve-todos');
  parentSpan.setAttribute('todo_id', todo_id);

  const span = tracer.startSpan('process-todo-response', {
    kind: 1,
    attributes: { requestItems: 100 },
  });
  let normal_latency_ms = Math.random() * (600 - 250) + 250;
  await sleep(normal_latency_ms);
  span.end();
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(
      {
        "msg": "hello world! (from Lambda)",
      },
      null,
      2
    ),
  };
};
