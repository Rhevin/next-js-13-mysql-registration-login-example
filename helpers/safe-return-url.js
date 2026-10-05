const DEFAULT_PATH = '/';

/**
 * Resolve a post-login redirect to a same-origin relative path only.
 * Rejects protocol-relative, absolute, and off-origin targets.
 */
export function safeReturnPath(returnUrlQuery, baseHref) {
    const raw = Array.isArray(returnUrlQuery) ? returnUrlQuery[0] : returnUrlQuery;
    if (typeof raw !== 'string' || raw.length === 0) {
        return DEFAULT_PATH;
    }

    const base =
        baseHref ??
        (typeof window !== 'undefined' ? window.location.href : 'http://localhost/');

    try {
        const resolved = new URL(raw, base);
        const baseOrigin = new URL(base).origin;
        if (resolved.origin !== baseOrigin) {
            return DEFAULT_PATH;
        }
        const path = `${resolved.pathname}${resolved.search}${resolved.hash}`;
        if (!path.startsWith('/') || path.startsWith('//')) {
            return DEFAULT_PATH;
        }
        return path;
    } catch {
        return DEFAULT_PATH;
    }
}
