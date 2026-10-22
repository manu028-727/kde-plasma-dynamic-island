Run the network parser, state, and text helper tests with Node.js 18 or later:

```bash
node tests/network-state.test.cjs
node tests/text-utils.test.cjs
```

Run the tile's sizing, live binding, and mouse interaction tests with Qt 6, Qt Quick Test, and the Plasma QML modules installed:

```bash
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software /usr/lib/qt6/bin/qmltestrunner -input tests
```

Adjust the Qt tool path for your distribution. These tests use synthetic network data and do not change network settings or require a running Plasma session.

The Node tests and package validation run in `.github/workflows/ci.yml` on every push and pull request.
