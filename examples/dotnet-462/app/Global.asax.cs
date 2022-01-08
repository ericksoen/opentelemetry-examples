using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Http;
using System.Web.Routing;
using OpenTelemetry;
using OpenTelemetry.Exporter;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

namespace opentelemetry_api_4_6_2
{
    public class WebApiApplication : HttpApplication
    {
        private IDisposable tracerProvider;
        private string telemetry_target;
        private string telemetry_headers;
        protected void Application_Start()
        {
            telemetry_target = Environment.GetEnvironmentVariable("OpenTelemetryTarget");
            telemetry_headers = Environment.GetEnvironmentVariable("OpenTelemetryHeaders");

            if (string.IsNullOrEmpty(telemetry_target))
            {
                telemetry_target = ConfigurationManager.AppSettings["OpenTelemetryTarget"];
            }

            if (string.IsNullOrEmpty(telemetry_headers))
            {
                telemetry_headers = ConfigurationManager.AppSettings["OpenTelemetryHeaders"];
            }


            var builder = Sdk.CreateTracerProviderBuilder()
                .AddAspNetInstrumentation()
                .AddHttpClientInstrumentation()
                .AddSource("Values.Controlller")
                .SetResourceBuilder(
                    ResourceBuilder.CreateDefault()
                        .AddService(serviceName: "dotnet-462-demo", serviceVersion: "v1.0.0")
                )
                .AddOtlpExporter((options) =>
                {
                    options.Endpoint = new Uri($"{telemetry_target}");
                    options.Headers = telemetry_headers;
                });

            this.tracerProvider = builder.Build();

            GlobalConfiguration.Configure(WebApiConfig.Register);
        }

        protected void Application_End()
        {
            this.tracerProvider?.Dispose();
        }
    }
}
