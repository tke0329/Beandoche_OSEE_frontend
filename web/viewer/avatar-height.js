/** Uniform scale for a glTF body, preserving its proportions and grounding its feet. */
export function heightTransform(baseMinY, baseHeight, heightMm) {
    if (
        !Number.isFinite(baseMinY) ||
        !Number.isFinite(baseHeight) ||
        baseHeight <= 0
    ) {
        throw new RangeError('Invalid avatar bounds');
    }
    if (
        heightMm !== null &&
        (!Number.isSafeInteger(heightMm) ||
            heightMm <= 0 ||
            heightMm > 999999999)
    ) {
        throw new RangeError('Invalid avatar height');
    }
    const scale = heightMm === null ? 1 : heightMm / 1000 / baseHeight;
    return { scale, offsetY: -baseMinY * scale };
}
