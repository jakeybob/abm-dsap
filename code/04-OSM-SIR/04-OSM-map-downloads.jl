cd(@__DIR__)
import Pkg
Pkg.activate(".")
import Downloads

using LightOSM, OSMMakie, GLMakie

try
    mkdir("maps")
catch
    @warn "maps folder already exists"
end

# https://github.com/MakieOrg/OSMMakie.jl
# define area boundaries
area = (
    minlat = 55.85599, minlon = -4.24921, # bottom left corner
    maxlat = 55.86071, maxlon = -4.23719 # top right corner
)


# download OpenStreetMap data
download_osm_network(:bbox; # rectangular area
    area..., # splat previously defined area boundaries
    network_type = :drive, # download motorways
    save_to_file_location = "maps/test.json"
);

# load as OSMGraph
osm = graph_from_file("maps/test.json";
    graph_type = :light, # SimpleDiGraph
    weight_type = :distance
)

# use min and max latitude to calculate approximate aspect ratio for map projection
autolimitaspect = map_aspect(area.minlat, area.maxlat)

# plot it
fig, ax, plot = osmplot(osm; axis = (; autolimitaspect))
fig


# George Square, Glasgow
# OSM format
# download("https://www.openstreetmap.org/api/0.6/map?bbox=-4.25295,55.86017,-4.24507,55.86253",
# joinpath("maps", "george_sq.osm"))

download("https://www.openstreetmap.org/api/0.6/map.json?bbox=-4.25295,55.86017,-4.24507,55.86253",
joinpath("maps", "george_sq.json"))


# Cadogan Street, Meridian Court, Glasgow
download("https://www.openstreetmap.org/api/0.6/map.json?bbox=-4.26295,55.85895,-4.25995,55.86013",
joinpath("maps", "meridian_court.json"))


# Johnstone cul-de-sac
download("https://www.openstreetmap.org/api/0.6/map.json?bbox=-4.5095,55.8312,-4.5056,55.8328",
joinpath("maps", "johnstone_cul_de_sac.json"))
