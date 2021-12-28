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
        private string telemetry_host;
        protected void Application_Start()
        {
            telemetry_host = Environment.GetEnvironmentVariable("OpenTelemetryHttpHost");

            if (string.IsNullOrEmpty(telemetry_host))
            {
                telemetry_host = telemetry_host = ConfigurationManager.AppSettings["OpenTelemetryHttpHost"];
            }

            var builder = Sdk.CreateTracerProviderBuilder()
                .AddAspNetInstrumentation()
                .AddHttpClientInstrumentation()
                .AddSource("Values.Controlller")
                .SetResourceBuilder(
                    ResourceBuilder.CreateDefault()
                        .AddService(serviceName: "dotnet-462-demo", serviceVersion: "v1.0.0")
                )
                .AddConsoleExporter()
                .AddOtlpExporter((options) =>
                {
                    options.Endpoint = new Uri($"{telemetry_host}/v1/traces");
                    options.Protocol = OtlpExportProtocol.HttpProtobuf;
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
