import test from 'node:test';
import assert from 'node:assert/strict';
import { getOrderingDayDisabledState } from './orderingDay.js';

test('disables ordering when today is not an ordering day', () => {
    assert.equal(
        getOrderingDayDisabledState({
            isOrderingDayAllowed: false,
        }),
        true
    );
});

test('keeps ordering enabled when today is an ordering day', () => {
    assert.equal(
        getOrderingDayDisabledState({
            isOrderingDayAllowed: true,
        }),
        false
    );
});
