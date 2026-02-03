using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Sybau_Backend._Services;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;

namespace Sybau_Backend.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class ShopController : ControllerBase
    {
        private readonly ShopService _shopService;

        public ShopController(ShopService shopService)
        {
            _shopService = shopService;
        }

        [HttpGet("items")]
        public async Task<IActionResult> Get()
        {
            var items = await _shopService.GetItemsAsync();
            return Ok(items);
        }

        [HttpGet("items/{itemId}")]
        public async Task<IActionResult> GetItemById(int itemId)
        {
            var item = await _shopService.GetItemAsync(itemId);
            return Ok(item);
        }

        [HttpPost("items/add")]
        public async Task<IActionResult> AddItem([FromBody] ItemDto dto)
        {
            var item = await _shopService.AddItemAsync(dto);
            return Ok(item);
        }
        
        
        [HttpPost("{userId}/buy/{itemId}")]
        public async Task<IActionResult> BuyItem(int userId, int itemId)
        {
            var success = await _shopService.BuyItemAsync(userId, itemId);

            if (!success)
                return BadRequest("Not enough coins or item not found");

            return Ok();
        }

    }
}
