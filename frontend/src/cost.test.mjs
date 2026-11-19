import {test} from 'node:test';
import assert from 'node:assert/strict';
import {age, costParts, costRows, costText, dollars, nextCostSort, sortCostRows, sessionCost, usageText, used, warnings} from './cost.js';

test('dollars', () => {
    assert.equal(dollars(0), '$0.00');
    assert.equal(dollars(0.425), '$0.43');
    assert.equal(dollars(1234.5), '$1,234.50');
    assert.equal(dollars(undefined), '$0.00');
});

test('costText', () => {
    const c = costText({today: 4.12, total: 87.3, unpriced: [], since: ''});
    assert.equal(c.text, 'today $4.12 · total $87.30');
    assert.match(c.title, /API prices/);
    assert.doesNotMatch(c.title, /No price/);
    const u = costText({today: 1, total: 2, unpriced: ['claude-new-9'], today_partial: true, total_partial: true, since: '2026-11-10 09:00'});
    assert.equal(u.text, 'today ≥ $1.00 · total ≥ $2.00');
    // After a reset the total may have no reply of the unpriced model.
    assert.equal(costText({today: 1, total: 0, unpriced: ['x'], today_partial: true}).text, 'today ≥ $1.00 · total $0.00');
    assert.match(u.title, /claude-new-9/);
    assert.match(u.title, /from 2026-11-10 09:00/);
});

const NOW = 1_800_000_000;
const usage = {five_hour: {used: 23.7, resets_at: NOW + 3600}, seven_day: {used: 41.2, resets_at: NOW + 86400 * 3}, at: NOW - 30, host: 'agent'};

test('used and age', () => {
    assert.equal(used(null, NOW), null);
    assert.equal(used({used: 50, resets_at: NOW + 1}, NOW), 50);
    assert.equal(used({used: 50, resets_at: NOW - 1}, NOW), 0); // reset since
    assert.equal(age(10), 'just now');
    assert.equal(age(12 * 60), '12 min');
    assert.equal(age(3 * 3600), '3 h');
    assert.equal(age(3 * 86400), '3 days');
});

test('the figure with usage and warnings', () => {
    const s = {today: 12, total: 50, usage};
    let p = costParts(s, {}, NOW);
    assert.equal(p.text, 'today $12.00 · total $50.00 · 5h 23% · 7d 41%');
    assert.ok(p.parts.every(x => !x.warn));
    assert.match(p.title, /5-hour 23% \(resets .*\), 7-day 41%/);
    // Old data says how old.
    p = costParts({...s, usage: {...usage, at: NOW - 12 * 60}}, {}, NOW);
    assert.equal(p.text, 'today $12.00 · total $50.00 · 5h 23% · 7d 41% (12 min ago)');
    // Limits reached: those parts warn.
    const ui = {cost_daily_limit: 10, usage_5h_limit: 80, usage_7d_limit: 40};
    p = costParts(s, ui, NOW);
    assert.deepEqual(p.parts.map(x => x.warn), [true, false, false, true]);
    assert.deepEqual(warnings(s, ui, NOW), {daily: true, five: false, seven: true});
    assert.match(p.title, /above your limit of \$10\.00/);
    // 0 = no warning; a window that has reset is 0%.
    assert.deepEqual(warnings(s, {}, NOW), {daily: false, five: false, seven: false});
    const reset = {...usage, five_hour: {used: 95, resets_at: NOW - 5}};
    assert.equal(warnings({usage: reset}, {usage_5h_limit: 80}, NOW).five, false);
    assert.equal(costParts({usage: reset}, {}, NOW).parts[2].text, '5h 0%');
});

test('usageText', () => {
    assert.match(usageText(null, NOW), /none reported yet/);
    assert.match(usageText(usage, NOW), /^Subscription usage: 5-hour 23% \(resets \d\d:\d\d\), 7-day 41% \(resets \w+ \d\d:\d\d\) — reported just now on agent\.$/);
});

test('sessionCost', () => {
    assert.equal(sessionCost(undefined), '');
    assert.equal(sessionCost({today: 0, total: 0}), '');
    assert.equal(sessionCost({today: 0, total: 3.5}), 'Cost: today $0.00 · total $3.50');
});

test('costRows', () => {
    const {rows, sum} = costRows([{id: 'a', name: 'A', host: 'h'}, {id: 'b', name: 'B', host: 'h'}],
        {sessions: {a: {today: 1, total: 5, first: '2026-11-03'}}});
    assert.deepEqual(rows, [{name: 'A', host: 'h', first: '2026-11-03', today: 1, total: 5},
        {name: 'B', host: 'h', first: '', today: 0, total: 0}]);
    assert.deepEqual(sum, {today: 1, total: 5});
    // Before the first count (no summary yet): all empty.
    assert.deepEqual(costRows([{id: 'a', name: 'A', host: 'h'}], null).rows, [{name: 'A', host: 'h', first: '', today: 0, total: 0}]);
});

test('the Cost table sorts by the start day, sessions without one last', () => {
    const rows = [
        {name: 'none', first: '', today: 0, total: 0},
        {name: 'nov2', first: '2026-11-03', today: 0, total: 3},
        {name: 'oct', first: '2026-10-28', today: 0, total: 2},
        {name: 'nov', first: '2026-11-03', today: 0, total: 1},
    ];
    const names = sort => sortCostRows(rows, sort).map(r => r.name);
    assert.deepEqual(names({key: 'first'}), ['oct', 'nov', 'nov2', 'none']); // oldest first, equal days by name
    assert.deepEqual(names({key: 'first', desc: true}), ['nov', 'nov2', 'oct', 'none']); // newest first, still last
    assert.deepEqual(names({key: 'name'}), ['none', 'nov', 'nov2', 'oct']); // other columns as before
    assert.deepEqual(nextCostSort(undefined, 'first'), {key: 'first', desc: false});
});

test('the Cost table sorts by a column', () => {
    const rows = [
        {name: 'web10', host: 'b', today: 1, total: 5},
        {name: 'Api', host: 'a', today: 3, total: 5},
        {name: 'web9', host: 'b', today: 0, total: 9},
    ];
    const names = sort => sortCostRows(rows, sort).map(r => r.name);
    assert.deepEqual(names(undefined), ['web10', 'Api', 'web9']); // list order
    assert.deepEqual(names({key: 'name'}), ['Api', 'web9', 'web10']); // ignoring case, numbers as numbers
    assert.deepEqual(names({key: 'name', desc: true}), ['web10', 'web9', 'Api']);
    assert.deepEqual(names({key: 'host'}), ['Api', 'web9', 'web10']); // equal hosts by name
    assert.deepEqual(names({key: 'today', desc: true}), ['Api', 'web10', 'web9']);
    assert.deepEqual(names({key: 'total', desc: true}), ['web9', 'Api', 'web10']); // 5 and 5 by name
    assert.deepEqual(names({key: 'total'}), ['Api', 'web10', 'web9']);
    assert.deepEqual(names({key: 'gone'}), ['web10', 'Api', 'web9']);
    assert.equal(rows[0].name, 'web10'); // not changed
});

test('a click on a column heading', () => {
    assert.deepEqual(nextCostSort(undefined, 'name'), {key: 'name', desc: false});
    assert.deepEqual(nextCostSort({key: 'name', desc: false}, 'name'), {key: 'name', desc: true});
    assert.deepEqual(nextCostSort({key: 'name', desc: true}, 'total'), {key: 'total', desc: true});
    assert.deepEqual(nextCostSort({key: 'total', desc: true}, 'total'), {key: 'total', desc: false});
    assert.deepEqual(nextCostSort({key: 'host', desc: false}, 'nope'), {key: 'host', desc: false});
});
