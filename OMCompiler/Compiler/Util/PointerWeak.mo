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

encapsulated uniontype PointerWeak<T>
"A non-owning reference to a Pointer cell.

Breaks an ownership cycle so plain reference counting can reclaim it. The
referent must be owned somewhere else -- for `VAR_NODE.varPointer` that is
the backend's `VariablePointers`, which holds every variable.

In the bootstrapped C compiler a weak reference *is* the strong one (Boehm
reclaims cycles by tracing, so there is nothing to break) and `upgrade` can
never fail. The Rust port gives it real weak semantics, and `upgrade` fails
if the referent is already gone."

import Pointer;

impure function downgrade
  "A reference that does not keep the cell alive. Never fails."
  input Pointer<T> pointer;
  output PointerWeak<T> weak;
external "C" weak=pointerWeakDowngrade(pointer) annotation(Include="
static inline void* pointerWeakDowngrade(void *pointer)
{
  return pointer;
}
");
end downgrade;

impure function upgrade
  "An owning cell again. Fails if the referent is already gone — which means
   a weak reference outlived the structure that owned it, so the ownership
   split is wrong somewhere. Dereferencing a cell never fails; only this
   conversion does."
  input PointerWeak<T> weak;
  output Pointer<T> pointer;
external "C" pointer=pointerWeakUpgrade(weak) annotation(Include="
static inline void* pointerWeakUpgrade(void *weak)
{
  return weak;
}
");
end upgrade;

annotation(__OpenModelica_Interface="util_datatypes_basic");
end PointerWeak;
