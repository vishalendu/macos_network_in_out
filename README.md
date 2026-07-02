# Network In Out

Tiny macOS menu bar app that shows total network download/upload counters.

## Requirements

- macOS
- Xcode Command Line Tools

Install the tools if `swiftc` is missing:

```sh
xcode-select --install
```

## Build

```sh
make build
```

The app bundle is created at:

```text
build/Network In Out.app
```

## Run

```sh
make run
```

If an older copy is already running, quit it from the menu bar dropdown first.

## Test

```sh
make test
```

This builds the app binary and runs a quick counter read without opening the menu bar app.

## Clean

```sh
make clean
```
