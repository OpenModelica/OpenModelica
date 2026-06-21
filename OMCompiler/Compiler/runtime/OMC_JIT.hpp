// University of Illinois/NCSA
// Open Source License

// Copyright (c) 2003-2010 University of Illinois at Urbana-Champaign.
// All rights reserved.

// Developed by:

//     LLVM Team

//     University of Illinois at Urbana-Champaign

//     http://llvm.org

// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal with
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:

//     * Redistributions of source code must retain the above copyright notice,
//       this list of conditions and the following disclaimers.

//     * Redistributions in binary form must reproduce the above copyright notice,
//       this list of conditions and the following disclaimers in the
//       documentation and/or other materials provided with the distribution.

//     * Neither the names of the LLVM Team, University of Illinois at
//       Urbana-Champaign, nor the names of its contributors may be used to
//       endorse or promote products derived from this Software without specific
//       prior written permission.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH THE
// SOFTWARE.


/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


#ifndef LLVM_EXECUTIONENGINE_ORC_OMC_JIT_H
#define LLVM_EXECUTIONENGINE_ORC_OMC_JIT_H

#include "llvm/ADT/STLExtras.h"
#include "llvm/ExecutionEngine/ExecutionEngine.h"
#include "llvm/ExecutionEngine/JITSymbol.h"
#include "llvm/ExecutionEngine/RTDyldMemoryManager.h"
#include "llvm/ExecutionEngine/SectionMemoryManager.h"
#include "llvm/ExecutionEngine/Orc/CompileUtils.h"
#include "llvm/ExecutionEngine/Orc/IRCompileLayer.h"
#include "llvm/ExecutionEngine/Orc/LambdaResolver.h"
#include "llvm/ExecutionEngine/Orc/RTDyldObjectLinkingLayer.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Mangler.h"
#include "llvm/Support/DynamicLibrary.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetMachine.h"
#include <algorithm>
#include <memory>
#include <string>
#include <vector>

namespace llvm {
  namespace orc {

    class OMC_JIT {
    private:
      std::unique_ptr<TargetMachine> TM;
      DataLayout DL;
      RTDyldObjectLinkingLayer ObjectLayer;
      IRCompileLayer<decltype(ObjectLayer), SimpleCompiler> CompileLayer;

    public:
      using ModuleHandle = decltype(CompileLayer)::ModuleHandleT;

      OMC_JIT()
   	:
        TM{EngineBuilder().selectTarget()}
        , DL{TM->createDataLayout()}
        ,ObjectLayer{[]() { return std::make_shared<SectionMemoryManager>(); }}
        ,CompileLayer{ObjectLayer, SimpleCompiler(*TM)}
      {
        /* Load host process */
        llvm::sys::DynamicLibrary::LoadLibraryPermanently(nullptr);
      }

      TargetMachine &getTargetMachine() { return *TM; }

      ModuleHandle addModule(std::unique_ptr<Module> M) {

        auto Resolver = createLambdaResolver(
                                             [&](const std::string &Name) {
                                               if (auto Sym = CompileLayer.findSymbol(Name, false))
                                                 return Sym;
                                               return JITSymbol(nullptr);
                                             },
                                             [](const std::string &Name) {
                                               /*We first search the JIT runtime (This have to be kept separate from the simulation runtime for now.)*/
                                               auto SymAddr = RTDyldMemoryManager::getSymbolAddressInProcess(Name+"_jit");
                                               if (SymAddr) {
                                                 return JITSymbol(SymAddr, JITSymbolFlags::Exported);
                                               } else {
                                                 /*Ugly workaround...*/
                                                 SymAddr = RTDyldMemoryManager::getSymbolAddressInProcess(Name);
                                                 if (SymAddr) {
                                                   return JITSymbol(SymAddr, JITSymbolFlags::Exported);
                                                 }
                                               }
                                               return JITSymbol(nullptr);
                                             });
        return cantFail(CompileLayer.addModule(std::move(M),
                                               std::move(Resolver)));
      }

      JITSymbol findSymbol(const std::string Name) {
        std::string MangledName;
        raw_string_ostream MangledNameStream(MangledName);
        Mangler::getNameWithPrefix(MangledNameStream, Name, DL);
	JITSymbol jSym = CompileLayer.findSymbol(MangledNameStream.str(), true);
	return jSym;
      }

      void removeModule(ModuleHandle H) {
        cantFail(CompileLayer.removeModule(H));
      }
    };
  } // end namespace orc
} // end namespace llvm
#endif // LLVM_EXECUTIONENGINE_ORC_OMC_JIT_
