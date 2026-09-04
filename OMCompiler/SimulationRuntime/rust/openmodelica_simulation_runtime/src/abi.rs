//! Rust mirrors of the C runtime's ABI (`simulation_data.h`, `openmodelica_func.h`).
//!
//! The generated `<Model>.c` puts `DATA`, `MODEL_DATA` and `SIMULATION_INFO` on
//! its own stack and hands us pointers, so these definitions must match the
//! headers exactly. `tests/abi_layout.rs` compiles the headers and compares every
//! offset, so a change to the C side fails the test rather than corrupting memory.
//!
//! Fields the Rust runtime never reads keep their C name and width; pointers to
//! types we do not follow are `*mut c_void`.

#![allow(non_camel_case_types, non_snake_case, dead_code)]

use core::ffi::{c_char, c_int, c_long, c_uint, c_ulong, c_void};

pub type modelica_real = f64;
/// `mmc_sint_t` is pointer-sized: `long` on LP64 but `long long` under `_WIN64`,
/// where `c_long` would be half its width.
#[cfg(target_pointer_width = "64")]
pub type modelica_integer = i64;
#[cfg(not(target_pointer_width = "64"))]
pub type modelica_integer = i32;
pub type modelica_boolean = c_int;
/// A boxed MetaModelica string (`modelica_metatype`); opaque here.
pub type modelica_string = *mut c_void;
/// Also `mmc_sint_t`.
pub type _index_t = modelica_integer;

/// `util/rtclock.h`: `union { struct timespec; unsigned long long; }` on unix,
/// `LARGE_INTEGER`/`uint64_t` elsewhere -- 16 bytes either way on the unix build.
/// `gc/omc_gc.h`'s `errorStage`: `threadData->currentErrorStage`.
pub const ERROR_SIMULATION: i32 = 1;
pub const ERROR_INTEGRATOR: i32 = 2;
pub const ERROR_NONLINEARSOLVER: i32 = 3;
pub const ERROR_EVENTSEARCH: i32 = 4;
pub const ERROR_EVENTHANDLING: i32 = 5;
pub const ERROR_OPTIMIZE: i32 = 6;

#[repr(C)]
#[derive(Clone, Copy)]
pub struct rtclock_t {
    pub a: u64,
    pub b: u64,
}

#[repr(C)]
#[derive(Clone, Copy)]
pub struct FILE_INFO {
    pub filename: *const c_char,
    pub lineStart: c_int,
    pub colStart: c_int,
    pub lineEnd: c_int,
    pub colEnd: c_int,
    pub readonly: c_int,
}

impl FILE_INFO {
    pub const fn dummy() -> Self {
        FILE_INFO {
            filename: c"".as_ptr(),
            lineStart: 0,
            colStart: 0,
            lineEnd: 0,
            colEnd: 0,
            readonly: 0,
        }
    }
}

/// `struct base_array_s` -- `real_array`, `integer_array`, ... are all this.
#[repr(C)]
#[derive(Clone, Copy)]
pub struct base_array_t {
    pub ndims: c_int,
    pub dim_size: *mut _index_t,
    pub data: *mut c_void,
    pub flexible: modelica_boolean,
}
pub type real_array = base_array_t;

impl base_array_t {
    /// The scalar (or first) element of a real attribute array; C's attributes are
    /// `real_array` so an array variable can carry one value per element.
    pub fn first_real(&self, fallback: f64) -> f64 {
        if self.data.is_null() { fallback } else { unsafe { *(self.data as *const f64) } }
    }
    pub fn real_at(&self, i: usize, fallback: f64) -> f64 {
        if self.data.is_null() { fallback } else { unsafe { *(self.data as *const f64).add(i) } }
    }
}

#[repr(C)]
#[derive(Clone, Copy)]
pub struct VAR_INFO {
    pub id: c_int,
    pub inputIndex: c_int,
    pub name: *const c_char,
    pub comment: *const c_char,
    pub info: FILE_INFO,
}

#[repr(C)]
pub struct SAMPLE_INFO {
    pub index: c_long,
    pub start: f64,
    pub interval: f64,
}

#[repr(C)]
pub struct CHATTERING_INFO {
    pub numEventLimit: c_int,
    pub lastSteps: *mut c_int,
    pub lastTimes: *mut f64,
    pub currentIndex: c_int,
    pub lastStepsNumStateEvents: c_int,
    pub messageEmitted: c_int,
}

#[repr(C)]
pub struct CALL_STATISTICS {
    pub functionODE: c_long,
    pub updateDiscreteSystem: c_long,
    pub functionZeroCrossingsEquations: c_long,
    pub functionZeroCrossings: c_long,
    pub functionEvalDAE: c_long,
    pub functionAlgebraics: c_long,
}

#[repr(C)]
pub struct SPARSE_PATTERN {
    pub nnz: c_uint,
    pub leadindex: *mut c_uint,
    pub index: *mut c_uint,
    pub colorCols: *mut c_uint,
    pub maxColors: c_uint,
    pub sizeCols: c_uint,
}

#[repr(C)]
pub struct NONLINEAR_PATTERN {
    pub numberOfVars: c_uint,
    pub numberOfEqns: c_uint,
    pub numberOfNonlinear: c_uint,
    pub indexVar: *mut c_uint,
    pub indexEqn: *mut c_uint,
    pub columns: *mut c_uint,
    pub rows: *mut c_uint,
}

pub type jacobianColumn_func_ptr = Option<
    unsafe extern "C" fn(*mut DATA, *mut threadData_t, *mut JACOBIAN, *mut JACOBIAN) -> c_int,
>;
pub type initialAnalyticalJacobian_func_ptr =
    Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t, *mut JACOBIAN) -> c_int>;

#[repr(C)]
pub struct JACOBIAN {
    pub availability: c_int,
    pub sizeCols: usize,
    pub sizeRows: usize,
    pub sizeTmpVars: usize,
    pub sparsePattern: *mut SPARSE_PATTERN,
    pub seedVars: *mut modelica_real,
    pub tmpVars: *mut modelica_real,
    pub resultVars: *mut modelica_real,
    pub dae_cj: modelica_real,
    pub dag: *mut c_void,
    pub evalSelection: *mut c_void,
    pub evalColumn: jacobianColumn_func_ptr,
    pub constantEqns: jacobianColumn_func_ptr,
    pub isRowEval: modelica_boolean,
    pub isBidirectional: modelica_boolean,
    pub adjointJacobian: *mut JACOBIAN,
    pub recoverMask: *mut u8,
    pub csrToCscMap: *mut c_uint,
}

/// `JACOBIAN_AVAILABILITY`
pub const JACOBIAN_UNKNOWN: c_int = 0;
pub const JACOBIAN_NOT_AVAILABLE: c_int = 1;
pub const JACOBIAN_ONLY_SPARSITY: c_int = 2;
pub const JACOBIAN_AVAILABLE: c_int = 3;

#[repr(C)]
pub struct EXTERNAL_INPUT {
    pub active: modelica_boolean,
    pub u: *mut *mut modelica_real,
    pub t: *mut modelica_real,
    pub N: modelica_integer,
    pub n: modelica_integer,
    pub i: modelica_integer,
}

#[repr(C)]
pub struct DATA_ALIAS {
    pub negate: c_int,
    pub nameID: c_int,
    pub aliasType: c_int,
    pub info: VAR_INFO,
    pub filterOutput: modelica_boolean,
    pub unit: modelica_string,
    pub displayUnit: modelica_string,
    pub relativeQuantity: modelica_boolean,
}

#[repr(C)]
pub struct array_index_t {
    pub array_idx: usize,
    pub dim_idx: usize,
}

#[repr(C)]
pub struct REAL_ATTRIBUTE {
    pub unit: modelica_string,
    pub displayUnit: modelica_string,
    pub relativeQuantity: modelica_boolean,
    pub min: real_array,
    pub max: real_array,
    pub fixed: modelica_boolean,
    pub useNominal: modelica_boolean,
    pub nominal: real_array,
    pub start: real_array,
}

#[repr(C)]
pub struct INTEGER_ATTRIBUTE {
    pub min: modelica_integer,
    pub max: modelica_integer,
    pub fixed: modelica_boolean,
    pub start: modelica_integer,
}

#[repr(C)]
pub struct BOOLEAN_ATTRIBUTE {
    pub fixed: modelica_boolean,
    pub start: modelica_boolean,
}

#[repr(C)]
pub struct STRING_ATTRIBUTE {
    pub start: modelica_string,
}

#[repr(C)]
pub struct DIMENSION_ATTRIBUTE {
    pub ty: c_int,
    pub start: modelica_integer,
    pub valueReference: modelica_integer,
}

#[repr(C)]
pub struct DIMENSION_INFO {
    pub numberOfDimensions: usize,
    pub dimensions: *mut DIMENSION_ATTRIBUTE,
    pub scalar_length: usize,
}

#[repr(C)]
pub struct STATIC_REAL_DATA {
    pub dimension: DIMENSION_INFO,
    pub info: VAR_INFO,
    pub attribute: REAL_ATTRIBUTE,
    pub filterOutput: modelica_boolean,
    pub time_unvarying: modelica_boolean,
}

#[repr(C)]
pub struct STATIC_INTEGER_DATA {
    pub dimension: DIMENSION_INFO,
    pub info: VAR_INFO,
    pub attribute: INTEGER_ATTRIBUTE,
    pub filterOutput: modelica_boolean,
    pub time_unvarying: modelica_boolean,
}

#[repr(C)]
pub struct STATIC_BOOLEAN_DATA {
    pub dimension: DIMENSION_INFO,
    pub info: VAR_INFO,
    pub attribute: BOOLEAN_ATTRIBUTE,
    pub filterOutput: modelica_boolean,
    pub time_unvarying: modelica_boolean,
}

#[repr(C)]
pub struct STATIC_STRING_DATA {
    pub dimension: DIMENSION_INFO,
    pub info: VAR_INFO,
    pub attribute: STRING_ATTRIBUTE,
    pub filterOutput: modelica_boolean,
    pub time_unvarying: modelica_boolean,
}

#[repr(C)]
pub struct RESIDUAL_USERDATA {
    pub data: *mut DATA,
    pub threadData: *mut threadData_t,
    pub solverData: *mut c_void,
}

pub type residual_func_ptr = Option<
    unsafe extern "C" fn(*mut RESIDUAL_USERDATA, *const f64, *mut f64, *const c_int),
>;

#[repr(C)]
pub struct NONLINEAR_SYSTEM_DATA {
    pub size: modelica_integer,
    pub equationIndex: modelica_integer,
    pub homotopySupport: modelica_boolean,
    pub initHomotopy: modelica_boolean,
    pub mixedSystem: modelica_boolean,
    pub min: *mut modelica_real,
    pub max: *mut modelica_real,
    pub nominal: *mut modelica_real,
    pub analyticalJacobianColumn: jacobianColumn_func_ptr,
    pub initialAnalyticalJacobian: initialAnalyticalJacobian_func_ptr,
    pub jacobianIndex: modelica_integer,
    pub sparsePattern: *mut SPARSE_PATTERN,
    pub nonlinearPattern: *mut NONLINEAR_PATTERN,
    pub eqn_simcode_indices: *mut c_int,
    pub torn_plus_residual_size: modelica_integer,
    pub residualFunc: residual_func_ptr,
    pub residualFuncConstraints:
        Option<unsafe extern "C" fn(*mut RESIDUAL_USERDATA, *const f64, *mut f64, *const c_int) -> c_int>,
    pub initializeStaticNLSData: Option<
        unsafe extern "C" fn(
            *mut DATA,
            *mut threadData_t,
            *mut NONLINEAR_SYSTEM_DATA,
            modelica_boolean,
            modelica_boolean,
        ),
    >,
    pub freeStaticNLSData:
        Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t, *mut NONLINEAR_SYSTEM_DATA)>,
    pub strictTearingFunctionCall:
        Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t) -> c_int>,
    pub getIterationVars: Option<unsafe extern "C" fn(*mut DATA, *mut f64)>,
    pub checkConstraints: Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t) -> c_int>,
    pub matrixFormat: c_int,
    pub nlsMethod: c_int,
    pub solverData: *mut c_void,
    pub nlsLinearSolver: c_int,
    pub nlsx: *mut modelica_real,
    pub nlsxOld: *mut modelica_real,
    pub nlsxExtrapolation: *mut modelica_real,
    pub oldValueList: *mut c_void,
    pub resValues: *mut modelica_real,
    pub solved: c_int,
    pub lastTimeSolved: modelica_real,
    pub logActive: modelica_boolean,
    pub numberOfCall: c_ulong,
    pub numberOfFEval: c_ulong,
    pub numberOfFailures: c_ulong,
    pub numberOfJEval: c_ulong,
    pub numberOfIterations: c_ulong,
    pub totalTime: f64,
    pub totalTimeClock: rtclock_t,
    pub jacobianTime: f64,
    pub jacobianTimeClock: rtclock_t,
    pub csvData: *mut c_void,
}

#[repr(C)]
pub struct LINEAR_SYSTEM_DATA {
    pub setA: Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t, *mut LINEAR_SYSTEM_DATA)>,
    pub setb: Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t, *mut LINEAR_SYSTEM_DATA)>,
    pub setAElement: Option<
        unsafe extern "C" fn(c_int, c_int, f64, c_int, *mut LINEAR_SYSTEM_DATA, *mut threadData_t),
    >,
    pub setBElement:
        Option<unsafe extern "C" fn(c_int, f64, *mut LINEAR_SYSTEM_DATA, *mut threadData_t)>,
    pub analyticalJacobianColumn: jacobianColumn_func_ptr,
    pub initialAnalyticalJacobian: initialAnalyticalJacobian_func_ptr,
    pub residualFunc: residual_func_ptr,
    pub initializeStaticLSData: Option<
        unsafe extern "C" fn(*mut DATA, *mut threadData_t, *mut LINEAR_SYSTEM_DATA, modelica_boolean),
    >,
    pub strictTearingFunctionCall:
        Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t) -> c_int>,
    pub checkConstraints: Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t) -> c_int>,
    pub min: *mut modelica_real,
    pub max: *mut modelica_real,
    pub nominal: *mut modelica_real,
    pub nnz: modelica_integer,
    pub size: modelica_integer,
    pub equationIndex: modelica_integer,
    pub jacobianIndex: modelica_integer,
    pub method: modelica_integer,
    pub matrixFormat: c_int,
    pub useSparseSolver: modelica_boolean,
    pub solverData: [*mut c_void; 2],
    pub A: *mut modelica_real,
    pub b: *mut modelica_real,
    pub parentJacobian: *mut JACOBIAN,
    pub jacobian: *mut JACOBIAN,
    pub solved: modelica_boolean,
    pub failed: modelica_boolean,
    pub logActive: modelica_boolean,
    pub numberOfCall: c_ulong,
    pub numberOfFailures: c_ulong,
    pub numberOfJEval: c_ulong,
    pub totalTime: f64,
    pub totalTimeClock: rtclock_t,
    pub jacobianTime: f64,
}

#[repr(C)]
pub struct MIXED_SYSTEM_DATA {
    pub size: modelica_integer,
    pub equationIndex: modelica_integer,
    pub continuous_solution: modelica_boolean,
    pub solveContinuousPart: Option<unsafe extern "C" fn(*mut c_void)>,
    pub updateIterationExps: Option<unsafe extern "C" fn(*mut c_void)>,
    pub iterationVarsPtr: *mut *mut modelica_boolean,
    pub iterationPreVarsPtr: *mut *mut modelica_boolean,
    pub solverData: *mut c_void,
    pub method: modelica_integer,
    pub solved: modelica_boolean,
    pub logActive: modelica_boolean,
}

#[repr(C)]
pub struct STATE_SET_DATA {
    pub nCandidates: modelica_integer,
    pub nStates: modelica_integer,
    pub nDummyStates: modelica_integer,
    pub A: *mut VAR_INFO,
    pub rowPivot: *mut modelica_integer,
    pub colPivot: *mut modelica_integer,
    pub J: *mut modelica_real,
    pub states: *mut *mut VAR_INFO,
    pub statescandidates: *mut *mut VAR_INFO,
    pub analyticalJacobianColumn: jacobianColumn_func_ptr,
    pub initialAnalyticalJacobian: initialAnalyticalJacobian_func_ptr,
    pub jacobianIndex: modelica_integer,
}

#[repr(C)]
pub struct DAEMODE_DATA {
    pub nResidualVars: c_long,
    pub nAlgebraicDAEVars: c_long,
    pub nAuxiliaryVars: c_long,
    pub residualVars: *mut modelica_real,
    pub auxiliaryVars: *mut modelica_real,
    pub sparsePattern: *mut SPARSE_PATTERN,
    pub evaluateDAEResiduals:
        Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t, c_int) -> c_int>,
    pub algIndexes: *mut c_int,
}

#[repr(C)]
pub struct INLINE_DATA {
    pub dt: modelica_real,
    pub algVars: *mut modelica_real,
    pub algOldVars: *mut modelica_real,
}

/// `EQUATION_SECTION`: which generated section an equation belongs to.
pub const EQUATION_SECTION_UNKNOWN: c_int = 0;
pub const EQUATION_SECTION_INIT_LAMBDA0: c_int = 1;
pub const EQUATION_SECTION_INITIAL: c_int = 2;
pub const EQUATION_SECTION_REGULAR: c_int = 3;

#[repr(C)]
pub struct EQUATION_INFO {
    pub id: c_int,
    pub section: c_int,
    pub profileBlockIndex: c_int,
    pub parent: c_int,
    pub numVar: c_int,
    pub vars: *const *const c_char,
    pub numVarUsed: c_int,
    pub varsUsed: *const *const c_char,
}

#[repr(C)]
pub struct FUNCTION_INFO {
    pub id: c_int,
    pub name: *const c_char,
    pub info: FILE_INFO,
}

#[repr(C)]
pub struct MODEL_DATA_XML {
    pub fileName: *const c_char,
    pub infoXMLData: *const c_char,
    pub modelInfoXmlLength: usize,
    pub nFunctions: c_long,
    pub nEquations: c_long,
    pub nProfileBlocks: c_long,
    pub functionNames: *mut FUNCTION_INFO,
    pub equationInfo: *mut EQUATION_INFO,
}

#[repr(C)]
pub struct MODEL_DATA {
    pub realVarsData: *mut STATIC_REAL_DATA,
    pub integerVarsData: *mut STATIC_INTEGER_DATA,
    pub booleanVarsData: *mut STATIC_BOOLEAN_DATA,
    pub stringVarsData: *mut STATIC_STRING_DATA,

    pub realParameterData: *mut STATIC_REAL_DATA,
    pub integerParameterData: *mut STATIC_INTEGER_DATA,
    pub booleanParameterData: *mut STATIC_BOOLEAN_DATA,
    pub stringParameterData: *mut STATIC_STRING_DATA,

    pub realAlias: *mut DATA_ALIAS,
    pub integerAlias: *mut DATA_ALIAS,
    pub booleanAlias: *mut DATA_ALIAS,
    pub stringAlias: *mut DATA_ALIAS,

    pub realSensitivityData: *mut STATIC_REAL_DATA,

    pub modelDataXml: MODEL_DATA_XML,

    pub modelName: *const c_char,
    pub modelFilePrefix: *const c_char,
    pub modelFileName: *const c_char,
    pub resultFileName: *mut c_char,
    pub modelDir: *const c_char,
    pub modelGUID: *const c_char,
    pub initXMLData: *const c_char,
    pub resourcesDir: *mut c_char,
    pub runTestsuite: modelica_boolean,

    pub linearizationDumpLanguage: c_int,
    pub create_linearmodel: modelica_boolean,

    pub nSamples: c_long,
    pub samplesInfo: *mut SAMPLE_INFO,

    pub nBaseClocks: c_long,

    pub nStatesArray: c_long,
    pub nVariablesRealArray: c_long,
    pub nDiscreteRealArray: c_long,
    pub nVariablesIntegerArray: c_long,
    pub nVariablesBooleanArray: c_long,
    pub nVariablesStringArray: c_long,

    pub nParametersRealArray: c_long,
    pub nParametersIntegerArray: c_long,
    pub nParametersBooleanArray: c_long,
    pub nParametersStringArray: c_long,

    pub nAliasRealArray: c_long,
    pub nAliasIntegerArray: c_long,
    pub nAliasBooleanArray: c_long,
    pub nAliasStringArray: c_long,

    pub nStates: c_long,
    pub nVariablesReal: c_long,
    pub nVariablesInteger: c_long,
    pub nVariablesBoolean: c_long,
    pub nVariablesString: c_long,

    pub nParametersReal: c_long,
    pub nParametersInteger: c_long,
    pub nParametersBoolean: c_long,
    pub nParametersString: c_long,

    pub nInputVars: c_long,
    pub nOutputVars: c_long,

    pub nAliasReal: c_long,
    pub nAliasInteger: c_long,
    pub nAliasBoolean: c_long,
    pub nAliasString: c_long,

    pub dag: *mut c_void,

    pub nZeroCrossings: c_long,
    pub nRelations: c_long,
    pub nMathEvents: c_long,
    pub nDelayExpressions: c_long,
    pub nSpatialDistributions: c_long,
    pub nExtObjs: c_long,
    pub nMixedSystems: c_long,
    pub nLinearSystems: c_long,
    pub nNonLinearSystems: c_long,
    pub nStateSets: c_long,
    pub nInlineVars: c_long,
    pub nOptimizeConstraints: c_long,
    pub nOptimizeFinalConstraints: c_long,

    pub nJacobians: c_long,

    pub nSensitivityVars: c_long,
    pub nSensitivityParamVars: c_long,
    pub nSetcVars: c_long,
    pub ndataReconVars: c_long,
    pub nSetbVars: c_long,
    pub nRelatedBoundaryConditions: c_long,
}

#[repr(C)]
#[derive(Clone, Copy)]
pub struct RATIONAL {
    pub num: c_long,
    pub den: c_long,
}

#[repr(C)]
#[derive(Clone, Copy)]
pub struct CLOCK_STATS {
    pub previousInterval: modelica_real,
    pub count: c_int,
    pub lastActivationTime: f64,
}

#[repr(C)]
pub struct SUBCLOCK_DATA {
    pub shift: RATIONAL,
    pub factor: RATIONAL,
    pub solverMethod: *const c_char,
    pub holdEvents: modelica_boolean,
    pub stats: CLOCK_STATS,
}

#[repr(C)]
pub struct BASECLOCK_DATA {
    pub intervalCounter: c_int,
    pub resolution: c_int,
    pub interval: f64,
    pub subClocks: *mut SUBCLOCK_DATA,
    pub nSubClocks: c_int,
    pub isEventClock: modelica_boolean,
    pub stats: CLOCK_STATS,
}

#[repr(C)]
pub struct SPATIAL_DISTRIBUTION_DATA {
    pub index: c_int,
    pub isInitialized: modelica_boolean,
    pub oldPosX: modelica_real,
    pub startPosXSet: modelica_boolean,
    pub startPosX: modelica_real,
    pub transportedQuantity: *mut c_void,
    pub storedEvents: *mut c_void,
    pub lastStoredEventValue: c_int,
}

#[repr(C)]
pub struct SIMULATION_INFO {
    pub startTime: modelica_real,
    pub stopTime: modelica_real,
    pub useStopTime: c_int,
    pub numSteps: modelica_integer,
    pub stepSize: modelica_real,
    pub minStepSize: modelica_real,
    pub tolerance: modelica_real,
    pub solverMethod: *const c_char,
    pub outputFormat: *const c_char,
    pub variableFilter: *const c_char,

    pub loggingTimeRecord: [f64; 2],
    pub useLoggingTime: c_int,
    pub maxWarnDisplays: c_ulong,

    pub lsMethod: c_int,
    pub lssMethod: c_int,
    pub mixedMethod: c_int,

    pub nlsMethod: c_int,
    pub newtonStrategy: c_int,
    pub nlsCsvInfomation: c_int,
    pub nlsLinearSolver: c_int,

    pub currentContext: c_int,
    pub currentContextOld: c_int,
    pub jacobianEvals: c_int,
    pub currentJacobianEval: c_int,

    pub homotopySteps: c_int,
    pub lambda: f64,

    pub initial: modelica_boolean,
    pub terminal: modelica_boolean,
    pub discreteCall: modelica_boolean,
    pub needToIterate: modelica_boolean,
    pub simulationSuccess: modelica_boolean,
    pub sampleActivated: modelica_boolean,
    pub solveContinuous: modelica_boolean,
    pub noThrowDivZero: modelica_boolean,
    pub noThrowAsserts: modelica_boolean,
    pub needToReThrow: modelica_boolean,

    pub solverSteps: f64,

    pub extObjs: *mut *mut c_void,

    pub nextSampleEvent: f64,
    pub nextSampleTimes: *mut f64,
    pub samples: *mut modelica_boolean,

    pub baseClocks: *mut BASECLOCK_DATA,
    pub intvlTimers: *mut c_void,

    pub spatialDistributionData: *mut SPATIAL_DISTRIBUTION_DATA,

    pub zeroCrossings: *mut modelica_real,
    pub zeroCrossingsPre: *mut modelica_real,
    pub zeroCrossingsBackup: *mut modelica_real,
    pub relations: *mut modelica_boolean,
    pub relationsPre: *mut modelica_boolean,
    pub storedRelations: *mut modelica_boolean,
    pub mathEventsValuePre: *mut modelica_real,
    pub zeroCrossingIndex: *mut c_long,
    pub states_left: *mut modelica_real,
    pub states_right: *mut modelica_real,

    pub realVarsIndex: *mut usize,
    pub integerVarsIndex: *mut usize,
    pub booleanVarsIndex: *mut usize,
    pub stringVarsIndex: *mut usize,

    pub evalSelection: *mut c_void,

    pub realParamsIndex: *mut usize,
    pub integerParamsIndex: *mut usize,
    pub booleanParamsIndex: *mut usize,
    pub stringParamsIndex: *mut usize,

    pub realAliasIndex: *mut usize,
    pub integerAliasIndex: *mut usize,
    pub booleanAliasIndex: *mut usize,
    pub stringAliasIndex: *mut usize,

    pub realVarsReverseIndex: *mut array_index_t,
    pub integerVarsReverseIndex: *mut array_index_t,
    pub booleanVarsReverseIndex: *mut array_index_t,
    pub stringVarsReverseIndex: *mut array_index_t,

    pub realParamsReverseIndex: *mut array_index_t,
    pub integerParamsReverseIndex: *mut array_index_t,
    pub booleanParamsReverseIndex: *mut array_index_t,
    pub stringParamsReverseIndex: *mut array_index_t,

    pub realAliasReverseIndex: *mut array_index_t,
    pub integerAliasReverseIndex: *mut array_index_t,
    pub booleanAliasReverseIndex: *mut array_index_t,
    pub stringAliasReverseIndex: *mut array_index_t,

    pub timeValueOld: modelica_real,
    pub realVarsOld: *mut modelica_real,
    pub integerVarsOld: *mut modelica_integer,
    pub booleanVarsOld: *mut modelica_boolean,
    pub stringVarsOld: *mut modelica_string,

    pub realVarsPre: *mut modelica_real,
    pub integerVarsPre: *mut modelica_integer,
    pub booleanVarsPre: *mut modelica_boolean,
    pub stringVarsPre: *mut modelica_string,

    pub realParameter: *mut modelica_real,
    pub integerParameter: *mut modelica_integer,
    pub booleanParameter: *mut modelica_boolean,
    pub stringParameter: *mut modelica_string,

    pub inputVars: *mut modelica_real,
    pub outputVars: *mut modelica_real,
    pub setcVars: *mut modelica_real,
    pub datainputVars: *mut modelica_real,
    pub setbVars: *mut modelica_real,

    pub external_input: EXTERNAL_INPUT,

    pub sensitivityMatrix: *mut modelica_real,
    pub sensitivityParList: *mut c_int,

    pub analyticJacobians: *mut JACOBIAN,

    pub nonlinearSystemData: *mut NONLINEAR_SYSTEM_DATA,
    pub linearSystemData: *mut LINEAR_SYSTEM_DATA,
    pub mixedSystemData: *mut MIXED_SYSTEM_DATA,
    pub stateSetData: *mut STATE_SET_DATA,
    pub daeModeData: *mut DAEMODE_DATA,
    pub inlineData: *mut INLINE_DATA,

    pub backupSolverData: *mut c_void,

    pub delayStructure: *mut *mut c_void,
    pub OPENMODELICAHOME: *const c_char,

    pub chatteringInfo: CHATTERING_INFO,
    pub callStatistics: CALL_STATISTICS,
}

#[repr(C)]
pub struct SIMULATION_DATA {
    pub timeValue: modelica_real,
    pub realVars: *mut modelica_real,
    pub integerVars: *mut modelica_integer,
    pub booleanVars: *mut modelica_boolean,
    pub stringVars: *mut modelica_string,
    pub inlineVars: *mut modelica_real,
}

#[repr(C)]
pub struct real_time_sync_t {
    pub enabled: c_int,
    pub scaling: f64,
    pub time: f64,
    pub clock: rtclock_t,
    pub maxLate: i64,
}

#[repr(C)]
pub struct DATA {
    pub simulationData: *mut c_void,
    pub localData: *mut *mut SIMULATION_DATA,
    pub modelData: *mut MODEL_DATA,
    pub simulationInfo: *mut SIMULATION_INFO,
    pub callback: *mut OpenModelicaGeneratedFunctionCallbacks,
    pub embeddedServerState: *mut c_void,
    pub real_time_sync: real_time_sync_t,
}

/// `MAX_LOCAL_ROOTS` (gc/omc_gc.h).
pub const MAX_LOCAL_ROOTS: usize = 20;
/// `LOCAL_ROOT_SIMULATION_DATA` == `LOCAL_ROOT_ERROR_MO`.
pub const LOCAL_ROOT_SIMULATION_DATA: usize = 9;

/// Only the head of `threadData_s` is mirrored: everything past `parent` depends
/// on build options (pthreads) the runtime never reads. `threadData_t` is only
/// ever handled as a pointer that came from the generated `main`.
#[repr(C)]
pub struct threadData_t {
    pub mmc_jumper: *mut c_void,
    pub mmc_stack_overflow_jumper: *mut c_void,
    pub mmc_thread_work_exit: *mut c_void,
    pub localRoots: [*mut c_void; MAX_LOCAL_ROOTS],
    pub globalJumpBuffer: *mut c_void,
    pub simulationJumpBuffer: *mut c_void,
    pub currentErrorStage: c_int,
    pub parent: *mut threadData_t,
}

pub type sim_fn = Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t) -> c_int>;

#[repr(C)]
pub struct OpenModelicaGeneratedFunctionCallbacks {
    pub performSimulation:
        Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t, *mut c_void) -> c_int>,
    pub performQSSSimulation:
        Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t, *mut c_void) -> c_int>,
    pub updateContinuousSystem: Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t)>,
    pub callExternalObjectDestructors: Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t)>,

    pub initialNonLinearSystem: Option<unsafe extern "C" fn(c_int, *mut NONLINEAR_SYSTEM_DATA)>,
    pub initialLinearSystem: Option<unsafe extern "C" fn(c_int, *mut LINEAR_SYSTEM_DATA)>,
    pub initialMixedSystem: Option<unsafe extern "C" fn(c_int, *mut MIXED_SYSTEM_DATA)>,
    pub initializeStateSets:
        Option<unsafe extern "C" fn(c_int, *mut STATE_SET_DATA, *mut DATA)>,
    pub initializeDAEmodeData: Option<unsafe extern "C" fn(*mut DATA, *mut DAEMODE_DATA) -> c_int>,
    pub getDAG_ODE: Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t)>,

    pub functionODE: sim_fn,
    pub functionAlgebraics: sim_fn,
    pub functionDAE: sim_fn,
    pub functionLocalKnownVars: sim_fn,

    pub input_function: sim_fn,
    pub input_function_init: sim_fn,
    pub input_function_updateStartValues: sim_fn,
    pub data_function: sim_fn,
    pub output_function: sim_fn,
    pub setc_function: sim_fn,
    pub setb_function: sim_fn,

    pub function_storeDelayed: sim_fn,
    pub function_storeSpatialDistribution: sim_fn,
    pub function_initSpatialDistribution: sim_fn,

    pub updateBoundVariableAttributes: sim_fn,
    pub functionInitialEquations: sim_fn,
    pub homotopyMethod: c_int,
    pub functionInitialEquations_lambda0: sim_fn,
    pub functionRemovedInitialEquations: sim_fn,
    pub updateBoundParameters: sim_fn,
    pub checkForAsserts: sim_fn,
    pub function_ZeroCrossingsEquations: sim_fn,
    pub function_ZeroCrossings:
        Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t, *mut f64) -> c_int>,
    pub function_updateRelations:
        Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t, c_int) -> c_int>,
    pub zeroCrossingDescription:
        Option<unsafe extern "C" fn(c_int, *mut *mut c_int) -> *const c_char>,
    pub relationDescription: Option<unsafe extern "C" fn(c_int) -> *const c_char>,
    pub function_initSample: Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t)>,

    pub INDEX_JAC_A: c_int,
    pub INDEX_JAC_ADJ: c_int,
    pub INDEX_JAC_B: c_int,
    pub INDEX_JAC_C: c_int,
    pub INDEX_JAC_D: c_int,
    pub INDEX_JAC_F: c_int,
    pub INDEX_JAC_H: c_int,

    pub initialAnalyticJacobianA: initialAnalyticalJacobian_func_ptr,
    pub initialAnalyticJacobianADJ: initialAnalyticalJacobian_func_ptr,
    pub initialAnalyticJacobianB: initialAnalyticalJacobian_func_ptr,
    pub initialAnalyticJacobianC: initialAnalyticalJacobian_func_ptr,
    pub initialAnalyticJacobianD: initialAnalyticalJacobian_func_ptr,
    pub initialAnalyticJacobianF: initialAnalyticalJacobian_func_ptr,
    pub initialAnalyticJacobianH: initialAnalyticalJacobian_func_ptr,

    pub functionJacA_column: jacobianColumn_func_ptr,
    pub functionJacADJ_column: jacobianColumn_func_ptr,
    pub functionJacB_column: jacobianColumn_func_ptr,
    pub functionJacC_column: jacobianColumn_func_ptr,
    pub functionJacD_column: jacobianColumn_func_ptr,
    pub functionJacF_column: jacobianColumn_func_ptr,
    pub functionJacH_column: jacobianColumn_func_ptr,

    pub getDAG_JacA: Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t, *mut JACOBIAN)>,

    pub linear_model_frame: Option<unsafe extern "C" fn() -> *const c_char>,
    pub linear_model_datarecovery_frame: Option<unsafe extern "C" fn() -> *const c_char>,

    pub mayer: Option<unsafe extern "C" fn(*mut DATA, *mut *mut modelica_real, *mut i16) -> c_int>,
    pub lagrange: Option<
        unsafe extern "C" fn(*mut DATA, *mut *mut modelica_real, *mut i16, *mut i16) -> c_int,
    >,
    pub getInputVarIndicesInOptimization:
        Option<unsafe extern "C" fn(*mut DATA, *mut c_int, *mut c_int) -> c_int>,
    pub pickUpBoundsForInputsInOptimization: Option<
        unsafe extern "C" fn(
            *mut DATA,
            *mut modelica_real,
            *mut modelica_real,
            *mut modelica_real,
            *mut modelica_boolean,
            *mut *mut c_char,
            *mut modelica_real,
            *mut modelica_real,
        ) -> c_int,
    >,
    pub setInputData: Option<unsafe extern "C" fn(*mut DATA) -> c_int>,
    pub getTimeGrid: Option<
        unsafe extern "C" fn(*mut DATA, *mut modelica_integer, *mut *mut modelica_integer) -> c_int,
    >,

    pub symbolicInlineSystems: sim_fn,

    pub function_initSynchronous: Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t)>,
    pub function_updateSynchronous:
        Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t, c_long)>,
    pub function_equationsSynchronous:
        Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t, c_long, c_long) -> c_int>,

    pub inputNames: Option<unsafe extern "C" fn(*mut DATA, *mut *mut c_char) -> c_int>,
    pub dataReconciliationInputNames:
        Option<unsafe extern "C" fn(*mut DATA, *mut *mut c_char) -> c_int>,
    pub dataReconciliationUnmeasuredVariables:
        Option<unsafe extern "C" fn(*mut DATA, *mut *mut c_char) -> c_int>,

    pub read_simulation_info: Option<unsafe extern "C" fn(*mut SIMULATION_INFO)>,
    pub read_input_fmu: Option<unsafe extern "C" fn(*mut MODEL_DATA)>,

    pub initialPartialFMIDER: initialAnalyticalJacobian_func_ptr,
    pub functionJacFMIDER_column: jacobianColumn_func_ptr,
    pub INDEX_JAC_FMIDER: c_int,

    pub initialPartialFMIDERINIT: initialAnalyticalJacobian_func_ptr,
    pub functionJacFMIDERINIT_column: jacobianColumn_func_ptr,
    pub INDEX_JAC_FMIDERINIT: c_int,
}

/// The solver defaults `initializeDataStruc` installs (util/simulation_options.h,
/// mixedSystem.h).
/// `simulation_options.h`'s solver enumerations, as `simulationInfo` holds them.
pub const LS_LAPACK: c_int = 1;
pub const LS_LIS: c_int = 2;
pub const LS_KLU: c_int = 3;
pub const LS_UMFPACK: c_int = 4;
pub const LS_TOTALPIVOT: c_int = 5;
pub const LS_DEFAULT: c_int = 6;
pub const NLS_HYBRID: c_int = 1;
pub const NLS_KINSOL: c_int = 2;
pub const NLS_KINSOL_B: c_int = 3;
pub const NLS_NEWTON: c_int = 4;
pub const NLS_MIXED: c_int = 5;
pub const NLS_HOMOTOPY: c_int = 6;
pub const NLS_LS_DEFAULT: c_int = 1;
pub const NLS_LS_TOTALPIVOT: c_int = 2;
pub const NLS_LS_LAPACK: c_int = 3;
pub const NLS_LS_KLU: c_int = 4;
pub const LSS_DEFAULT: c_int = 1;
pub const MIXED_SEARCH: c_int = 1;
pub const NEWTON_DAMPED2: c_int = 2;

/// `enum _FLAG` (util/simulation_options.h), indexing `omc_flag`/`omc_flagValue`.
/// Only the entries the generated code or this runtime reads are named;
/// `tests/abi_layout.rs` checks every one against the header.
pub const FLAG_MAX: usize = 156;
pub const FLAG_NO_SCALING: usize = 99;
pub const FLAG_EMIT_PROTECTED: usize = 15;
pub const FLAG_F: usize = 17;
pub const FLAG_IDAS: usize = 41;
pub const FLAG_IGNORE_HIDERESULT: usize = 42;
pub const FLAG_IIF: usize = 43;
pub const FLAG_INPUT_CSV: usize = 48;
pub const FLAG_INPUT_PATH: usize = 50;
pub const FLAG_LV: usize = 66;
pub const FLAG_MOO_OPTIMIZATION: usize = 75;
pub const FLAG_NOEMIT: usize = 92;
pub const FLAG_OUTPUT_FORMAT: usize = 105;
pub const FLAG_OUTPUT_PATH: usize = 106;
pub const FLAG_OVERRIDE: usize = 107;
pub const FLAG_OVERRIDE_FILE: usize = 108;
pub const FLAG_R: usize = 110;
pub const FLAG_S: usize = 131;
pub const FLAG_VARIABLE_FILTER: usize = 147;

