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

encapsulated uniontype PointerCyclic<T>
"A Pointer whose content may transitively contain the cell itself.

Same representation and semantics as Pointer; see MutableCyclic for why the
two are separate types. Cells that close a reference cycle must be declared
here, because the Rust port frees by reference counting and only the traced
representation this gets can be reclaimed once cyclic."

impure function create
  input T data;
  output PointerCyclic<T> ptr;
external "C" ptr=pointerCreate(data) annotation(Include="
static inline void* pointerCreate(void *data)
{
  return mmc_mk_box1(0, data);
}
");
end create;

function createImmutable
  input T data;
  output PointerCyclic<T> ptr;
external "builtin" ptr=mmc_mk_some(data);
end createImmutable;

impure function update
  input PointerCyclic<T> mutable;
  input T data;
external "C" pointerUpdate(OpenModelica.threadData(), mutable, data) annotation(Include="
static inline void pointerUpdate(threadData_t *threadData, void *ptr, void *data)
{
  if (valueConstructor(ptr)!=0) {
    MMC_THROW_INTERNAL();
  }
  MMC_STRUCTDATA(ptr)[0] = data;
}
");
end update;

impure function access
  input PointerCyclic<T> mutable;
  output T data;
external "C" data=pointerAccess(mutable) annotation(Include="
static inline void* pointerAccess(void *ptr)
{
  return MMC_STRUCTDATA(ptr)[0];
}
");
end access;

function clone
  input output PointerCyclic<T> mutable = create(access(mutable));
end clone;

function apply
  input output PointerCyclic<T> mutable;
  input Func func;
  partial function Func
    input output T value;
  end Func;
protected
  T new;
algorithm
  new := func(access(mutable));
  if not referenceEq(new, access(mutable)) then
    update(mutable, new);
  end if;
end apply;

annotation(__OpenModelica_Interface="util_datatypes_basic");
end PointerCyclic;
