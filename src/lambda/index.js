'use strict';

const axios = require("axios");
const opentelemetry = require('@opentelemetry/api');

const tracer = opentelemetry.trace.getTracer('example-basic-tracer-node');
module.exports.handler = async (event) => {
 const todoItem = await axios('https://jsonplaceholder.typicode.com/todos/1');

 const parentSpan = opentelemetry.trace.getSpan(opentelemetry.context.active());
 
 console.log(`The current parent span = ${parentSpan.isRecording()}`);
 console.log(`The current parent span = ${parentSpan.spanContext().traceId}`);
 console.log(`The received event = ${JSON.stringify(event)}`);
 console.log(`The traceId environment variable = ${process.env["_X_AMZN_TRACE_ID"]}`)

 let event_type = "CONST"
 parentSpan.setAttribute('event_type', event_type);
 parentSpan.updateName('tracer-override');

 const span = tracer.startSpan('handleRequest', {
     kind: 1,
     attributes: {'requestItems': 100},
 })
 span.end();
 return {
   statusCode: 200,
   headers: {
       'Content-Type': "application/json",
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