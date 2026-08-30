# TapMouse

Tap-to-click for the Apple Magic Mouse on macOS.

The Magic Mouse's entire top surface is a multitouch sensor — macOS already reads
it for scrolling and swipes. Apple just never wired it to "tap = click" the way
they did for trackpads. TapMouse does that, in ~570 lines of Swift with no
dependencies and no network access.

Scrolling, swiping and the physical click all keep working. TapMouse installs no
event tap, so it cannot intercept or block anything — it only adds clicks.

## Requirements

- macOS 11 or later
- An Apple Magic Mouse (1st, 2nd or 3rd generation)
- Accessibility permission, which macOS requires for any app that synthesizes input

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

## Caveats

**It relies on a private framework.** `MultitouchSupport` is undocumented and its
struct layout is reverse-engineered. Apple can change it in any macOS release and
break this. That is true of every Magic Mouse tap-to-click tool, paid ones
included — there is no public API for this data.

**Builds are ad-hoc signed, not notarized.** Gatekeeper may need a right-click →
Open on first launch. Because macOS keys Accessibility grants to an app's
signature, rebuilding can require removing the old entry from the Accessibility
list and re-adding it.

**A very short, very small flick can read as a tap.** It is the one realistic
false positive. Set Tap Sensitivity to Low if it bothers you.

**No launch-at-login.** Add it under System Settings → General → Login Items.

## Scope

Only the four gestures in the table above. It does not remap buttons, add swipe
gestures, or run at login. Deliberately small enough to read in one sitting.

## License

MIT — see [LICENSE](LICENSE).
