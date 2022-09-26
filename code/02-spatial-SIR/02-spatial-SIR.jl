# SETUP ####
cd(@__DIR__)
import Pkg
Pkg.activate(".")

using Agents, Random
# include("SpatialSIRs.jl")
# using .SpatialSIRs


# FUNCTIONS ####
function rate_to_proportion(r::Float64, t::Float64)
    1 - exp(-r*t)
end

# set up 2D agent (id, pos and vel properties created automatically for ContinuousAgent type)
@agent Person ContinuousAgent{2} begin
    # properties of each agent
    # id::Int64
    # pos::NTuple{2, Int}
    status::Symbol
    # age::Int8
    # sex::Symbol
    # type::Symbol # dummy for testing other potential variables
end


# MODEL PARAMETERS ####
begin
    Random.seed!(1234)
    Δt = 0.1 # time step width
    nsteps = 400 
    tf = nsteps * Δt # time at end of simulation
    t = 0:Δt:tf # vector of time points

    γ = rate_to_proportion(0.25, Δt) # prob of recovery for each time step (if infected)
    β = 0.4 # prob of a contact causing infection
    c = 0.3 # poissonian expectation value of number of contacts in time step

    N = 1000 # total agents
    I0 = 10 # initial infected

    properties = Dict(:β=>β, :c=>c, :γ=>γ)
    space = ContinuousSpace((1,1); spacing = 0.02) # unit space with resolution .02
    model = ABM(Person, space; properties=properties)
end


# MODEL SETUP ####
function init_model(properties::Dict, space::ContinuousSpace, N::Int64, I0::Int64)
    for i in 1:N
        if i <= I0
            s = :I # these are symbols, as defined in the Person struct
        else
            s = :S
        end
        # instatiate a "Person" agent with appropriate id and status, and add to model
        pos = Tuple(rand(2))
        vel = Tuple(rand(2))
        p = Person(i, pos, vel, s)
        p = add_agent!(p, model)
    end
    return model
end


# RUN MODEL ####
abm_model = init_model(properties, space, N, I0) # initiate model

