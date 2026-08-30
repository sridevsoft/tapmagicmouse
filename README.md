# TapMouse

Tap-to-click for the Apple Magic Mouse on macOS. Written from scratch, ~570 lines
of Swift, no dependencies, no network access.

## Build

```sh
./build.sh
ditto build/TapMouse.app /Applications/TapMouse.app
open /Applications/TapMouse.app
```

Grant Accessibility when prompted (System Settings -> Privacy & Security ->
Accessibility). The app cannot post clicks without it.

## Behaviour

| Gesture | Result |
|---|---|
| Tap left part of the surface | Left click |
| Tap right part of the surface | Right click |
| Two-finger tap | Right click (off by default) |
| Double-tap, then hold and move | Drag (off by default) |

Everything is toggled from the menu bar icon.

**Tap Sensitivity** trades accidental clicks against how crisply you must tap.
Low requires a 0.18s tap with almost no drift; High allows 0.35s and more
movement. Start at Medium; drop to Low if a resting hand triggers clicks.

**Right-Click Area** sets where the surface splits, from 50/50 to 80/20.

## How it works

`MultitouchSupport.framework` is a private Apple framework and the only way to
read raw Magic Mouse touch data — there is no public API. `TouchSource` registers
a frame callback on every external multitouch device that reports an opaque
surface (Magic Mice do; trackpads do not; built-in trackpads are always skipped).

`TapEngine` is a state machine over those frames. A contact becomes a tap only if
it is brief, drifts less than the sensitivity threshold, and is not part of a
multi-finger gesture. Anything else is rejected so scrolling and swiping still work.

`ClickSynthesizer` posts the events. The non-obvious part is `clickState`: macOS
decides "that was a double-click" from a counter carried on the event, not from
timing at the receiving end. Tap-to-click implementations that post every click
with `clickState = 1` break double-clicking — folders don't open, words don't
select. This tracks the run length against the system double-click interval and
stamps it on each event.

Drags are driven from the touch callback itself: while a drag is active, each
frame posts a `leftMouseDragged` at the current cursor position, so no global
event tap is needed.

## Scope

Only the four gestures in the table above. It does not remap buttons, add swipe
gestures, or run at login. Deliberately small enough to read in one sitting.

MIT.
