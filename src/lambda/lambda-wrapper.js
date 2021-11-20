const { BatchSpanProcessor } = require("@opentelemetry/sdk-trace-base");
const { CollectorTraceExporter } = require('@opentelemetry/exporter-collector');
const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
const { Resource } = require('@opentelemetry/resources');
const { AwsLambdaInstrumentation } = require('@opentelemetry/instrumentation-aws-lambda');
const { registerInstrumentations } = require('@opentelemetry/instrumentation');
const { getNodeAutoInstrumentations } = require("@opentelemetry/auto-instrumentations-node");
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

const provider = new NodeTracerProvider({
    resource: new Resource({
        [SemanticResourceAttributes.SERVICE_NAME]: 'serverless-demo',
    })
});

provider.addSpanProcessor(new BatchSpanProcessor(new CollectorTraceExporter(), {
    // The maximum queue size. After the size is reached spans are dropped.
    maxQueueSize: 100,
    // The maximum batch size of every export. It must be smaller or equal to maxQueueSize.
    maxExportBatchSize: 10,
    // The interval between two consecutive exports
    scheduledDelayMillis: 500,
    // How long the export can run before it is cancelled
    exportTimeoutMillis: 30000,
}));


provider.register()

registerInstrumentations({
 instrumentations: [
   getNodeAutoInstrumentations(),
   new AwsLambdaInstrumentation({
     requestHook: (span, {event, context}) => {

      if ('path' in event) {
        span.setAttribute("http.route",  event.path);
      }

      if ('httpMethod' in event) {
        span.setAttribute("http.method", event.httpMethod)
      }
      
     },
     responseHook: (span, {error, res}) => {
      if (error instanceof Error) {
        span.setAttribute('faas.error', error.message);
      }

      if (res) {
        span.setAttribute('http.status_code', res.statusCode);
      }
     },
     disableAwsContextPropagation: true
   })
 ],
});