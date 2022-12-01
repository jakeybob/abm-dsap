cd(@__DIR__)
import Pkg
Pkg.activate(".")

using Random, Agents, Agents.Pathfinding
using InteractiveDynamics
using GLMakie, CairoMakie
using StatsBase
using FileIO


# DEFINE AGENT ####
@agent Person GridAgent{2} begin
    steps_infected::Int  # number of model steps since infection
    status::Symbol  # disease status, S, I, R
    β::Float64 # infectivity (currently inherited from global model params)
    num_infected::Int # number infected, for calculating effective R0
    journey_type::Symbol # :none, :exit, :bathroom, :kitchen
    pos_initial::Tuple # initial position for agent to make return trips to
    pos_infected_at::Tuple # place where infected (initialise at (0, 0))
end


# DEFINE SPACE ####
walkmap_url = joinpath("pics", "meridian.bmp")
walkmap = rotr90(BitArray(map(x -> x.r > 0, load(walkmap_url))), 1)

# define points of interest and agent's desk positions
begin
    bathroom_pos = (940, 890)
    kitchen_pos = (770, 730)
    exit_pos = (860, 200)

    function combos(verts, horizs)
        points = size(verts)[1] * size(horizs)[1]
        out = Vector{Tuple{Int64, Int64}}(undef, points)
        c = 1
        for i in eachindex(horizs) , j in eachindex(verts)
            out[c] = (horizs[i], verts[j])
            c+=1
        end
        return out
    end

    desk_bank_1 = combos([130, 260, 300, 430, 470, 600, 640, 770, 810, 940], [50, 130, 210])
    desk_bank_2 = combos([300, 430, 470, 600, 640, 770], [418, 498])
    desk_bank_3 = combos([310], [652, 732, 812, 892, 972])
    desk_bank_4 = combos([300, 430, 470, 600, 640, 770], [1210, 1130])
    desk_bank_5 = combos([300, 430, 470, 600, 640, 770, 810], [1370, 1450])
    all_desks = reduce(vcat, [desk_bank_1, desk_bank_2, desk_bank_3, desk_bank_4, desk_bank_5])
end


function init_model(walkmap;
    step = 0,
    positions_to_use = all_desks,
    # agent properties
    N = size(positions_to_use)[1],
    I0 = 1, # initial number infected
    num_infected = 0,

    # disease proerties
    interaction_radius = 0.02,
    β = 0.4,

    # space/time properties (spatial extent assumed as unit square)
    Δt = 1.0,
    seed = 1234,
    bathroom_weight = 0.05,
    kitchen_weight = 0.05,
    exit_weight = 0.01,
    none_weight = 1,
    exit_signal_step = 300,
    journey_weights = Weights([bathroom_weight, kitchen_weight, exit_weight, none_weight])
)
    # dictionary of above properties to be applied globally to model
    properties = Dict(
        :interaction_radius => interaction_radius,
        :Δt => Δt,
        :journey_weights => journey_weights,
        :step => step,
        :walkmap => walkmap,
        :exit_signal_step => exit_signal_step)

    space = GridSpace(size(walkmap); periodic = false, metric = :euclidean)
    pathfinder = AStar(space; walkmap = walkmap, diagonal_movement = true)
    model = ABM(Person, space, properties = properties, rng = MersenneTwister(seed))

    # Add initial individuals
    infected_inds = sample(1:N, I0) # randomly choose who is infected
    for ind in 1:N
        pos = positions_to_use[ind]
        status = ind in infected_inds ? :I : :S
        agent = Person(ind, pos, 0, status, β, num_infected, :none, pos, (0, 0))
        add_agent_pos!(agent, model)
    end

    return model, pathfinder
end 

function agent_step!(agent, model)
    # if at desk then choose to either stay there or start a journey
    # if journey chosen, then plan route
    if agent.journey_type == :none
        agent.journey_type = sample([:bathroom, :kitchen, :exit, :none], model.properties[:journey_weights])
        if model.step >= model.exit_signal_step
            agent.journey_type = :exit
        end
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
                model[nearby_agent].pos_infected_at = model[nearby_agent].pos 
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

    if (agent.pos == exit_pos) & (model.step >= model.exit_signal_step)
        kill_agent!(agent, model)
    end

end

function model_step!(model)
    model.step += 1
end


# OUTPUT ####
colours(agent) = agent.status == :S ? "#0000ff" : agent.status == :I ? "#ff0000" : "#00ff00"

# GENERAL ANIMATION: showing behaviours etc ####
model, pathfinder = init_model(walkmap; none_weight = 150, I0 = 2, interaction_radius = 1, exit_signal_step = 2500)

abmvideo(
    joinpath("pics", "meridian_agent_anim.mp4"),
    model,
    agent_step!,
    model_step!,
    figure = (; resolution = (1500, 1000)),
    # figure = (; resolution = (750, 500)),
    axis = (; yticksvisible = false, xticksvisible = false, yticklabelsvisible = false, xticklabelsvisible = false, leftspinevisible = false),
    frames = 1100,
    framerate = 30,
    spf = 5,
    ac = colours,
    as = 32,
    heatarray = _ -> pathfinder.walkmap,
    add_colorbar = false,
    showstep = true
    )


    
# GLMakie.activate!()
# fig, ax, abmobs = abmplot(model;
#     agent_step! = agent_step!, 
#     model_step! = model_step!,
#     ac = colours,
#     heatarray = _ -> pathfinder.walkmap)
# fig
