cd(@__DIR__)
import Pkg
Pkg.activate(".")

using Random, Agents, Agents.Pathfinding
using InteractiveDynamics
using GLMakie , CairoMakie

# DEFINE AGENT ####
@agent Person GridAgent{2} begin
    mass::Float64 # set this to Inf and vel to 0,0 for immovable agent; is assumed 1 if not set for elastic_collisions
    steps_infected::Int  # number of model steps since infection
    status::Symbol  # disease status, S, I, R
    β::Float64 # infectivity (currently inherited from global model params)
    num_infected::Int # number infected, for calculating effective R0
end

# DEFINE SPACES ####
room = BitArray([  
    0 0 0 0 0 0 0 0 0 0;
    0 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 0;
    0 0 0 0 0 0 0 0 0 0;])

room2 = BitArray([  
    0 0 0 0 0 0 0 0 0 0;
    0 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 0;
    0 0 0 0 1 1 0 0 0 0;
    0 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 0;
    0 1 1 1 1 1 1 1 1 0;
    0 0 0 0 0 0 0 0 0 0;])

function init_model(bit_space;
    # agent properties
    N = 10, # number of agents
    I0 = 1, # initial number infected
    # immovable = 0.1,  # fraction of immovable agents
    # immovable_mass = Inf,
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
    # for ind in 1:N
    #     pos = Tuple(rand(model.rng, 2))
    #     status = ind ≤ N - I0 ? :S : :I
    #     isimmovable = ind ≤ immovable * N
    #     mass = isimmovable ? immovable_mass : 1.0
    #     vel = isimmovable ? (0.0, 0.0) : sincos(2π * rand(model.rng)) .* speed

    #     add_agent!(pos, model, vel, mass, 0, status, β, num_infected)
    # end

    test_person = Person(1, (3, 3), 1, 0, :S, β, 0)
    add_agent_pos!(test_person, model)
    plan_route!(test_person, (7, 7), pathfinder)

    return model, pathfinder
end 

model, pathfinder = init_model(room2)
agent_step!(agent, model) = move_along_route!(agent, model, pathfinder)

CairoMakie.activate!()
colours(agent) = agent.status == :S ? "#0000ff" : agent.status == :I ? "#ff0000" : "#00ff00"
fig, _ = abmplot(model; ac = colours, heatarray = _ -> pathfinder.walkmap)
fig


GLMakie.activate!()
model, pathfinder = init_model(room2)
fig, ax, abmobs = abmplot(model;
    agent_step! = agent_step!, 
    # model_step! = model_step!,
    ac = colours,
    heatarray = _ -> pathfinder.walkmap)
fig
