cd(@__DIR__)
import Downloads

try
    mkdir("maps")
catch
    @warn "maps folder already exists"
end

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
