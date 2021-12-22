using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace app
{
    public class Program
    {
        public static void Main(string[] args)
        {
            // Initialize Activity Id format to use W3C before building application
            // since default dotnet 3.1 Activity is hierarchical.
            
            // Eventually the OpenTelemetry SDK changes the format to W3C, but the 
            // first application request is already in flight prior to that change.

            // See: https://github.com/open-telemetry/opentelemetry-dotnet/issues/2746#issuecomment-995357477
            Activity.DefaultIdFormat = ActivityIdFormat.W3C;
            Activity.ForceDefaultIdFormat = true;            
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
    }
}
