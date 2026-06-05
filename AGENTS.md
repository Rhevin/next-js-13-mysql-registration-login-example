# AGENTS.md

## Stack
- Next.js 15 (pages router)
- MySQL + Sequelize ORM
- JWT auth (jsonwebtoken + express-jwt)
- React Hook Form + Yup validation
- Bootstrap (CDN, loaded in `pages/_document.js`)

## Run
No npm locally. Use Docker:
```sh
docker run --rm -v "$(pwd)":/app -w /app node:20-alpine npm <command>
```

## Commands
```sh
npm run dev     # start dev server
npm run build   # production build
npm run lint    # ESLint
npm test        # Jest (--passWithNoTests)
```

## Env
Copy `.env.example` to `.env.local` and fill in values. Never commit `.env.local`.

| Variable | Used in |
|---|---|
| `DB_HOST/PORT/USER/PASSWORD/NAME` | `helpers/api/db.js` |
| `JWT_SECRET` | `helpers/api/jwt-middleware.js`, `helpers/api/users-repo.js` |
| `NEXT_PUBLIC_API_URL` | `helpers/fetch-wrapper.js`, `services/user.service.js` |

## Structure
```
pages/
  api/users/        # REST API routes (Next.js API handlers)
  account/          # login, register pages
  users/            # user list, add, edit pages
helpers/
  api/              # server-only: db, jwt, users-repo, api-handler
  fetch-wrapper.js  # client-side HTTP with auth header
services/
  user.service.js   # RxJS BehaviorSubject, wraps fetch-wrapper
  alert.service.js  # global alert state
components/         # shared UI components
```

## Import aliases
All imports are relative to project root (no `../../`). Example:
```js
import { userService } from 'services';
import { fetchWrapper } from 'helpers';
```

## Auth flow
1. POST `/api/users/authenticate` → returns JWT
2. JWT stored in `localStorage`
3. `fetchWrapper` adds `Authorization: Bearer <token>` to every API request
4. `jwt-middleware.js` validates token server-side (public routes exempt)

## CI
GitHub Actions runs lint + test on every push/PR to `master` (`.github/workflows/ci.yml`).
Dependabot auto-updates npm deps weekly.

## Rules
- Server-only code lives in `helpers/api/` — never import it from pages or components
- Use `process.env.*` for config — do NOT use `next/config`
- Validate `returnUrl` before redirecting (must start with `/`, not `//`)
- Run `npm audit` after dependency changes — 0 vulnerabilities required
