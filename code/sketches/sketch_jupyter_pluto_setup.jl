# JUPYTER SETUP ####
cd(@__DIR__)
import Pkg
Pkg.activate(".")

# run these first time
# Pkg.add("IJulia")
# Pkg.build("IJulia")

using IJulia

notebook(dir=pwd(), detached=true) # execute this line via REPL on first run



# PLUTO SETUP ####
cd(@__DIR__)
import Pkg
Pkg.activate(".")
# Pkg.add("Pluto")

import Pluto
Pluto.run()