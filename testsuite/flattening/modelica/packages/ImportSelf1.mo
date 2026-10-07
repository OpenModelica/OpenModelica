// name:     ImportSelf1
// keywords: import, bug1445
// status:   correct
//
// Checks that importing a package in itself works.
//

package ImportSelf1
  import P = ImportSelf1;

  function f
    output Real r = 2.0;
  end f;

  constant Real c = P.f();
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ImportSelf1;

// Result:
// function ImportSelf1.f
//   output Real r = 2.0;
// end ImportSelf1.f;
//
// class ImportSelf1
//   constant Real c = 2.0;
// end ImportSelf1;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
