# Stained Glass 3D Printed Frame Generator

An OpenSCAD parametric generator for creating 3D printed lead-came-style frames that embed laser-cut acrylic panes using a pause-at-height technique.

## How It Works

1. **Design in Vector Software (Affinity Designer / Illustrator)**:
   - Export an SVG at 96 DPI with **Flatten transforms** enabled.
   - Organize elements using layer/group IDs:
     - `outside`: Outer frame perimeter and hanging loops (use Boolean Subtract for holes).
     - `inside`: Default acrylic glass shapes to laser cut (uses `glass_thickness`).
     - `inside-X`: Custom thickness acrylic groups to prevent rattling (e.g. `inside-2.8`, `inside-2.7`).
       * Naming a group `inside 2.8` in Affinity Designer automatically exports as `inside-2.8`.
       * The generator automatically raises the pocket floor for thinner panes so the tops remain flush at a single pause height.
     - `island`: (Optional) Solid floating features inside a pane (e.g. eye of a bird) with outward retaining lips.
2. **Laser Cut Acrylic**:
   - Cut the `inside` paths directly on a laser cutter (e.g., Glowforge).
3. **Generate 3D Frame (OpenSCAD)**:
   - Load `stained-glass.scad` in OpenSCAD.
   - Select or drag-and-drop your SVG file.
   - Adjust thickness, clearances, and lip overhangs in the Customizer.
   - Render (F6) and export STL.
4. **Print & Embed (Bambu Studio / PrusaSlicer / OrcaSlicer)**:
   - Slicer Settings:
     - **Auxiliary Fan**: 0% (prevents blowing acrylic pieces around).
     - **Force Fan for Overhangs**: Disabled / OFF.
     - **Overhang / Bridge Speed**: 15–20 mm/s.
     - **Thick Bridges**: Disabled / OFF.
   - Add a slicer pause at:
     $$\text{Pause } Z = \text{lip\_thickness} + \text{pocket\_height}$$
   - When the print pauses, drop the acrylic panes into the printed pockets and resume. The top lip seals the panes permanently into the frame.

## Project Structure

- `stained-glass.scad`: Main OpenSCAD generator script.
- `stained-glass.json.example`: Sample Customizer presets. (Copy to `stained-glass.json` for local use).
- `examples/`: Sample test SVGs, affinity source files, and test models.
