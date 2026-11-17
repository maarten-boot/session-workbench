import test from 'node:test';
import assert from 'node:assert/strict';
import {MAX, osc52Text} from './osc52.js';

const b64 = s => Buffer.from(s, 'utf8').toString('base64');

test('a program puts text on the clipboard', () => {
    assert.equal(osc52Text('c;' + b64('hello')), 'hello');
    assert.equal(osc52Text(';' + b64('no target')), 'no target'); // tmux sends an empty target
    assert.equal(osc52Text('pc;' + b64('ëmoji 🙂\nline 2')), 'ëmoji 🙂\nline 2');
});

test('reads and broken requests are ignored', () => {
    assert.equal(osc52Text('c;?'), null); // read the clipboard: never
    assert.equal(osc52Text('c;'), null);
    assert.equal(osc52Text('c'), null);
    assert.equal(osc52Text('c;not base64!'), null);
    assert.equal(osc52Text('c;' + Buffer.from([0xff, 0xfe]).toString('base64')), null); // not UTF-8
    assert.equal(osc52Text('c;' + 'A'.repeat(MAX + 4)), null);
});
