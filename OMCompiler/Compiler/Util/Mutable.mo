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

encapsulated uniontype Mutable<T>
"Creating mutable (shared) objects

This uniontype contains routines for creating and updating objects,
similar to array<> structures."

impure function create
  input T data;
  output Mutable<T> mutable;
external "C" mutable=mutableCreate(data) annotation(Include="
static inline void* mutableCreate(void *data)
{
  return mmc_mk_box1(0, data);
}
");
end create;

impure function update
  input Mutable<T> mutable;
  input T data;
external "C" mutableUpdate(mutable, data) annotation(Include="
static inline void mutableUpdate(void *mutable, void *data)
{
  MMC_STRUCTDATA(mutable)[0] = data;
}
");
end update;

impure function access
  input Mutable<T> mutable;
  output T data;
external "C" data=mutableAccess(mutable) annotation(Include="
static inline void* mutableAccess(void *mutable)
{
  return MMC_STRUCTDATA(mutable)[0];
}
");
end access;

annotation(__OpenModelica_Interface="util");
end Mutable;
