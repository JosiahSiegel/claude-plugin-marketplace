# Input Protocols Reference

## Keyboard ambiguity

Traditional terminal input was not designed for modern shortcut-rich applications. Esc may be a key, an Alt prefix, or the start of a control sequence. Ctrl combinations collapse onto control bytes. Function keys vary. Prefer framework parsers and only adopt extended keyboard protocols when you can push/pop modes safely and provide fallbacks.

## Bracketed paste

Bracketed paste wraps pasted text with start and end markers so the application can insert text literally. Use it for shells, editors, search boxes, command palettes, and multiline forms. Do not execute pasted content automatically. Apply length limits and validation after paste completes.

## Keyboard modes

Legacy protocols encode many keys as ambiguous byte sequences. xterm `modifyOtherKeys` and the Kitty keyboard protocol can distinguish modifiers, key releases, text vs physical keys, and Esc/Alt ambiguity more reliably. Enable them only when the framework supports safe negotiation, preserve legacy fallbacks, and pop modes during cleanup.

## Mouse modes

Mouse protocols include X10, normal tracking, button-event tracking, any-event tracking, SGR coordinates, and URXVT-style encodings. SGR mouse mode is easier to parse than older coordinate encodings and avoids small coordinate limits. Mouse events should include button, release, drag, wheel, modifiers, and coordinates. Validate against current layout. Treat wheel, motion, drag, and hover as high-frequency input and throttle expensive side effects.

## Drag, drop, touch, and gestures

Terminal drag usually arrives as mouse motion with a button held, not a high-level drag object. Some emulators support file drop as pasted paths or proprietary escape sequences, and touchpads may map gestures to wheel or mouse events. Treat drag/drop/touch as optional enhancements, validate paths as untrusted input, and provide keyboard alternatives.

## Resize events

Resize is an input event. It invalidates layout, viewport measurements, mouse hit boxes, wrapped text, table widths, and snapshot expectations. Coalesce resize storms and render a minimum-size fallback when needed.

## Focus events

Focus in/out can pause spinners, suppress notifications, or mark stale views, but should never be required for correctness. Terminals and multiplexers may omit or filter focus events.
