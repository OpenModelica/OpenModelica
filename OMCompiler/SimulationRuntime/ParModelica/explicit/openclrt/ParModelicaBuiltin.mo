/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */


/*

 Mahder.Gebremedhin@liu.se  2012-08-23

*/

// package ParModelica

impure parallel function oclGetWorkDim
  output Integer dim;
  external "builtin";
end oclGetWorkDim;

impure parallel function oclGetGlobalSize
  input Integer dim;
  output Integer size;
  external "builtin";
end oclGetGlobalSize;

impure parallel function oclGetGlobalId
  input Integer dim;
  output Integer id;
  external "builtin";
end oclGetGlobalId;

impure parallel function oclGetLocalSize
  input Integer dim;
  output Integer size;
  external "builtin";
end oclGetLocalSize;

impure parallel function oclGetLocalId
  input Integer dim;
  output Integer id;
  external "builtin";
end oclGetLocalId;

impure parallel function oclGetNumGroups
  input Integer dim;
  output Integer num;
  external "builtin";
end oclGetNumGroups;

impure parallel function oclGetGroupId
  input Integer dim;
  output Integer id;
  external "builtin";
end oclGetGroupId;

impure parallel function oclGlobalBarrier
  external "builtin";
end oclGlobalBarrier;

impure parallel function oclLocalBarrier
  external "builtin";
end oclLocalBarrier;

impure function oclSetNumThreadsOnlyGlobal
  input Integer num_threads;
  external "builtin";
end oclSetNumThreadsOnlyGlobal;

impure function oclSetNumThreadsGlobalLocal
  input Integer global_num_threads;
  input Integer local_num_threads;
  external "builtin";
end oclSetNumThreadsGlobalLocal;

impure function oclSetNumThreadsGlobalLocal1D
  input Integer[1] global_num_threads;
  input Integer[1] local_num_threads;
  external "builtin";
end oclSetNumThreadsGlobalLocal1D;

impure function oclSetNumThreadsGlobalLocal2D
  input Integer[2] global_num_threads;
  input Integer[2] local_num_threads;
  external "builtin";
end oclSetNumThreadsGlobalLocal2D;

impure function oclSetNumThreadsGlobalLocal3D
  input Integer[3] global_num_threads;
  input Integer[3] local_num_threads;
  external "builtin";
end oclSetNumThreadsGlobalLocal3D;

impure function oclSetNumThreadsGlobalLocalError
  input Integer[:] global_num_threads;
  input Integer[:] local_num_threads;
  external "builtin";
end oclSetNumThreadsGlobalLocalError;

impure function oclSetNumThreads = $overload(
  oclSetNumThreadsOnlyGlobal,
  oclSetNumThreadsGlobalLocal,
  oclSetNumThreadsGlobalLocal1D,
  oclSetNumThreadsGlobalLocal2D,
  oclSetNumThreadsGlobalLocal3D
  );




encapsulated package OpenCL

  impure function matrixMult
    parglobal input Integer A[:,:];
    parglobal input Integer B[:,:];
    parglobal output Integer C[:,:];
    external "builtin";
  end matrixMult;

  impure function matrixTranspose
    parglobal input Integer A[:,:];
    parglobal output Integer B[:,:];
    external "builtin";
  end matrixTranspose;

end OpenCL;

// end ParModelica;
