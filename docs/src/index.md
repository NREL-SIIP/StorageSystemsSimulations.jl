## StorageSystemsSimulations.jl

```@meta
CurrentModule = StorageSystemsSimulations
```

## About

`StorageSystemsSimulations.jl` is a [`PowerSimulations.jl`](https://github.com/NREL-Sienna/PowerSystems.jl) extension to support formulations and models related to energy storage. Operational Storage Models can have multiple combinations of different resitrctions. To manage these variations `StorageSystemsSimulations.jl` relies on the [`DeviceModels`](https://nrel-sienna.github.io/PowerSimulations.jl/latest/api/PowerSimulations/#PowerSimulations.DeviceModel) attributes feature. Formulations can have varying implementations for different attributes defined in [`PowerSimulations.DeviceModel`](https://nrel-sienna.github.io/PowerSimulations.jl/latest/api/PowerSimulations/#PowerSimulations.DeviceModel).

## Installation

The latest stable release of PowerSimulations can be installed using the Julia package manager with

```
(@v1.10) pkg> add PowerSimulations StorageSystemsSimulations
```

For the current development version, "checkout" this package with

```
(@v1.10) pkg> add PowerSimulations StorageSystemsSimulations#main
```

An appropriate optimization solver is required for running StorageSystemsSimulations models. Refer to [`JuMP.jl` solver's page](https://jump.dev/JuMP.jl/stable/installation/#Install-a-solver) to select the most appropriate for the application of interest.

## How To Use This Documentation

There are five main sections containing different information:

  - **Tutorials** - Detailed walk-throughs to help you *learn* how to use
    `StorageSystemsSimulations.jl`
  - **How to...** - Directions to help *guide* your work for a particular task
  - **Explanation** - Additional details and background information to help you *understand*
    `StorageSystemsSimulations.jl`, its structure, and how it works behind the scenes
  - **Reference** - Technical references and API for a quick *look-up* during your work
  - **Model Library** - Technical references of the data types and their functions that
    `StorageSystemsSimulations.jl` uses to model power system components

`StorageSystemsSimulation.jl` strives to follow the [Diataxis](https://diataxis.fr/) documentation
framework.

## Getting Started

If you are new to `StorageSystemsSimulations.jl`, here's how we suggest getting started:

 1. [Installation](@ref)

 2. Work through the introductory tutorial: `Tutorial that doesn't exist yet` to familiarize yourself with how `StorageSystemsSimulations.jl` works.
 3. Work through other basic tutorials pertaining to your interest:
    
      + `Simulating operations with StorageSystemSimulations`
      + `Solving an operation with StorageSystemSimulations`

StorageSystemsSimulations has been developed as part of the Scalable Integrated Infrastructure Planning (SIIP) initiative at the U.S. Department of Energy's National Renewable Energy
Laboratory ([NREL](https://www.nrel.gov/)).
