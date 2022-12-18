# Configuration Notes

## Julia Setup
The Julia programming environment is available [here](https://julialang.org/downloads/) for all major platforms (Windows, MacOS, Linux), with platform specific installation instructions [here](https://julialang.org/downloads/platform/).

All code in this repository was written using Julia v1.8.2. 

## Running Jupyter Notebooks
### ...on the web
The interactive Jupyter notebook [here](../code/01-basic-SIR/01-basic-SIR.ipynb) can be run by launching a web-based computing environment via the [mybinder](https://mybinder.org) service.

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/jakeybob/abm-dsap/env-binder-01?urlpath=git-pull%3Frepo%3Dhttps%253A%252F%252Fgithub.com%252Fjakeybob%252Fabm-dsap%26urlpath%3Dtree%252Fabm-dsap%252Fcode%252F01-basic-SIR%252F01-basic-SIR.ipynb%26branch%3Dmain)

### ...on your computer
To run the same Jupyter notebook locally, run the launcher Julia script [here](../code/01-basic-SIR/01-basic-SIR-jupyter-setup.jl). 

## Running Pluto Notebooks
[Pluto.jl](https://github.com/fonsp/Pluto.jl) is a Julia specific, lightweight notebook format -- which contains all the information on packages / required dependencies for the notebook. [This](../code/01-basic-SIR/01-basic-SIR-pluto.jl) Pluto notebook can be launched locally in your browser, by running the short launcher script [here](../code/01-basic-SIR/01-basic-SIR-pluto-setup.jl).


## Further Configuration Notes
### Quarto / Python Setup

[Quarto](https://quarto.org) was used to write the presentations found in the [docs](docs) folder. As such, a working Quarto setup is required to compile and run them...

1. using your Python package manager of choice (e.g. [conda](https://docs.conda.io/en/latest/)) create an environment as defined in the `quarto_python_env.yml` file e.g. 

`conda env create -n quarto_python_env --file quarto_python_env.yml`

2. set a `QUARTO_PYTHON` environment variable to point to this e.g. 

`export QUARTO_PYTHON="/home/USERNAME/miniconda3/envs/quarto_python_env/bin/python"` 

to `.bashrc` on unix/Linux or

`export QUARTO_PYTHON="/Users/USERNAME/opt/anaconda3/envs/quarto_python_env/bin/python"` 

on MacOS, or set 

`QUARTO_PYTHON="/Path/To/quarto_python_env/bin/python` in the Windows user environment variables

3. finally run `quarto check jupyter` at the system command line to check that Jupyter/Quarto are configured 


### Binder Setup
The mybinder service uses the Python package [`jupyter-repo2docker`](https://repo2docker.readthedocs.io/en/latest/index.html) to build a [Docker](https://www.docker.com) image from a GitHub repository and open it in an executable environment.

This process can be (very) slow on first launch, but images are cached to speed up future launches. As any change to the main git repository branch will necessitate an image rebuild, the environment is built from an isolated branch (e.g. [`env-binder-01`](https://github.com/jakeybob/abm-dsap/tree/env-binder-01)) which contains the required Julia environment information (in a `Project.toml` file).

Additionally, the Python package [`nbgitpuller`](https://jupyterhub.github.io/nbgitpuller/install.html) is specified in a `requirements.txt` file. This enables the image build process to pull in the required notebook content (in this case it is pulled from the `main` branch).

This setup effectively decouples the environment specifications required for the image build, from the notebook content.

The nbgitpuller project also provides a useful utility for generating a launch-able mybinder link for this style of project [here](https://jupyterhub.github.io/nbgitpuller/link?tab=binder).

### API Setup
The [`code/05-web`](../code/05-web/) folder contains a script that implements a basic web API via the [`JuliaWebAPI`](https://github.com/JuliaWeb/JuliaWebAPI.jl) package. The [`srvr.jl`](../code/05-web/srvr.jl) script implements the basic SIR model from [`01-basic-SIR.jl`](../code/01-basic-SIR/01-basic-SIR.jl), wrapped in a function that listens for correctly formatted HTTP requests.

This can be run on a remote server (here a Raspberry Pi 4 running default RaspberryPi OS) by executing the following on the system command line to run the `srvr.jl` process in the background...

`julia srvr.jl &`

then, on a Julia REPL (on the remote server) start the HTTP server...

```Julia
using JuliaWebAPI   #Load package

#Create the ZMQ client that talks to the ZMQ listener above
const apiclnt = APIInvoker("tcp://127.0.0.1:9999");

#Start the HTTP server in current process (Ctrl+C to interrupt)
run_http(apiclnt, 8888)
```
This model can then be queried by sending an HTTP request to the server IP address, with the model parameters set as arguments in the request. Model outputs are then sent to a network location (but could easily be set to be returned as e.g. a .json response to the HTTP query). An example writting in R can be found [here](../code/R/api.R).
