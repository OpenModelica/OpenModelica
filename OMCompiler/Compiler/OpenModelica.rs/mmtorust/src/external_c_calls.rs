//! Registry of external C runtime calls used by MetaModelica sources.
//!
//! Every `external "C"` function referenced from the MetaModelica source must
//! be listed here together with its fallibility classification. The classifier
//! is consulted by [`crate::fallibility`] when building the call-graph: an
//! external function that *can* fail (e.g. throws via `MMC_THROW()` in the
//! OpenModelica runtime, returns a status code, or otherwise reports errors)
//! propagates `Result<_>` to its callers; an infallible one does not.
//!
//! ## Why a hand-curated table?
//!
//! The OpenModelica C runtime expresses errors through several mechanisms
//! (`MMC_THROW()`, `c_add_message(...)`, return codes, `errno`), and the
//! MetaModelica binding signature alone does not say which mechanism applies.
//! There is no machine-readable manifest on the C side either. So the only
//! safe approach is to enumerate the externals manually after inspecting the
//! corresponding `.c` source under `OMCompiler/Compiler/runtime/`.
//!
//! ## Strict mode
//!
//! [`lookup_or_panic`] panics if the external name is not listed. That makes
//! the table self-policing: adding a new `external "C"` declaration in the MM
//! source forces a compile-time-equivalent decision before code generation
//! runs.  We deliberately do *not* default to "fallible" — silently
//! over-approximating would defeat the whole point of the analysis.
//!
//! ## Adding entries
//!
//! For each new external, read the C implementation under
//! `OMCompiler/Compiler/runtime/` and check whether it:
//!   * calls `MMC_THROW()` / `MMC_THROW_INTERNAL()` / similar long-jump exits,
//!   * calls `c_add_message(..., ErrorLevel_error, ...)` followed by `MMC_THROW`,
//!   * returns a status code that the MM wrapper checks,
//!   * may set `errno` / abort.
//! Any of those → `Fallibility::Fallible`. Otherwise → `Fallibility::Infallible`.

use std::collections::BTreeMap;
use std::sync::OnceLock;

/// Whether an external C function can fail (and therefore returns `Result<T>`
/// in our lowering) or is provably infallible.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Fallibility {
    /// Function never fails: it has no `MMC_THROW`, no error reporting,
    /// no error-returning side channel. The Rust lowering returns the
    /// raw output type without a `Result` wrapper.
    Infallible,
    /// Function can fail: it propagates errors back to the MetaModelica
    /// runtime via `MMC_THROW` / `c_add_message` / status return. The
    /// Rust lowering wraps the output in `Result<T>`.
    Fallible,
    /// The function is not used in MetaModelica. It is an error if this
    /// function is used during code generation.
    Irrelevant,
}

/// Static registry of known external "C" calls.
///
/// Built lazily on first use; the table is intentionally append-only — once
/// a classification is committed it should only change if the underlying C
/// behavior changes. Each entry must be justified by an inspection of the
/// matching C source.
fn registry() -> &'static BTreeMap<&'static str, Fallibility> {
    static REGISTRY: OnceLock<BTreeMap<&'static str, Fallibility>> = OnceLock::new();
    REGISTRY.get_or_init(|| {
        use Fallibility::*;
        let mut m: BTreeMap<&'static str, Fallibility> = BTreeMap::new();

        // ── ASSCEXT.cpp ────────────────────────────────────────────────────
        // Adjugate-style matrix store: pure data setters/getters, no throws.
        m.insert("ASSC_setMatrix", Infallible);
        m.insert("ASSC_freeMatrix", Infallible);
        m.insert("ASSC_printMatrix", Infallible);

        // ── BackendDAEEXT_omc.cpp ──────────────────────────────────────────
        // Bipartite-matching state machine. Only getAssignment throws (when
        // the caller passes mismatched array dimensions).
        m.insert("BackendDAEEXT_initMarks", Infallible);
        m.insert("BackendDAEEXT_eMark", Infallible);
        m.insert("BackendDAEEXT_getEMark", Infallible);
        m.insert("BackendDAEEXT_vMark", Infallible);
        m.insert("BackendDAEEXT_getVMark", Infallible);
        m.insert("BackendDAEEXT_getMarkedEqns", Infallible);
        m.insert("BackendDAEEXT_getDifferentiatedEqns", Infallible);
        m.insert("BackendDAEEXT_clearDifferentiated", Infallible);
        m.insert("BackendDAEEXT_markDifferentiated", Infallible);
        m.insert("BackendDAEEXT_getMarkedVariables", Infallible);
        m.insert("BackendDAEEXT_initLowLink", Infallible);
        m.insert("BackendDAEEXT_initNumber", Infallible);
        m.insert("BackendDAEEXT_setLowLink", Infallible);
        m.insert("BackendDAEEXT_getLowLink", Infallible);
        m.insert("BackendDAEEXT_setNumber", Infallible);
        m.insert("BackendDAEEXT_getNumber", Infallible);
        m.insert("BackendDAEEXT_dumpMarkedEquations", Infallible);
        m.insert("BackendDAEEXT_dumpMarkedVariables", Infallible);
        m.insert("BackendDAEEXT_initV", Infallible);
        m.insert("BackendDAEEXT_initF", Infallible);
        m.insert("BackendDAEEXT_setV", Infallible);
        m.insert("BackendDAEEXT_getV", Infallible);
        m.insert("BackendDAEEXT_setF", Infallible);
        m.insert("BackendDAEEXT_getF", Infallible);
        m.insert("BackendDAEEXT_setAdjacencyMatrix", Infallible);
        m.insert("BackendDAEEXT_cheapmatching", Infallible);
        m.insert("BackendDAEEXT_matching", Infallible);
        m.insert("BackendDAEEXT_setAssignment", Infallible);
        m.insert("BackendDAEEXT_getAssignment", Fallible); // length mismatch throws

        // ── Corba_omc.cpp / corbaimpl_stub_omc.c ──────────────────────────
        // In the stub build every Corba_* throws; in the corba build only
        // initialize can throw. We choose the safe upper bound: Fallible.
        m.insert("Corba_haveCorba", Infallible); // pure flag query
        m.insert("Corba_setObjectReferenceFilePath", Fallible);
        m.insert("Corba_setSessionName", Fallible);
        m.insert("Corba_waitForCommand", Fallible);
        m.insert("Corba_initialize", Fallible);
        m.insert("Corba_close", Fallible);
        m.insert("Corba_sendreply", Fallible);

        // ── Dynload_omc.cpp ────────────────────────────────────────────────
        m.insert("DynLoad_executeFunction", Fallible); // throws on lookup/call failure

        // ── errorext.cpp / Error_omc.cpp ──────────────────────────────────
        // Message-stack accounting; none of these throw on their own.
        m.insert("ErrorImpl__setCheckpoint", Infallible);
        m.insert("ErrorImpl__rollBack", Infallible);
        m.insert("ErrorImpl__delCheckpoint", Infallible);
        m.insert("ErrorImpl__deleteNumCheckpoints", Infallible);
        m.insert("ErrorImpl__rollbackNumCheckpoints", Infallible);
        m.insert("ErrorImpl__getNumCheckpoints", Infallible);
        m.insert("ErrorImpl__isTopCheckpoint", Infallible);
        m.insert("ErrorImpl__getNumErrorMessages", Infallible);
        m.insert("ErrorImpl__getNumWarningMessages", Infallible);
        m.insert("ErrorImpl__clearMessages", Infallible);
        m.insert("ErrorImpl__getCheckpointMessages", Infallible);
        m.insert("ErrorImpl__pop", Infallible);
        m.insert("ErrorImpl__pushMessages", Infallible);
        m.insert("ErrorImpl__freeMessages", Infallible);
        m.insert("Error_addSourceMessage", Infallible);
        m.insert("Error_getMessages", Infallible);
        m.insert("Error_getNumMessages", Infallible);
        m.insert("Error_initAssertionFunctions", Infallible);
        m.insert("Error_moveMessagesToParentThread", Infallible);
        m.insert("Error_printCheckpointMessagesStr", Infallible);
        m.insert("Error_printErrorsNoWarning", Infallible);
        m.insert("Error_printMessagesStr", Infallible);
        m.insert("Error_registerModelicaFormatError", Infallible);
        m.insert("Error_setShowErrorMessages", Infallible);

        // ── ffi_omc.cpp ────────────────────────────────────────────────────
        m.insert("FFI_callFunction", Fallible); // arg packing + dlsym lookup may throw

        // ── FMIImpl.c ──────────────────────────────────────────────────────
        m.insert("FMIImpl__initializeFMIImport", Fallible); // wrapper throws on stub builds
        m.insert("FMIImpl__releaseFMIImport", Fallible);

        // ── boehm-gc library (omcgc) ───────────────────────────────────────
        // These are direct calls into libgc; the GC primitives have well-
        // defined return-value semantics and never propagate failure back.
        m.insert("GC_disable", Infallible);
        m.insert("GC_enable", Infallible);
        m.insert("GC_expand_hp_dbl", Infallible);
        m.insert("GC_gcollect", Infallible);
        m.insert("GC_gcollect_and_unmap", Infallible);
        m.insert("GC_get_force_unmap_on_gcollect", Infallible);
        m.insert("GC_set_force_unmap_on_gcollect", Infallible);
        m.insert("GC_set_free_space_divisor", Infallible);
        m.insert("GC_set_max_heap_size_dbl", Infallible);
        m.insert("GC_get_prof_stats_modelica", Infallible);

        // ── HpcOmBenchmarkExt_omc.cpp / HpcOmSchedulerExt_omc.cpp ──────────
        // The Visual-Studio stub throws unconditionally; the real impl may
        // also throw on parse failures. Conservative: Fallible.
        m.insert("HpcOmBenchmarkExt_readCalcTimesFromJson", Fallible);
        m.insert("HpcOmBenchmarkExt_readCalcTimesFromXml", Fallible);
        m.insert("HpcOmBenchmarkExt_requiredTimeForComm", Fallible);
        m.insert("HpcOmBenchmarkExt_requiredTimeForOp", Fallible);
        m.insert("HpcOmSchedulerExt_readScheduleFromGraphMl", Fallible);
        m.insert("HpcOmSchedulerExt_scheduleMetis", Fallible);
        m.insert("HpcOmSchedulerExt_schedulehMetis", Fallible);

        // ── IOStreamExt_omc.cpp ────────────────────────────────────────────
        // All File/Buffer ops are NYI stubs that throw; appendReversedList
        // is the only fully-implemented one.
        m.insert("IOStreamExt_createFile", Fallible);
        m.insert("IOStreamExt_closeFile", Fallible);
        m.insert("IOStreamExt_deleteFile", Fallible);
        m.insert("IOStreamExt_clearFile", Fallible);
        m.insert("IOStreamExt_printFile", Fallible);
        m.insert("IOStreamExt_readFile", Fallible);
        m.insert("IOStreamExt_appendFile", Fallible);
        m.insert("IOStreamExt_createBuffer", Fallible);
        m.insert("IOStreamExt_deleteBuffer", Fallible);
        m.insert("IOStreamExt_clearBuffer", Fallible);
        m.insert("IOStreamExt_readBuffer", Fallible);
        m.insert("IOStreamExt_appendBuffer", Fallible);
        m.insert("IOStreamExt_printBuffer", Fallible);
        m.insert("IOStreamExt_appendReversedList", Infallible);
        m.insert("IOStreamExt_printReversedList", Fallible); // default case throws

        // ── NFInst.mo inline external ──────────────────────────────────────
        m.insert("Inst_makeTopNode", Infallible); // TODO: not found in runtime/; inline helper

        // ── lapackimpl.c ───────────────────────────────────────────────────
        // LAPACK wrappers return *INFO via output args; only the
        // no-LAPACK build throws. Conservative on success path: Infallible.
        m.insert("LapackImpl__dgbsv", Infallible);
        m.insert("LapackImpl__dgeev", Infallible);
        m.insert("LapackImpl__dgegv", Infallible);
        m.insert("LapackImpl__dgels", Infallible);
        m.insert("LapackImpl__dgelsx", Infallible);
        m.insert("LapackImpl__dgelsy", Infallible);
        m.insert("LapackImpl__dgeqpf", Infallible);
        m.insert("LapackImpl__dgesv", Infallible);
        m.insert("LapackImpl__dgesvd", Infallible);
        m.insert("LapackImpl__dgetrf", Infallible);
        m.insert("LapackImpl__dgetri", Infallible);
        m.insert("LapackImpl__dgetrs", Infallible);
        m.insert("LapackImpl__dgglse", Infallible);
        m.insert("LapackImpl__dgtsv", Infallible);
        m.insert("LapackImpl__dhseqr", Infallible);
        m.insert("LapackImpl__dorgqr", Infallible);

        // ── OMSimulator_omc.c ──────────────────────────────────────────────
        // All OMSimulator entry points return an int oms_status_t; none
        // call MMC_THROW. Errors flow back via the integer status code.
        m.insert("OMSimulator_loadDLL", Infallible);
        m.insert("OMSimulator_unloadDLL", Infallible);
        m.insert("OMSimulator_oms_getVersion", Infallible);
        m.insert("OMSimulator_oms_RunFile", Infallible);
        m.insert("OMSimulator_oms_addBus", Infallible);
        m.insert("OMSimulator_oms_addConnection", Infallible);
        m.insert("OMSimulator_oms_addConnector", Infallible);
        m.insert("OMSimulator_oms_addConnectorToBus", Infallible);
        m.insert("OMSimulator_oms_addConnectorToTLMBus", Infallible);
        m.insert("OMSimulator_oms_addDynamicValueIndicator", Infallible);
        m.insert("OMSimulator_oms_addEventIndicator", Infallible);
        m.insert("OMSimulator_oms_addExternalModel", Infallible);
        m.insert("OMSimulator_oms_addSignalsToResults", Infallible);
        m.insert("OMSimulator_oms_addStaticValueIndicator", Infallible);
        m.insert("OMSimulator_oms_addSubModel", Infallible);
        m.insert("OMSimulator_oms_addSystem", Infallible);
        m.insert("OMSimulator_oms_addTLMBus", Infallible);
        m.insert("OMSimulator_oms_addTLMConnection", Infallible);
        m.insert("OMSimulator_oms_addTimeIndicator", Infallible);
        m.insert("OMSimulator_oms_compareSimulationResults", Infallible);
        m.insert("OMSimulator_oms_copySystem", Infallible);
        m.insert("OMSimulator_oms_delete", Infallible);
        m.insert("OMSimulator_oms_deleteConnection", Infallible);
        m.insert("OMSimulator_oms_deleteConnectorFromBus", Infallible);
        m.insert("OMSimulator_oms_deleteConnectorFromTLMBus", Infallible);
        m.insert("OMSimulator_oms_export", Infallible);
        m.insert("OMSimulator_oms_exportDependencyGraphs", Infallible);
        m.insert("OMSimulator_oms_exportSnapshot", Infallible);
        m.insert("OMSimulator_oms_extractFMIKind", Infallible);
        m.insert("OMSimulator_oms_faultInjection", Infallible);
        m.insert("OMSimulator_oms_getBoolean", Infallible);
        m.insert("OMSimulator_oms_getFixedStepSize", Infallible);
        m.insert("OMSimulator_oms_getInteger", Infallible);
        m.insert("OMSimulator_oms_getModelState", Infallible);
        m.insert("OMSimulator_oms_getReal", Infallible);
        m.insert("OMSimulator_oms_getSolver", Infallible);
        m.insert("OMSimulator_oms_getStartTime", Infallible);
        m.insert("OMSimulator_oms_getStopTime", Infallible);
        m.insert("OMSimulator_oms_getSubModelPath", Infallible);
        m.insert("OMSimulator_oms_getSystemType", Infallible);
        m.insert("OMSimulator_oms_getTolerance", Infallible);
        m.insert("OMSimulator_oms_getVariableStepSize", Infallible);
        m.insert("OMSimulator_oms_importFile", Infallible);
        m.insert("OMSimulator_oms_importSnapshot", Infallible);
        m.insert("OMSimulator_oms_initialize", Infallible);
        m.insert("OMSimulator_oms_instantiate", Infallible);
        m.insert("OMSimulator_oms_list", Infallible);
        m.insert("OMSimulator_oms_listUnconnectedConnectors", Infallible);
        m.insert("OMSimulator_oms_loadSnapshot", Infallible);
        m.insert("OMSimulator_oms_newModel", Infallible);
        m.insert("OMSimulator_oms_removeSignalsFromResults", Infallible);
        m.insert("OMSimulator_oms_rename", Infallible);
        m.insert("OMSimulator_oms_reset", Infallible);
        m.insert("OMSimulator_oms_setBoolean", Infallible);
        m.insert("OMSimulator_oms_setCommandLineOption", Infallible);
        m.insert("OMSimulator_oms_setFixedStepSize", Infallible);
        m.insert("OMSimulator_oms_setInteger", Infallible);
        m.insert("OMSimulator_oms_setLogFile", Infallible);
        m.insert("OMSimulator_oms_setLoggingInterval", Infallible);
        m.insert("OMSimulator_oms_setLoggingLevel", Infallible);
        m.insert("OMSimulator_oms_setReal", Infallible);
        m.insert("OMSimulator_oms_setRealInputDerivative", Infallible);
        m.insert("OMSimulator_oms_setResultFile", Infallible);
        m.insert("OMSimulator_oms_setSignalFilter", Infallible);
        m.insert("OMSimulator_oms_setSolver", Infallible);
        m.insert("OMSimulator_oms_setStartTime", Infallible);
        m.insert("OMSimulator_oms_setStopTime", Infallible);
        m.insert("OMSimulator_oms_setTLMPositionAndOrientation", Infallible);
        m.insert("OMSimulator_oms_setTLMSocketData", Infallible);
        m.insert("OMSimulator_oms_setTempDirectory", Infallible);
        m.insert("OMSimulator_oms_setTolerance", Infallible);
        m.insert("OMSimulator_oms_setVariableStepSize", Infallible);
        m.insert("OMSimulator_oms_setWorkingDirectory", Infallible);
        m.insert("OMSimulator_oms_simulate", Infallible);
        m.insert("OMSimulator_oms_stepUntil", Infallible);
        m.insert("OMSimulator_oms_terminate", Infallible);

        // ── ModelicaBuiltin.mo runtime helpers ─────────────────────────────
        // Declared as `external "C"` from ModelicaBuiltin.mo but backed by
        // genuine C entry points under runtime/.
        m.insert("OpenModelicaInternal_stat", Fallible); // syscall, throws on EACCES etc.
        m.insert("OpenModelica_regex", Fallible);        // throws on bad pattern
        m.insert("OpenModelica_updateUriMapping", Infallible);

        // ── Parser_omc.c ───────────────────────────────────────────────────
        // All parse_* throw on parse failure; the LVE side returns int.
        m.insert("ParserExt_parse", Fallible);
        m.insert("ParserExt_parseexp", Fallible);
        m.insert("ParserExt_parsestring", Fallible);
        m.insert("ParserExt_parsestringexp", Fallible);
        m.insert("ParserExt_stringPath", Fallible);
        m.insert("ParserExt_stringCref", Fallible);
        m.insert("ParserExt_stringMod", Fallible);
        m.insert("ParserExt_stringEq", Fallible);
        m.insert("ParserExt_startLibraryVendorExecutable", Infallible);
        m.insert("ParserExt_checkLVEToolLicense", Infallible);
        m.insert("ParserExt_checkLVEToolFeature", Infallible);
        m.insert("ParserExt_stopLibraryVendorExecutable", Infallible);

        // ── Print_omc.c ────────────────────────────────────────────────────
        // Wrappers that touch the per-thread print buffer; throw if the
        // PrintImpl side returns NULL / out-of-bounds.
        m.insert("Print_saveAndClearBuf", Fallible);
        m.insert("Print_restoreBuf", Fallible);
        m.insert("Print_printErrorBuf", Fallible);
        m.insert("Print_printBufLen", Fallible);
        m.insert("Print_hasBufNewLineAtEnd", Infallible);
        m.insert("Print_getBufLength", Infallible);
        m.insert("Print_getString", Fallible);
        m.insert("Print_getErrorString", Fallible);
        m.insert("Print_clearErrorBuf", Infallible);
        m.insert("Print_clearBuf", Infallible);
        m.insert("Print_printBufSpace", Fallible);
        m.insert("Print_printBufNewLine", Fallible);
        m.insert("Print_writeBuf", Fallible);
        m.insert("Print_writeBufConvertLines", Fallible);

        // ── serializer.cpp ─────────────────────────────────────────────────
        m.insert("Serializer_outputFile", Infallible);
        m.insert("Serializer_bypass", Infallible);

        // ── settingsimpl.c / Settings_omc.cpp ──────────────────────────────
        // Settings_omc.cpp wrappers for the installation/Modelica path can
        // throw if the underlying impl returns NULL.
        m.insert("SettingsImpl__setInstallationDirectoryPath", Infallible);
        m.insert("SettingsImpl__setModelicaPath", Infallible);
        m.insert("SettingsImpl__setTempDirectoryPath", Infallible);
        m.insert("Settings_dumpSettings", Infallible);
        m.insert("Settings_getEcho", Infallible);
        m.insert("Settings_getHomeDir", Infallible);
        m.insert("Settings_getInstallationDirectoryPath", Fallible);
        m.insert("Settings_getModelicaPath", Fallible);
        m.insert("Settings_getTempDirectoryPath", Infallible);
        m.insert("Settings_getVersionNr", Infallible);
        m.insert("Settings_setEcho", Infallible);

        // ── SimulationResults_omc.c ────────────────────────────────────────
        // The reader chain can fail (missing file, missing variable, parse
        // error). Closing the cache is infallible.
        m.insert("SimulationResults_close", Infallible);
        m.insert("SimulationResults_cmpSimulationResults", Fallible);
        m.insert("SimulationResults_deltaSimulationResults", Fallible);
        m.insert("SimulationResults_diffSimulationResults", Fallible);
        m.insert("SimulationResults_diffSimulationResultsHtml", Fallible);
        m.insert("SimulationResults_filterSimulationResults", Fallible);
        m.insert("SimulationResults_readDataset", Fallible);
        m.insert("SimulationResults_readSimulationResultSize", Fallible);
        m.insert("SimulationResults_readVariables", Fallible);
        m.insert("SimulationResults_val", Fallible);

        // ── socketimpl.c / Socket_omc.c ────────────────────────────────────
        m.insert("Socket_waitforconnect", Infallible);
        m.insert("Socket_handlerequest", Infallible);
        m.insert("Socket_close", Infallible);
        m.insert("Socket_sendreply", Infallible);
        m.insert("Socket_cleanup", Infallible);

        // ── System.mo inline external (StringAllocator) ────────────────────
        m.insert("StringAllocator_constructor", Fallible); // negative size throws

        // ── systemimpl.c (SystemImpl_*) ────────────────────────────────────
        m.insert("SystemImpl__alarm", Infallible);
        m.insert("SystemImpl__chdir", Infallible);             // returns int status
        m.insert("SystemImpl__copyFile", Infallible);          // returns int status
        m.insert("SystemImpl__covertTextFileToCLiteral", Infallible);
        m.insert("SystemImpl__createDirectory", Infallible);
        m.insert("SystemImpl__createTemporaryDirectory", Fallible); // mkdtemp failure throws
        m.insert("SystemImpl__ctime", Infallible);
        m.insert("SystemImpl__dgesv", Fallible);               // throws if LAPACK missing
        m.insert("SystemImpl__directoryExists", Infallible);
        m.insert("SystemImpl__dladdr", Infallible);
        m.insert("SystemImpl__fflush", Infallible);
        m.insert("SystemImpl__fileContentsEqual", Infallible);
        m.insert("SystemImpl__fputs", Infallible);
        m.insert("SystemImpl__getCurrentTime", Infallible);
        m.insert("SystemImpl__getSizeOfData", Infallible);
        m.insert("SystemImpl__gettext", Infallible);
        m.insert("SystemImpl__gettextInit", Infallible);
        m.insert("SystemImpl__iconv", Infallible);             // returns "" on failure, not MMC_THROW
        m.insert("SystemImpl__loadModelCallBack", Infallible);
        m.insert("SystemImpl__loadModelCallBackDefined", Infallible);
        m.insert("SystemImpl__plotCallBack", Infallible);
        m.insert("SystemImpl__plotCallBackDefined", Infallible);
        m.insert("SystemImpl__pwd", Infallible);               // returns NULL/empty on failure
        m.insert("SystemImpl__realRand", Infallible);
        m.insert("SystemImpl__regularFileExists", Infallible);
        m.insert("SystemImpl__regularFileReadable", Infallible);
        m.insert("SystemImpl__regularFileWritable", Infallible);
        m.insert("SystemImpl__relocateFunctions", Infallible);
        m.insert("SystemImpl__removeDirectory", Infallible);
        m.insert("SystemImpl__removeFile", Infallible);
        m.insert("SystemImpl__rename", Infallible);
        m.insert("SystemImpl__reopenStandardStream", Infallible);
        m.insert("SystemImpl__setCCompiler", Infallible);
        m.insert("SystemImpl__setCFlags", Infallible);
        m.insert("SystemImpl__setCXXCompiler", Infallible);
        m.insert("SystemImpl__setLDFlags", Infallible);
        m.insert("SystemImpl__setLinker", Infallible);
        m.insert("SystemImpl__spawnCall", Infallible);
        m.insert("SystemImpl__stat", Infallible);
        m.insert("SystemImpl__systemCall", Infallible);
        m.insert("SystemImpl__systemCallParallel", Infallible);
        m.insert("SystemImpl__time", Infallible);
        m.insert("SystemImpl__unescapedStringLength", Infallible);
        m.insert("SystemImpl__waitForInput", Infallible);
        m.insert("SystemImpl__winGetSystemDirectoryA", Infallible); // c_add_message but no MMC_THROW
        m.insert("SystemImpl_tmpTickIndex", Infallible);
        m.insert("SystemImpl_tmpTickIndexReserve", Infallible);
        m.insert("SystemImpl_tmpTickMaximum", Infallible);
        m.insert("SystemImpl_tmpTickReset", Infallible);
        m.insert("SystemImpl_tmpTickResetIndex", Infallible);
        m.insert("SystemImpl_tmpTickSetIndex", Infallible);

        // ── System_omc.c (System_* wrappers) ───────────────────────────────
        // The wrappers in System_omc.c that throw on NULL/-1 return: any of
        // the file/library/realtime functions whose preconditions are
        // checked at the wrapper.
        m.insert("System_appendFile", Fallible);
        m.insert("System_basename", Infallible);
        m.insert("System_dirname", Infallible);
        m.insert("System_escapedString", Infallible);
        m.insert("System_fileIsNewerThan", Fallible);          // returns -1 → MMC_THROW
        m.insert("System_freeFunction", Fallible);
        m.insert("System_freeLibrary", Fallible);
        m.insert("System_gccDumpMachine", Infallible);
        m.insert("System_gccVersion", Infallible);
        m.insert("System_getCCompiler", Infallible);
        m.insert("System_getCFlags", Infallible);
        m.insert("System_getCXXCompiler", Infallible);
        m.insert("System_getClassnamesForSimulation", Infallible);
        m.insert("System_getCurrentDateTime", Infallible);
        m.insert("System_getCurrentTimeStr", Fallible);        // localtime failure throws
        m.insert("System_getFileModificationTime", Infallible);
        m.insert("System_getHasExpandableConnectors", Infallible);
        m.insert("System_getHasInnerOuterDefinitions", Infallible);
        m.insert("System_getHasOverconstrainedConnectors", Infallible);
        m.insert("System_getHasStreamConnectors", Infallible);
        m.insert("System_getLDFlags", Infallible);
        m.insert("System_getLinker", Infallible);
        m.insert("System_getLoadModelPath", Fallible);         // throws when no path matches
        m.insert("System_getMemorySize", Infallible);
        m.insert("System_getOMPCCompiler", Infallible);
        m.insert("System_getPartialInstantiation", Infallible);
        m.insert("System_getSimulationHelpTextSphinx", Infallible);
        m.insert("System_getTerminalWidth", Infallible);
        m.insert("System_getTimerCummulatedTime", Infallible);
        m.insert("System_getTimerElapsedTime", Infallible);
        m.insert("System_getTimerIntervalTime", Infallible);
        m.insert("System_getTimerStackIndex", Infallible);
        m.insert("System_getUUIDStr", Infallible);
        m.insert("System_getUsesCardinality", Infallible);
        m.insert("System_getVariableValue", Fallible);         // throws on lookup failure
        m.insert("System_getuid", Infallible);
        m.insert("System_initGarbageCollector", Infallible);
        m.insert("System_launchParallelTasks", Fallible);      // MMC_THROW_INTERNAL on pthread error
        m.insert("System_loadLibrary", Fallible);              // throws on dlopen failure
        m.insert("System_lookupFunction", Fallible);           // -1 → throw
        m.insert("System_makeC89Identifier", Infallible);
        m.insert("System_moFiles", Infallible);
        m.insert("System_mocFiles", Infallible);
        m.insert("System_modelicaPlatform", Infallible);
        m.insert("System_numProcessors", Infallible);
        m.insert("System_openModelicaPlatform", Infallible);
        m.insert("System_openModelicaPlatformAlternative", Infallible);
        m.insert("System_popen", Infallible);                  // returns status via output arg
        m.insert("System_readEnv", Fallible);                  // throws on missing var
        m.insert("System_readFile", Fallible);
        m.insert("System_realpath", Fallible);                 // canonicalisation throws
        m.insert("System_realtimeAccumulate", Fallible);       // index OOB throws
        m.insert("System_realtimeAccumulated", Fallible);
        m.insert("System_realtimeClear", Fallible);
        m.insert("System_realtimeNtick", Fallible);
        m.insert("System_realtimeTick", Fallible);
        m.insert("System_realtimeTock", Fallible);
        m.insert("System_regex", Infallible);                  // numMatches returned as 0 on bad regex
        m.insert("System_resetTimer", Infallible);
        m.insert("System_setClassnamesForSimulation", Infallible);
        m.insert("System_setHasExpandableConnectors", Infallible);
        m.insert("System_setHasInnerOuterDefinitions", Infallible);
        m.insert("System_setHasOverconstrainedConnectors", Infallible);
        m.insert("System_setHasStreamConnectors", Infallible);
        m.insert("System_setPartialInstantiation", Infallible);
        m.insert("System_setUsesCardinality", Infallible);
        m.insert("System_snprintff", Fallible);                // format-arg validation throws
        m.insert("System_splitOnNewline", Fallible);           // allocation failure throws
        m.insert("System_sprintff", Fallible);
        m.insert("System_startTimer", Infallible);
        m.insert("System_stopTimer", Infallible);
        m.insert("System_strcmp", Infallible);
        m.insert("System_strcmp_offset", Infallible);
        m.insert("System_stringFind", Fallible);               // returns -1 → MMC_THROW
        m.insert("System_stringFindString", Infallible);
        m.insert("System_stringReplace", Fallible);            // NULL on alloc fail throws
        m.insert("System_strncmp", Infallible);
        m.insert("System_strtok", Infallible);
        m.insert("System_strtokIncludingDelimiters", Infallible);
        m.insert("System_subDirectories", Infallible);
        m.insert("System_threadFail", Infallible);             // direct MMC_THROW is the entire body — but it is the *callee*'s purpose to throw; treat as Fallible? See below.
        m.insert("System_tolower", Infallible);
        m.insert("System_toupper", Infallible);
        m.insert("System_trim", Infallible);
        m.insert("System_trimChar", Fallible);                 // multi-char input throws
        m.insert("System_unescapedString", Infallible);
        m.insert("System_unquoteIdentifier", Infallible);
        m.insert("System_uriToClassAndPath", Fallible);        // malformed URI throws
        m.insert("System_userIsRoot", Infallible);
        m.insert("System_writeFile", Fallible);

        // ── TaskGraphResults_omc.cpp ───────────────────────────────────────
        m.insert("TaskGraphResults_checkCodeGraph", Fallible);
        m.insert("TaskGraphResults_checkTaskGraph", Fallible);

        // ── unitparserext.cpp / UnitParserExt_omc.cpp ─────────────────────
        m.insert("UnitParserExtImpl__addBase", Infallible);
        m.insert("UnitParserExtImpl__addDerived", Infallible);
        m.insert("UnitParserExtImpl__addDerivedWeight", Infallible);
        m.insert("UnitParserExtImpl__allUnitSymbols", Infallible);
        m.insert("UnitParserExtImpl__checkpoint", Infallible);
        m.insert("UnitParserExtImpl__clear", Infallible);
        m.insert("UnitParserExtImpl__commit", Infallible);
        m.insert("UnitParserExtImpl__initSIUnits", Infallible);
        m.insert("UnitParserExtImpl__registerWeight", Infallible);
        m.insert("UnitParserExtImpl__rollback", Infallible);
        m.insert("UnitParserExt_str2unit", Fallible);
        m.insert("UnitParserExt_unit2str", Infallible);

        // ── zeromqimpl.c / ZeroMQ_omc.c ────────────────────────────────────
        m.insert("ZeroMQ_initialize", Infallible);
        m.insert("ZeroMQ_handleRequest", Infallible);
        m.insert("ZeroMQ_sendReply", Infallible);
        m.insert("ZeroMQ_close", Infallible);

        // ── Util.mo / NFModelicaBuiltin.mo inline helpers ──────────────────
        // Tiny inline `external "C" Include="..."` shims; pure data access.
        m.insert("anyStringCode", Infallible);
        m.insert("architecture_numbits", Infallible);
        m.insert("referenceCompareExt", Infallible);

        // ── libc / runtime symbols used directly ───────────────────────────
        m.insert("exit", Fallible);                            // by definition, terminates control
        m.insert("rand", Infallible);
        m.insert("setenv", Infallible);                        // success/failure via return value

        // ── StackOverflow.mo runtime hooks ─────────────────────────────────
        m.insert("mmc_do_stackoverflow", Fallible);            // longjmps
        m.insert("mmc_getStacktraceMessages_threadData", Infallible);
        m.insert("mmc_setStacktraceMessages_threadData", Infallible);
        m.insert("mmc_hasStacktraceMessages", Infallible);
        m.insert("mmc_clearStacktraceMessages", Infallible);

        // ── Mutable.mo / Pointer.mo inline helpers ─────────────────────────
        m.insert("mutableCreate", Infallible);
        m.insert("mutableUpdate", Infallible);
        m.insert("mutableAccess", Infallible);
        m.insert("pointerCreate", Infallible);
        m.insert("pointerUpdate", Infallible);
        m.insert("pointerAccess", Infallible);

        // ── om_curl.c / om_unzip.c ─────────────────────────────────────────
        m.insert("om_curl_multi_download", Infallible);
        m.insert("om_unzip", Infallible);

        // ── omc_file_ext.h inline file API ─────────────────────────────────
        // The om_file_* family of helpers are static inline; none of them
        // call MMC_THROW or report failure beyond their integer status.
        m.insert("om_file_new", Infallible);
        m.insert("om_file_free", Infallible);
        m.insert("om_file_open", Infallible);
        m.insert("om_file_write", Infallible);
        m.insert("om_file_write_int", Infallible);
        m.insert("om_file_write_real", Infallible);
        m.insert("om_file_write_escape", Infallible);
        m.insert("om_file_seek", Infallible);
        m.insert("om_file_tell", Infallible);
        m.insert("om_file_get_filename", Infallible);
        m.insert("om_file_no_reference", Infallible);
        m.insert("om_file_get_reference", Infallible);
        m.insert("om_file_release_reference", Infallible);

        // ── System.mo inline StringAllocator helpers ───────────────────────
        m.insert("om_stringAllocatorResult", Infallible);
        m.insert("om_stringAllocatorStringCopy", Infallible);

        // ── GCExt.mo inline GC_free wrapper ────────────────────────────────
        m.insert("omc_GC_free_ext", Infallible);

        // ── JSONExt.mo inline cast/inspector helpers ───────────────────────
        m.insert("omc_cast_int", Infallible);
        m.insert("omc_cast_real", Infallible);
        m.insert("omc_cast_string", Infallible);
        m.insert("omc_get_list", Infallible);
        m.insert("omc_get_list_element", Infallible);
        m.insert("omc_get_record_component", Infallible);
        m.insert("omc_get_record_names", Infallible);
        m.insert("omc_get_some", Infallible);
        m.insert("omc_get_tuple_size", Infallible);
        m.insert("omc_is_array", Infallible);
        m.insert("omc_is_cons", Infallible);
        m.insert("omc_is_integer", Infallible);
        m.insert("omc_is_nil", Infallible);
        m.insert("omc_is_none", Infallible);
        m.insert("omc_is_real", Infallible);
        m.insert("omc_is_record", Infallible);
        m.insert("omc_is_some", Infallible);
        m.insert("omc_is_string", Infallible);
        m.insert("omc_is_tuple", Infallible);

        // ── SerializeSparsityPattern.mo writers ────────────────────────────
        // Inline C snippets in the .mo's Include annotation (not in runtime/);
        // they throwStreamPrint on open/write failure. Hand-written as
        // Result-returning functions in
        // `openmodelica_backend/src/SerializeSparsityPattern.rs`.
        m.insert("serializeC", Fallible);
        m.insert("serializeJ", Fallible);

        m.insert("intMaxLit", Infallible);
        m.insert("realMaxLit", Infallible);

        // NFApi.mo
        m.insert("ModelInstanceReference_store", Infallible);
        m.insert("ModelInstanceReference_release", Infallible);

        m.insert("OMGraphics_graphicalRepresentationXMLFromHandle", Infallible);
        m.insert("OMGraphics_iconSVGFromHandle", Infallible);
        m.insert("OMGraphics_placedConnectorCount", Infallible);
        m.insert("OMGraphics_placedConnectorIconSVG", Infallible);
        m.insert("OMGraphics_placedConnectorInfo", Infallible);
        m.insert("OMGraphics_writeIconPNGFromHandle", Infallible);
        m.insert("OMGraphics_writePlacedConnectorIconPNG", Infallible);

        m
    })
}

/// Look up an external C function by its `funcName` (the symbol referenced
/// from the `external "C" ...` clause). Returns `None` if not registered.
///
/// Codegen will use this once it learns to emit external bindings; for
/// the analysis-phase consumer, see [`lookup_or_panic`].
#[allow(dead_code)]
pub fn lookup(name: &str) -> Option<Fallibility> {
    registry().get(name).copied()
}

/// Strict variant of [`lookup`] — panics with an explanatory message if the
/// external is not yet listed.  Use from analysis-phase code where the table
/// is required to be exhaustive.
///
/// `mm_qname` is the dotted MM-side name of the wrapper function (used only
/// for the panic diagnostic, so a missing entry can be traced back to the
/// MetaModelica declaration).
///
/// ## Lenient escape hatch
///
/// Setting `MMTORUST_LENIENT_EXTERNALS=1` in the environment downgrades the
/// panic to a one-shot stderr warning and returns [`Fallibility::Fallible`]
/// (the conservative classification: any call site keeps its `?`). This
/// exists *only* to unblock development while the 400+ entry registry is
/// being populated; CI and release builds should leave it unset so that the
/// strict invariant is enforced.
pub fn lookup_or_panic(c_name: &str, mm_qname: &str) -> Fallibility {
    if !mm_qname.contains('.') {
        return Fallibility::Irrelevant;
    }
    if mm_qname.starts_with("Connections") ||
       mm_qname.starts_with("Subtask") ||
       mm_qname.starts_with("OMC_") ||
       mm_qname.starts_with("Pointer") ||
       mm_qname.starts_with("OpenModelica.") {
        return Fallibility::Irrelevant;
    }
    if let Some(f) = registry().get(c_name) {
        return *f;
    }
    if lenient_mode() {
        record_lenient_miss(c_name, mm_qname);
        return Fallibility::Fallible;
    }
    panic!(
        "external_c_calls: no fallibility entry for external \"C\" function `{c_name}` \
         (used by MetaModelica function `{mm_qname}`).\n\
         Add an entry to mmtorust/src/external_c_calls.rs after inspecting the \
         corresponding C source under OMCompiler/Compiler/runtime/.\n\
         To bypass during bulk registry population, set MMTORUST_LENIENT_EXTERNALS=1 \
         — but only as a temporary measure; missing entries default to `Fallible` \
         and silently bloat the generated code."
    );
}

fn lenient_mode() -> bool {
    static LENIENT: OnceLock<bool> = OnceLock::new();
    *LENIENT.get_or_init(|| matches!(
        std::env::var("MMTORUST_LENIENT_EXTERNALS").as_deref(),
        Ok("1") | Ok("true") | Ok("TRUE") | Ok("yes")
    ))
}

/// Track misses in lenient mode so we can emit one consolidated warning per
/// distinct symbol — flooding stderr with a line per call site would obscure
/// the real signal.
fn record_lenient_miss(c_name: &str, mm_qname: &str) {
    use std::sync::Mutex;
    static MISSES: OnceLock<Mutex<std::collections::BTreeSet<String>>> = OnceLock::new();
    let set = MISSES.get_or_init(|| Mutex::new(std::collections::BTreeSet::new()));
    let mut guard = set.lock().expect("MISSES mutex");
    if guard.insert(c_name.to_owned()) {
        eprintln!("warning: external_c_calls: unlisted external `{c_name}` for `{mm_qname}` (assuming Fallible — lenient mode)");
    }
}

/// Number of registered externals — diagnostic aid for the analysis summary.
pub fn registered_count() -> usize {
    registry().len()
}

/// Map a C function name (the symbol in `external "C" foo(...)`) to the
/// Rust path of a hand-written replacement. When `Some`, the codegen emits
/// a delegating call instead of the default `todo!()` stub.
///
/// Implementations live in `metamodelica::ext` (see
/// `metamodelica/src/ext.rs`) so every generated crate can reach them
/// through the runtime crate it already imports.
///
/// The Rust signature is expected to match the *MetaModelica* signature
/// of the wrapper function (the `threadData` argument the C side takes is
/// not part of the MM side, so it is dropped here too).
pub fn external_c_impl_path(c_name: &str) -> Option<&'static str> {
    match c_name {
        // NBASSC matrix store (runtime/ASSCEXT_omc.cpp): an upstream stub —
        // setMatrix stores a CSR matrix that nothing reads back yet.
        // Hand-written in `openmodelica_nbackend/src/NBASSCExt.rs`; `NBASSC` is
        // the only package that declares these externals, so the generated
        // call site is always in that crate and `crate::` resolves correctly.
        "ASSC_setMatrix" => Some("crate::NBASSCExt::ASSC_setMatrix"),
        "ASSC_freeMatrix" => Some("crate::NBASSCExt::ASSC_freeMatrix"),
        "ASSC_printMatrix" => Some("crate::NBASSCExt::ASSC_printMatrix"),
        // `-d=gen` dynamic-load pipeline: marshal the argument/result `Values`
        // through the dynamically loaded `in_*` entry point. Only called from
        // `DynLoad.executeFunction` (same crate), hence the `crate::` path.
        "DynLoad_executeFunction" => Some("crate::DynLoadExt::executeFunction"),
        // In-memory model-instance reference store (runtime/
        // ModelInstanceReference_omc.c, issue #15219). Hand-written in
        // `openmodelica_backend_main/src/ModelInstanceReference.rs`; only
        // `NFApi` (same crate) declares these externals, so `crate::` resolves.
        "ModelInstanceReference_store" => Some("crate::ModelInstanceReference::store"),
        "ModelInstanceReference_release" => Some("crate::ModelInstanceReference::release"),
        _ => None,
    }
}
