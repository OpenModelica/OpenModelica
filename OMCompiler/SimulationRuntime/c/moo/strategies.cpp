/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2025, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "simulation/arrayIndex.h"

#include "evaluations.h"

#include "strategies.h"

namespace OpenModelica {

// TODO: make more initializer methods: bionic?!

// ==================== Helpers for Emit and Simulation ====================

// use this field when needing some data object inside OpenModelica
// callbacks / interfaces but no nice void* field exists
static void *_global_reference_data_field = nullptr;

// set the global pointer
void set_global_reference_data(void *reference_data) {
    assert(!_global_reference_data_field);
    _global_reference_data_field = reference_data;
}

// get the global pointer
void* get_global_reference_data() {
    assert(_global_reference_data_field);
    return _global_reference_data_field;
}

// clear the global pointer
void clear_global_reference_data() {
    _global_reference_data_field = nullptr;
}

static int control_trajectory_input_function(DATA* data, threadData_t* threadData) {
    AuxiliaryControls* aux_controls = static_cast<AuxiliaryControls*>(get_global_reference_data());

    const ControlTrajectory& controls = aux_controls->controls;
    InfoGDOP& info = aux_controls->info;
    f64* u_interpolation = aux_controls->u_interpolation.raw();

    // important use data here not info.data
    // for some reason a new data object is created for each solve
    // but not important for now
    f64 time = data->localData[0]->timeValue;

    // transform back to GDOP time (always [0, tf])
    time -= info.model_start_time;

    controls.interpolate_at(time, u_interpolation);
    set_inputs(info, u_interpolation);

    return 0;
}

static void trajectory_xut_emit(simulation_result* sim_result, DATA* data, threadData_t *threadData)
{
    AuxiliaryTrajectory* aux = static_cast<AuxiliaryTrajectory*>(sim_result->storage); // exploit void* field
    InfoGDOP& info = aux->info;
    Trajectory& trajectory = aux->trajectory;
    SOLVER_INFO* solver_info = aux->solver_info;

    for (int x_idx = 0; x_idx < info.x_size; x_idx++) {
        trajectory.x[x_idx].push_back(data->localData[0]->realVars[x_idx]);
    }

    for (int u_idx = 0; u_idx < info.u_size; u_idx++) {
        int u = info.u_indices_real_vars[u_idx];
        trajectory.u[u_idx].push_back(data->localData[0]->realVars[u]);
    }

    trajectory.t.push_back(solver_info->currentTime - info.model_start_time);
}

static void trajectory_p_emit(simulation_result* sim_result, DATA* data, threadData_t *threadData)
{
    // TODO: PARAMETERS
    AuxiliaryTrajectory* aux = static_cast<AuxiliaryTrajectory*>(sim_result->storage);
    InfoGDOP& info = aux->info;
    Trajectory& trajectory = aux->trajectory;

    for (int p_idx = 0; p_idx < info.p_size; p_idx++) {
        trajectory.p.push_back(data->localData[0]->realVars[0 /* parameter index */]);
    }
}

// sets state and control initial values
// from e.g. initial equations / parameters
void initialize_model(InfoGDOP& info) {
    externalInputallocate(info.data);
    initializeModel(info.data, info.threadData, "", "", info.model_start_time);
}

// at least free for externalInputallocate();
void free_model(InfoGDOP& info) {
    externalInputFree(info.data);
}

// ==================== Emit to MAT file ====================

MatEmitter::MatEmitter(InfoGDOP& info) : info(info) {}

int MatEmitter::operator()(const PrimalDualTrajectory& trajectory) {
    DATA* data = info.data;
    threadData_t* threadData = info.threadData;

    // TODO: this is placed poorly here -> maybe move the entry point from generated code deeper into the runtime
    const char *result_file = omc_flagValue[FLAG_R];
    std::string result_file_cstr;
    if (result_file) {
        data->modelData->resultFileName = GC_strdup(result_file);
    } else if (omc_flag[FLAG_OUTPUT_PATH]) { /* read the output path from the command line (if any) */
        if (0 > GC_asprintf(&result_file, "%s/%s_res.%s", omc_flagValue[FLAG_OUTPUT_PATH], data->modelData->modelFilePrefix, data->simulationInfo->outputFormat)) {
        throwStreamPrint(NULL, "simulation_runtime.c: Error: can not allocate memory.");
        }
        data->modelData->resultFileName = GC_strdup(result_file);
    } else {
        result_file_cstr = std::string(data->modelData->modelFilePrefix) + std::string("_res.") + data->simulationInfo->outputFormat;
        data->modelData->resultFileName = GC_strdup(result_file_cstr.c_str());
    }

    const auto& primals = trajectory.primals;

    data->simulationInfo->numSteps = primals->t.size();
    initializeResultData(data, threadData, 0);
    sim_result.writeParameterData(&sim_result, data, threadData);

    // allocate contiguous array for xu
    FixedVector<f64> xu(primals->x.size() + primals->u.size());
    for (size_t i = 0; i < primals->t.size(); i++) {
        // move trajectory data in contiguous array
        for (size_t x_index = 0; x_index < primals->x.size(); x_index++) {
            xu[x_index] = primals->x[x_index][i];
        }
        for (size_t u_index = 0; u_index < primals->u.size(); u_index++) {
            xu[primals->x.size() + u_index] = primals->u[u_index][i];
        }

        // evaluate all algebraic variables
        set_time(info, info.model_start_time + primals->t[i]);
        set_states_inputs(info, xu.raw());
        eval_current_point_dae(info);

        // emit point
        sim_result.emit(&sim_result, data, threadData);
    }

    sim_result.free(&sim_result, data, threadData);

    return 0;
}

// ==================== Constant Initialization  ====================

ConstantInitialization::ConstantInitialization(InfoGDOP& info)
  : info(info) {}

std::unique_ptr<PrimalDualTrajectory> ConstantInitialization::operator()(const GDOP::GDOP& gdop) {
    DATA* data = info.data;

    std::vector<f64> t = {0, info.tf};
    std::vector<std::vector<f64>> x_guess;
    std::vector<std::vector<f64>> u_guess;
    std::vector<f64> p;
    InterpolationMethod interpolation = InterpolationMethod::LINEAR;

    for (int x = 0; x < info.x_size; x++) {
        if (data->modelData->realVarsData[x].dimension.numberOfDimensions > 0) {
            Log::error("Support for array variables not yet implemented!");
            abort();
        }
        modelica_real* start = (modelica_real *)data->modelData->realVarsData[x].attribute.start.data;
        x_guess.push_back({start[0], start[0]});
    }

    for (int u : info.u_indices_real_vars) {
        if (data->modelData->realVarsData[u].dimension.numberOfDimensions > 0) {
            Log::error("Support for array variables not yet implemented!");
            abort();
        }
        modelica_real* start = (modelica_real *)data->modelData->realVarsData[u].attribute.start.data;
        u_guess.push_back({start[0], start[0]});
    }

    // TODO: PARAMETERS add p

    return std::make_unique<PrimalDualTrajectory>(std::make_unique<Trajectory>(t, x_guess, u_guess, p, interpolation));
}

// ==================== Simulation  ====================

Simulation::Simulation(InfoGDOP& info, SOLVER_METHOD solver)
  : info(info), solver(solver) {}

std::unique_ptr<Trajectory> Simulation::operator()(const ControlTrajectory& controls, const FixedVector<f64>& parameters,
                                                   int num_steps, f64 start_time, f64 stop_time, f64* x_start_values) {
    DATA* data = info.data;
    threadData_t* threadData = info.threadData;
    SOLVER_INFO solver_info;
    SIMULATION_INFO *simInfo = data->simulationInfo;

    solver_info.solverMethod = solver;
    simInfo->numSteps  = num_steps;
    simInfo->startTime = start_time + info.model_start_time; // shift by model start time
    simInfo->stopTime  = stop_time  + info.model_start_time; // shift by model start time
    simInfo->stepSize  = (stop_time - start_time) / static_cast<f64>(num_steps);
    simInfo->useStopTime = 1;

    // allocate and reserve trajectory vectors
    std::vector<f64> t;
    t.reserve(num_steps + 1);

    std::vector<std::vector<f64>> x_sim(info.x_size);
    for (auto& v : x_sim) v.reserve(num_steps + 1);

    std::vector<std::vector<f64>> u_sim(info.u_size);
    for (auto& v : u_sim) v.reserve(num_steps + 1);

    std::vector<f64> p_sim(info.p_size);

    // create Trajectory object
    auto trajectory = std::make_unique<Trajectory>(Trajectory{t, x_sim, u_sim, p_sim, InterpolationMethod::LINEAR, nullptr});

    // auxiliary data (passed as void* in storage member of sim_result)
    auto aux_trajectory = std::make_unique<AuxiliaryTrajectory>(AuxiliaryTrajectory{*trajectory, info, &solver_info});

    // define global sim_result
    sim_result.filename           = nullptr;
    sim_result.numpoints          = 0;
    sim_result.cpuTime            = 0;
    sim_result.storage            = aux_trajectory.get();
    sim_result.emit               = trajectory_xut_emit;
    sim_result.init               = nullptr;
    sim_result.writeParameterData = trajectory_p_emit;
    sim_result.free               = nullptr;

    // init simulation
    initializeSolverData(data, threadData, &solver_info);
    setZCtol(fmin(simInfo->stepSize, simInfo->tolerance));
    initialize_model(info); // TODO: is this needed? we pass x0 after all, maybe call this when getting x0 from the model?!
    data->real_time_sync.enabled = FALSE;

    // create an auxiliary object (stored in global void*)
    // since the input_function interface offers no additional argument
    FixedVector<f64> u_interpolation_buffer = FixedVector<f64>(info.u_size);
    auto aux_controls = AuxiliaryControls{controls, info, u_interpolation_buffer};
    set_global_reference_data(&aux_controls);

    // set the new input function
    auto generated_input_function = data->callback->input_function;
    data->callback->input_function = control_trajectory_input_function;

    // set states and controls for start time
    // emit for time = start_time
    controls.interpolate_at(start_time, u_interpolation_buffer.raw());
    set_inputs(info, u_interpolation_buffer.raw());
    set_states(info, x_start_values);
    eval_current_point_dae(info);
    trajectory_xut_emit(&sim_result, data, threadData);

    // ensure realVars stay consistent across ring buffer rotation (prefixedName_performSimulation line 491ff):
    // copy current slot (localData[0]) into the upcoming slots (localData[1], localData[2])
    // after rotateRingBuffer() + lookupRingBuffer(), the new "current slot"
    // (localData[0]) will already contain our enforced values.
    // necessary for simulation steps, as otherwise start values (t = 0) would be present in these slots!
    memcpy(data->localData[1]->realVars, data->localData[0]->realVars, sizeof(modelica_real) * data->modelData->nVariablesReal);
    memcpy(data->localData[2]->realVars, data->localData[1]->realVars, sizeof(modelica_real) * data->modelData->nVariablesReal);

    // simulation with custom emit
    data->callback->performSimulation(data, threadData, &solver_info);

    // reset to previous input function (from generated code)
    data->callback->input_function = generated_input_function;

    // set global aux data to nullptr
    clear_global_reference_data();

    // free allocated memory
    free_model(info);                   // free for initialize_model() (at least partial)

    // Attention: this deletes the A Jacobian also!!
    freeSolverData(data, &solver_info); // free for initializeSolverData

    return trajectory;
}

// ==================== Simulation Step  ====================

SimulationStep::SimulationStep(std::shared_ptr<Simulation> simulation) : simulation(simulation) {}

void SimulationStep::activate(const ControlTrajectory& controls_, const FixedVector<f64>& parameters_) {
    controls = &controls_;
    parameters = &parameters_;
}

void SimulationStep::reset() {
    controls = nullptr;
    parameters = nullptr;
}

std::unique_ptr<Trajectory> SimulationStep::operator()(f64* x_start_values, f64 start_time, f64 stop_time) {
    if (!controls || !parameters) {
        Log::error("OpenModelica::SimulationStep has not been activated.");
        abort();
    }
    const int num_steps = 1;
    return (*simulation)(*controls, *parameters, num_steps, start_time, stop_time, x_start_values);
}

// ==================== Nominal Scaling Factory ====================

std::shared_ptr<NLP::Scaling> NominalScalingFactory::operator()(const GDOP::GDOP& gdop) {
    // x, g, f of the NLP { min f(x) s.t. g_l <= g(x) <= g_l }
    auto x_nominal = FixedVector<f64>(gdop.get_number_vars());
    auto g_nominal = FixedVector<f64>(gdop.get_number_constraints());
    f64  f_nominal = 1;

    // get problem sizes
    auto x_size  = info.x_size;
    auto u_size  = info.u_size;
    auto xu_size = info.xu_size;
    auto f_size = info.f_size;
    auto g_size = info.g_size;
    auto r_size = info.r_size;
    auto fg_size = f_size + g_size;

    auto has_mayer = gdop.get_problem().pc->has_mayer;
    auto has_lagrange = gdop.get_problem().pc->has_lagrange;

    if (has_mayer && has_lagrange) {
        const modelica_real nominal_mayer = getNominalFromScalarIdx(info.data->simulationInfo, info.data->modelData, info.index_mayer_real_vars);
        const modelica_real nominal_lagrange = getNominalFromScalarIdx(info.data->simulationInfo, info.data->modelData, info.index_lagrange_real_vars);

        f_nominal = (nominal_mayer + nominal_lagrange) / 2;
    }
    else if (has_lagrange) {
        f_nominal = getNominalFromScalarIdx(info.data->simulationInfo, info.data->modelData, info.index_lagrange_real_vars);
    }
    else if (has_mayer) {
        f_nominal = getNominalFromScalarIdx(info.data->simulationInfo, info.data->modelData, info.index_mayer_real_vars);
    }

    // x(t_0)
    for (int x = 0; x < info.x_size; x++) {
        x_nominal[x] = getNominalFromScalarIdx(info.data->simulationInfo, info.data->modelData, x);
    }

    // (x, u)_(t_node)
    for (int node = 0; node < gdop.get_mesh().node_count; node++) {
        for (int x = 0; x < x_size; x++) {
            x_nominal[x_size + node * xu_size + x] = getNominalFromScalarIdx(info.data->simulationInfo, info.data->modelData, x);
        }

        for (int u = 0; u < u_size; u++) {
            int u_real_vars = info.u_indices_real_vars[u];
            x_nominal[2 * x_size + node * xu_size + u] = getNominalFromScalarIdx(info.data->simulationInfo, info.data->modelData, u_real_vars);
        }
    }

    for (int node = 0; node < gdop.get_mesh().node_count; node++) {
        for (int f = 0; f < f_size; f++) {
            g_nominal[node * fg_size + f] = x_nominal[f]; // reuse x nominal for dynamic for now!
        }

        for (int g = 0; g < g_size; g++) {
            g_nominal[f_size + node * fg_size + g] = getNominalFromScalarIdx(info.data->simulationInfo, info.data->modelData, info.index_g_real_vars + g);
        }
    }

    for (int r = 0; r < r_size; r++) {
        g_nominal[gdop.get_off_fg_total() + r] = getNominalFromScalarIdx(info.data->simulationInfo, info.data->modelData, info.index_r_real_vars + r);
    }

    return std::make_shared<NLP::NominalScaling>(std::move(x_nominal), std::move(g_nominal), f_nominal);
}

// default strategies for OpenModelica
GDOP::Strategies default_strategies(InfoGDOP& info, GDOP::Problem& problem, bool use_moo_simulation) {
    GDOP::Strategies strategies;

    // TODO: do add simulation_tolerance factor here?
    FixedVector<f64> verifier_tolerances(info.x_size);
    for (int x = 0; x < info.x_size; x++) {
        verifier_tolerances[x] = 1e-4 * getNominalFromScalarIdx(info.data->simulationInfo, info.data->modelData, x);
    }

    auto scaling_factory               = std::make_shared<NominalScalingFactory>(info);
    auto emitter                       = std::make_shared<MatEmitter>(MatEmitter(info));
    auto const_initialization_strategy = std::make_shared<ConstantInitialization>(ConstantInitialization(info));

    std::shared_ptr<GDOP::Simulation> simulation_strategy;
    std::shared_ptr<GDOP::SimulationStep> simulation_step_strategy;

    if (!use_moo_simulation) {
        auto tmp_simulation_strategy = std::make_shared<Simulation>(info, info.user_ode_solver);
        simulation_step_strategy = std::make_shared<SimulationStep>(tmp_simulation_strategy);
        simulation_strategy = tmp_simulation_strategy;
    }
    else {
        simulation_strategy      = std::make_shared<GDOP::RadauIntegratorSimulation>(*problem.dynamics);
        simulation_step_strategy = std::make_shared<GDOP::RadauIntegratorSimulationStep>(*problem.dynamics);
    }

    auto simulation_initialization_strategy = std::make_shared<GDOP::SimulationInitialization>(GDOP::SimulationInitialization(const_initialization_strategy,
                                                                                                                              simulation_strategy));
    auto verifier = std::make_shared<GDOP::SimulationVerifier>(GDOP::SimulationVerifier(simulation_strategy,
                                                                                        Linalg::Norm::NORM_INF,
                                                                                        std::move(verifier_tolerances)));

    strategies.initialization          = simulation_initialization_strategy;
    strategies.simulation              = simulation_strategy;
    strategies.simulation_step         = simulation_step_strategy;
    strategies.mesh_refinement         = std::make_shared<GDOP::L2BoundaryNorm>(info.l2bn_phase_one_iterations, info.l2bn_phase_two_iterations, info.l2bn_phase_two_level);
    strategies.interpolation           = std::make_shared<GDOP::PolynomialInterpolation>();
    strategies.emitter                 = emitter;
    strategies.verifier                = verifier;
    strategies.scaling_factory         = scaling_factory;
    strategies.refined_initialization  = std::make_shared<GDOP::InterpolationRefinedInitialization>(
                                            GDOP::InterpolationRefinedInitialization(strategies.interpolation, true, true, true));
    return strategies;
};

} // namespace OpenModelica
