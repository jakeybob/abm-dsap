# Agent Based Modelling in Julia
[![DOI](https://zenodo.org/badge/533281355.svg)](https://zenodo.org/badge/latestdoi/533281355)

<!-- [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/jakeybob/abm-dsap/HEAD?labpath=code%2F01-basic-SIR%2F01-basic-SIR.ipynb) -->

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/jakeybob/binder-test/HEAD?labpath=01-basic-SIR.ipynb)

An agent based model prototype, developed in [Julia](https://julialang.org/downloads/) (primarily using [Agents.jl](https://juliadynamics.github.io/Agents.jl/stable/)) as part of the Scottish Government [Data Science Accelerator Programme](https://www.gov.scot/publications/data-science-accelerator/)


## Julia Setup
[https://julialang.org/downloads/](https://julialang.org/downloads/)


## Quarto / Python Setup (optional)
e.g. 

`conda env create -n quarto_python_env --file quarto_python_env.yml`

add ` export QUARTO_PYTHON="/home/USERNAME/miniconda3/envs/quarto_python_env/bin/python"` to `.bashrc` on unix-alike or

`export QUARTO_PYTHON="/Users/USERNAME/opt/anaconda3/envs/quarto_python_env/bin/python"` on MacOS, 

or set `QUARTO_PYTHON="/Path/To/quarto_python_env/bin/python` in Windows user environment variables.

...running `quarto check jupyter` should confirm this and check that Jupyter rendering works.
