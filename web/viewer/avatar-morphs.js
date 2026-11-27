import { widthScaleForWeight } from './avatar-weight.js';

const GIRTH_KEYS = {
    chestCircumferenceMm: 'Chest',
    waistCircumferenceMm: 'Waist',
    hipCircumferenceMm: 'Hips',
    thighCircumferenceMm: 'Leg_Thickness',
};

function delta([low, smaller, high, larger], influence) {
    return influence < 0
        ? (influence / low) * smaller
        : (influence / high) * larger;
}

function estimate(measurement, influences) {
    return Object.entries(measurement.keys).reduce(
        (size, [key, range]) => size + delta(range, influences[key] ?? 0),
        measurement.base,
    );
}

function fitGirth(measurement, key, target, influences) {
    const range = measurement.keys[key];
    const [lo, smaller, hi, larger] = range;
    const others =
        estimate(measurement, influences) - delta(range, influences[key]);
    const difference = target - others;
    if (difference < 0) return lo * Math.min(difference / smaller, 1);
    return hi * Math.min(difference / larger, 1);
}

export function solveMorphs(profile, heightMm, weightKg, dimensions) {
    const table = profile.measurements;
    const height = heightMm ?? table.heightMm.base;
    const width = widthScaleForWeight(weightKg);
    // Preserve the existing 70 kg reference and map each end to the source key range.
    const influences = {
        Weight: width < 1 ? (width - 1) / 0.5 : (width - 1) / 0.3,
        Chest: 0,
        Waist: 0,
        Hips: 0,
        Leg_Thickness: 0,
    };
    influences.Weight = Math.min(1, Math.max(-0.5, influences.Weight));
    const heightScale = height / table.heightMm.base;
    const fields = Object.entries(GIRTH_KEYS).filter(
        ([field]) => dimensions[field] !== undefined,
    );
    // Hip and thigh targets can affect each other. Refit using the CSV deltas.
    for (let pass = 0; pass < 8; pass++) {
        for (const [field, key] of fields) {
            influences[key] = fitGirth(
                table[field],
                key,
                dimensions[field] / heightScale,
                influences,
            );
        }
    }
    const limited = fields.some(
        ([field]) =>
            Math.abs(
                estimate(table[field], influences) * heightScale -
                    dimensions[field],
            ) > 5,
    );
    return { influences, height, limited };
}
