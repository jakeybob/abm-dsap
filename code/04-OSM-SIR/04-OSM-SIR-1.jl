# SETUP ####
cd(@__DIR__)
import Pkg
Pkg.activate(".")

# https://juliahub.com/ui/Packages/OpenStreetMapX/3fbUy/0.3.3

# using Conda
# Conda.runconda(`install folium -c conda-forge`) # run via repl

using OpenStreetMapX
# import Downloads
# download("https://www.openstreetmap.org/api/0.6/map?bbox=-4.25295,55.86017,-4.24507,55.86253",
# joinpath("maps", "george_sq.osm"))

map_data = get_map_data("maps/george_sq.osm");

println("The map contains $(length(map_data.nodes)) nodes")
