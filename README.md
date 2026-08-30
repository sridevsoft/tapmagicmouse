# TapMouse — Tap to Click for the Apple Magic Mouse on macOS

**Tap the surface instead of pressing down.** TapMouse adds trackpad-style
tap-to-click, right-click and drag gestures to the Apple Magic Mouse on macOS.
Free, open source, ~570 lines of Swift, no dependencies, no network access.

![Platform](https://img.shields.io/badge/platform-macOS%2011%2B-lightgrey)
![Language](https://img.shields.io/badge/swift-5.x-orange)
![License](https://img.shields.io/badge/license-MIT-blue)
![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)

---

## Why this exists

The Magic Mouse's entire top surface is a multitouch sensor. macOS already reads
it for scrolling and swipe gestures — but Apple never wired it to "tap = click"
the way they did for the trackpad. There is no checkbox for it in System Settings,
and there never has been.

The touch data is right there, streaming. TapMouse listens to it and turns a light
tap into a click. No more pressing down; no more click noise in a quiet room.

## Install

```sh
git clone https://github.com/sridevsoft/tapmagicmouse.git
cd tapmagicmouse
./build.sh
ditto build/TapMouse.app /Applications/TapMouse.app
open /Applications/TapMouse.app
```

Grant **Accessibility** when prompted (System Settings → Privacy & Security →
Accessibility). macOS requires it for any app that synthesizes input — TapMouse
cannot post a click without it.

No prebuilt binary is published on purpose. An app that can synthesize input
should be one you compiled yourself from source you can read.

## Gestures

| Gesture | Result |
|---|---|
| Tap the left part of the surface | Left click |
| Tap the right part of the surface | Right click |
| Tap twice quickly | Double-click |
| Two-finger tap | Right click *(optional)* |
| Double-tap, then hold and move | Drag *(optional)* |

Everything is toggled from the menu bar icon. **Tap Sensitivity** (Low / Medium /
High) trades accidental clicks against how crisply you have to tap.
**Right-Click Area** sets where the surface splits, from 50/50 to 80/20.

Scrolling, swiping and the physical click keep working exactly as before.
TapMouse installs no event tap, so it cannot intercept or block anything — it
only adds clicks.

## How it compares

| | TapMouse | BetterTouchTool | Magic Utilities | MouseToucher / MagicTap |
|---|---|---|---|---|
| Price | Free | Paid (free trial) | Paid | Free |
| Open source | Yes (MIT) | No | No | Yes |
| Runs on macOS | Yes | Yes | **No — Windows only** | Yes |
| Double-tap = double-click | Yes | Yes | Yes | No |
| Tap-and-drag | Yes | Yes | Yes | No |
| Adjustable sensitivity | Yes | Yes | Yes | No |
| Scope | Just tap-to-click | Everything | Everything | Just tap-to-click |

If you want a full gesture and automation suite, BetterTouchTool is genuinely
excellent and worth paying for. TapMouse does one thing.

**A note on Magic Utilities:** it is frequently suggested for this, but it is a
Windows driver package for using Apple peripherals on a PC. It does not run on
macOS at all.

## FAQ

### Does the Magic Mouse have tap to click?

The hardware does — the surface is a multitouch sensor. macOS does not expose the
feature. That gap is what this app fills.

### How do I enable tap to click on a Magic Mouse on a Mac?

There is no built-in setting. You need software that reads the mouse's touch data
and synthesizes clicks — TapMouse, or one of the alternatives in the table above.

### Can I stop the Magic Mouse from clicking so loudly?

Yes. The click noise comes from the physical switch. Tap instead of pressing and
the mouse is silent. The physical click still works whenever you want it.

### Does this break scrolling?

No. TapMouse observes the touch stream rather than intercepting it, and installs
no event tap. Scrolling and swiping are untouched, and a scroll gesture is
explicitly disqualified from becoming a tap.

### Does it work on Apple Silicon?

Yes. `build.sh` produces a universal binary for both arm64 and x86_64.

### Which Magic Mouse generations work?

All of them — 1, 2 and 3. They report touch data identically.

## How it works

**`TouchSource.swift`** — There is no public API for raw Magic Mouse touches. The
data lives behind `MultitouchSupport.framework`, a private Apple framework, so the
functions are declared by hand in `MultitouchBridge.h`. `MTDeviceCreateList()`
enumerates multitouch devices, `MTRegisterContactFrameCallback()` subscribes, and
from then on a callback fires 60–100 times a second with each contact's position
on the surface, size, velocity and lifecycle state.

**`TapEngine.swift`** — The hard part is not reading touches, it is that *most
contacts are not taps*: a resting palm, a hand repositioning, a scroll. So the
engine inverts the problem. Every contact starts as a tap candidate and gets
disqualified — too slow, drifted too far, too many fingers — dropping into a
rejected state it cannot leave until all fingers lift. What survives is a tap.

**`ClickSynthesizer.swift`** — Posts `CGEvent` mouse events at the cursor,
injected at `cghidEventTap` where real hardware events enter. The non-obvious part
is `clickState`: macOS decides "that was a double-click" from a counter carried on
the event itself, not from timing at the receiving end. Post every click with
`clickState = 1` and double-clicking silently breaks forever — folders don't open,
words don't select. TapMouse tracks the run length against the system double-click
interval and stamps it on each event.

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

Only the gestures in the table above. It does not remap buttons, add swipe
gestures, or run at login. Deliberately small enough to read in one sitting.

Issues and pull requests welcome.

## About

- **Author:** Sriharish Sathya
- **License:** MIT — see [LICENSE](LICENSE)
- **System Requirements:** macOS 11.0 (Big Sur) or higher, Apple Magic Mouse (1, 2 or 3)
- **Repo URL:** https://github.com/sridevsoft/tapmagicmouse
- **Contacts:** sriharishsathya@gmail.com
- **LinkedIn:** https://www.linkedin.com/in/sriharishs/

If TapMouse is useful to you, a star helps other Magic Mouse owners find it.
