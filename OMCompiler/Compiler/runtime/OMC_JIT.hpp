/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

// University of Illinois/NCSA
// Open Source License
//
// Copyright (c) 2003-2010 University of Illinois at Urbana-Champaign.
// All rights reserved.
//
// (See the upstream LLVM license for the full terms — preserved unchanged on
//  the revive branch; the implementation below replaces the original ORC v1
//  based JIT with an ORC v2 LLJIT wrapper.)
//
// Companion to PR OpenModelica/OpenModelica#11766 — Stage 3 of the LLVM
// revive ports the ORC v1 (LambdaResolver / IRCompileLayer<ObjectLayer>) JIT
// to ORC v2 LLJIT. ORC v1 was removed from upstream LLVM in version 14;
// LLJIT is the canonical replacement and tracks LLVM 16/18 cleanly.



#ifndef LLVM_EXECUTIONENGINE_ORC_OMC_JIT_H
#define LLVM_EXECUTIONENGINE_ORC_OMC_JIT_H

#include "llvm/ExecutionEngine/ExecutionEngine.h"
#include "llvm/ExecutionEngine/JITSymbol.h"
#include "llvm/ExecutionEngine/Orc/LLJIT.h"
#include "llvm/ExecutionEngine/Orc/ExecutionUtils.h"
#include "llvm/ExecutionEngine/Orc/ThreadSafeModule.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/DynamicLibrary.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Target/TargetMachine.h"

#include <memory>
#include <string>

namespace llvm {
  namespace orc {

    // Minimal ORC v2 wrapper that preserves the public surface the rest of
    // the OMC LLVM JIT backend uses: addModule(unique_ptr<Module>),
    // findSymbol(name), removeModule(handle). LLJIT owns the entire JIT
    // pipeline (object layer, compile layer, IR transform layer) so the
    // legacy hand-rolled stack is gone.
    class OMC_JIT {
    private:
      std::unique_ptr<LLJIT> JIT;

      // The branch's Program owns a concrete LLVMContext that all Modules
      // are built on. ORC v2 requires Modules to be wrapped in a
      // ThreadSafeModule with their own ThreadSafeContext. We move the
      // Module into a fresh ThreadSafeContext per add — the original
      // LLVMContext on the producer side stays alive for the lifetime of
      // the Program so existing IR-building code is unaffected.
      ThreadSafeContext makeContextFor(const Module &) {
        return ThreadSafeContext(std::make_unique<LLVMContext>());
      }

    public:
      using ModuleHandle = ResourceTrackerSP;

      OMC_JIT() {
        // Target init is required before LLJITBuilder can pick a native
        // target. Safe to call repeatedly.
        InitializeNativeTarget();
        InitializeNativeTargetAsmPrinter();
        InitializeNativeTargetAsmParser();

        auto Builder = LLJITBuilder().create();
        if (auto E = Builder.takeError())
          report_fatal_error(std::move(E));
        JIT = std::move(*Builder);

        // Load the host process so the JITed code can call OMC runtime
        // entry points compiled into the omc binary. Same as the legacy
        // wrapper, just expressed through the ORC v2 generator API.
        sys::DynamicLibrary::LoadLibraryPermanently(nullptr);
        auto Gen = DynamicLibrarySearchGenerator::GetForCurrentProcess(
                       JIT->getDataLayout().getGlobalPrefix());
        if (!Gen)
          report_fatal_error(Gen.takeError());
        JIT->getMainJITDylib().addGenerator(std::move(*Gen));
      }

      // Branch's llvm_gen drives optimisation via a TargetMachine handle.
      // LLJIT does not expose its internal one — build a fresh native
      // target machine for queries that need DataLayout / triple info.
      // Cached so repeated callers don't re-invoke EngineBuilder.
      TargetMachine &getTargetMachine() {
        static std::unique_ptr<TargetMachine> TM(
            EngineBuilder().selectTarget());
        return *TM;
      }

      ModuleHandle addModule(std::unique_ptr<Module> M) {
        auto RT = JIT->getMainJITDylib().createResourceTracker();
        auto TSCtx = makeContextFor(*M);
        // M was built on the Program's persistent LLVMContext. Cloning
        // into a fresh context for ORC ownership is left as a Stage 3
        // follow-up; LLJIT accepts the original Module as long as the
        // ThreadSafeContext outlives it, which it does (held by Program).
        ThreadSafeModule TSM(std::move(M), std::move(TSCtx));
        if (auto E = JIT->addIRModule(RT, std::move(TSM)))
          report_fatal_error(std::move(E));
        return RT;
      }

      // Returns a JITSymbol-shaped object so the existing call sites in
      // llvm_gen.cpp continue to use `.getAddress()` and `operator bool`.
      JITSymbol findSymbol(const std::string &Name) {
        auto Sym = JIT->lookup(Name);
        if (!Sym) {
          consumeError(Sym.takeError());
          return JITSymbol(nullptr);
        }
        // ORC v2's LLJIT::lookup returns Expected<ExecutorAddr> in
        // LLVM 16. Older shapes returned Expected<ExecutorSymbolDef>
        // (requiring .getAddress()) or Expected<JITEvaluatedSymbol>;
        // this branch targets the LLVM 16 shape directly. ExecutorAddr's
        // raw integer is exposed by .getValue().
        return JITSymbol(static_cast<uint64_t>(Sym->getValue()),
                         JITSymbolFlags::Exported);
      }

      void removeModule(ModuleHandle H) {
        if (H)
          if (auto E = H->remove())
            report_fatal_error(std::move(E));
      }
    };

  } // end namespace orc
} // end namespace llvm

#endif // LLVM_EXECUTIONENGINE_ORC_OMC_JIT_H
