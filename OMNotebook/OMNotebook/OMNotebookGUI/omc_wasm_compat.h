#ifndef OMC_WASM_COMPAT_H
#define OMC_WASM_COMPAT_H

// Web build: omc runs in a Web Worker, not in-process, so there is no
// MetaModelica runtime. threadData is an empty carrier and MMC try/init become
// plain blocks (the no-op slice of omc_rust_embedding.h). Shared header so the
// definitions stay single across the headers cellapplication.cpp pulls in.
#if defined(__EMSCRIPTEN__)
struct threadData_s {};
typedef struct threadData_s threadData_t;
#define MMC_INIT(...)       ((void) 0)
#define MMC_TRY_TOP()       { threadData_t threadDataOnStack = {}; threadData_t *threadData = &threadDataOnStack; (void) threadData; {
#define MMC_CATCH_TOP(...)  } if (0) { __VA_ARGS__; } }
#endif

#endif
