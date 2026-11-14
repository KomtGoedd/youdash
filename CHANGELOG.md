# Changelog

## Unreleased

- CarPlay fullscreen uses the car window rather than the phone-window presentation gate, skips phone-rotation requests, and suspends split-watch layout in fullscreen. Pending user visual confirmation; no new test run.

- CarPlay seek bar: a minimum 6-point visible track, larger scrubber thumb, and 44-point touch region, adjusted for canvas scaling. Phone styling and playback settings are preserved. Pending user visual confirmation; no new test run.

## 0.1.0 — Native CarPlay preview

- Native controller handoff between phone and CarPlay.
- Responsive Home grid and small-screen density scaling.
- Split video/details and recommendation/queue layouts on landscape displays.
- English/Arabic on-screen keyboard with native field integration.
- Header safe-area, scroll-collapse, search viewport, and mini-player adjustments.
- Reversible reported-version compatibility override with actual-version metadata preserved.
- Standalone source distribution, credited YouMod snapshot, unsigned packaging, and privacy auditing.

Experimental preview. Compatibility limitations are documented rather than implied to be solved universally.
