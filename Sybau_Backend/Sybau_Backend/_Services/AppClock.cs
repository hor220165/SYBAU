namespace Sybau_Backend._Services;

public static class AppClock
{
    private const string AppTimeZoneId = "Europe/Vienna";

    public static DateOnly Today => DateOnly.FromDateTime(Now);

    public static DateTime Now
    {
        get
        {
            try
            {
                var timeZone = TimeZoneInfo.FindSystemTimeZoneById(AppTimeZoneId);
                return TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timeZone);
            }
            catch (TimeZoneNotFoundException)
            {
                return DateTime.UtcNow;
            }
            catch (InvalidTimeZoneException)
            {
                return DateTime.UtcNow;
            }
        }
    }
}
