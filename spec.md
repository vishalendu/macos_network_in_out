# Network In/Out Menu Bar App

## Goal

A tiny macOS menu bar app that shows total network traffic when opened:

- Download total with a down arrow.
- Upload total with an up arrow.
- Live values while the dropdown is open.
- No graphs, charts, dock window, preferences, or history.

## Behavior

- The app runs as a menu bar accessory.
- The menu bar item is a native up/down traffic icon.
- Clicking it opens a small menu with:
  - `↓ <total downloaded>`
  - `↑ <total uploaded>`
  - `Quit`
- Totals are cumulative macOS network interface byte counters since boot/interface start, not since app launch.
- Loopback traffic is ignored.
- Values refresh when the menu opens, then every 5 seconds while it stays open.

## Implementation

- Native Swift + AppKit.
- Read byte counters with `getifaddrs`.
- Build with `swiftc`; no package manager dependency.
- Bundle as `build/Network In Out.app`.

## Deferred

- Per-interface breakdown.
- Session-only counters.
- Graphs or speed meters.
- Launch-at-login.
