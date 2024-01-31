export type GetQuantoPnlArgs = {
  baseAssetStartPrice: number;
  baseAssetEndPrice: number;
  quantoAssetStartPrice: number;
  quantoAssetEndPrice: number;
  baseAssetSizeDelta: number;
};

export const getQuantoPnl = ({
  baseAssetStartPrice,
  baseAssetEndPrice,
  quantoAssetStartPrice,
  quantoAssetEndPrice,
  baseAssetSizeDelta,
}: GetQuantoPnlArgs): number => {
  const baseAssetPriceChange = baseAssetEndPrice - baseAssetStartPrice;
  const quantoMultiplier = quantoAssetEndPrice / quantoAssetStartPrice;
  return baseAssetPriceChange * baseAssetSizeDelta * quantoMultiplier;
};