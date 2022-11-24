cd(@__DIR__)
import Pkg
Pkg.activate(".")

using Random, Agents, Agents.Pathfinding
using InteractiveDynamics
using GLMakie, CairoMakie
using StatsBase

# DEFINE AGENT ####
@agent Person GridAgent{2} begin
    steps_infected::Int  # number of model steps since infection
    status::Symbol  # disease status, S, I, R
    β::Float64 # infectivity (currently inherited from global model params)
    num_infected::Int # number infected, for calculating effective R0
    journey_type::Symbol # :none, :exit, :bathroom, :kitchen
end

# DEFINE SPACE ####
room = permutedims(BitArray([  
    0 0 0 0 0 0 0 0 0 0 0;
    0 1 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 1 0;
    0 0 0 0 1 1 0 0 0 0 0;
    0 0 0 0 1 1 0 0 0 0 0;
    0 1 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 1 0;
    0 0 0 0 0 0 0 0 0 0 0;]))

function init_model(bit_space;
    # agent properties
    N = 10, # number of agents
    I0 = 1, # initial number infected
    num_infected = 0,

    # disease proerties
    infection_period = 200,
    reinfection_probability = 0.05,
    interaction_radius = 0.02,
    death_rate = 0.02,
    β = 0.4,

    # space/time properties (spatial extent assumed as unit square)
    Δt = 1.0,
    seed = 1234
)
    # dictionary of above properties to be applied globally to model
    properties = Dict(:infection_period => infection_period, 
        :reinfection_probability => reinfection_probability, 
        :death_rate => death_rate,
        :interaction_radius => interaction_radius,
        :Δt => Δt)

    space = GridSpace(size(bit_space); periodic = false)
    pathfinder = AStar(space; walkmap = bit_space, diagonal_movement = true)
    model = ABM(Person, space, properties = properties, rng = MersenneTwister(seed))

    # Add initial individuals
    room_size = size(bit_space)
    cols = room_size[1]
    rows = room_size[2]
    num_points = rows*cols
    valid_spaces = (bit_space .== 1)[1:num_points]
    available_spaces = (1:num_points)[valid_spaces]
    positions_to_use = sample(available_spaces, N; replace=false)
    index2tuple(pos) = (rem(pos, cols), div(pos, cols)+1)
    positions_to_use = index2tuple.(positions_to_use)
    
    for ind in 1:N
        pos = positions_to_use[ind]
        agent = Person(ind, pos, 1, 0, :S, β, 0)
        add_agent_pos!(agent, model)
        plan_route!(agent, (8, 3), pathfinder)
    end

    return model, pathfinder
end 