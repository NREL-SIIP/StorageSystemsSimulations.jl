"""
Adds a constraint to enforce a minimum energy level target with a slack variable associated witha penalty term.
"""
struct EnergyTargetFeedforward <: PSI.AbstractAffectFeedforward
    optimization_container_key::PSI.OptimizationContainerKey
    affected_values::Vector{<:PSI.OptimizationContainerKey}
    target_period::Int
    penalty_cost::Float64
    function EnergyTargetFeedforward(;
        component_type::Type{<:PSY.Component},
        source::Type{T},
        affected_values::Vector{DataType},
        target_period::Int,
        penalty_cost::Float64,
        meta=PSI.CONTAINER_KEY_EMPTY_META,
    ) where {T}
        values_vector = Vector{PSI.VariableKey}(undef, length(affected_values))
        for (ix, v) in enumerate(affected_values)
            if v <: PSI.VariableType
                values_vector[ix] =
                    PSI.get_optimization_container_key(v(), component_type, meta)
            else
                error(
                    "EnergyTargetFeedforward is only compatible with VariableType or ParamterType affected values",
                )
            end
        end
        new(
            PSI.get_optimization_container_key(T(), component_type, meta),
            values_vector,
            target_period,
            penalty_cost,
        )
    end
end

PSI.get_default_parameter_type(::EnergyTargetFeedforward, _) = EnergyTargetParameter
PSI.get_optimization_container_key(ff::EnergyTargetFeedforward) =
    ff.optimization_container_key

function PSI._add_feedforward_arguments!(
    container::PSI.OptimizationContainer,
    model::PSI.DeviceModel,
    devices::IS.FlattenIteratorWrapper{T},
    ff::EnergyTargetFeedforward,
) where {T <: PSY.Storage}
    time_steps = PSI.get_time_steps(container)
    parameter_type = PSI.get_default_parameter_type(ff, T)
    PSI.add_parameters!(container, parameter_type, ff, model, devices)
    # Enabling this FF requires the addition of an extra variable
    PSI.add_variables!(
        container,
        StorageEnergyShortageVariable,
        devices,
        time_steps,
        PSI.get_formulation(model)(),
    )
    return
end

@doc raw"""
        add_feedforward_constraints(
            container::OptimizationContainer,
            ::DeviceModel,
            devices::IS.FlattenIteratorWrapper{T},
            ff::EnergyTargetFeedforward,
        ) where {T <: PSY.Component}

Constructs a equality constraint to a fix a variable in one model using the variable value from other model results.


``` variable[var_name, t] + slack[var_name, t] >= param[var_name, t] ```

# LaTeX

`` x + slack >= param``

# Arguments
* container::OptimizationContainer : the optimization_container model built in PowerSimulations
* model::DeviceModel : the device model
* devices::IS.FlattenIteratorWrapper{T} : list of devices
* ff::EnergyTargetFeedforward : a instance of the EnergyTarget Feedforward
"""
function PSI.add_feedforward_constraints!(
    container::PSI.OptimizationContainer,
    ::PSI.DeviceModel{T, U},
    devices::IS.FlattenIteratorWrapper{T},
    ff::EnergyTargetFeedforward,
) where {T <: PSY.Storage, U <: AbstractStorageFormulation}
    time_steps = PSI.get_time_steps(container)
    parameter_type = PSI.get_default_parameter_type(ff, T)
    param = PSI.get_parameter_array(container, parameter_type(), T)
    multiplier = PSI.get_parameter_multiplier_array(container, parameter_type(), T)
    target_period = ff.target_period
    penalty_cost = ff.penalty_cost
    for var in PSI.get_affected_values(ff)
        variable = PSI.get_variable(container, var)
        slack_var = PSI.get_variable(container, StorageEnergyShortageVariable(), T)
        set_name, set_time = JuMP.axes(variable)
        IS.@assert_op set_name == [PSY.get_name(d) for d in devices]
        IS.@assert_op set_time == time_steps

        var_type = PSI.get_entry_type(var)
        con_ub = PSI.add_constraints_container!(
            container,
            PSI.FeedforwardEnergyTargetConstraint(),
            T,
            set_name;
            meta="$(var_type)target",
        )

        for d in devices
            name = PSY.get_name(d)
            con_ub[name] = JuMP.@constraint(
                PSI.get_jump_model(container),
                variable[name, target_period] + slack_var[name, target_period] >=
                param[name, target_period] * multiplier[name, target_period]
            )
            PSI.add_to_objective_invariant_expression!(
                container,
                slack_var[name, target_period] * penalty_cost,
            )
        end
    end
    return
end

"""
Adds a constraint to limit the sum of a variable over the number of periods to the source value
"""
struct EnergyLimitFeedforward <: PSI.AbstractAffectFeedforward
    optimization_container_key::PSI.OptimizationContainerKey
    affected_values::Vector{<:PSI.OptimizationContainerKey}
    number_of_periods::Int
    function EnergyLimitFeedforward(;
        component_type::Type{<:PSY.Component},
        source::Type{T},
        affected_values::Vector{DataType},
        number_of_periods::Int,
        meta=PSI.CONTAINER_KEY_EMPTY_META,
    ) where {T}
        values_vector = Vector{PSI.VariableKey}(undef, length(affected_values))
        for (ix, v) in enumerate(affected_values)
            if v <: PSI.VariableType
                values_vector[ix] =
                    PSI.get_optimization_container_key(v(), component_type, meta)
            else
                error(
                    "EnergyLimitFeedforward is only compatible with VariableType or ParamterType affected values",
                )
            end
        end
        new(
            PSI.get_optimization_container_key(T(), component_type, meta),
            values_vector,
            number_of_periods,
        )
    end
end

PSI.get_default_parameter_type(::EnergyLimitFeedforward, _) = EnergyLimitParameter
PSI.get_optimization_container_key(ff) = ff.optimization_container_key
get_number_of_periods(ff) = ff.number_of_periods

@doc raw"""
        add_feedforward_constraints(container::OptimizationContainer,
                        cons_name::Symbol,
                        param_reference,
                        var_key::VariableKey)

Constructs a parameterized integral limit constraint to implement feedforward from other models.
The Parameters are initialized using the upper boundary values of the provided variables.


``` sum(variable[var_name, t] for t in 1:affected_periods)/affected_periods <= param_reference[var_name] ```

# LaTeX

`` \sum_{t} x \leq param^{max}``

# Arguments
* container::OptimizationContainer : the optimization_container model built in PowerSimulations
* model::DeviceModel : the device model
* devices::IS.FlattenIteratorWrapper{T} : list of devices
* ff::FixValueFeedforward : a instance of the FixValue Feedforward
"""
function PSI.add_feedforward_constraints!(
    container::PSI.OptimizationContainer,
    ::PSI.DeviceModel,
    devices::IS.FlattenIteratorWrapper{T},
    ff::EnergyLimitFeedforward,
) where {T <: PSY.Component}
    time_steps = PSI.get_time_steps(container)
    parameter_type = PSI.get_default_parameter_type(ff, T)
    param = PSI.get_parameter_array(container, parameter_type(), T)
    multiplier = PSI.get_parameter_multiplier_array(container, parameter_type(), T)
    affected_periods = get_number_of_periods(ff)
    for var in PSI.get_affected_values(ff)
        variable = PSI.get_variable(container, var)
        set_name, set_time = JuMP.axes(variable)
        IS.@assert_op set_name == [PSY.get_name(d) for d in devices]
        IS.@assert_op set_time == time_steps

        if affected_periods > set_time[end]
            error(
                "The number of affected periods $affected_periods is larger than the periods available $(set_time[end])",
            )
        end
        no_trenches = set_time[end] ÷ affected_periods
        var_type = PSI.get_entry_type(var)
        con_ub = PSI.add_constraints_container!(
            container,
            PSI.FeedforwardIntegralLimitConstraint(),
            T,
            set_name,
            1:no_trenches;
            meta="$(var_type)integral",
        )

        for name in set_name, i in 1:no_trenches
            con_ub[name, i] = JuMP.@constraint(
                container.JuMPmodel,
                sum(
                    variable[name, t] for
                    t in (1 + (i - 1) * affected_periods):(i * affected_periods)
                ) <= sum(
                    param[name, t] * multiplier[name, t] for
                    t in (1 + (i - 1) * affected_periods):(i * affected_periods)
                )
            )
        end
    end
    return
end

# TODO: It also needs the add parameters code

function PSI.update_parameter_values!(
    model::PSI.OperationModel,
    key::PSI.ParameterKey{T, U},
    input::PSI.DatasetContainer{PSI.InMemoryDataset},
) where {T <: EnergyLimitParameter, U <: PSY.Generator}
    # Enable again for detailed debugging
    # TimerOutputs.@timeit RUN_SIMULATION_TIMER "$T $U Parameter Update" begin
    optimization_container = PSI.get_optimization_container(model)
    # Note: Do not instantite a new key here because it might not match the param keys in the container
    # if the keys have strings in the meta fields
    parameter_array = PSI.get_parameter_array(optimization_container, key)
    parameter_attributes = PSI.get_parameter_attributes(optimization_container, key)
    internal = PSI.get_internal(model)
    execution_count = internal.execution_count
    current_time = PSI.get_current_time(model)
    state_values =
        PSI.get_dataset_values(input, PSI.get_attribute_key(parameter_attributes))
    component_names, time = axes(parameter_array)
    resolution = PSI.get_resolution(model)
    interval_time_steps =
        Int(PSI.get_interval(model.internal.store_parameters) / resolution)
    state_data = PSI.get_dataset(input, PSI.get_attribute_key(parameter_attributes))
    state_timestamps = state_data.timestamps
    max_state_index = PSI.get_num_rows(state_data)

    state_data_index = PSI.find_timestamp_index(state_timestamps, current_time)
    sim_timestamps = range(current_time; step=resolution, length=time[end])
    old_parameter_values = jump_value.(parameter_array)
    # The current method uses older parameter values because when passing the energy output from one stage
    # to the next, the aux variable values gets over-written by the lower level model after its solve.
    # This approach is a temporary hack and will be replaced in future versions.
    for t in time
        timestamp_ix = min(max_state_index, state_data_index + 1)
        @debug "parameter horizon is over the step" max_state_index > state_data_index + 1
        if state_timestamps[timestamp_ix] <= sim_timestamps[t]
            state_data_index = timestamp_ix
        end
        for name in component_names
            # the if statement checks if its the first solve of the model and uses the values stored in the state
            # and for subsequent solves uses the state data to update the parameter values for the last set of time periods
            # that are equal to the length of the interval i.e. the time periods that dont overlap between each solves.
            if execution_count == 0 || t > time[end] - interval_time_steps
                # Pass indices in this way since JuMP DenseAxisArray don't support view()
                state_value = state_values[name, state_data_index]
                if !isfinite(state_value)
                    error(
                        "The value for the system state used in $(encode_key_as_string(key)) is not a finite value $(state_value) \
                         This is commonly caused by referencing a state value at a time when such decision hasn't been made. \
                         Consider reviewing your models' horizon and interval definitions",
                    )
                end
                PSI._set_param_value!(parameter_array, state_value, name, t)
            else
                # Currently the update method relies on using older parameter values of the EnergyLimitParameter
                # to update the parameter for overlapping periods between solves i.e. we ingoring the parameter values
                # in the model interval time periods.
                state_value = state_values[name, state_data_index]
                if !isfinite(state_value)
                    error(
                        "The value for the system state used in $(encode_key_as_string(key)) is not a finite value $(state_value) \
                         This is commonly caused by referencing a state value at a time when such decision hasn't been made. \
                         Consider reviewing your models' horizon and interval definitions",
                    )
                end
                PSI._set_param_value!(
                    parameter_array,
                    old_parameter_values[name, t + interval_time_steps],
                    name,
                    t,
                )
            end
        end
    end

    IS.@record :execution PSI.ParameterUpdateEvent(
        T,
        U,
        parameter_attributes,
        PSI.get_current_timestamp(model),
        PSI.get_name(model),
    )
    return
end
