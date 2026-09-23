# VANTA App Icon

Source: `vanta-icon.svg` (1024×1024).

- Background: `#05070A` (near-black, rounded squircle)
- Glyph: geometric **V** in electric blue `#2E7CF6`
- Glow: subtle ellipse, no gradients on the glyph itself

## Export (macOS, Xcode)

1. Open `vanta-icon.svg` in Sketch/Figma/Preview and export PNGs:
   - 1024×1024 → `AppIcon-1024.png`
   - 180×180 (`@3x`), 120×120 (`@2x`), 87×87, 80×80, 60×60, 58×58, 40×40
2. In Xcode: *Assets → AppIcon →* drag the 1024pt image
   (Xcode generates the rest), or use `xcrun actool`.
3. Keep the SVG as the single source of truth in git; generated PNGs are
   build artifacts and stay out of the repo until release export.

iPhone + iPad use the same glyph; iPad gains no extra detail — recognisable
at 60pt and at 1024pt by design.
