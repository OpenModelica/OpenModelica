// name: ExternalFunctionExtends
// status: correct

class ExternalFunctionExtends
  function f1
    input Real r1;
    output Real o1;
  external;
  end f1;
  function f2
    extends f1;
  algorithm
    o1 := r1;
  end f2;
  constant Real r = f2(1.0);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ExternalFunctionExtends;

// Result:
// function ExternalFunctionExtends.f2
//   input Real r1;
//   output Real o1;
// algorithm
//   o1 := r1;
// end ExternalFunctionExtends.f2;
//
// class ExternalFunctionExtends
//   constant Real r = 1.0;
// end ExternalFunctionExtends;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [flattening/modelica/external-functions/ExternalFunctionExtends.mo:11:5-11:15:writable] Warning: Ignoring external declaration of the extended class: f1.
//
// endResult
