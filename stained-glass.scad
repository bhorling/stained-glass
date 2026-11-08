// ==============================================================================
// OpenSCAD Stained-Glass Frame Generator
//
// ------------------------------------------------------------------------------
// SLICER PRINT PROFILE & PAUSE INSTRUCTIONS (e.g. Bambu Studio / OrcaSlicer)
// ------------------------------------------------------------------------------
// 1. Slicer Print Profile ("Stained Glass"):
//    - Auxiliary Fan:           Set to 0% (Filament Settings -> Cooling).
//                               *Crucial* so side airflow doesn't blow acrylic around.
//    - Force Fan for Overhangs: DISABLED / OFF (Filament Settings -> Cooling).
//                               Prevents the slicer from blasting 100% fan over the cavity.
//    - Part Cooling Fan:        Gentle (max 20-30%) or 0% during pause resume.
//    - Overhang / Bridge Speed: Set to 15-20 mm/s (Print Settings -> Speed).
//                               Slows down toolhead right over the acrylic edges.
//    - Bridge Flow Ratio:       Set to 1.0 (Print Settings -> Quality -> Advanced).
//    - Thick Bridges:           DISABLED / OFF (Print Settings -> Quality).
//
// 2. Pause-At-Height:
//    - In the slicer Preview slider, add a Pause at:
//      Z = lip_thickness + pocket_height = 0.5 + 3.30 = 3.80 mm
//      (Layer 19 when printing with 0.20 mm layer height).
//    - At the pause: peel protective film, insert acrylic pieces, and resume.
//
// ------------------------------------------------------------------------------
// AFFINITY DESIGNER SVG EXPORT REMINDER:
//    - Ensure "Flatten transforms" is CHECKED under File -> Export -> SVG -> More...
//    - Ensure elements are named in the Layers panel:
//      * "outside": outer perimeter of the frame (+ hanger loop)
//      * "inside":  group containing all cut acrylic glass shapes
//      * "island":  (optional) solid floating features inside a glass pane (e.g. bird's eye)
// ==============================================================================

/* [File Settings] */
// SVG file to import (select from list or type filename)
glass_svg       = "examples/test.svg"; // [examples/test.svg, examples/test2.svg]

// Export DPI from Affinity Designer (96 matches Glowforge standard)
svg_dpi         = 96;

// Convert pixels to millimeters (set true if SVG width/height is in px)
svg_is_pixels   = true; 

// Scaling: Converts pixels at svg_dpi to true physical millimeters (25.4 / 96 = ~0.2646 mm/px)
scale_factor    = svg_is_pixels ? (25.4 / svg_dpi) : 1.0;

/* [Physical Dimensions (mm)] */
// Nominal acrylic thickness (measure with calipers)
glass_thickness = 2.85;

// Overhang width holding glass edges in place (XY)
lip_overhang    = 0.5;

// Height/thickness of both the top and bottom lips (Z)
lip_thickness   = 0.5;

/* [Manufacturing Tolerances (mm)] */
// Radial clearance around pocket so acrylic drops in smoothly (snug fit)
xy_clearance    = 0.25;

// Extra pocket depth to prevent nozzle colliding with acrylic
z_clearance     = 0.3;

/* [Visualization & Quality] */
// Preview translucent acrylic in OpenSCAD (F5)
show_glass      = true;

// Automatically generate solid floating island(s) with outward lips
include_island  = true;

// SVG element/group ID for the floating island feature
island_id       = "island";

// Arc and curve segment resolution
$fn             = 64;

/* [Hidden] */
pocket_height   = glass_thickness + z_clearance;
total_height    = (lip_thickness * 2) + pocket_height;
eps             = 0.05; // Prevents Z-fighting / zero-thickness coincident faces

// Helper to import and scale 2D geometry to true millimeters
module load_svg(filename, id) {
    scale([scale_factor, scale_factor])
        import(filename, id = id, dpi = svg_dpi);
}

// 1. Solid Outer Boundary (extruded to full height)
module outer_frame(filename) {
    linear_extrude(height = total_height)
        load_svg(filename, id = "outside");
}

// 2. Daylight Aperture (Through-hole shrunk by lip_overhang)
// This creates the opening light passes through and leaves the retaining lips
module daylight_aperture(filename) {
    translate([0, 0, -eps])
    linear_extrude(height = total_height + 2 * eps)
        offset(delta = -lip_overhang, chamfer = false)
        load_svg(filename, id = "inside");
}

// 3. Glass Pocket (Internal cavity matching acrylic + clearance)
module glass_pocket(filename) {
    translate([0, 0, lip_thickness])
    linear_extrude(height = pocket_height)
        offset(delta = xy_clearance, chamfer = false)
        load_svg(filename, id = "inside");
}

// Main Frame (perimeter and dividing came)
module frame(filename) {
    difference() {
        outer_frame(filename);
        daylight_aperture(filename);
        glass_pocket(filename);
    }
}

// 4. Solid Island Feature (e.g. bird's eye) with outward-facing lips
// - Solid core through the middle
// - Outward-flanged bottom and top lips to hold the surrounding acrylic
module island_feature(filename, id) {
    union() {
        // Core plug passing through the acrylic cutout (shrunk by xy_clearance)
        linear_extrude(height = total_height)
            offset(delta = -xy_clearance, chamfer = false)
            load_svg(filename, id = id);

        // Bottom lip (outward flange supporting acrylic from below)
        linear_extrude(height = lip_thickness)
            offset(delta = lip_overhang, chamfer = false)
            load_svg(filename, id = id);

        // Top lip (outward flange capturing acrylic from above)
        translate([0, 0, lip_thickness + pocket_height])
        linear_extrude(height = lip_thickness)
            offset(delta = lip_overhang, chamfer = false)
            load_svg(filename, id = id);
    }
}

// Complete 3D Printed Frame (outer frame + any islands)
module complete_frame(filename) {
    union() {
        frame(filename);
        if (include_island) {
            island_feature(filename, island_id);
        }
    }
}

// Visual preview of the cut acrylic panes inside the frame
// Note: '%' modifier displays it in preview (F5) but excludes it from STL export (F6)
module preview_glass(filename) {
    translate([0, 0, lip_thickness])
    color([0.2, 0.6, 1.0, 0.45])
    linear_extrude(height = glass_thickness) {
        difference() {
            load_svg(filename, id = "inside");
            if (include_island) {
                load_svg(filename, id = island_id);
            }
        }
    }
}

// Render the complete 3D printable frame
complete_frame(glass_svg);

// Render acrylic preview
if (show_glass) {
    %preview_glass(glass_svg);
}
