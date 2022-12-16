# PLUTO SETUP ####
# run the below code to set up the Julia environment and launch Pluto
cd(@__DIR__)
import Pkg
Pkg.add("Pluto"; preserve=Pkg.PRESERVE_ALL)
import Pluto

Pluto.run(notebook = "01-basic-SIR-pluto.jl")
