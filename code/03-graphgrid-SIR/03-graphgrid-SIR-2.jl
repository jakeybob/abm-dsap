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
    pos_initial::Tuple # initial position for agent to make return trips to
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

bathroom_pos = (8, 3)
kitchen_pos = (8, 2)
exit_pos = (9, 2)

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
    seed = 1234,
    bathroom_weight = 0.05,
    kitchen_weight = 0.05,
    exit_weight = 0.01
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
        agent = Person(ind, pos, 0, :S, β, 0, :none, pos)
        add_agent_pos!(agent, model)
    end

    return model, pathfinder
end 


function agent_step!(agent, model)
    choice = rand()
    if agent.journey_type == :none && (choice < 0.1)
        agent.journey_type = :bathroom
        plan_route!(agent, (8, 3), pathfinder)
    end

    # if reached bathroom, thehn head back
    if agent.journey_type == :bathroom && agent.pos == (8, 3)
        plan_route!(agent, agent.pos_initial, pathfinder)
    end

    # if on a journey, then move. If arrived back home, then not on a journey.
    if agent.journey_type != :none
        move_along_route!(agent, model, pathfinder)
        if agent.pos == agent.pos_initial
            agent.journey_type = :none 
        end
    end
end



GLMakie.activate!()
colours(agent) = agent.status == :S ? "#0000ff" : agent.status == :I ? "#ff0000" : "#00ff00"
model, pathfinder = init_model(room)
fig, ax, abmobs = abmplot(model;
    agent_step! = agent_step!, 
    # model_step! = model_step!,
    ac = colours,
    heatarray = _ -> pathfinder.walkmap)
fig
