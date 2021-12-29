using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Runtime.Versioning;
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

            // Permit export to an insecure gRPC port. This config switch is required for a .NET Core 3.1.x app
            // Export over an insecure gRPC port is the default behavior for OpenTelemetry Agent Collectors
            // See: https://github.com/open-telemetry/opentelemetry-dotnet/blob/main/src/OpenTelemetry.Exporter.OpenTelemetryProtocol/README.md#special-case-when-using-insecure-channel
            AppContext.SetSwitch("System.Net.Http.SocketsHttpHandler.Http2UnencryptedSupport", true);

            var otlpTarget = Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_ENDPOINT");

            var framework = Assembly
                .GetEntryAssembly()?
                .GetCustomAttribute<TargetFrameworkAttribute>()?
                .FrameworkName;
            
            Console.WriteLine($"The current OTLP target = {otlpTarget}");
            services.AddOpenTelemetryTracing((builder) => builder
                .SetResourceBuilder(
                    ResourceBuilder.CreateDefault()
                        .AddService("otlp-dotnet-demo")
                        .AddAttributes(new Dictionary<string, object>{ {"dotnetFramework", framework} } )
                )
                .AddAspNetCoreInstrumentation()
                .AddSource("Dotnet.Api.Controllers")
                .AddHttpClientInstrumentation()

                .AddConsoleExporter()
                .AddOtlpExporter(otlpOptions =>
                {
                    otlpOptions.Protocol = OtlpExportProtocol.Grpc;
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
