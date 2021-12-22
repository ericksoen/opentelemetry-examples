using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using OpenTelemetry.Exporter;
using OpenTelemetry.Instrumentation.AspNetCore;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

namespace app
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();

            // I have not successfully configured a dotnet application to export to an insecure gRPC
            // port. The extant documentation suggests that the combination of a .NET Core 3.1.x app
            // and a config switch to allow Http2Unencrypted support should enable this behavior, but I have yet to observe it.
            // See: https://github.com/open-telemetry/opentelemetry-dotnet/blob/main/src/OpenTelemetry.Exporter.OpenTelemetryProtocol/README.md#special-case-when-using-insecure-channel

            // Instead, I'm using OpenTelemetry.Exporter.OpenTelemetryProtocol v1.2.0-rc1 to export over HTTP:
            // See: https://github.com/open-telemetry/opentelemetry-dotnet/blob/core-1.2.0-rc1/src/OpenTelemetry.Exporter.OpenTelemetryProtocol/OtlpExporterOptions.cs
            
            var otlpTarget = Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_ENDPOINT");

            Console.WriteLine($"The current OTLP target = {otlpTarget}");
            services.AddOpenTelemetryTracing((builder) => builder
                .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService("otlp-dotnet-demo"))
                .AddAspNetCoreInstrumentation()
                .AddSource("Dotnet.Api.Controllers")
                .AddHttpClientInstrumentation()
                .AddConsoleExporter()
                .AddOtlpExporter(otlpOptions =>
                {
                    otlpOptions.Protocol = OtlpExportProtocol.HttpProtobuf;
                    otlpOptions.Endpoint = new Uri(otlpTarget);
                }));            
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseRouting();

            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}
