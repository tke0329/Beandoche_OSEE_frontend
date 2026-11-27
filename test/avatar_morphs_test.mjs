import test from 'node:test';
import assert from 'node:assert/strict';
import { solveMorphs } from '../web/viewer/avatar-morphs.js';

// Synthetic calibration to exercise coupling without storing private model data.
const profile = {
    measurements: {
        heightMm: { base: 1600, keys: { Leg_Length: [-1, -100, 1, 100] } },
        inseamMm: { base: 700, keys: { Leg_Length: [-1, -90, 1, 90] } },
        chestCircumferenceMm: {
            base: 900,
            keys: { Chest: [-1, -100, 1, 100] },
        },
        waistCircumferenceMm: {
            base: 700,
            keys: { Waist: [-1, -100, 1, 100], Weight: [-0.5, -30, 1, 60] },
        },
        hipCircumferenceMm: {
            base: 900,
            keys: {
                Hips: [-1, -100, 1, 100],
                Leg_Thickness: [-0.5, -40, 1, 80],
            },
        },
        thighCircumferenceMm: {
            base: 500,
            keys: {
                Leg_Thickness: [-0.5, -50, 1, 100],
                Hips: [-1, -10, 1, 10],
            },
        },
    },
};

test('t1 maintains the 70 kg base and fits signed girth targets', () => {
    const { influences, limited } = solveMorphs(profile, 1600, 70, {
        chestCircumferenceMm: 850,
        waistCircumferenceMm: 760,
    });
    assert.equal(influences.Weight, 0);
    assert.equal(influences.Chest, -0.5);
    assert.equal(influences.Waist, 0.6);
    assert.equal(limited, false);
});

test('t2 accounts for weight and linked hip and thigh changes', () => {
    const { influences, limited } = solveMorphs(profile, 1600, 100, {
        waistCircumferenceMm: 700,
        hipCircumferenceMm: 950,
        thighCircumferenceMm: 540,
    });
    assert.ok(influences.Weight > 0);
    assert.ok(influences.Waist < 0);
    assert.ok(influences.Hips > 0);
    assert.ok(influences.Leg_Thickness > 0);
    assert.equal(limited, false);
});

test('t3 fits inseam relative to requested height and clamps impossible inputs', () => {
    const result = solveMorphs(profile, 1700, null, { inseamMm: 790 });
    assert.equal(result.height, 1700);
    assert.equal(result.influences.Leg_Length, 1);
    assert.equal(result.limited, false);
    for (const [input, limit] of [
        [9999, 1],
        [1, -1],
    ]) {
        const clamped = solveMorphs(profile, 1700, null, { inseamMm: input });
        assert.equal(clamped.influences.Leg_Length, limit);
        assert.equal(clamped.limited, true);
    }
});
