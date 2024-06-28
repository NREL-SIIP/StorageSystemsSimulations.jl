# StorageSystemsSimulations.jl

```@meta
CurrentModule = StorageSystemsSimulations
```

## Overview

`StorageSimulations.jl` is a `PowerSimulations.jl` extension to support formulations and models
related to energy storage.

An Operational Storage Model can have multiple combinations of different restrictions. For instance,
it might be relevant to a study to consider cycling limits or employ energy targets coming from a planning model. To manage all these variations `StorageSimulations.jl` heavily uses the `DeviceModel` attributes feature.

For example, the formulation `StorageDispatchWithReserves` can be parametrized as follows:

```julia
DeviceModel(
    StorageType, # E.g. EnergyReservoirStorage
    StorageDispatchWithReserves;
    attributes=Dict(
        "reservation" => true,
        "cycling_limits" => false,
        "energy_target" => false,
        "complete_coverage" => false,
        "regularization" => true,
    ),
    use_slacks=false,
)
```

Each formulation can have different implementations for these attributes and the details can be found in the Formulation Library section in the documentation.

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

StorageSystemsSimulations has been developed as part of the Scalable Integrated Infrastructure Planning (SIIP) initiative at the U.S. Department of Energy's National Renewable Energy
Laboratory ([NREL](https://www.nrel.gov/)).
