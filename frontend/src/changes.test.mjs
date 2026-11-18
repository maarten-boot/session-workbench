// SPEC §4.6 About: the list of changes per release, and when the app
// points at it after an update.
import test from 'node:test';
import assert from 'node:assert/strict';
import {newVersion, parseChanges, released} from './changes.js';

test('parseChanges: headings and items, other lines left out', () => {
    const text = '## Since v1.1.23 (not released)\r\n- Cross-check\r\n\r\n' +
        '## v1.1.23 (2026-11-17)\n- Copy image\n- Cross-check v1.1.22\nnoise\n  - indented\n';
    assert.deepEqual(parseChanges(text), [
        {title: 'Since v1.1.23 (not released)', items: ['Cross-check']},
        {title: 'v1.1.23 (2026-11-17)', items: ['Copy image', 'Cross-check v1.1.22']},
    ]);
});

test('parseChanges: items before a heading, empty text, an HTML 404 page', () => {
    assert.deepEqual(parseChanges('- orphan\n## v1\n'), [{title: 'v1', items: []}]);
    assert.deepEqual(parseChanges(''), []);
    assert.deepEqual(parseChanges(undefined), []);
    assert.deepEqual(parseChanges('<!doctype html><title>404</title>'), []);
});

test('released: only a tag build', () => {
    assert.equal(released('v1.1.24'), true);
    assert.equal(released('v1.1.23-1-g9fb5353'), false);
    assert.equal(released('v1.1.24-dirty'), false);
    assert.equal(released('dev'), false);
    assert.equal(released(undefined), false);
});

test('newVersion: once per release, never for other builds', () => {
    assert.equal(newVersion('v1.1.24', 'v1.1.23'), true);
    assert.equal(newVersion('v1.1.24', undefined), true);
    assert.equal(newVersion('v1.1.24', 'v1.1.24'), false);
    assert.equal(newVersion('v1.1.24-2-gabc', 'v1.1.23'), false);
    assert.equal(newVersion('dev', undefined), false);
});
