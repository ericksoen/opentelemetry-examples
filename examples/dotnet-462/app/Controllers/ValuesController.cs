using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Swashbuckle.Swagger.Annotations;

namespace opentelemetry_api_4_6_2.Controllers
{
    public class ValuesController : ApiController
    {
        private static ActivitySource _source = new ActivitySource("Values.Controlller", "1.0.0");

        // GET api/values
        [SwaggerOperation("GetAll")]
        public async Task<IEnumerable<string>> Get()
        {
            using (var activity = _source.StartActivity("Some work"))
            {
                var response = new string[] { "value1", "value2", "value3" };
                activity?.AddTag("response.count", response.Length);
                await Task.Delay(500);

                return response;
            }
        }

        // GET api/values/5
        [SwaggerOperation("GetById")]
        [SwaggerResponse(HttpStatusCode.OK)]
        [SwaggerResponse(HttpStatusCode.NotFound)]
        public string Get(int id)
        {
            return "value";
        }
          
    }
}
