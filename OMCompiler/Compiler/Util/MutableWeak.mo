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

encapsulated uniontype MutableWeak<T>
"A non-owning reference to a Mutable cell.

Breaks an ownership cycle so plain reference counting can reclaim it: a
child holds its parent weakly, the parent owns its children, and the whole
structure hangs off one strong root. Nothing here is reclaimed by a
collector — the point is that no collector is needed.

In the bootstrapped C compiler a weak reference *is* the strong one (Boehm
reclaims cycles by tracing, so there is nothing to break) and `strong` can
never fail. The Rust port gives it real weak semantics, and `strong` fails
if the referent is already gone. Only code that can hold a weak reference
past its owner's lifetime can observe the difference."

import Mutable;

impure function downgrade
  "A reference that does not keep the cell alive. Never fails."
  input Mutable<T> mutable;
  output MutableWeak<T> weak;
external "C" weak=mutableWeakDowngrade(mutable) annotation(Include="
static inline void* mutableWeakDowngrade(void *mutable)
{
  return mutable;
}
");
end downgrade;

impure function upgrade
  "An owning cell again. Fails if the referent is already gone — which means
   a weak reference outlived the structure that owned it, so the ownership
   split is wrong somewhere. Dereferencing a cell never fails; only this
   conversion does."
  input MutableWeak<T> weak;
  output Mutable<T> mutable;
external "C" mutable=mutableWeakUpgrade(weak) annotation(Include="
static inline void* mutableWeakUpgrade(void *weak)
{
  return weak;
}
");
end upgrade;

impure function ownership
  "True where a cell needs an explicit owner to stay alive, so `InstNode`
   has to copy a record to set and clear one. False in the bootstrapped
   compiler: Boehm keeps the cell alive by tracing, and an owner there would
   only build the very cycle the collector then has to reclaim."
  output Boolean needed;
external "C" needed=mutableWeakOwnership() annotation(Include="
static inline int mutableWeakOwnership(void)
{
  return 0;
}
");
end ownership;

impure function root
  "Keeps a cell alive for the current frontend run, for a cell whose only
   other references are weak. A no-op in the bootstrapped compiler: there a
   weak reference *is* the strong one, so nothing can die early and there is
   nothing to keep."
  input Mutable<T> mutable;
external "C" mutableWeakRoot(mutable) annotation(Include="
static inline void mutableWeakRoot(void *mutable)
{
}
");
end root;

impure function clearRoots
  "Drops everything `root` is holding. A no-op in the bootstrapped compiler."
external "C" mutableWeakClearRoots() annotation(Include="
static inline void mutableWeakClearRoots(void)
{
}
");
end clearRoots;

annotation(__OpenModelica_Interface="util_datatypes_basic");
end MutableWeak;
