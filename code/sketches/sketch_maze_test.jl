cd(@__DIR__)
import Pkg
Pkg.activate(".")
# https://juliadynamics.github.io/AgentsExampleZoo.jl/dev/examples/maze/#Maze-Solver

using Agents, Agents.Pathfinding
using FileIO # To load images you also need ImageMagick available to your project

@agent Walker GridAgent{2} begin end

function initalize_model(map_url)
    # Load the maze from the image file. White values can be identified by a
    # non-zero red component
    
    # maze = BitArray(map(x -> x.r > 0, load(download(map_url))))
    maze = BitArray(map(x -> x.r > 0, load(map_url)))


    # The size of the space is the size of the maze
    space = GridSpace(size(maze); periodic = false)
    # Create a pathfinder using the AStar algorithm by providing the space and specifying
    # the `walkmap` parameter for the pathfinder.
    # Since we are interested in the most direct path to the end, the default
    # `DirectDistance` is appropriate.
    # `diagonal_movement` is set to false to prevent cutting corners by going along
    # diagonals.
    pathfinder = AStar(space; walkmap=maze, diagonal_movement=false)
    model = ABM(Walker, space)
    # Place a walker at the start of the maze
    walker = Walker(1, (1, 4))
    add_agent_pos!(walker, model)
    # The walker's movement target is the end of the maze.
    plan_route!(walker, (41, 32), pathfinder)

    return model, pathfinder
end

# Our sample walkmap
# map_url =
#     "https://raw.githubusercontent.com/JuliaDynamics/" *
#     "JuliaDynamics/master/videos/agents/maze.bmp"
map_url = joinpath("pics", "maze.bmp")

model, pathfinder = initalize_model(map_url)

agent_step!(agent, model) = move_along_route!(agent, model, pathfinder)

using InteractiveDynamics
using CairoMakie

abmvideo(
    joinpath("pics", "maze.mp4"),
    model,
    agent_step!;
    figurekwargs = (resolution=(700,700),),
    frames=60,
    framerate=30,
    ac=:red,
    as=11,
    heatarray = _ -> pathfinder.walkmap,
    add_colorbar = false,
)
