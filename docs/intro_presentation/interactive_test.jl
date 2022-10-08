# https://github.com/JuliaDynamics/AgentsExampleZoo.jl/blob/main/docs/examples/social_distancing.jl
using Agents, Random

@agent SocialAgent ContinuousAgent{2} begin
    mass::Float64
end

# Let's also initialize a trivial model with continuous space
function ball_model(; speed = 0.002)
    space2d = ContinuousSpace((1, 1); spacing = 0.02)
    model = ABM(SocialAgent, space2d, properties = Dict(:dt => 1.0), rng = MersenneTwister(42))

    ## And add some agents to the model
    for ind in 1:500
        pos = Tuple(rand(model.rng, 2))
        vel = sincos(2π * rand(model.rng)) .* speed
        add_agent!(pos, model, vel, 1.0)
    end
    return model
end

model = ball_model()

agent_step!(agent, model) = move_agent!(agent, model, model.dt)


function model_step!(model)
    for (a1, a2) in interacting_pairs(model, 0.012, :nearest)
        elastic_collision!(a1, a2, :mass)
    end
end

model2 = ball_model()

using InteractiveDynamics
using CairoMakie
CairoMakie.activate!() # hide

model3 = ball_model()

for id in 1:400
    agent = model3[id]
    agent.mass = Inf
    agent.vel = (0.0, 0.0)
end


@agent PoorSoul ContinuousAgent{2} begin
    mass::Float64
    days_infected::Int  # number of days since is infected
    status::Symbol  # :S, :I or :R
    β::Float64
end

const steps_per_day = 24

using DrWatson: @dict
function sir_initiation(;
    infection_period = 30 * steps_per_day,
    detection_time = 14 * steps_per_day,
    reinfection_probability = 0.05,
    isolated = 0.0, # in percentage
    interaction_radius = 0.012,
    dt = 1.0,
    # dt = 0.2,
    speed = 0.002,
    death_rate = 0.044, # from website of WHO
    N = 1000,
    initial_infected = 5,
    seed = 42,
    βmin = 0.4,
    βmax = 0.8,
)

    properties = (;
        infection_period,
        reinfection_probability,
        detection_time,
        death_rate,
        interaction_radius,
        dt,
    )
    space = ContinuousSpace((1,1); spacing = 0.02)
    model = ABM(PoorSoul, space, properties = properties, rng = MersenneTwister(seed))

    ## Add initial individuals
    for ind in 1:N
        pos = Tuple(rand(model.rng, 2))
        status = ind ≤ N - initial_infected ? :S : :I
        isisolated = ind ≤ isolated * N
        mass = isisolated ? Inf : 1.0
        vel = isisolated ? (0.0, 0.0) : sincos(2π * rand(model.rng)) .* speed

        ## very high transmission probability
        ## we are modelling close encounters after all
        β = (βmax - βmin) * rand(model.rng) + βmin
        add_agent!(pos, model, vel, mass, 0, status, β)
    end

    return model
end

sir_model = sir_initiation()
sir_colors(a) = a.status == :S ? "#2b2b33" : a.status == :I ? "#bf2642" : "#338c54"

using GLMakie

function transmit!(a1, a2, rp)
    ## for transmission, only 1 can have the disease (otherwise nothing happens)
    count(a.status == :I for a in (a1, a2)) ≠ 1 && return
    infected, healthy = a1.status == :I ? (a1, a2) : (a2, a1)

    rand(model.rng) > infected.β && return

    if healthy.status == :R
        rand(model.rng) > rp && return
    end
    healthy.status = :I
end

function sir_model_step!(model)
    r = model.interaction_radius
    for (a1, a2) in interacting_pairs(model, r, :nearest)
        transmit!(a1, a2, model.reinfection_probability)
        elastic_collision!(a1, a2, :mass)
    end
end


function sir_agent_step!(agent, model)
    move_agent!(agent, model, model.dt)
    update!(agent)
    recover_or_die!(agent, model)
end

update!(agent) = agent.status == :I && (agent.days_infected += 1)

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


# GLMakie.activate!()
# sir_model = sir_initiation()
# fig, ax, abmobs = abmplot(sir_model;
#     agent_step! = sir_agent_step!, 
#     model_step! = sir_model_step!,
#     ac = sir_colors,
#     as = 20)
# fig

CairoMakie.activate!()
sir_model = sir_initiation()
abmvideo(
    "presentation/sir_anim.mp4",
    sir_model,
    sir_agent_step!,
    sir_model_step!;
    title = "SIR model",
    frames = 50,
    ac = sir_colors,
    as = 20,
    spf = 1,
    framerate = 8,
)