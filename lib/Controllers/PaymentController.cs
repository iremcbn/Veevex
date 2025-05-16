using Microsoft.AspNetCore.Mvc;
using System.Net.Http.Headers;
using System.Text;
using System.Security.Cryptography;
using Newtonsoft.Json;

namespace VeevexBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PaymentController : ControllerBase
    {
        private const string merchantId = "XXXXXX";
        private const string merchantKey = "YYYYYY";
        private const string merchantSalt = "ZZZZZZ";

        [HttpPost("create")]
        public async Task<IActionResult> CreatePayment([FromBody] PaymentRequest request)
        {
            string userIp = request.UserIp ?? "127.0.0.1";
            
            string merchantOid = Guid.NewGuid().ToString();

            string paymentAmount = ((int)(request.Amount * 100)).ToString();

            string userBasket = JsonConvert.SerializeObject(new[]
            {
                new object[] { request.StationTitle, "1", request.Amount.ToString("F2") }
            });

            string hashStr = merchantId + userIp + merchantOid + request.Email + paymentAmount + userBasket + "TL" + "0" + merchantSalt;
            byte[] bytes = Encoding.UTF8.GetBytes(hashStr + merchantKey);
            string paytrToken;

            using (SHA256 sha = SHA256.Create())
            {
                byte[] hash = sha.ComputeHash(bytes);
                paytrToken = Convert.ToBase64String(hash);
            }

            var parameters = new Dictionary<string, string>
            {
                { "merchant_id", merchantId },
                { "user_ip", userIp },
                { "merchant_oid", merchantOid },
                { "email", request.Email },
                { "payment_amount", paymentAmount },
                { "paytr_token", paytrToken },
                { "user_basket", userBasket },
                { "currency", "TL" },
                { "test_mode", "1" }, 
                { "merchant_ok_url", "https://seninsite.com/odeme-basarili" },
                { "merchant_fail_url", "https://seninsite.com/odeme-hata" },
                { "debug_on", "1" }
            };

            using var httpClient = new HttpClient();
            var content = new FormUrlEncodedContent(parameters);
            var response = await httpClient.PostAsync("https://www.paytr.com/odeme/api/get-token", content);
            var responseBody = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
                return BadRequest("PayTR bağlantı hatası.");

            var result = JsonConvert.DeserializeObject<PayTRResponse>(responseBody);

            if (result.Status == "success")
            {
                string iframeUrl = $"https://www.paytr.com/odeme/guvenli/{result.Token}";
                return Ok(new { paymentUrl = iframeUrl });
            }
            else
            {
                return BadRequest(result.Reason);
            }
        }
    }

    public class PaymentRequest
    {
        public string Email { get; set; }
        public string StationTitle { get; set; }
        public double Amount { get; set; }
        public string? UserIp { get; set; }
    }

    public class PayTRResponse
    {
        [JsonProperty("status")]
        public string Status { get; set; }

        [JsonProperty("token")]
        public string Token { get; set; }

        [JsonProperty("reason")]
        public string Reason { get; set; }
    }
}
