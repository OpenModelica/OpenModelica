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
end ImportSelf1;

model UseImportSelf1
  constant Real c = ImportSelf1.c;
end UseImportSelf1;

// Result:
// class UseImportSelf1
//   constant Real c = 2.0;
// end UseImportSelf1;
// endResult
