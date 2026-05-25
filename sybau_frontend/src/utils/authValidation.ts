export const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/i;

const disposableEmailDomains = new Set([
  '10minutemail.com',
  'dispostable.com',
  'emailondeck.com',
  'fakeinbox.com',
  'getnada.com',
  'grr.la',
  'guerrillamail.com',
  'mail.tm',
  'maildrop.cc',
  'mailinator.com',
  'moakt.com',
  'mytemp.email',
  'sharklasers.com',
  'tempmail.com',
  'temp-mail.org',
  'tempr.email',
  'throwawaymail.com',
  'tmail.io',
  'trashmail.com',
  'yopmail.com',
]);

export const passwordRequirements = [
  { key: 'length', label: 'Mindestens 8 Zeichen', test: (value: string) => value.length >= 8 },
  { key: 'lower', label: 'Ein Kleinbuchstabe', test: (value: string) => /[a-z]/.test(value) },
  { key: 'upper', label: 'Ein Großbuchstabe', test: (value: string) => /[A-Z]/.test(value) },
  { key: 'number', label: 'Eine Zahl', test: (value: string) => /\d/.test(value) },
  { key: 'special', label: 'Ein Sonderzeichen', test: (value: string) => /[^A-Za-z0-9]/.test(value) },
];

export function normalizeEmail(value: string) {
  return value.trim().toLowerCase();
}

export function isDisposableEmail(value: string) {
  const domain = normalizeEmail(value).split('@')[1] ?? '';
  return [...disposableEmailDomains].some((blockedDomain) =>
    domain === blockedDomain || domain.endsWith(`.${blockedDomain}`),
  );
}

export function validateEmail(value: string, options: { required?: boolean; blockDisposable?: boolean } = {}) {
  const email = normalizeEmail(value);
  if (!email) return options.required === false ? '' : 'Bitte gib eine E-Mail-Adresse ein.';
  if (!emailRegex.test(email)) return 'Bitte gib eine gültige E-Mail-Adresse ein.';
  if (options.blockDisposable && isDisposableEmail(email)) {
    return 'Temporäre E-Mail-Adressen sind nicht erlaubt.';
  }
  return '';
}

export function getPasswordRequirementStates(value: string) {
  return passwordRequirements.map((requirement) => ({
    ...requirement,
    valid: requirement.test(value),
  }));
}

export function validatePassword(
  value: string,
  options: { required?: boolean; requireStrength?: boolean } = {},
) {
  if (!value) return options.required === false ? '' : 'Bitte gib ein Passwort ein.';
  if (!options.requireStrength) return '';

  const failedRequirement = passwordRequirements.find((requirement) => !requirement.test(value));
  if (failedRequirement) return 'Das Passwort erfüllt noch nicht alle Anforderungen.';
  if (value.length > 128) return 'Das Passwort darf maximal 128 Zeichen lang sein.';
  return '';
}
