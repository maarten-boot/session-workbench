// SPEC §4.6 Sidebar: colors, contrast and the text color on them.
import test from 'node:test';
import assert from 'node:assert/strict';
import {contrast, dotWarnings, expand, minText, textOn} from './sidebarcolors.js';

test('expand reads #rgb and #rrggbb', () => {
    assert.equal(expand('#ABC'), '#aabbcc');
    assert.equal(expand('#1E8E3E'), '#1e8e3e');
    for (const bad of ['', 'abc', '#abcd', 'red', null, undefined]) assert.equal(expand(bad), null, String(bad));
});

test('contrast: the WCAG ratios', () => {
    assert.equal(Math.round(contrast('#000', '#fff')), 21);
    assert.equal(contrast('#777', '#777'), 1);
    assert.ok(Math.abs(contrast('#767676', '#ffffff') - 4.54) < 0.01);
});

test('textOn: black unless it misses the minimum', () => {
    assert.equal(textOn('#ffffff'), '#000000');
    assert.equal(textOn('#ffe0e0'), '#000000');
    assert.equal(textOn('#000080'), '#ffffff');
    assert.equal(textOn('#1e1e1e'), '#ffffff');
    // Mid grey: black reaches 4.5, white does not.
    assert.equal(textOn('#777777'), '#000000');
    // With a 7:1 minimum black misses on #777 and white is no better: black.
    assert.equal(textOn('#777777', 7), '#000000');
    assert.equal(textOn('#5a5a5a', 7), '#ffffff');
    // Whatever the background, the chosen text reaches 4.5:1.
    for (let v = 0; v < 256; v += 5) {
        const h = v.toString(16).padStart(2, '0');
        const bg = `#${h}${h}${h}`;
        assert.ok(contrast(bg, textOn(bg)) >= 4.5, bg);
    }
});

test('minText: 4.5, or a higher Appearance minimum', () => {
    assert.equal(minText({}), 4.5);
    assert.equal(minText({min_contrast: 3}), 4.5);
    assert.equal(minText({min_contrast: 7}), 7);
    assert.equal(minText({min_contrast: 99}), 21);
});

test('dotWarnings: dots below 3:1 against the background', () => {
    assert.deepEqual(dotWarnings({dot_idle: '#eeeeee', dot_connected: '#1e8e3e', dot_error: ''}, '#ffffff'), ['dot_idle']);
    assert.deepEqual(dotWarnings({dot_idle: '#eeeeee'}, ''), []);
});
