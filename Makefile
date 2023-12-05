.PHONY: all

all: mesh_cells.scad

mesh_cells.scad: base_mesh.svg
	./svg2scad.pl > $@
