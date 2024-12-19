@testset "Decision Model initial_conditions test for Storage" begin
    ######## Test with BookKeeping ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat"; force_build=true)
    set_device_model!(template, EnergyReservoirStorage, StorageDispatchWithReserves)
    model = DecisionModel(template, c_sys5_bat; optimizer=HiGHS_optimizer)
    @test build!(model; output_dir=mktempdir(; cleanup=true)) == PSI.ModelBuildStatus.BUILT
    check_energy_initial_conditions_values(model, EnergyReservoirStorage)
    @test solve!(model) == PSI.RunStatus.SUCCESSFULLY_FINALIZED

    ######## Test with EnergyTarget ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat_ems"; force_build=true)
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    set_device_model!(template, device_model)
    model = DecisionModel(template, c_sys5_bat; optimizer=HiGHS_optimizer)
    @test build!(model; output_dir=mktempdir(; cleanup=true)) == PSI.ModelBuildStatus.BUILT
    check_energy_initial_conditions_values(model, EnergyReservoirStorage)
    @test solve!(model) == PSI.RunStatus.SUCCESSFULLY_FINALIZED
end

@testset "Emulation Model initial_conditions test for Storage" begin
    ######## Test with BookKeeping ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(
        PSITestSystems,
        "c_sys5_bat";
        add_single_time_series=true,
        force_build=true,
    )
    set_device_model!(template, EnergyReservoirStorage, StorageDispatchWithReserves)
    model = EmulationModel(template, c_sys5_bat; optimizer=HiGHS_optimizer)
    @test build!(model; executions=10, output_dir=mktempdir(; cleanup=true)) ==
          PSI.ModelBuildStatus.BUILT
    ic_data = PSI.get_initial_condition(
        PSI.get_optimization_container(model),
        InitialEnergyLevel(),
        EnergyReservoirStorage,
    )
    for ic in ic_data
        d = ic.component
        name = PSY.get_name(d)
        e_var = PSI.jump_value(PSI.get_value(ic))
        @test PSY.get_initial_storage_capacity_level(d) *
              PSY.get_storage_capacity(d) *
              PSY.get_conversion_factor(d) == e_var
    end
    @test run!(model) == PSI.RunStatus.SUCCESSFULLY_FINALIZED

    ######## Test with BatteryAncillaryServices ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(
        PSITestSystems,
        "c_sys5_bat";
        add_single_time_series=true,
        force_build=true,
    )
    set_device_model!(template, EnergyReservoirStorage, StorageDispatchWithReserves)
    model = EmulationModel(template, c_sys5_bat; optimizer=HiGHS_optimizer)
    @test build!(model; executions=10, output_dir=mktempdir(; cleanup=true)) ==
          PSI.ModelBuildStatus.BUILT
    ic_data = PSI.get_initial_condition(
        PSI.get_optimization_container(model),
        InitialEnergyLevel(),
        EnergyReservoirStorage,
    )
    for ic in ic_data
        d = ic.component
        name = PSY.get_name(d)
        e_var = PSI.jump_value(PSI.get_value(ic))
        @test PSY.get_initial_storage_capacity_level(d) *
              PSY.get_storage_capacity(d) *
              PSY.get_conversion_factor(d) == e_var
    end
    @test run!(model) == PSI.RunStatus.SUCCESSFULLY_FINALIZED

    ######## Test with EnergyTarget ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(
        PSITestSystems,
        "c_sys5_bat_ems";
        add_single_time_series=true,
        force_build=true,
    )
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => true,
            "regularization" => false,
        ),
    )
    set_device_model!(template, device_model)
    model = EmulationModel(template, c_sys5_bat; optimizer=HiGHS_optimizer)
    @test build!(model; executions=10, output_dir=mktempdir(; cleanup=true)) ==
          PSI.ModelBuildStatus.BUILT
    ic_data = PSI.get_initial_condition(
        PSI.get_optimization_container(model),
        InitialEnergyLevel(),
        EnergyReservoirStorage,
    )
    for ic in ic_data
        d = ic.component
        name = PSY.get_name(d)
        e_var = PSI.jump_value(PSI.get_value(ic))
        @test PSY.get_initial_storage_capacity_level(d) *
              PSY.get_storage_capacity(d) *
              PSY.get_conversion_factor(d) == e_var
    end
    @test run!(model) == PSI.RunStatus.SUCCESSFULLY_FINALIZED
end

@testset "Simulation with 2-Stages EnergyLimitFeedforward with EnergyReservoirStorage" begin
    sys_uc = build_system(PSITestSystems, "c_sys5_bat")
    sys_ed = build_system(PSITestSystems, "c_sys5_bat")

    template_uc = get_template_basic_uc_storage_simulation()
    template_ed = get_template_dispatch_storage_simulation()

    models = SimulationModels(;
        decision_models=[
            DecisionModel(
                template_uc,
                sys_uc;
                name="UC",
                optimizer=HiGHS_optimizer,
                store_variable_names=true,
            ),
            DecisionModel(
                template_ed,
                sys_ed;
                name="ED",
                optimizer=HiGHS_optimizer,
                store_variable_names=true,
            ),
        ],
    )

    sequence = SimulationSequence(;
        models=models,
        feedforwards=Dict(
            "ED" => [
                SemiContinuousFeedforward(;
                    component_type=ThermalStandard,
                    source=OnVariable,
                    affected_values=[ActivePowerVariable],
                ),
                EnergyLimitFeedforward(;
                    component_type=EnergyReservoirStorage,
                    source=ActivePowerOutVariable,
                    affected_values=[ActivePowerOutVariable],
                    number_of_periods=12,
                ),
            ],
        ),
        ini_cond_chronology=InterProblemChronology(),
    )

    sim_cache = Simulation(;
        name="sim",
        steps=2,
        models=models,
        sequence=sequence,
        simulation_folder=mktempdir(; cleanup=true),
    )

    build_out = build!(sim_cache)
    @test build_out == PSI.SimulationBuildStatus.BUILT

    execute_out = execute!(sim_cache)
    @test execute_out == PSI.RunStatus.SUCCESSFULLY_FINALIZED

    # Test UC Vars are equal to ED params
    res = SimulationResults(sim_cache)
    res_ed = res.decision_problem_results["ED"]
    param_ed =
        read_realized_parameter(res_ed, "EnergyLimitParameter__EnergyReservoirStorage")

    res_uc = res.decision_problem_results["UC"]
    p_out_bat =
        read_realized_variable(res_uc, "ActivePowerOutVariable__EnergyReservoirStorage")

    @test isapprox(param_ed[!, 2], p_out_bat[!, 2] / 100.0; atol=1e-4)
end

@testset "Test cost handling" begin
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat"; force_build=true)
    template = get_thermal_dispatch_template_network()
    storage_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict(
            "reservation" => false,
            "cycling_limits" => false,
            "energy_target" => false,
            "complete_coverage" => false,
            "regularization" => true,
        ),
    )
    set_device_model!(template, storage_model)
    model = DecisionModel(template, c_sys5_bat; optimizer=HiGHS_optimizer)
    @test build!(model; output_dir=mktempdir(; cleanup=true)) == PSI.ModelBuildStatus.BUILT
end
