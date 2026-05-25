using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace Sybau_Backend.Validation;

public static partial class AuthValidation
{
    public const int MinPasswordLength = 8;
    public const int MaxPasswordLength = 128;
    public const string PasswordPolicyMessage =
        "Passwort muss mindestens 8 Zeichen lang sein und Großbuchstaben, Kleinbuchstaben, Zahl und Sonderzeichen enthalten.";

    private static readonly HashSet<string> DisposableEmailDomains = new(StringComparer.OrdinalIgnoreCase)
    {
        "10minutemail.com",
        "dispostable.com",
        "emailondeck.com",
        "fakeinbox.com",
        "getnada.com",
        "grr.la",
        "guerrillamail.com",
        "mail.tm",
        "maildrop.cc",
        "mailinator.com",
        "moakt.com",
        "mytemp.email",
        "sharklasers.com",
        "tempmail.com",
        "temp-mail.org",
        "tempr.email",
        "throwawaymail.com",
        "tmail.io",
        "trashmail.com",
        "yopmail.com"
    };

    public static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();

    public static bool HasValidEmailShape(string email)
    {
        var normalized = NormalizeEmail(email);
        return EmailRegex().IsMatch(normalized);
    }

    public static bool IsDisposableEmail(string email)
    {
        var domain = NormalizeEmail(email).Split('@').LastOrDefault() ?? string.Empty;
        return DisposableEmailDomains.Any(blocked =>
            string.Equals(domain, blocked, StringComparison.OrdinalIgnoreCase) ||
            domain.EndsWith($".{blocked}", StringComparison.OrdinalIgnoreCase));
    }

    public static bool IsStrongPassword(string password)
    {
        return password.Length is >= MinPasswordLength and <= MaxPasswordLength
            && password.Any(char.IsLower)
            && password.Any(char.IsUpper)
            && password.Any(char.IsDigit)
            && password.Any(ch => !char.IsLetterOrDigit(ch));
    }

    [GeneratedRegex(@"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)]
    private static partial Regex EmailRegex();
}

public sealed class NotDisposableEmailAttribute : ValidationAttribute
{
    public NotDisposableEmailAttribute()
    {
        ErrorMessage = "Temporäre E-Mail-Adressen sind nicht erlaubt.";
    }

    public override bool IsValid(object? value)
    {
        if (value is not string email || string.IsNullOrWhiteSpace(email)) return true;
        return AuthValidation.HasValidEmailShape(email) && !AuthValidation.IsDisposableEmail(email);
    }
}

public sealed class StrongPasswordAttribute : ValidationAttribute
{
    public StrongPasswordAttribute()
    {
        ErrorMessage = AuthValidation.PasswordPolicyMessage;
    }

    public override bool IsValid(object? value)
    {
        if (value is not string password || string.IsNullOrWhiteSpace(password)) return false;
        return AuthValidation.IsStrongPassword(password);
    }
}
