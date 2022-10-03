# SETUP ####
cd(@__DIR__)
import Pkg
Pkg.activate(".")

using Agents, Random, InteractiveDynamics, GLMakie, CairoMakie, StatsPlots


# DEFINE AGENT ####
# (id, pos and vel properties created automatically for ContinuousAgent type)
@agent Person ContinuousAgent{2} begin
    mass::Float64 # set this to Inf and vel to 0,0 for immovable agent; is assumed 1 if not set for elastic_collisions
    days_infected::Int  # number of days since is infected
    status::Symbol  # disease status, S, I, R
    β::Float64 # infectivity (currently inherited from global model params)
    # num_infected::Int # number infected, for calculating effective R0
    # age::Int8
    # sex::Symbol
    # type::Symbol # dummy for testing other potential variables
end


# DEFINE MODEL ####
function init_model(;
    # agent properties
    N = 1000, # number of agents
    I0 = 5, # initial number infected
    immovable = 0.1,  # fraction of immovable agents

    # disease proerties
    infection_period = 700,
    reinfection_probability = 0.05,
    interaction_radius = 0.012,
    death_rate = 0.05,
    β = 0.4,

    # space/time properties (spatial extent assumed as unit square)
    Δt = 1.0,
    speed = 0.002, # initial speed of agents
    spacing = 0.02,
    seed = 1234,
)
    # dictionary of above properties to be applied globally to model
    properties = Dict(:infection_period => infection_period, 
        :reinfection_probability => reinfection_probability, 
        :death_rate => death_rate,
        :interaction_radius => interaction_radius,
        :Δt => Δt)

    space = ContinuousSpace((1, 1); spacing = spacing)
    model = ABM(Person, space, properties = properties, rng = MersenneTwister(seed))

    # Add initial individuals
    for ind in 1:N
        pos = Tuple(rand(model.rng, 2))
        status = ind ≤ N - I0 ? :S : :I
        isimmovable = ind ≤ immovable * N
        mass = isimmovable ? Inf : 1.0
        vel = isimmovable ? (0.0, 0.0) : sincos(2π * rand(model.rng)) .* speed

        add_agent!(pos, model, vel, mass, 0, status, β)
    end

    return model
end 

model = init_model()


# DEFINE AGENT_STEP ####
# if infected, increment counter
update!(agent) = agent.status == :I && (agent.days_infected += 1)

# if infected for long time then either kill or recover
function recover_or_die!(agent, model)
    if agent.days_infected ≥ model.infection_period
        if rand(model.rng) ≤ model.death_rate
            kill_agent!(agent, model)
        else
            agent.status = :R
            agent.days_infected = 0
        end
    end
end

# combine these into agent_step()
function agent_step!(agent, model)
    move_agent!(agent, model, model.Δt)
    update!(agent)
    recover_or_die!(agent, model)
end


# DEFINE MODEL_STEP ####
# transmit function to work with interacting_pairs()
function transmit!(a1, a2, reinfection_probability)
    # short circuit if the pair does not have 1 infected (nothing happens with 0 or 2)
    count(a.status == :I for a in (a1, a2)) ≠ 1 && return

    # infected, healthy = (a1, a2) if a1 is infefcted; and vice-versa if not
    infected, healthy = a1.status == :I ? (a1, a2) : (a2, a1)

    # depending on infected agent infectivity, 
    # short circuit here (ie transmission does not occur at this encounter)
    rand(model.rng) > infected.β && return

    # similarly, short circuit depending on the reinfection probability
    if healthy.status == :R
        rand(model.rng) > reinfection_probability && return
    end

    # otherwise, healthy agent is infected
    healthy.status = :I
end

# model step applies transmit!() and elastic_collision!() to each agent pair
function model_step!(model)
    r = model.interaction_radius
    for (a1, a2) in interacting_pairs(model, r, :nearest)
        transmit!(a1, a2, model.reinfection_probability)
        elastic_collision!(a1, a2, :mass)
    end
end


# PLOT INITIAL MODEL STATE ####
CairoMakie.activate!()
model = init_model()
colours(agent) = agent.status == :S ? "#0000ff" : agent.status == :I ? "#ff0000" : "#00ff00"
fig, _, _ = abmplot(model; ac = colours)
fig


# INTERACTIVE MODEL ####
GLMakie.activate!()
model = init_model()
fig, ax, abmobs = abmplot(model;
    agent_step! = agent_step!, 
    model_step! = model_step!,
    ac = colours)
fig


# VIDEO OUTPUT ####
CairoMakie.activate!()
model = init_model()
abmvideo(
    "abm_test.mp4",
    model,
    agent_step!,
    model_step!;
    title = "SIR/ABM model",
    frames = 1000,
    ac = colours,
    as = 10,
    spf = 1,
    framerate = 20,
)


# ANALYSIS ####
susceptible(x) = count(i == :S for i in x)
infected(x) = count(i == :I for i in x)
recovered(x) = count(i == :R for i in x)
to_collect = [(:status, f) for f in (susceptible, infected, recovered)]


n_steps = 1000
immovable_1, immovable_2 = 0.0, 0.2

model_1 = init_model(immovable = immovable_1)
abm_data_1, _ = run!(model_1, agent_step!, model_step!, n_steps; adata = to_collect) # run model and collect data; returned as abm_data

model_2 = init_model(immovable = immovable_2)
abm_data_2, _ = run!(model_2, agent_step!, model_step!, n_steps; adata = to_collect) # run model and collect data; returned as abm_data

figure = Figure()
ax = figure[1, 1] = Axis(figure; ylabel = "Infected")
l1 = lines!(ax, abm_data_1[:, dataname((:status, infected))], color = :orange)
l2 = lines!(ax, abm_data_2[:, dataname((:status, infected))], color = :blue)

figure[1, 2][1,1] =
    Legend(figure, [l1, l2], ["immovable = $immovable_1", "immovable = $immovable_2"])
figure


# t = abm_data_1.step .* model_1.Δt
# title = "plot"
# p = plot(t, abm_data_1[:, 3], xlab="time", ylabel="N agents", title = title, lw=3)
# p = plot!(t, abm_data_1[:, 4], label="I", lw = 3)




