using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sybau_Backend._Services;
using Sybau_Backend.DTOs;

namespace Sybau_Backend.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class ShopController : ControllerBase
    {
        private readonly ShopService _shopService;
        private readonly DataImageCache _imageCache;
        private readonly MediaStorageService _mediaStorage;
        private readonly ILogger<ShopController> _logger;

        public ShopController(
            ShopService shopService,
            DataImageCache imageCache,
            MediaStorageService mediaStorage,
            ILogger<ShopController> logger)
        {
            _shopService = shopService;
            _imageCache = imageCache;
            _mediaStorage = mediaStorage;
            _logger = logger;
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
            var item = await _shopService.GetItemDtoAsync(itemId);
            return item == null ? NotFound() : Ok(item);
        }

        [HttpGet("items/{itemId}/image")]
        public async Task<IActionResult> GetItemImage(int itemId)
        {
            var cacheKey = DataImageCache.ShopItemKey(itemId);
            if (_imageCache.TryGet(cacheKey, out var image))
            {
                return CachedImageResponse(image);
            }

            var imageUrl = await _shopService.GetItemImageUrlAsync(itemId);
            return ToImageResponse(imageUrl, cacheKey);
        }

        [HttpGet("daily")]
        public async Task<IActionResult> GetDailyShop()
        {
            var dailyShop = await _shopService.GetDailyShopAsync();
            return Ok(dailyShop);
        }

        [HttpGet("chests")]
        public async Task<IActionResult> GetChests()
        {
            var chests = await _shopService.GetChestsAsync();
            return Ok(chests);
        }

        [HttpGet("chests/{chestId}")]
        public async Task<IActionResult> GetChestById(int chestId)
        {
            var chest = await _shopService.GetChestAsync(chestId);
            return chest == null ? NotFound() : Ok(chest);
        }

        [HttpGet("chests/{chestId}/image")]
        public async Task<IActionResult> GetChestImage(int chestId)
        {
            var cacheKey = DataImageCache.ChestKey(chestId);
            if (_imageCache.TryGet(cacheKey, out var image))
            {
                return CachedImageResponse(image);
            }

            var imageUrl = await _shopService.GetChestImageUrlAsync(chestId);
            return ToImageResponse(imageUrl, cacheKey);
        }

        [Authorize]
        [HttpPost("chests/{chestId}/open")]
        public async Task<IActionResult> OpenChest(int chestId)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var (error, result) = await _shopService.OpenChestAsync(userId, chestId);
            if (error != null) return BadRequest(error);
            return Ok(result);
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPost("chests/add")]
        public async Task<IActionResult> AddChest([FromForm] ChestFormDto dto)
        {
            var image = ReadChestImage(dto);
            if (image == null || image.Length == 0)
                return BadRequest("Ein Bild ist fuer neue Chests Pflicht.");

            try
            {
                dto.ItemIds = ReadChestItemIds(dto);
                var imageUrl = await SaveShopUploadAsync(image, "chests");
                var chest = await _shopService.AddChestAsync(dto, imageUrl);
                return Ok(chest);
            }
            catch (ArgumentException e)
            {
                return BadRequest(e.Message);
            }
            catch (InvalidOperationException e)
            {
                return StorageUploadFailed(e);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPut("chests/{chestId}")]
        public async Task<IActionResult> UpdateChest(int chestId, [FromForm] ChestFormDto dto)
        {
            return await UpdateChestFromForm(chestId, dto);
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPost("chests/{chestId}/update")]
        public async Task<IActionResult> UpdateChestPost(int chestId, [FromForm] ChestFormDto dto)
        {
            return await UpdateChestFromForm(chestId, dto);
        }

        private async Task<IActionResult> UpdateChestFromForm(int chestId, ChestFormDto dto)
        {
            var existing = await _shopService.GetChestEntityAsync(chestId);
            if (existing == null) return NotFound();
            var previousImageUrl = existing.ImageUrl;

            try
            {
                dto.ItemIds = ReadChestItemIds(dto);
                string? imageUrl = null;
                var image = ReadChestImage(dto);
                if (image is { Length: > 0 })
                {
                    imageUrl = await SaveShopUploadAsync(image, "chests");
                }

                var chest = await _shopService.UpdateChestAsync(chestId, dto, imageUrl);
                if (chest == null) return NotFound();

                if (!string.IsNullOrWhiteSpace(imageUrl))
                {
                    _imageCache.Remove(DataImageCache.ChestKey(chestId));
                    await _mediaStorage.DeletePublicUrlAsync(previousImageUrl);
                }

                return Ok(chest);
            }
            catch (ArgumentException e)
            {
                return BadRequest(e.Message);
            }
            catch (InvalidOperationException e)
            {
                return StorageUploadFailed(e);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpDelete("chests/{chestId}")]
        public async Task<IActionResult> DeleteChest(int chestId)
        {
            var existing = await _shopService.GetChestEntityAsync(chestId);
            if (existing == null) return NotFound();

            var deleted = await _shopService.DeleteChestAsync(chestId);
            if (!deleted) return NotFound();

            _imageCache.Remove(DataImageCache.ChestKey(chestId));
            await _mediaStorage.DeletePublicUrlAsync(existing.ImageUrl);
            return NoContent();
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPost("items/add")]
        public async Task<IActionResult> AddItem([FromForm] ShopItemFormDto dto)
        {
            if (dto.Image == null || dto.Image.Length == 0)
                return BadRequest("Ein Bild ist fuer neue Shop-Items Pflicht.");

            try
            {
                var imageUrl = await SaveShopUploadAsync(dto.Image, "shop-items");
                var item = await _shopService.AddItemAsync(ToItemDto(dto, imageUrl));
                return Ok(item);
            }
            catch (ArgumentException e)
            {
                return BadRequest(e.Message);
            }
            catch (InvalidOperationException e)
            {
                return StorageUploadFailed(e);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPut("items/{itemId}")]
        public async Task<IActionResult> UpdateItem(int itemId, [FromForm] ShopItemFormDto dto)
        {
            return await UpdateItemFromForm(itemId, dto);
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPost("items/{itemId}/update")]
        public async Task<IActionResult> UpdateItemPost(int itemId, [FromForm] ShopItemFormDto dto)
        {
            return await UpdateItemFromForm(itemId, dto);
        }

        private async Task<IActionResult> UpdateItemFromForm(int itemId, ShopItemFormDto dto)
        {
            var existing = await _shopService.GetItemAsync(itemId);
            if (existing == null) return NotFound();
            var previousImageUrl = existing.ImageUrl;

            try
            {
                string? imageUrl = null;
                if (dto.Image is { Length: > 0 })
                {
                    imageUrl = await SaveShopUploadAsync(dto.Image, "shop-items");
                }

                var item = await _shopService.UpdateItemAsync(itemId, ToItemDto(dto, imageUrl));
                if (item == null) return NotFound();

                if (!string.IsNullOrWhiteSpace(imageUrl))
                {
                    _imageCache.Remove(DataImageCache.ShopItemKey(itemId));
                    await _mediaStorage.DeletePublicUrlAsync(previousImageUrl);
                }

                return Ok(item);
            }
            catch (ArgumentException e)
            {
                return BadRequest(e.Message);
            }
            catch (InvalidOperationException e)
            {
                return StorageUploadFailed(e);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpDelete("items/{itemId}")]
        public async Task<IActionResult> DeleteItem(int itemId)
        {
            var existing = await _shopService.GetItemAsync(itemId);
            if (existing == null) return NotFound();

            var deleted = await _shopService.DeleteItemAsync(itemId);
            if (!deleted) return NotFound();

            _imageCache.Remove(DataImageCache.ShopItemKey(itemId));
            await _mediaStorage.DeletePublicUrlAsync(existing.ImageUrl);
            return NoContent();
        }
        
        
        [HttpPost("buy-item/{itemId}")]
        [Authorize]
        public async Task<IActionResult> BuyItem(int itemId)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();
            
            var userId = int.Parse(userIdClaim);
            var result = await _shopService.BuyItemAsync(userId, itemId);
    
            if (result != null) return BadRequest(result);
            return Ok();
        }

        [HttpPost("real-money/{itemId}/start")]
        [Authorize]
        public async Task<IActionResult> StartRealMoneyPurchase(int itemId)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var result = await _shopService.StartRealMoneyPurchaseAsync(userId, itemId);
            return StatusCode(result.StatusCode, new { message = result.Message });
        }

        [HttpPost("sell-item/{itemId}")]
        [Authorize]
        public async Task<IActionResult> SellItem(int itemId, [FromBody] SellItemRequestDto? request)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var (error, result) = await _shopService.SellItemAsync(userId, itemId, request?.Quantity ?? 1);

            if (error != null) return BadRequest(error);
            return Ok(result);
        }

        private static ItemDto ToItemDto(ShopItemFormDto form, string? imageUrl)
        {
            return new ItemDto
            {
                Name = form.Name,
                Description = form.Description,
                Type = form.Type,
                Price = form.Price,
                RealMoneyPrice = form.RealMoneyPrice,
                XpBoostPercentage = form.XpBoostPercentage,
                CoinBoostPercentage = form.CoinBoostPercentage,
                Rarity = form.Rarity,
                MaxQuantity = form.MaxQuantity,
                ImageUrl = imageUrl
            };
        }

        private async Task<string> SaveShopUploadAsync(IFormFile image, string category)
        {
            var extension = Path.GetExtension(image.FileName);
            var allowedExtensions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                ".png",
                ".jpg",
                ".jpeg",
                ".webp",
                ".gif"
            };

            var hasImageContentType =
                !string.IsNullOrWhiteSpace(image.ContentType) &&
                image.ContentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase);
            var hasAllowedExtension = allowedExtensions.Contains(extension);

            if (!hasImageContentType && !hasAllowedExtension)
                throw new ArgumentException("Nur Bilddateien sind erlaubt.");

            return await _mediaStorage.SaveFormFileAsync(image, category, extension);
        }

        private ObjectResult StorageUploadFailed(Exception exception)
        {
            _logger.LogError(exception, "Could not save shop image to media storage.");
            return StatusCode(
                StatusCodes.Status502BadGateway,
                $"Bild konnte nicht in Supabase Storage gespeichert werden: {SanitizeStorageError(exception.Message)}");
        }

        private static string SanitizeStorageError(string message)
        {
            return string.IsNullOrWhiteSpace(message)
                ? "Bitte Render Environment Variables und den Storage-Bucket pruefen."
                : message.ReplaceLineEndings(" ");
        }

        private IActionResult ToImageResponse(string? imageUrl, string cacheKey)
        {
            if (string.IsNullOrWhiteSpace(imageUrl)) return NotFound();

            SetImageCacheHeaders();

            if (!imageUrl.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
            {
                if (Uri.TryCreate(imageUrl, UriKind.Absolute, out var absoluteUri) &&
                    (absoluteUri.Scheme == Uri.UriSchemeHttp || absoluteUri.Scheme == Uri.UriSchemeHttps))
                {
                    return Redirect(imageUrl);
                }

                var localPath = imageUrl.StartsWith("/", StringComparison.Ordinal)
                    ? imageUrl
                    : $"/{imageUrl}";
                if (localPath.StartsWith("//", StringComparison.Ordinal) ||
                    localPath.StartsWith("/\\", StringComparison.Ordinal))
                {
                    return BadRequest("Ungueltiger Bildpfad.");
                }

                return LocalRedirect(localPath);
            }

            if (!DataImageCache.TryDecodeDataImage(imageUrl, out var image, out var error) || image == null)
                return BadRequest(error);

            _imageCache.Set(cacheKey, image);
            return File(image.Bytes, image.ContentType);
        }

        private IActionResult CachedImageResponse(CachedDataImage image)
        {
            SetImageCacheHeaders();
            return File(image.Bytes, image.ContentType);
        }

        private void SetImageCacheHeaders()
        {
            Response.Headers.CacheControl = "public, max-age=31536000, immutable";
            Response.Headers.Remove("Pragma");
            Response.Headers.Remove("Expires");
        }

        private List<int> ReadChestItemIds(ChestFormDto dto)
        {
            var ids = dto.ItemIds?.Where(id => id > 0).ToList() ?? new List<int>();

            if (!Request.HasFormContentType) return ids.Distinct().ToList();

            foreach (var field in Request.Form)
            {
                if (!field.Key.StartsWith("itemIds", StringComparison.OrdinalIgnoreCase) &&
                    !field.Key.StartsWith("ItemIds", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                foreach (var rawValue in field.Value)
                {
                    if (int.TryParse(rawValue, out var id) && id > 0)
                    {
                        ids.Add(id);
                    }
                }
            }

            return ids.Distinct().ToList();
        }

        private IFormFile? ReadChestImage(ChestFormDto dto)
        {
            if (dto.Image is { Length: > 0 }) return dto.Image;
            if (!Request.HasFormContentType) return null;

            return Request.Form.Files.FirstOrDefault(file =>
                file.Length > 0 &&
                (file.Name.Equals("image", StringComparison.OrdinalIgnoreCase) ||
                 file.Name.Equals("Image", StringComparison.OrdinalIgnoreCase)));
        }
    }
}
