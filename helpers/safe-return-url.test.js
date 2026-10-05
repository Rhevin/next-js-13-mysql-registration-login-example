import { safeReturnPath } from './safe-return-url';

describe('safeReturnPath', () => {
    const baseHref = 'https://app.example.test/account/login';

    it('allows same-origin relative paths', () => {
        expect(safeReturnPath('/users', baseHref)).toBe('/users');
        expect(safeReturnPath('/users?tab=1', baseHref)).toBe('/users?tab=1');
    });

    it('rejects external and protocol-relative targets', () => {
        expect(safeReturnPath('https://evil.test/phish', baseHref)).toBe('/');
        expect(safeReturnPath('//evil.test/phish', baseHref)).toBe('/');
    });

    it('falls back for missing values', () => {
        expect(safeReturnPath(undefined, baseHref)).toBe('/');
        expect(safeReturnPath(['/users'], baseHref)).toBe('/users');
    });
});
