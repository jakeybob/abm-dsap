cd(@__DIR__)
import Pkg
Pkg.activate(".")

using Agents, Random, InteractiveDynamics, CairoMakie, GLMakie

# DEFINE AGENT ####
# (id, and pos properties created automatically for OSMAgent type)
@agent Person OSMAgent begin
    steps_infected::Int  # number of model steps since infection
    status::Symbol  # disease status, S, I, R
    β::Float64 # infectivity (currently inherited from global model params)
    num_infected::Int # number infected, for calculating effective R0
    speed::Float64
    # age::Int8
    # sex::Symbol
    # type::Symbol # dummy for testing other potential variables
end

# DEFINE MODEL ####
function init_model(;
    map_path = OSM.test_map(),

    # agent properties
    N = 100, # number of agents
    I0 = 5, # initial number infected
    num_infected = 0,

    # disease proerties
    infection_period = 200,
    reinfection_probability = 0.05,
    interaction_radius = 0.02,
    death_rate = 0.02,
    β = 0.4,

    # space/time properties
    Δt = 1.0,
    speed = 2, # speed of agents
    # spacing = 0.02,
    seed = 1234,
)
    # dictionary of above properties to be applied globally to model
    properties = Dict(:infection_period => infection_period, 
        :reinfection_probability => reinfection_probability, 
        :death_rate => death_rate,
        :interaction_radius => interaction_radius,
        :Δt => Δt)

    # intialise space and model
    space = OpenStreetMapSpace(map_path)
    model = ABM(Person, space, properties = properties, rng = MersenneTwister(seed))

    # add agents
    for id in 1:N
        status = id ≤ N - I0 ? :S : :I
        start = random_position(model) 
        # speed = rand(model.rng) * 5.0 + 2.0 
        agent = Person(id, start, 0, status, β, num_infected, speed)
        add_agent_pos!(agent, model)
        OSM.plan_random_route!(agent, model; limit = 50) # try 50 times to find a random route
    end

    return(model)
end

model = init_model()


# DEFINE AGENT_STEP ####
# if infected, increment counter
update!(agent) = agent.status == :I && (agent.steps_infected += 1)

function recover_or_die!(agent, model)
    killed = false
    if (agent.status == :I) & (agent.steps_infected ≥ model.infection_period)
        if rand(model.rng) ≤ model.death_rate
            kill_agent!(agent, model)
            killed = true
        end
    end

    if (killed == false) & (agent.status == :I)
        if rand(model.rng) < 0.005
            agent.status = :R
        end
    end
end


# combine these into agent_step()
function agent_step!(agent, model)
    # move_agent!(agent, model, model.Δt)

    distance_left = move_along_route!(agent, model, agent.speed * model.Δt)
    if is_stationary(agent, model) && rand(model.rng) < 0.1
        # When stationary, give the agent a 10% chance of going somewhere else
        OSM.plan_random_route!(agent, model; limit = 50)
        # Start on new route, moving the remaining distance
        move_along_route!(agent, model, distance_left)
    end

    if agent.status == :I
        map(i -> model[i].status = :I, nearby_ids(agent, model, 0.01)) 
    end

    update!(agent)
    recover_or_die!(agent, model)
end


susceptible(x) = count(i == :S for i in x)
infected(x) = count(i == :I for i in x)
recovered(x) = count(i == :R for i in x)
to_collect = [(:status, f) for f in (susceptible, infected, recovered)]
colours(agent) = agent.status == :S ? "#0000ff" : agent.status == :I ? "#ff0000" : "#00ff00"

# output video
begin
    CairoMakie.activate!()
    model = init_model(speed=0.005)
    fps = 60
    duration = 10
    abmvideo("osm_test.mp4", model, agent_step!;
    title = "SIR test", framerate = fps, frames = fps*duration, ac=colours)
end

# output interactive
begin
    GLMakie.activate!()
    model = init_model(speed=0.005)
    fig, ax, abmobs = abmplot(model;
        agent_step! = agent_step!, 
        # model_step! = model_step!,
        ac = colours,
        as = 40)
    fig
end
