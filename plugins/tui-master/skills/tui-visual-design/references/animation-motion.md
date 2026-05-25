# Animation and Motion in TUIs

## When motion helps

Use motion to communicate:

- The app is alive during unknown waits.
- Determinate work is advancing.
- A view changed and the user's context should be preserved.
- A notification appeared or a background task completed.

Avoid motion as constant decoration. In terminals, every frame is text output and can cost CPU, bandwidth, battery, and readability.

## Spinners

Choose spinner style by tone and compatibility:

- ASCII: `- \ | /`, safest and familiar.
- Dots: calm, low visual weight.
- Braille: smooth and compact, but needs Unicode fallback.
- Arc/clock: expressive, but emoji width can be unreliable.
- Custom frames: useful for brand, but test all frames for equal display width.

Keep spinner text stable. Do not rewrite long status lines at high frequency.

## Progress animation

Determinate progress should update on meaningful progress, not on a fixed high-rate timer. Indeterminate bars can pulse or slide, but should slow down over remote connections and stop immediately when work completes or fails.

## Transitions

Slide, fade, and expand/collapse transitions can make navigation feel spatial. Use them sparingly:

- Keep duration short.
- Allow interruption by input.
- Skip transitions in reduced-motion, CI, non-TTY, and slow-terminal modes.
- Do not animate large full-screen diffs over SSH unless throttled.

Color fades are cheaper conceptually but can generate many SGR changes. Use coarse steps rather than dozens of truecolor frames.

## Scrolling and viewport motion

Smooth scrolling helps local browsing and file explorers. Page jumps are often better for logs, terminals over SSH, and screen-reader-adjacent workflows. Always keep selection visible and expose position through a scrollbar, line count, percentage, or breadcrumb.

## Decorative effects

Particles, shimmer, typewriter effects, and animated borders can delight in onboarding or empty states, but they are rarely appropriate in dense work screens. They must be disableable and should not block input.

## Performance and accessibility limits

- Avoid flashing more than three times per second.
- Cap redraws to the minimum that preserves perceived smoothness.
- Coalesce animation ticks with data updates.
- Pause animation when the app is unfocused if focus events are available.
- Respect reduced-motion preferences and provide a config flag.
- Stabilize tests by disabling animation, cursor blink, clocks, and random decorative frames.
