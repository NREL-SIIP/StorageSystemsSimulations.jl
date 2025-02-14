# Component Variables

# Variables Taken from PSI
# ActivePowerInVariable
# ActivePowerOutVariable
# EnergyVariable
# ReservationVariable

# Ancillary Service Assignment Variables
"""
Ancillary service fraction assigned to Storage Discharging to product p

Docs abbreviation: ``sb^{std}_{p,t}``
"""
struct AncillaryServiceVariableDischarge <: PSI.VariableType end

"""
Ancillary service fraction assigned to Storage Charging to product p

Docs abbreviation: ``sb^{stc}_{p,t}``
"""
struct AncillaryServiceVariableCharge <: PSI.VariableType end

"""
Slack variable for energy storage levels < target storage levels

Docs abbreviation: ``e^{st-}``
"""
struct StorageEnergyShortageVariable <: PSI.VariableType end

"""
Slack variable for energy storage levels > target storage levels

Docs abbreviation: ``e^{st+}``
"""
struct StorageEnergySurplusVariable <: PSI.VariableType end

"""
Slack variable for the cycling limits to allow for more charging usage than the allowed limited

Docs nomenclature: ``c^{ch-}``
"""
struct StorageChargeCyclingSlackVariable <: PSI.VariableType end

"""
Slack variable for the cycling limits to allow for more discharging usage than the allowed limited

Docs nomenclature: ``c^{ds-}``
"""
struct StorageDischargeCyclingSlackVariable <: PSI.VariableType end

"""
Abstract used for StorageRegularization variables
"""
abstract type StorageRegularizationVariable <: PSI.VariableType end

"""
Slack variable for energy storage levels > target storage levels

Docs nomenclature: ``z^{st, ch}``
"""
struct StorageRegularizationVariableCharge <: StorageRegularizationVariable end

"""
Slack variable for energy storage levels > target storage levels

Docs abbreviation: ``z^{st, ds}``
"""
struct StorageRegularizationVariableDischarge <: StorageRegularizationVariable end

"""
Auxiliary Variable for Storage Models that solve for total energy output
"""
struct StorageEnergyOutput <: PSI.AuxVariableType end
