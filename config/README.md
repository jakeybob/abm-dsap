## Julia Setup
[https://julialang.org/downloads/](https://julialang.org/downloads/)

(note: all code in this repository was written using Julia 1.8.2)

## Running Jupyter Notebooks

This can be run locally, or via e.g. binder etc.

https://jupyterhub.github.io/nbgitpuller/link?tab=binder


## Running Pluto Notebooks

This can be run locally, or via e.g. binder etc.


## Quarto / Python Setup

[Quarto](https://quarto.org) was used to write the presentations found in the [docs](docs) folder. As such, a working Quarto setup is required to compile and run them...

1. using your Python package manager of choice (e.g. [conda](https://docs.conda.io/en/latest/)) create an environment as defined in the `quarto_python_env.yml` file e.g. 
`conda env create -n quarto_python_env --file quarto_python_env.yml`

2. set a `QUARTO_PYTHON` environment variable to point to this e.g. 
` export QUARTO_PYTHON="/home/USERNAME/miniconda3/envs/quarto_python_env/bin/python"` to `.bashrc` on unix/Linux or
`export QUARTO_PYTHON="/Users/USERNAME/opt/anaconda3/envs/quarto_python_env/bin/python"` on MacOS, 
or set `QUARTO_PYTHON="/Path/To/quarto_python_env/bin/python` in the Windows user environment variables

3. finally run `quarto check jupyter` at the system command line to check that Jupyter/Quarto are configured 
