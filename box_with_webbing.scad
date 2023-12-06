box_inner_size = 65;
box_inner_height = 50;
box_corner_r = 4;
box_bottom_thick = 1.5;
box_top_inner_height = 8;
box_top_thick = 4.5;
box_top_height = box_top_inner_height + box_top_thick; // ToDo also overlap
box_bottom_inner_height = box_inner_height - box_top_inner_height;
box_bottom_height = box_bottom_thick + box_bottom_inner_height;
webbing_border_thick = 0.95;
webbing_margin_x = 5.5;
webbing_margin_y = 3.5;
webbing_margin_top = 4;
webbing_thick = 0.8;
webbing_base_thick = 0.8;
box_side_thick = webbing_thick + webbing_base_thick + 1.2;
box_outer_size = box_inner_size + 2*box_side_thick;
web_scaling = (box_outer_size - 2*webbing_margin_x) / 50;
webbing_side_height = box_bottom_height - 2*webbing_margin_y;
lid_bevel_fit = 0.9;

show_expanded=true;

$fs=.5;
$fa=5;

module svg_cell_2d(points) {
  points_accum =
    [for (i=0, p=[-100+30,-100-18];
          i < len(points);
          p = p + points[i], i=i+1) p+points[i]];
  polygon(points=points_accum);
}

module organic_cell(mod1, mod2) {
  difference() {
      children();
    offset(r=mod2)
      offset(delta=-(mod1+mod2), chamfer=true)
      offset(delta=mod2, chamfer=true)
      offset(delta=-(mod1+mod2), chamfer=true)
      children();
  }
}

module mesh_cell(points) {
  organic_cell(0.2, 2.25)
    svg_cell_2d(points);
}

module webbing() {
  mirror([0,1]) {
    include <mesh_cells.scad>
  }
}

module the_area(width=65, height=50) {
  square([width, height]);
}

module framed_webbing(area_sx, area_sy, trans_x=0, trans_y=0, rot=0) {
  translate([-.5*area_sx, -.5*area_sy]) {
    intersection() {
      translate([trans_x, trans_y]) {
        rotate(rot) {
          scale([web_scaling, web_scaling]) {
            webbing();
          }
        }
      }
      the_area(area_sx, area_sy);
    }
    difference() {
      the_area(area_sx, area_sy);
      offset(delta=-webbing_border_thick)
        the_area(area_sx, area_sy);
    }
  }
}

module generic_webbing(size_x, maybe_size_y=0, trans_x=0, trans_y=0, rot=0, bevel=false) {
  eps= 0.0017;
  size_y = maybe_size_y ? maybe_size_y : size_x;

  difference() {
    union() {
      linear_extrude(height=webbing_base_thick) {
        square([size_x, size_y], center=true);
      }
      color("red")
      translate([0, 0, webbing_base_thick - eps]) {
        linear_extrude(height=webbing_thick, convexity=10) {
          framed_webbing(size_x, size_y,
                         trans_x=trans_x, trans_y=trans_y, rot=rot);
        }
      }
    }
    if (bevel) {
      // 45° bevel to make bottom easier to print.
      translate([0, .5*size_y-(webbing_base_thick+webbing_thick), 0])
      rotate([-45, 0, 0])
      translate([0, (webbing_base_thick+webbing_thick), 0])
      cube([size_x+1, 2*(webbing_base_thick+webbing_thick),
            8*(webbing_base_thick+webbing_thick)], center=true);
    }
  }
}

module top_webbing() {
  generic_webbing(box_outer_size - 2*webbing_margin_top);
}

module front_webbing() {
  translate([0, -.5*box_outer_size + webbing_thick + webbing_base_thick,
             .5*webbing_side_height + webbing_margin_y]) {
    rotate([90, 0, 0]) {
      generic_webbing(box_outer_size - 2*webbing_margin_x, webbing_side_height,
                      trans_x=-15.25, trans_y=14, rot=-37, bevel=true);
    }
  }
}

module back_webbing() {
  translate([0, .5*box_outer_size - (webbing_thick + webbing_base_thick),
             .5*webbing_side_height + webbing_margin_y]) {
    rotate([-90, 180, 0]) {
      generic_webbing(box_outer_size - 2*webbing_margin_x, webbing_side_height,
                      trans_x=51, trans_y=-18, rot=73, bevel=true);
    }
  }
}

module left_webbing() {
  translate([-.5*box_outer_size + webbing_thick + webbing_base_thick, 0,
             .5*webbing_side_height + webbing_margin_y]) {
    rotate([180, 90, 0]) rotate([0,0,90]) {
      generic_webbing(box_outer_size - 2*webbing_margin_x, webbing_side_height,
                      trans_x=-23, trans_y=-10, rot=-12, bevel=true);
    }
  }
}

module right_webbing() {
  translate([.5*box_outer_size - (webbing_thick + webbing_base_thick), 0,
             .5*webbing_side_height + webbing_margin_y]) {
    rotate([0, 90, 0]) rotate([0,0,90]) {
      generic_webbing(box_outer_size - 2*webbing_margin_x, webbing_side_height,
                      trans_x=-1, trans_y=-30.2, rot=23, bevel=true);
    }
  }
}

module box_bottom() {
  T = webbing_base_thick + webbing_thick;
  L = box_outer_size - 2*webbing_margin_x;
  H = box_bottom_height - 2*webbing_margin_y;
  eps=.034;

  difference() {
    linear_extrude(height=box_bottom_height) {
      offset(r=box_side_thick) {
        offset(delta=-box_side_thick) {
          square([box_outer_size, box_outer_size], center=true);
        }
      }
    }
    // Inner space in box.
    translate([0, 0, box_bottom_thick]) {
      linear_extrude(height=box_bottom_height) {
        square([box_inner_size, box_inner_size], center=true);
      }
    }
    // Top bevels for easier lid fit.
    translate([0, 0, box_bottom_height-lid_bevel_fit]) {
      rotate([0, 0, 45]) {
        cylinder(h=4*box_side_thick,
                 d1=(box_inner_size-2*box_side_thick)/cos(180/4),
                 d2=(box_inner_size+2*box_side_thick)/cos(180/4),
                 center=true, $fn=4);
      }
    }
    // Cutouts for the webbing panels.
    for (i = [0 : 1 : 1]) {
      for (j = [-1 : 2 : 1]) {
        translate([i*j*.5*box_outer_size, (1-i)*j*.5*box_outer_size, webbing_margin_y]) {
          translate([-j*(1-i)*.5*L, j*i*.5*L, 0]) {
            rotate([0, -90, -90*(i+(1+j))]) {
              linear_extrude(height=L) {
                polygon(points=[[0,-eps], [H+eps,-eps], [H-T,T], [0, T]]);
              }
            }
          }
        }
      }
    }
  }
}

// A box with the side and top edges rounded. Eg. for box lid.
module rounded_slab(sizex, sizey, heightz, round_r) {
  eps=0.0068;
  for (j= [-1 : 2: 1]) {
    for (i= [-1 : 2: 1]) {
      translate([i*(.5*sizex-round_r), j*(.5*sizey-round_r), -round_r]) {
        sphere(r=round_r);
        translate([0, 0, -(heightz-round_r)])
          cylinder(r=round_r, h=heightz-round_r+eps);
      }
      sizexy = (1-j)/2*sizex + (j+1)/2*sizey;
      rotate([0, 0, 45*(j+1)]) {
        translate([0, i*(.5*sizexy-round_r), -round_r]) {
          rotate([0, 90, 0]) {
            cylinder(r=round_r, h=sizexy-2*round_r+eps, center=true);
          }
        }
      }
    }
  }
  translate([0, 0, -.5*(heightz+round_r)]) {
    cube([sizex-2*round_r, sizey, heightz-round_r], center=true);
    cube([sizex, sizey-2*round_r, heightz-round_r], center=true);
  }
  translate([0, 0, -.5*(round_r+eps)]) {
    cube([sizex-2*round_r, sizey-2*round_r, round_r+eps], center=true);
  }
}

module box_top() {
  difference() {
    rounded_slab(box_outer_size, box_outer_size, box_top_height, box_corner_r);
    translate([0, 0, -.5*box_top_height - box_top_thick]) {
      cube([box_inner_size, box_inner_size, box_top_height], center=true);
    }
  }
}

box_bottom();
explode = (show_expanded ? 5 : 0);
if (true) {
  translate([0, 0, explode + box_bottom_height + box_top_height]) top_webbing();
  translate([0, -explode, 0]) front_webbing();
  translate([0, explode, 0]) back_webbing();
  translate([-explode, 0, 0]) left_webbing();
  translate([explode, 0, 0]) right_webbing();
}

translate([0, 0, 60/* + ToDo */]) box_top();
