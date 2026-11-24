// Sidebar colors (SPEC §4.6 Sidebar): the background, the selected row and
// its bar, the status dots, and a heading color per host and folder. Text
// on a chosen color is black, white only where black misses the minimum
// contrast (WCAG: 4.5:1, or the higher one set in Appearance).

// expand turns #rgb into #rrggbb; null when s is not a color.
export function expand(s) {
    if (typeof s !== 'string') return null;
    if (/^#[0-9a-f]{6}$/i.test(s)) return s.toLowerCase();
    if (/^#[0-9a-f]{3}$/i.test(s)) return '#' + [...s.slice(1)].map(c => c + c).join('').toLowerCase();
    return null;
}

// luminance is the WCAG relative luminance of a color.
export function luminance(hex) {
    const c = expand(hex);
    const [r, g, b] = [1, 3, 5].map(i => {
        const v = parseInt(c.slice(i, i + 2), 16) / 255;
        return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
    });
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

// contrast is the WCAG contrast ratio of two colors (1 to 21).
export function contrast(a, b) {
    const [x, y] = [luminance(a), luminance(b)].sort((p, q) => q - p);
    return (x + 0.05) / (y + 0.05);
}

// minText is the contrast text needs: 4.5, or the Appearance minimum when
// higher.
export function minText(ui) {
    return Math.min(21, Math.max(4.5, Number(ui?.min_contrast) || 0));
}

// textOn is the text color for a background: black when it reaches min,
// else white when that is better.
export function textOn(bg, min = 4.5) {
    const black = contrast(bg, '#000000');
    if (black >= min) return '#000000';
    return contrast(bg, '#ffffff') > black ? '#ffffff' : '#000000';
}

const TEXT_VARS = ['--text', '--text-strong', '--muted', '--faint'];

// paint sets a background and its text color on an element (its children
// use the text variables); a missing color leaves the theme's.
export function paint(e, color, min) {
    const c = expand(color);
    for (const v of ['background', ...TEXT_VARS]) e.style.removeProperty(v);
    e.style.removeProperty('color');
    if (!c) return;
    const fg = textOn(c, min);
    e.style.background = c;
    e.style.color = fg;
    for (const v of TEXT_VARS) e.style.setProperty(v, fg);
}

// DOTS maps the settings to the CSS variables of the dots.
export const DOTS = {dot_idle: '--dot-idle', dot_connected: '--dot-connected', dot_exited: '--dot-exited', dot_error: '--dot-error'};

// applySidebarColors sets the sidebar's background (with its text), the
// selected row (with its text) and bar, and the dots (also in the quick
// switcher) from ui; unset ones are the theme's.
export function applySidebarColors(ui, sidebar, root = document.documentElement) {
    const min = minText(ui);
    paint(sidebar, ui.sidebar_bg, min);
    const bg = expand(ui.sidebar_bg);
    // The hover tint of the theme would not suit the text on another
    // background: none then.
    for (const v of ['--panel', '--panel-2']) {
        if (bg) sidebar.style.setProperty(v, bg);
        else sidebar.style.removeProperty(v);
    }
    // The selected row keeps its own text color: on the chosen color, or on
    // the theme's when only the background was chosen.
    const sel = expand(ui.sidebar_selected) ??
        (bg ? expand(getComputedStyle(root).getPropertyValue('--focus-selected').trim()) : null);
    for (const [v, val] of [['--focus-selected', expand(ui.sidebar_selected)], ['--selected-text', sel && textOn(sel, min)],
        ['--selected-bar', expand(ui.sidebar_selected_bar)]]) {
        if (val) sidebar.style.setProperty(v, val);
        else sidebar.style.removeProperty(v);
    }
    for (const [k, v] of Object.entries(DOTS)) {
        if (expand(ui[k])) root.style.setProperty(v, expand(ui[k]));
        else root.style.removeProperty(v);
    }
}

// dotWarnings names the dots that do not stand out from bg (below 3:1, the
// WCAG minimum for a graphic).
export function dotWarnings(dots, bg) {
    const b = expand(bg);
    if (!b) return [];
    return Object.entries(dots).filter(([, c]) => expand(c) && contrast(c, b) < 3).map(([k]) => k);
}
