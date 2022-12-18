# JUPYTER NOTEBOOK SETUP ####
# run the below code to set up the Julia environment and launch a Jupyter notebook
cd(@__DIR__)
import Pkg
Pkg.activate(".")
Pkg.instantiate()

using IJulia
notebook(dir = pwd())
