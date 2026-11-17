// D2 diagrams (SPEC N1c): ```d2 blocks in Notes and Q&A answers are drawn
// by the app (App.DrawD2) and shown as an <img> (an SVG loaded as an image
// runs no scripts and loads nothing).
import {CopyImage, DrawD2} from '../wailsjs/go/main/App';
import {toast} from './ui';
import {svgURL} from './qaparse';

// dark: the app's theme (dark unless set to light), so a diagram matches it.
export const dark = () => document.documentElement.dataset.theme !== 'light';

const cache = new Map(); // "dark|source" → Promise of {url} or {error}
const MAX = 64;

// drawD2 gives {url} (a data: URL of the SVG) or {error} (D2's message).
// The same text is drawn once (the last 64 kept).
export function drawD2(source) {
    const key = `${dark() ? 'd' : 'l'}|${source}`;
    let p = cache.get(key);
    if (p) {
        cache.delete(key); // most recently used last
    } else {
        p = DrawD2(source, dark()).then(svg => ({url: svgURL(svg)}), err => ({error: String(err?.message ?? err)}));
        if (cache.size >= MAX) cache.delete(cache.keys().next().value);
    }
    cache.set(key, p);
    return p;
}

// fillDiagram shows source's diagram in box: the picture, or "⚠ D2: …"
// with the error. The picture there stays until the new one is ready.
// onDone runs after the box changed (the editor measures again).
export async function fillDiagram(box, source, onDone) {
    box.dataset.source = source;
    if (!box.firstChild) box.append(Object.assign(document.createElement('div'), {className: 'd2-status', textContent: 'Drawing the diagram…'}));
    const r = await drawD2(source);
    if (box.dataset.source !== source) return; // the text changed meanwhile
    if (r.url) {
        const img = Object.assign(document.createElement('img'), {className: 'd2-picture', src: r.url, alt: 'D2 diagram'});
        img.onload = () => onDone?.();
        box.replaceChildren(img);
    } else {
        box.replaceChildren(Object.assign(document.createElement('div'), {className: 'd2-error', textContent: `⚠ D2: ${r.error}`}));
    }
    onDone?.();
}

// copyImage puts a picture (a D2 drawing, an SVG from an answer) on the
// clipboard as a PNG at twice its size, so it stays sharp when pasted;
// a picture without its own background gets the page's.
export async function copyImage(img) {
    try {
        await img.decode();
        const scale = 2;
        const w = img.naturalWidth || img.width, h = img.naturalHeight || img.height;
        if (!w || !h) throw new Error('the picture has no size');
        const canvas = Object.assign(document.createElement('canvas'), {width: w * scale, height: h * scale});
        const g = canvas.getContext('2d');
        const bg = getComputedStyle(img).backgroundColor;
        g.fillStyle = bg && bg !== 'rgba(0, 0, 0, 0)' ? bg : getComputedStyle(document.body).backgroundColor;
        g.fillRect(0, 0, canvas.width, canvas.height);
        g.drawImage(img, 0, 0, canvas.width, canvas.height);
        await CopyImage(canvas.toDataURL('image/png').split(',')[1]);
        toast('Image copied');
    } catch (err) {
        toast(`The image was not copied: ${err?.message ?? err}`, true);
    }
}
