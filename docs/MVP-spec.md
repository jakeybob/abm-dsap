# Minimum Viable Product Specification

## Format
* an interactive Jupyter / Pluto notebook implementing a simple but customisable infectious disease agent-based model in Julia
* web hosted
* appropriate commentary through the notebook re agent-based modelling, user definable parameter meanings/values, and outputs

## User Definable Parameters
* $N$ number of agents
* $\beta$ probability of a contact causing an infection
* $c$ (Poissonian) expectation of number of contacts per unit time
* $steps$ number of time steps
* $\Delta t$ length of each time step

## Outputs
* plot/s of e.g. susceptible, infected, recovered populations over the timescale specified by the user
