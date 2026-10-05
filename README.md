# next-js-13-mysql-registration-login-example

Next.js 13 + MySQL - User Registration and Login Example

Documentation at https://jasonwatmore.com/next-js-13-mysql-user-registration-and-login-tutorial-with-example-app

## CloudLinux shared `node_modules` benchmark

On a CloudLinux host with [Shared node_modules Store](https://blog.cloudlinux.com/shared-node-modules-store-for-nodejs-selector-now-in-beta) enabled, compare disk use for two identical `npm ci` trees (shared delivery vs excluded “ordinary” npm):

```sh
./scripts/benchmark-shared-node-modules.sh preflight
./scripts/benchmark-shared-node-modules.sh run
./scripts/benchmark-shared-node-modules.sh report
./scripts/benchmark-shared-node-modules.sh cleanup
```

Defaults: `lt-bnk-web40016.main-hosting.eu`, user `u11004003`. Override with `BENCHMARK_HOST`, `BENCHMARK_USER`, `NODE_BIN`, `NPM_BIN`.
