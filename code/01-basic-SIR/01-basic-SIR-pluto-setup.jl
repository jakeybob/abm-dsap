# PLUTO SETUP ####
# run the below code to set up the Julia environment and launch Pluto

cd(@__DIR__)
import Pkg
Pkg.activate(".")
Pkg.instantiate()
Pkg.precompile()
# Pkg.resolve()
import Pluto
Pluto.run()