pcb_width = 30;
pcb_length = 65 + 5;
box_height = 10;
radius = 3;
thickness = 0.6; // 0.4 * 3 / 2;
$fn = 50;

module main_body() {
  hull() {
    for (x = [ -pcb_width / 2 - thickness, pcb_width / 2 + thickness ],
        y = [ -pcb_length / 2 - thickness, pcb_length / 2 + thickness ])
      translate([ x, y, 0 ])
          cylinder(box_height + thickness, radius + thickness / 2,
                   radius + thickness / 2, center = true);
  }
}

module internal_cutouts() {
  // hull out the main body
  hull() {
    for (x = [ -pcb_width / 2, pcb_width / 2 ],
        y = [ -pcb_length / 2, pcb_length / 2 ])
      translate([ x, y, 0 ])
          cylinder(box_height - thickness, radius, radius, center = true);
  }
}

module external_cutouts() {
  // sd card cutout
  translate([ -(10.14 - 11.5), 0, 0 ]) translate([ 0, -pcb_length / 2, -2 ])
      cube([ 13, 13, 2 ], center = true);
  // heatsink cutout - remove if not using one
  translate([ -(10 - 7), -25 / 2, 0 ]) translate([ 0, 0, -box_height * 0.6 ])
      cube([ 15, 15, 8 ], center = true);
  // OTG cutout - allows for a mini USB plug
  translate([ -pcb_width / 2 - thickness, 4, 0 ])
      translate([ -4, -1, -box_height * 0.5 ])
          cube([ 6, 10, 10 ], center = true);
  // HDMI cutout
  translate([ 0, -pcb_length / 2 + 2, box_height - 5 ])
      cube([ 16, 13, 4 ], center = true);
}

module pi_standoffs() {
  for (x = [ 0, 23 ], y = [ 0, 58 ]) {
    translate([ x, y, 0 ]) cylinder(3, 2.5, 2.5, $fn = 20);
    translate([ x, y, 0 ]) cylinder(5, 1.2, 1.2, $fn = 6);
  }
}

module bridge_standoffs() {
  for (x = [ 0, 23 ], y = [ 0, 29.5 ]) {
    translate([ x, y, 0 ]) cylinder(2, 2.5, 2.5, $fn = 20);
    translate([ x, y, 0 ]) cylinder(4, 1.2, 1.2, $fn = 6);
  }
}

module assembly() {
  difference() {
    main_body();
    union() {
      internal_cutouts();
      external_cutouts();
    }
  }
}

module prism(length = 5, depth = 1) {
  rotate([ 0, 90, 0 ]) linear_extrude(length)
      polygon([ [ 0, 0 ], [ 0, depth ], [ depth, 0 ] ]);
}

module catch_tab(width = 7, height = 8, depth = 1.2, thickness = thickness) {
  color("red") union() {
    translate([ thickness * 1.5, 0, 0 ])
        cube([ width - (thickness * 3), thickness * 2.5, height ]);
    translate([ thickness * 1.5, 0, height ])
        prism(width - (thickness * 3), thickness * 6);
  }
}

module catch_carveout(width, height, depth, thickness) {
  translate([ thickness, -thickness, 0 ]) cube(
      [ width - (thickness * 2), depth + thickness * 2, height + thickness ]);
  translate([ thickness, 0, height + 0.4 ])
      prism(width - (thickness * 2), thickness * 7);
}

module catch_inset(width = 7, height = 8, depth = 1.2, thickness = thickness) {
  color("green") {
    difference() {
      union() {
        cube([ width, depth + thickness * 2, height ]);
        translate([ 0, 0, height ]) prism(width, thickness * 7);
      }
      catch_carveout(width, height, depth, thickness);
    }
  }
}

module place_catches(size) {
  for (x = [ -pcb_width / 2 - radius, pcb_width / 2 + radius ], y = [ -27, 20 ])
    translate([ x, y, 0 ]) if (x < 0) {
      translate([ -thickness - 0.3, size, -box_height / 2 ])
          rotate([ 0, 0, -90 ]) children(0);
    }
  else {
    translate([ thickness + 0.3, 0, -box_height / 2 ]) rotate([ 0, 0, 90 ])
        children(0);
  }
}

module place_carveouts(size) {
  for (x = [ -pcb_width / 2 - radius, pcb_width / 2 + radius ], y = [ -27, 20 ])
    translate([ x, y, 0 ]) if (x < 0) {
      translate([ -thickness - 0.3, size, 0 ]) rotate([ 0, 0, -90 ])
          children(0);
    }
  else {
    translate([ thickness + 0.3, 0, 0 ]) rotate([ 0, 0, 90 ]) children(0);
  }
}

module top_half() {
  union() {
    difference() {
      color("green") rotate([ 180, 0, 0 ]) intersection() {
        assembly();
        translate([ 0, 0, 30 ]) cube([ 100, 100, 60 ], center = true);
      }
      rotate([ 180, 0, 0 ]) place_carveouts(7) {
        catch_carveout(7, box_height / 2, 1.8, thickness);
      }
    }
    rotate([ 180, 0, 0 ]) place_carveouts(7) {
      catch_inset(7, box_height / 2, 1.8, thickness);
    }
    translate([ -11.5, 5, -box_height / 2 ]) bridge_standoffs();
  }
}

module bottom_half() {
  union() {
    intersection() {
      assembly();
      translate([ 0, 0, -30 ]) cube([ 100, 100, 60 ], center = true);
    }
    place_catches(7) { catch_tab(7, box_height, 1.8, thickness); }
    translate([ -11.5, -35, -box_height / 2 ]) pi_standoffs();
    translate([ -10, 37.45, -2.5 ]) cube([ 20, thickness, box_height / 2 ]);
  }
}

module split() {
  translate([ 50, 0, 0 ]) { top_half(); }
  bottom_half();
}

*external_cutouts();
*assembly();

// full case, split out
split();

// uncomment these to examine the snap fittings
*catch_inset();
*catch_tab();