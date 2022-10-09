# SETUP ####
cd(@__DIR__)
import Pkg
Pkg.activate(".")

using Agents, Random, InteractiveDynamics, GLMakie, CairoMakie, StatsPlots, Statistics

# DEFINE AGENT ####
# (id, pos and vel properties created automatically for ContinuousAgent type)
@agent Person ContinuousAgent{2} begin
    mass::Float64 # set this to Inf and vel to 0,0 for immovable agent; is assumed 1 if not set for elastic_collisions
    steps_infected::Int  # number of model steps since infection
    status::Symbol  # disease status, S, I, R
    β::Float64 # infectivity (currently inherited from global model params)
    num_infected::Int # number infected, for calculating effective R0
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
    immovable_mass = Inf,
    num_infected = 0,

    # disease proerties
    infection_period = 200,
    reinfection_probability = 0.05,
    interaction_radius = 0.02,
    death_rate = 0.05,
    β = 0.4,

    # space/time properties (spatial extent assumed as unit square)
    Δt = 1.0,
    speed = 0.002, # initial speed of agents
    spacing = 0.02,
    seed = 1234,
    collide_physics = false,
)
    # dictionary of above properties to be applied globally to model
    properties = Dict(:infection_period => infection_period, 
        :reinfection_probability => reinfection_probability, 
        :death_rate => death_rate,
        :interaction_radius => interaction_radius,
        :collide_physics => collide_physics,
        :Δt => Δt)

    space = ContinuousSpace((1, 1); spacing = spacing)
    model = ABM(Person, space, properties = properties, rng = MersenneTwister(seed))

    # Add initial individuals
    for ind in 1:N
        pos = Tuple(rand(model.rng, 2))
        status = ind ≤ N - I0 ? :S : :I
        isimmovable = ind ≤ immovable * N
        mass = isimmovable ? immovable_mass : 1.0
        vel = isimmovable ? (0.0, 0.0) : sincos(2π * rand(model.rng)) .* speed

        add_agent!(pos, model, vel, mass, 0, status, β, num_infected)
    end

    return model
end 

model = init_model()


# DEFINE AGENT_STEP ####
# if infected, increment counter
update!(agent) = agent.status == :I && (agent.steps_infected += 1)

# if infected for long time then either kill or recover
function recover_or_die!(agent, model)
    if agent.steps_infected ≥ model.infection_period
        if rand(model.rng) ≤ model.death_rate
            kill_agent!(agent, model)
        else
            agent.status = :R
            agent.steps_infected = 0
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
    infected.num_infected += 1
end

# model step applies transmit!() and elastic_collision!() to each agent pair
function model_step!(model)
    r = model.interaction_radius
    for (a1, a2) in interacting_pairs(model, r, :nearest)
        transmit!(a1, a2, model.reinfection_probability)
        if model.collide_physics == true
            elastic_collision!(a1, a2, :mass)
        end
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
model = init_model(collide_physics = false)
colours(agent) = agent.status == :S ? "#0000ff" : agent.status == :I ? "#ff0000" : "#00ff00"
fig, ax, abmobs = abmplot(model;
    agent_step! = agent_step!, 
    model_step! = model_step!,
    ac = colours)
fig


# VIDEO TEST for collision physics ####
CairoMakie.activate!()
collide = false
model = init_model(collide_physics = collide, immovable = 0.1)
abmvideo(
    "abm_test_" * string(collide) * ".mp4",
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
immovable_1, immovable_2 = 0.0, 0.5
n_agents = 1000

model_1 = init_model(immovable = immovable_1, N=n_agents)
abm_data_1, _ = run!(model_1, agent_step!, model_step!, n_steps; adata = to_collect) # run model and collect data; returned as abm_data
abm_data_1.alive_status  = abm_data_1.infected_status + abm_data_1.recovered_status + abm_data_1.susceptible_status
abm_data_1.dead_status  = n_agents .- abm_data_1.alive_status

model_2 = init_model(immovable = immovable_2, N=n_agents)
abm_data_2, _ = run!(model_2, agent_step!, model_step!, n_steps; adata = to_collect) # run model and collect data; returned as abm_data
abm_data_2.alive_status  = abm_data_2.infected_status + abm_data_2.recovered_status + abm_data_2.susceptible_status
abm_data_2.dead_status  = n_agents .- abm_data_2.alive_status


# PLOT of infected
t = abm_data_1.step .* model_1.Δt
title = "2D ABM SIR infected"
p = StatsPlots.plot(t, abm_data_1[:, 3], xlab="time", ylabel="N agents infected", title = title, label="immovable="*string(immovable_1),lw=3)
p = StatsPlots.plot!(t, abm_data_2[:, 3], label="immovable="*string(immovable_2), lw = 3)
p
# savefig(p, "pics/infected.png")


# PLOT of alive
t = abm_data_1.step .* model_1.Δt
title = "2D ABM SIR dead"
p = StatsPlots.plot(t, abm_data_1[:, :alive_status], xlab="time", ylabel="N agents infected", title = title, label="immovable="*string(immovable_1),lw=3)
p = StatsPlots.plot!(t, abm_data_2[:, :alive_status], label="immovable="*string(immovable_2), lw = 3)
p


# R0
model_1 = init_model(immovable = immovable_1, N=n_agents)
r_data, _ = run!(model_1, agent_step!, model_step!, n_steps; adata = [:num_infected])
z = filter(row -> row["step"] == 1000, r_data)
r0_1 = round(mean(z.num_infected), digits = 2)

histogram(z.num_infected, bins=0:maximum(z.num_infected), title = "R_0 = "*string(r0_1))


model_2 = init_model(immovable = immovable_2, N=n_agents)
r_data, _ = run!(model_2, agent_step!, model_step!, n_steps; adata = [:num_infected])
z = filter(row -> row["step"] == 1000, r_data)
histogram(z.num_infected, bins=0:20)
mean(z.num_infected)


# SCRATCH ####
GLMakie.activate!()
model = init_model(N = 50, immovable = 0)
fig, ax, abmobs = abmplot(model;
    agent_step! = agent_step!, 
    model_step! = model_step!,
    ac = colours)
fig


# COLLISION VELOCITY ####
using DataFrames

model_vel = init_model(immovable_mass = 1.0, immovable = 0.0, collide_physics = true)
v_data, _ = run!(model_vel, agent_step!, model_step!, n_steps; adata = [:vel])
v_data.abs_velocity = [sqrt(sum(v_data.vel[i].^2)) for i in 1:size(v_data)[1]]
velocity_physics_true = combine(groupby(v_data, :step), :abs_velocity => mean)

model_vel = init_model(immovable_mass = 1.0, immovable = 0.0, collide_physics = false)
v_data, _ = run!(model_vel, agent_step!, model_step!, n_steps; adata = [:vel])
v_data.abs_velocity = [sqrt(sum(v_data.vel[i].^2)) for i in 1:size(v_data)[1]]
velocity_physics_false = combine(groupby(v_data, :step), :abs_velocity => mean)

# agent velocities remain constant
StatsPlots.plot(velocity_physics_false.step, velocity_physics_false.abs_velocity_mean)

# agent velocities out of control
StatsPlots.plot(velocity_physics_true.step, velocity_physics_true.abs_velocity_mean,
yaxis=:log10)
# first 100 steps...
StatsPlots.plot(velocity_physics_true.step[1:100], velocity_physics_true.abs_velocity_mean[1:100],
yaxis=:log10)

# check there are no weird dying off effects
model_vel = init_model(immovable_mass = 1.0, immovable = 0.0, collide_physics = true)
abm_data_vel, _ = run!(model_vel, agent_step!, model_step!, n_steps; adata = to_collect) # run model and collect data; returned as abm_data
abm_data_vel.alive_status  = abm_data_vel.infected_status + abm_data_vel.recovered_status + abm_data_vel.susceptible_status
minimum(abm_data_vel.alive_status)