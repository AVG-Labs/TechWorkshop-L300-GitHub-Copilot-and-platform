using Microsoft.AspNetCore.Mvc;
using System.Text;
using System.Text.Json;
using ZavaStorefront.Models;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ChatController> _logger;

        public ChatController(IHttpClientFactory httpClientFactory, IConfiguration configuration, ILogger<ChatController> logger)
        {
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
            _logger = logger;
        }

        [HttpGet]
        public IActionResult Index()
        {
            return View(new ChatViewModel());
        }

        [HttpPost]
        public async Task<IActionResult> Index(ChatViewModel model)
        {
            if (string.IsNullOrWhiteSpace(model.UserMessage))
                return View(model);

            var endpoint = _configuration["AzureAI:Endpoint"]
                           ?? Environment.GetEnvironmentVariable("AZURE_AI_SERVICES_ENDPOINT");
            var deploymentName = _configuration["AzureAI:DeploymentName"] ?? "gpt-4o";
            var apiKey = _configuration["AzureAI:ApiKey"]
                         ?? Environment.GetEnvironmentVariable("AZURE_AI_SERVICES_KEY");

            if (string.IsNullOrEmpty(endpoint) || string.IsNullOrEmpty(apiKey))
            {
                model.History = (model.History ?? string.Empty) +
                    "You: " + model.UserMessage + "\nAssistant: [Error: Azure AI endpoint is not configured.]\n\n";
                model.UserMessage = string.Empty;
                return View(model);
            }

            try
            {
                var client = _httpClientFactory.CreateClient();
                var url = $"{endpoint.TrimEnd('/')}/openai/deployments/{deploymentName}/chat/completions?api-version=2024-02-01";

                var requestBody = new
                {
                    messages = new[] { new { role = "user", content = model.UserMessage } }
                };

                var request = new HttpRequestMessage(HttpMethod.Post, url);
                request.Headers.Add("api-key", apiKey);
                request.Content = new StringContent(
                    JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");

                var response = await client.SendAsync(request);
                response.EnsureSuccessStatusCode();

                var json = await response.Content.ReadAsStringAsync();
                using var doc = JsonDocument.Parse(json);
                var reply = doc.RootElement
                    .GetProperty("choices")[0]
                    .GetProperty("message")
                    .GetProperty("content")
                    .GetString();

                model.History = (model.History ?? string.Empty) +
                    "You: " + model.UserMessage + "\nAssistant: " + reply + "\n\n";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calling Azure AI Services");
                model.History = (model.History ?? string.Empty) +
                    "You: " + model.UserMessage + "\nAssistant: [Error: " + ex.Message + "]\n\n";
            }

            model.UserMessage = string.Empty;
            return View(model);
        }
    }
}
