import test from 'node:test';
import assert from 'node:assert/strict';
import { widthScaleForWeight } from '../web/viewer/avatar-weight.js';

test('t1 70 kg and unset weight preserve the base model, with less or more width around the baseline', () => {
    assert.equal(widthScaleForWeight(null), 1);
    assert.equal(widthScaleForWeight(70), 1);
    assert.ok(widthScaleForWeight(50) < 1);
    assert.ok(widthScaleForWeight(100) > 1);
    assert.equal(widthScaleForWeight(70), 1);
});

test('t2 accepted extremes stay within visual bounds and invalid messages are rejected', () => {
    assert.equal(widthScaleForWeight(0.001), 0.75);
    assert.equal(widthScaleForWeight(99999.999), 1.3);
    for (const value of [0, -1, NaN, Infinity, '70', 100000]) {
        assert.throws(() => widthScaleForWeight(value), RangeError);
    }
});
