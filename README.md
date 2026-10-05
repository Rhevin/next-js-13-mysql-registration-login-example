# next-js-13-mysql-registration-login-example

Next.js registration/login example (UI from [Jason Watmore’s tutorial](https://jasonwatmore.com/next-js-13-mysql-user-registration-and-login-tutorial-with-example-app)). **Persistence uses PocketBase** (`app_users` collection) instead of MySQL — suited for Hostinger PocketBase on staging (`lt-bnk-web40016`).

Copy `.env.example` → `.env.local` and set `POCKETBASE_*`, `JWT_SECRET`, `NEXT_PUBLIC_API_URL`.

## CloudLinux shared `node_modules` benchmark

On a CloudLinux host with [Shared node_modules Store](https://blog.cloudlinux.com/shared-node-modules-store-for-nodejs-selector-now-in-beta) enabled, compare disk use for two identical `npm ci` trees (shared delivery vs excluded “ordinary” npm):

```sh
./scripts/benchmark-shared-node-modules.sh preflight
./scripts/benchmark-shared-node-modules.sh pocketbase-preflight   # pbctl on 40016 when manager is up
./scripts/benchmark-shared-node-modules.sh run
./scripts/benchmark-shared-node-modules.sh report
./scripts/benchmark-shared-node-modules.sh cleanup
```

Defaults: `lt-bnk-web40016.main-hosting.eu`, user `u11004003`. Override with `BENCHMARK_HOST`, `BENCHMARK_USER`, `NODE_BIN`, `NPM_BIN`, `POCKETBASE_URL`.

After `run`, copy `.env.local` into each bench app dir on the server (`shared-store`, `regular-npm`) so both installs talk to the same PocketBase instance.
