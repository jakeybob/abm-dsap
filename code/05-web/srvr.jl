# cd(@__DIR__)
# import Pkg
# Pkg.activate(".")

# see: https://github.com/JuliaWeb/JuliaWebAPI.jl README example for instructions

# Load required packages
using JuliaWebAPI
using Agents, DataFrames, Distributions, Random, CSV

# FUNCTIONS ####

# single Agent structure -- has ID and disease status
mutable struct Person <: AbstractAgent
    id::Int64
    status::Symbol
end

# function to set up the model, by setting parameter fields and adding agents to the model
function init_model(β::Float64, c::Float64, γ::Float64, N::Int64, I0::Int64)
    properties = Dict(:β=>β, :c=>c, :γ=>γ)
    model = ABM(Person; properties=properties)
    # set I0 agents to be infected, and the rest (up to N) as susceptible
    for i in 1:N
        if i <= I0
            s = :I # these are symbols, as defined in the Person struct
        else
            s = :S
        end
        # instatiate a "Person" agent with appropriate id and status, and add to model
        p = Person(i, s)
        p = add_agent!(p, model)
    end
    return model
end


## functions to count S, I , R in agent population ####
susceptible(x) = count(i == :S for i in x)
infected(x) = count(i == :I for i in x)
recovered(x) = count(i == :R for i in x)

# WEB API ####
function abm_args(arg1, arg2, arg3)
    N = parse(Int, arg1)
    I0 = parse(Int, arg2)
    nsteps = parse(Int, arg3)

    function transmit!(agent, model, N)
        agent.status != :S && return # short-circuit "and" evaluation here means that if status is not :S, function returns here, ie this agent cannot be infected 
    
        ncontacts = rand(Poisson(model.properties[:c])) # how many contacts has our agent made in time δt?
    
        all_agent_ids = 1:N
        agent_ids = all_agent_ids[all_agent_ids .!= agent.id] # agent ids excluding our agent itself
    
        for i in 1:ncontacts
            
            alter = model[rand(agent_ids)]
    
            if alter.status == :I && (rand() ≤ model.properties[:β])
                # An infection occurs
                agent.status = :I
                break
            end
        end
    end
    
    function recover!(agent, model)
        agent.status != :I && return
        if rand() ≤ model.properties[:γ]
                agent.status = :R
        end
    end
    
    function agent_step!(agent, model)
        transmit!(agent, model, N)
        recover!(agent, model)
    end


    γ = 0.025 # prob of recovery for each time step (if infected)
    β = 0.4 # prob of a contact causing infection
    c = 0.3 # poissonian expectation value of number of contacts in time step
    abm_model = init_model(β, c, γ, N, I0) # initiate model

    to_collect = [(:status, f) for f in (susceptible, infected, recovered)] # data to collect (counts of S, I, R)
    abm_data, _ = run!(abm_model, agent_step!, nsteps; adata = to_collect) # run model and collect data; returned as abm_data
    # abm_data[!, :t] = t # insert the time vector
    path_to_csv = "data.csv" # insert path to output data here
    CSV.write(path_to_csv, abm_data)

    return N+I0+nsteps

end

# Expose API
process(
    JuliaWebAPI.create_responder([
        (abm_args, true)
    ], "tcp://127.0.0.1:9999", true, "")
)
