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
//      Z = lip_thickness + pocket_height
//      (For 2.85 mm max thickness: 0.5 + 3.15 = 3.65 mm / Layer 18 or 19 @ 0.20 mm).
//    - At the pause: peel protective film, insert acrylic pieces, and resume.
//
// ------------------------------------------------------------------------------
// AFFINITY DESIGNER SVG EXPORT REMINDER:
//    - Ensure "Flatten transforms" is CHECKED under File -> Export -> SVG -> More...
//    - Layer / Group Naming:
//      * "outside":   outer perimeter of the frame (+ hanger loop; use Subtract for holes)
//      * "inside":    default acrylic pieces (uses glass_thickness)
//      * "inside-X":  custom thickness pieces (e.g. "inside-2.8", "inside-2.7", "inside-3.0").
//                     Note: Naming a layer "inside 2.8" in Affinity automatically exports
//                     as "inside-2.8".
//      * "island":    (optional) solid floating features inside a pane (e.g. bird's eye)
// ==============================================================================

/* [File Settings] */
// SVG file to import (select from list or type filename)
glass_svg         = "examples/test.svg"; // [examples/test.svg, examples/test2.svg]

// Export DPI from Affinity Designer (96 matches Glowforge standard)
svg_dpi           = 96;

// Convert pixels to millimeters (set true if SVG width/height is in px)
svg_is_pixels     = true; 

// Scaling: Converts pixels at svg_dpi to true physical millimeters (25.4 / 96 = ~0.2646 mm/px)
scale_factor      = svg_is_pixels ? (25.4 / svg_dpi) : 1.0;

/* [Physical Dimensions (mm)] */
// Nominal / default acrylic thickness (for "inside" group)
glass_thickness   = 2.9;

// Maximum acrylic thickness across all panes (sets uniform ceiling & pause height)
max_thickness     = 2.9;

// Overhang width holding glass edges in place (XY)
lip_overhang      = 0.2;

// Base height/thickness of both top and bottom lips (Z)
lip_thickness     = 0.4;

/* [Manufacturing Tolerances (mm)] */
// Radial clearance around pocket so acrylic drops in smoothly (snug fit)
xy_clearance      = 0.16;

// Extra pocket depth to prevent nozzle colliding with acrylic
z_clearance       = 0.05;

/* [Visualization & Quality] */
// Preview translucent acrylic in OpenSCAD (F5)
show_glass        = true;

// Automatically generate solid floating island(s) with outward lips
include_island    = true;

// SVG element/group ID for the floating island feature
island_id         = "island";

// Arc and curve segment resolution
$fn               = 64;

/* [Multi-Thickness Settings] */
// Specific thicknesses to scan for (e.g. "inside-2.8", "inside-2.7")
scan_thicknesses  = [2.0, 2.4, 2.5, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 3.0, 3.1, 3.2];

/* [Hidden] */
effective_max_t   = max(glass_thickness, max_thickness);
pocket_height     = effective_max_t + z_clearance;
total_height      = (lip_thickness * 2) + pocket_height;
pause_height      = lip_thickness + pocket_height;
eps               = 0.05; // Prevents Z-fighting / zero-thickness coincident faces

// Helper to import and scale 2D geometry to true millimeters
module load_svg(filename, id) {
    scale([scale_factor, scale_factor])
        import(filename, id = id, dpi = svg_dpi);
}

// Helper to try importing thickness-tagged IDs (e.g. "inside-2.8", "inside-3.0")
module try_import(filename, base_id, t) {
    load_svg(filename, id = str(base_id, "-", t));
    if (round(t) == t) {
        load_svg(filename, id = str(base_id, "-", t, ".0"));
    }
}

// 1. Solid Outer Boundary (extruded to full height)
module outer_frame(filename) {
    linear_extrude(height = total_height)
        load_svg(filename, id = "outside");
}

// 2. Daylight Aperture (Through-hole shrunk by lip_overhang)
// Cuts all the way through for all glass panes (default "inside" + any "inside-X")
module daylight_aperture(filename) {
    translate([0, 0, -eps])
    linear_extrude(height = total_height + 2 * eps)
        offset(delta = -lip_overhang, chamfer = false) {
            load_svg(filename, id = "inside");
            for (t = scan_thicknesses) {
                try_import(filename, "inside", t);
            }
        }
}

// Single pocket with custom floor lift for pane thickness t
module single_pocket(filename, t) {
    floor_lift   = effective_max_t - t;
    pocket_depth = t + z_clearance;
    translate([0, 0, lip_thickness + floor_lift])
    linear_extrude(height = pocket_depth)
        offset(delta = xy_clearance, chamfer = false)
            children();
}

// 3. All Glass Pockets (Internal cavities with thickness compensation)
module all_glass_pockets(filename) {
    // Default "inside" group
    single_pocket(filename, glass_thickness)
        load_svg(filename, id = "inside");

    // Specific thickness groups ("inside-2.8", etc.)
    for (t = scan_thicknesses) {
        single_pocket(filename, t)
            try_import(filename, "inside", t);
    }
}

// Main Frame (perimeter and dividing came)
module frame(filename) {
    difference() {
        outer_frame(filename);
        daylight_aperture(filename);
        all_glass_pockets(filename);
    }
}

// 4. Solid Island Feature (e.g. bird's eye) with outward-facing lips
// - Solid core through the middle
// - Outward-flanged bottom and top lips to hold the surrounding acrylic
module island_feature(filename, id) {
    union() {
        // Core plug passing through the acrylic cutout (shrunk by xy_clearance)
        linear_extrude(height = total_height)
            offset(delta = -xy_clearance, chamfer = false) {
                load_svg(filename, id = id);
                for (t = scan_thicknesses) {
                    try_import(filename, id, t);
                }
            }

        // Bottom lip (outward flange supporting acrylic from below)
        linear_extrude(height = lip_thickness)
            offset(delta = lip_overhang, chamfer = false) {
                load_svg(filename, id = id);
                for (t = scan_thicknesses) {
                    try_import(filename, id, t);
                }
            }

        // Top lip (outward flange capturing acrylic from above at pause ceiling)
        translate([0, 0, pause_height])
        linear_extrude(height = lip_thickness)
            offset(delta = lip_overhang, chamfer = false) {
                load_svg(filename, id = id);
                for (t = scan_thicknesses) {
                    try_import(filename, id, t);
                }
            }
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

// Preview pane at custom floor height and thickness
module preview_pane(filename, t) {
    floor_lift = effective_max_t - t;
    translate([0, 0, lip_thickness + floor_lift])
    linear_extrude(height = t) {
        difference() {
            children();
            if (include_island) {
                load_svg(filename, id = island_id);
                for (it = scan_thicknesses) {
                    try_import(filename, island_id, it);
                }
            }
        }
    }
}

// Visual preview of the cut acrylic panes inside the frame
// Note: '%' modifier displays it in preview (F5) but excludes it from STL export (F6)
module preview_glass(filename) {
    color([0.2, 0.6, 1.0, 0.45]) {
        // Default inside panes
        preview_pane(filename, glass_thickness)
            load_svg(filename, id = "inside");

        // Custom thickness panes
        for (t = scan_thicknesses) {
            preview_pane(filename, t)
                try_import(filename, "inside", t);
        }
    }
}

// Render the complete 3D printable frame
complete_frame(glass_svg);

// Render acrylic preview
if (show_glass) {
    %preview_glass(glass_svg);
}
