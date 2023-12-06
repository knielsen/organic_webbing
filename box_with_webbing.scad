nominal_print_layer = 0.2;

box_inner_size = 65;
box_inner_height = 50;
box_corner_r = 4;
box_bottom_thick = 1.5;
box_top_inner_height = 8;
box_top_thick = 4.5;
box_top_height = box_top_inner_height + box_top_thick; // ToDo also overlap
box_bottom_inner_height = box_inner_height - box_top_inner_height;
box_bottom_height = box_bottom_thick + box_bottom_inner_height;
webbing_border_thick = 1.4;
webbing_margin_x = 5.5;
webbing_margin_y = 3.5;
webbing_margin_top = 4;
webbing_thick = 0.8;
webbing_base_thick = 0.8;
box_side_thick = webbing_thick + webbing_base_thick + 1.2;
box_outer_size = box_inner_size + 2*box_side_thick;
web_scaling = (box_outer_size - 2*webbing_margin_x) / 50;
webbing_side_height = box_bottom_height - 2*webbing_margin_y;
webbing_top_size = box_outer_size - 2*webbing_margin_top;
lid_bevel_fit = 0.9;
interface_beam_height = 2.8;
interface_beam_x1 = 0.4;
interface_beam_x2 = interface_beam_x1 + 2*sin(22.5)*interface_beam_height;
interface_beam_cut = nominal_print_layer;
interface_beam_nominal_spacing = 9;
interface_beam_count = floor(webbing_top_size / interface_beam_nominal_spacing + 0.5) - 1;
interface_beam_spacing = webbing_top_size / (interface_beam_count + 1);
webbing_base_top_thick = webbing_base_thick + interface_beam_height;
interface_support_size = webbing_top_size - 2*2.1;
interface_support_thick = webbing_base_thick + webbing_thick + .5*interface_beam_height;

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

module generic_webbing(size_x, maybe_size_y=0, trans_x=0,
                       base_thick=webbing_base_thick, thick=webbing_thick,
                       trans_y=0, rot=0, bevel=false) {
  eps= 0.0017;
  size_y = maybe_size_y ? maybe_size_y : size_x;

  difference() {
    union() {
      linear_extrude(height=base_thick) {
        square([size_x, size_y], center=true);
      }
      color("red")
      translate([0, 0, base_thick - eps]) {
        linear_extrude(height=thick, convexity=10) {
          framed_webbing(size_x, size_y,
                         trans_x=trans_x, trans_y=trans_y, rot=rot);
        }
      }
    }
    if (bevel) {
      // 45° bevel to make bottom easier to print.
      translate([0, .5*size_y-(base_thick+thick), 0])
      rotate([-45, 0, 0])
      translate([0, (base_thick+thick), 0])
      cube([size_x+1, 2*(base_thick+thick),
            8*(base_thick+thick)], center=true);
    }
  }
}

// Making it a bit easier to 3d-print the lid of the box upside-down with a
// cut-out for the top webbing panel. Idea is to print the bottom of the
// cut-out with some support, but only up to some narrow trianguar-profile
// beams so the support will be easy to remove without leaving too much mess
// that prevents a clean interface. And then some matching depressions in the
// webbing panel.
module interface_beam(len, cut=false) {
  h = interface_beam_height - (cut ? interface_beam_cut : 0);
  x1 = interface_beam_x1 +
    (cut ?
     (interface_beam_x2 - interface_beam_x1) / interface_beam_height * interface_beam_cut :
     0);
  x2 = interface_beam_x2;
  rotate([90, 0, 0]) {
    linear_extrude(height=len, center=true) {
      polygon([[.5*x2, 0], [-.5*x2, 0], [-.5*x1, h], [.5*x1, h]]);
    }
  }
}

module top_webbing_interface(len, cut) {
  for (i = [1 : interface_beam_count]) {
    translate([(-.5 + i/(interface_beam_count+1))*webbing_top_size, 0, 0]) {
      interface_beam(len, cut);
    }
  }
}

module top_webbing() {
  eps=0.0013;
  difference() {
    generic_webbing(webbing_top_size, base_thick=webbing_base_top_thick);
    translate([0, 0, -eps])
      top_webbing_interface(webbing_top_size+2*eps, cut=false);
  }
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
module rounded_slab_simple_but_slow_maybe(sizex, sizey, heightz, round_r) {
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

// Try for the same with a single direct polyhedron().
//
// Base the rounding on a cylinder subdivided in 4*N faces (excluding
// top/bottom). There are corners at the 90°'s, so no faces are exactly 90°.
//
// Faces:
//  - A single horizontal bottom face (4*N+4 edges).
//  - 4*N+4 vertical sides (4 edges each).
//  - (N-1)*(4*N+4) skewed 4-edge on the rounded corners on the top.
//  - 4*N+4 final skewed edges. The ones on the sides are 4-edge, but the
//    4*N in the corners share a corner point and have 3 edges.
//  - A top horizontal simple rectangle with 4 edges.
//
// Points:
//   Each layer is 4*N+4 points, corresponding to a cylinder divided with 4*N
//   points, but with the 90° points duplicated to insert a 90° slab side. And
//   on the top layer there are just 4 points since all points in a corner
//   coincide there.
//
// Layers:
//  - 1 vertex layer on the bottom.
//  - N+1 vertex layers for rounding the top edges. Goes from z=heightz-round_r
//    to z=heightz. Layer i (i=0, ..., N) has
//      z = round_r*sin(90*i/N) - round_r - heightz
//
// Probably too much coordinate work compared to just building as the above
// from cylinders and spheres and 3 box pieces, but just for fun to see how it
// can be done and if it's any faster/smaller/cleaner.
module rounded_slab(sizex, sizey, heightz, round_r) {
  N = round_r < 0.01 ? 1 :
    $fn > 0 ? max(floor($fn/4 + 0.5), 1) :
    max( floor(min(360/$fa, round_r*2*PI/$fs)/4 + 0.5), 1 );

  // N*(N+1)+1 points for one corner (~ 1/8 a sphere).
  corner_points =
    [for (j = [0 : N-1])
        for (i = [0 : N])
               [cos(90*j/N)*round_r*cos(90*i/N),
                cos(90*j/N)*round_r*sin(90*i/N),
                round_r*sin(90*j/N)],
     [0, 0, round_r] ];
  all_points =
    [for (k = [-1 : N])
       for (c = [0 : 3])
         for (i = [0 : 1 : (k < N ? N : 0)])
           let (j=(k < 0 ? 0 : k),
                dx = ( c==0 || c==3 ? 1 : -1),
                dy = ( c<=1 ? 1 : -1),
                p=corner_points[j*(N+1)+((c%2 == 0 || k==N) ? i : N-i)])
             [ dx*(.5*sizex - round_r + p[0]),
               dy*(.5*sizey - round_r + p[1]),
               (k==-1 ? -heightz : p[2] - round_r) ] ];
  faces =
    [ [for (i = [0 : 4*N+4-1]) i],
      for (j = [0 : N-1])
        for (i = [0 : 4*N+4-1])
          let (b1 = j*(4*N+4), b2 = (j+1)*(4*N+4))
            [ b1 + i, b2 + i, b2 + (i + 1)%(4*N+4), b1 + (i + 1)%(4*N+4) ],
      for (c = [0 : 3])
        for (i = [0 : N])
          let (b1 = N*(4*N+4), b2 = (N+1)*(4*N+4), k = c*(N+1) + i)
            (i<N ?
             [ b1 + k, b2 + c, b1 + (k + 1)%(4*N+4) ] :
             [ b1 + k, b2 + c, b2 + (c+1)%4, b1 + (k + 1)%(4*N+4) ]),
      [for (i = [3 : -1 : 0]) (N+1)*(4*N+4) + i]
    ];
  polyhedron(points=all_points, faces=faces, convexity=2);
}

module box_top_support() {
  translate([0, 0, -.5*interface_support_thick])
    cube([interface_support_size, interface_support_size, interface_support_thick],
         center=true);
}

module box_top() {
  T = webbing_base_top_thick + webbing_thick;

  difference() {
    rounded_slab(box_outer_size, box_outer_size, box_top_height, box_corner_r);
    // Inner hollow in box lid.
    translate([0, 0, -.5*box_top_height - box_top_thick]) {
      cube([box_inner_size, box_inner_size, box_top_height], center=true);
    }
    // Cutout for the top panel.
    translate ([0, 0, .5*(-T+1)])
      cube([webbing_top_size, webbing_top_size, T+1], center=true);
  }
  // Top panel interface beams.
  translate([0, 0, -T])
    top_webbing_interface(webbing_top_size, cut=true);
  %box_top_support();
}

box_bottom();
explode = (show_expanded ? 5 : 0);
if (true) {
  translate([0, 0, 2*explode + box_bottom_height + box_top_height]) top_webbing();
  translate([0, -explode, 0]) front_webbing();
  translate([0, explode, 0]) back_webbing();
  translate([-explode, 0, 0]) left_webbing();
  translate([explode, 0, 0]) right_webbing();
}

translate([0, 0, 60/* + ToDo */]) box_top();

translate([0, 0, -15]) box_top_support();
