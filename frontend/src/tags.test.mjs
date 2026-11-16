import test from 'node:test';
import assert from 'node:assert/strict';
import {keepKnown, matches, parseTags, sessionTags, tagCounts, toggleTag} from './tags.js';

test('the dialog text becomes tags', () => {
    assert.deepEqual(parseTags(' client-x, go,, Go , urgent ,'), ['client-x', 'go', 'urgent']);
    assert.deepEqual(parseTags(''), []);
    assert.deepEqual(parseTags(undefined), []);
});

const webshop = {name: 'webshop', host: 'agent-vm', group: 'Work', tags: ['client-x', 'urgent']};
const api = {name: 'api', host: 'agent-vm', group: 'Work', tags: ['client-x', 'go']};
const blog = {name: 'blog', host: 'home-box', group: '', tags: ['go', 'work']};

test('the host and the folder are tags too', () => {
    assert.deepEqual(sessionTags(webshop), [{tag: 'client-x', from: ''}, {tag: 'urgent', from: ''},
        {tag: 'agent-vm', from: 'host'}, {tag: 'Work', from: 'folder'}]);
    // An own tag that is also the folder is listed once, as its own.
    assert.deepEqual(sessionTags({host: 'h', group: 'Work', tags: ['work']}).map(t => t.tag), ['work', 'h']);
    assert.deepEqual(sessionTags({host: 'h'}), [{tag: 'h', from: 'host'}]);
});

test('every tag with its count, by name', () => {
    assert.deepEqual(tagCounts([webshop, api, blog]).map(c => `${c.tag} ${c.count}`),
        ['agent-vm 2', 'client-x 2', 'go 2', 'home-box 1', 'urgent 1', 'Work 3']);
});

test('all of the selected tags, or any', () => {
    const all = [webshop, api, blog];
    const names = (sel, any) => all.filter(d => matches(d, sel, any)).map(d => d.name);
    assert.deepEqual(names([]), ['webshop', 'api', 'blog']);
    assert.deepEqual(names(['client-x']), ['webshop', 'api']);
    assert.deepEqual(names(['client-x', 'URGENT']), ['webshop']); // narrowing, ignoring case
    assert.deepEqual(names(['urgent', 'go']), []);
    assert.deepEqual(names(['urgent', 'go'], true), ['webshop', 'api', 'blog']);
    assert.deepEqual(names(['agent-vm', 'go']), ['api']); // the host counts
    assert.deepEqual(names(['work']), ['webshop', 'api', 'blog']); // folder Work and the own tag work
});

test('the stored selection', () => {
    assert.deepEqual(keepKnown(['go', 'gone', 'URGENT'], tagCounts([webshop, api])), ['go', 'URGENT']);
    assert.deepEqual(toggleTag(['go'], 'urgent'), ['go', 'urgent']);
    assert.deepEqual(toggleTag(['go', 'urgent'], 'GO'), ['urgent']);
    assert.deepEqual(toggleTag(undefined, 'go'), ['go']);
});
