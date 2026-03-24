export const useCoins = () => {
  const formatCoins = (input: number | string): string => {
    // Zahl sicher parsen
    const value = typeof input === "string" ? parseInt(input, 10) : input;
    if (isNaN(value)) return "0";

    if (value >= 1_000_000) {
      return `${(value / 1_000_000).toFixed(1).replace(/\.0$/, "")} Mio`;
    }
    if (value >= 10_000) {
      return `${Math.floor(value / 1_000)}k`;
    }
    return value.toLocaleString();
  };

  return { formatCoins };
};
