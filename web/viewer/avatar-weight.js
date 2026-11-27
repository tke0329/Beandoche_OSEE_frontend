const REFERENCE_WEIGHT_KG = 70;
const MIN_WIDTH_SCALE = 0.75;
export const MAX_WIDTH_SCALE = 1.3;

export function widthScaleForWeight(weightKg) {
    if (weightKg === null) return 1;
    if (!Number.isFinite(weightKg) || weightKg <= 0 || weightKg >= 100000) {
        throw new RangeError('Invalid avatar weight');
    }

    // Only width and depth change, so their product follows the weight ratio.
    const scale = Math.sqrt(weightKg / REFERENCE_WEIGHT_KG);
    return Math.min(MAX_WIDTH_SCALE, Math.max(MIN_WIDTH_SCALE, scale));
}
