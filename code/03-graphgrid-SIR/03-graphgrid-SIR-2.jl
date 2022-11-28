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

bathroom_pos = (10, 2)
kitchen_pos = (2, 2)
exit_pos = (10, 9)

function init_model(bit_space;
    step = 0,
    # agent properties
    N = 10, # number of agents
    I0 = 1, # initial number infected
    num_infected = 0,

    # disease proerties
    # infection_period = 200,
    # reinfection_probability = 0.05,
    interaction_radius = 0.02,
    # death_rate = 0.02,
    β = 0.4,

    # space/time properties (spatial extent assumed as unit square)
    Δt = 1.0,
    seed = 1234,
    bathroom_weight = 0.05,
    kitchen_weight = 0.05,
    exit_weight = 0.01,
    none_weight = 1,
    journey_weights = Weights([bathroom_weight, kitchen_weight, exit_weight, none_weight])
)
    # dictionary of above properties to be applied globally to model
    properties = Dict(
        # :infection_period => infection_period, 
        # :reinfection_probability => reinfection_probability, 
        # :death_rate => death_rate,
        :interaction_radius => interaction_radius,
        :Δt => Δt,
        :journey_weights => journey_weights,
        :step => step)

    space = GridSpace(size(bit_space); periodic = false, metric = :euclidean)
    pathfinder = AStar(space; walkmap = bit_space, diagonal_movement = true)
    model = ABM(Person, space, properties = properties, rng = MersenneTwister(seed))

    # Add initial individuals
    room_size = size(bit_space)
    cols = room_size[1]
    rows = room_size[2]
    num_points = rows*cols
    valid_spaces = (bit_space .== 1)
    valid_spaces[bathroom_pos[1], bathroom_pos[2]] = false
    valid_spaces[kitchen_pos[1], kitchen_pos[2]] = false
    valid_spaces[exit_pos[1], exit_pos[2]] = false
    valid_spaces = valid_spaces[1:num_points]
    available_spaces = (1:num_points)[valid_spaces]
    positions_to_use = sample(available_spaces, N; replace=false)
    index2tuple(pos) = (rem(pos, cols), div(pos, cols)+1)
    positions_to_use = index2tuple.(positions_to_use)
    
    for ind in 1:N
        pos = positions_to_use[ind]
        status = ind ≤ N - I0 ? :S : :I
        agent = Person(ind, pos, 0, status, β, num_infected, :none, pos)
        add_agent_pos!(agent, model)
    end

    return model, pathfinder
end 

function agent_step!(agent, model)
    # if at desk then choose to either stay there or start a journey
    # if journey chosen, then plan route
    if agent.journey_type == :none
        agent.journey_type = sample([:bathroom, :kitchen, :exit, :none], model.properties[:journey_weights])
        if agent.journey_type == :bathroom
            plan_route!(agent, bathroom_pos, pathfinder)
        elseif agent.journey_type == :kitchen
            plan_route!(agent, kitchen_pos, pathfinder)
        elseif agent.journey_type == :exit
            plan_route!(agent, exit_pos, pathfinder)
        end
    end

    # if reached destination, then head back
    if (agent.journey_type == :bathroom && agent.pos == bathroom_pos) |
        (agent.journey_type == :kitchen && agent.pos == kitchen_pos) |
        (agent.journey_type == :exit && agent.pos == exit_pos)
        plan_route!(agent, agent.pos_initial, pathfinder)
    end

    # infect surrounding agents
    if agent.status == :I
        # for nearby agents, infect if they are not currently infected, 
        # but dependent on our infected agent's beta
        for nearby_agent in nearby_ids(agent, model, model.interaction_radius)
            if (rand(model.rng) > agent.β) & (model[nearby_agent].status != :I)
                model[nearby_agent].status = :I
                agent.num_infected += 1
            end
        end
    end

    # if on a journey, then move. If arrived back home, then not on a journey
    if agent.journey_type != :none
        move_along_route!(agent, model, pathfinder)
        if agent.pos == agent.pos_initial
            agent.journey_type = :none 
        end
    end

end

function model_step!(model)
    model.step += 1
end


colours(agent) = agent.status == :S ? "#0000ff" : agent.status == :I ? "#ff0000" : "#00ff00"
model, pathfinder = init_model(room; none_weight = 50, N = 20, I0 = 2, interaction_radius = 1)

# GLMakie.activate!()
# fig, ax, abmobs = abmplot(model;
#     agent_step! = agent_step!, 
#     model_step! = model_step!,
#     ac = colours,
#     heatarray = _ -> pathfinder.walkmap)
# fig

abmvideo(
    joinpath("pics", "test.mp4"),
    model,
    agent_step!,
    model_step!,
    figurekwargs = (resolution=(700,700),),
    frames=200,
    framerate=30,
    ac = colours,
    as=11,
    heatarray = _ -> pathfinder.walkmap,
    add_colorbar = false,
)
