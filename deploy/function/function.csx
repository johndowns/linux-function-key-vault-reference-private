#r "Newtonsoft.Json"

using System.Net;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Primitives;

public static async Task<IActionResult> Run(HttpRequest req, ILogger log)
{
    var value = System.Environment.GetEnvironmentVariable("SampleKeyVaultSecret");
    log.LogInformation(value);
    return new OkObjectResult(value);
}
