import test from 'node:test';
import assert from 'node:assert/strict';
import {STATES, keepKnown, matches, parseTags, sessionTags, tagCounts, toggleTag} from './tags.js';

test('the dialog text becomes tags', () => {
    assert.deepEqual(parseTags(' client-x, go,, Go , urgent ,'), ['client-x', 'go', 'urgent']);
    assert.deepEqual(parseTags(''), []);
    assert.deepEqual(parseTags(undefined), []);
});

const webshop = {name: 'webshop', host: 'agent-vm', group: 'Work', tags: ['client-x', 'urgent']};
const api = {name: 'api', host: 'agent-vm', group: 'Work', tags: ['client-x', 'go']};
const blog = {name: 'blog', host: 'home-box', group: '', tags: ['go', 'work'], inactive: true};

test('the host and the folder are tags too', () => {
    assert.deepEqual(sessionTags(webshop), [{tag: 'client-x', from: ''}, {tag: 'urgent', from: ''},
        {tag: 'agent-vm', from: 'host'}, {tag: 'Work', from: 'folder'}, {tag: 'active', from: 'state'}]);
    // An own tag that is also the folder is listed once, as its own.
    assert.deepEqual(sessionTags({host: 'h', group: 'Work', tags: ['work']}).map(t => t.tag), ['work', 'h', 'active']);
    assert.deepEqual(sessionTags({host: 'h'}), [{tag: 'h', from: 'host'}, {tag: 'active', from: 'state'}]);
});

test('the state is a tag too', () => {
    const tags = (d, st) => sessionTags(d, st).filter(t => t.from === 'state').map(t => t.tag);
    assert.deepEqual(tags(blog), ['inactive']);
    assert.deepEqual(tags({host: 'boxes', files: 'container'}), ['active', 'container']);
    assert.deepEqual(tags({host: 'jump', plain: true, inactive: true}), ['inactive', 'login']);
    assert.deepEqual(tags(webshop, {stopped: true, todo: true, warning: true}), ['active', 'stopped', 'todo', 'warning']);
    assert.deepEqual(tags(webshop, {todo: false}), ['active']);
    for (const t of ['active', 'inactive', 'container', 'login', 'stopped', 'todo', 'warning']) assert.ok(STATES[t], t);
});

test('every tag with its count, by name', () => {
    assert.deepEqual(tagCounts([webshop, api, blog]).map(c => `${c.tag} ${c.count}`),
        ['active 2', 'agent-vm 2', 'client-x 2', 'go 2', 'home-box 1', 'inactive 1', 'urgent 1', 'Work 3']);
    // The state comes from the app: here webshop has a TODO.
    const st = d => ({todo: d === webshop});
    assert.deepEqual(tagCounts([webshop, api], st).filter(c => c.tag === 'todo'), [{tag: 'todo', count: 1, from: 'state'}]);
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
    assert.deepEqual(names(['go', 'inactive']), ['blog']); // the state counts
    assert.deepEqual(names(['client-x', 'inactive'], true), ['webshop', 'api', 'blog']);
    assert.deepEqual(all.filter(d => matches(d, ['todo'], false, {todo: d === api})).map(d => d.name), ['api']);
});

test('the stored selection', () => {
    assert.deepEqual(keepKnown(['go', 'gone', 'URGENT'], tagCounts([webshop, api])), ['go', 'URGENT']);
    assert.deepEqual(toggleTag(['go'], 'urgent'), ['go', 'urgent']);
    assert.deepEqual(toggleTag(['go', 'urgent'], 'GO'), ['urgent']);
    assert.deepEqual(toggleTag(undefined, 'go'), ['go']);
});
