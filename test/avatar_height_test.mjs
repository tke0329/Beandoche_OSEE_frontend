import test from 'node:test';
import assert from 'node:assert/strict';
import { heightTransform } from '../web/viewer/avatar-height.js';

test('t1 measured model heights normalize to requested millimetres without changing proportions', () => {
    for (const baseHeight of [1.65, 5.51536417]) {
        for (const requestedMm of [1500, 1650, 1800, 2000]) {
            const result = heightTransform(0.02, baseHeight, requestedMm);
            assert.ok(
                Math.abs(baseHeight * result.scale - requestedMm / 1000) <
                    1e-12,
            );
            assert.ok(Math.abs(0.02 * result.scale + result.offsetY) < 1e-12);
        }
    }
});

test('t2 repeated edits derive from the original geometry without accumulating scale', () => {
    const first = heightTransform(-0.3, 1.65, 1700);
    heightTransform(-0.3, 1.65, 2000);
    assert.deepEqual(heightTransform(-0.3, 1.65, 1700), first);
    assert.deepEqual(heightTransform(-0.3, 1.65, null), {
        scale: 1,
        offsetY: 0.3,
    });
});

test('t3 malformed sizes and degenerate model bounds are rejected', () => {
    for (const value of [
        0,
        -1,
        1650.5,
        '1650',
        undefined,
        NaN,
        Infinity,
        1000000000,
    ]) {
        assert.throws(() => heightTransform(0, 1.65, value), RangeError);
    }
    assert.throws(() => heightTransform(0, 0, 1650), RangeError);
    assert.throws(() => heightTransform(NaN, 1.65, 1650), RangeError);
});
