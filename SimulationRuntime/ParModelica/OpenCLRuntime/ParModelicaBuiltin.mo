

// package ParModelica

function oclGetWorkDim
  output Integer dim;
  external "builtin";
end oclGetWorkDim;

function oclGetGlobalSize
  input Integer dim;
  output Integer size;
  external "builtin";
end oclGetGlobalSize;

function oclGetGlobalId
  input Integer dim;
  output Integer id;
  external "builtin";
end oclGetGlobalId;

function oclGetLocalSize
  input Integer dim;
  output Integer size;
  external "builtin";
end oclGetLocalSize;

function oclGetLocalId
  input Integer dim;
  output Integer id;
  external "builtin";
end oclGetLocalId;

function oclGetNumGroups
  input Integer dim;
  output Integer num;
  external "builtin";
end oclGetNumGroups;

function oclGetGroupId
  input Integer dim;
  output Integer id;
  external "builtin";
end oclGetGroupId;

function oclGlobalBarrier
  external "builtin";
end oclGlobalBarrier;

function oclSetNumThreadsOnlyGlobal
  input Integer num_threads;
  external "builtin";
end oclSetNumThreadsOnlyGlobal;

function oclSetNumThreadsGlobalLocal
  input Integer global_num_threads;
  input Integer local_num_threads;
  external "builtin";
end oclSetNumThreadsGlobalLocal;

function oclSetNumThreadsGlobalLocal1D
  input Integer[1] global_num_threads;
  input Integer[1] local_num_threads;
  external "builtin";
end oclSetNumThreadsGlobalLocal1D;

function oclSetNumThreadsGlobalLocal2D
  input Integer[2] global_num_threads;
  input Integer[2] local_num_threads;
  external "builtin";
end oclSetNumThreadsGlobalLocal2D;

function oclSetNumThreadsGlobalLocal3D
  input Integer[3] global_num_threads;
  input Integer[3] local_num_threads;
  external "builtin";
end oclSetNumThreadsGlobalLocal3D;

function oclSetNumThreadsGlobalLocalError
  input Integer[:] global_num_threads;
  input Integer[:] local_num_threads;
  external "builtin";
end oclSetNumThreadsGlobalLocalError;

function oclSetNumThreads = overload(
  oclSetNumThreadsOnlyGlobal,
  oclSetNumThreadsGlobalLocal1D,
  oclSetNumThreadsGlobalLocal2D,
  oclSetNumThreadsGlobalLocal3D
  );
  
  
  
  
encapsulated package OpenCL
  
  function matrixMult
    parglobal input Integer A[:,:];
    parglobal input Integer B[:,:];
    parglobal output Integer C[:,:];
  external "builtin";
  end matrixMult;
  
  function matrixTranspose
    parglobal input Integer A[:,:];
    parglobal output Integer B[:,:];
  external "builtin";
  end matrixTranspose;
  
end OpenCL;
  
// end ParModelica;