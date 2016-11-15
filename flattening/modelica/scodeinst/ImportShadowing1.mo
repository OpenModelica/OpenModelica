// name:     ImportShadowing1
// keywords: import shadowing
// status:   correct
// cflags:   -d=newInst
//
// Checks that a warning is displayed when imports are shadowed.
//

package P
  model M
    Real x;
  end M;
end P;

model ImportShadowing1
  import P.M;
  Real M;
end ImportShadowing1;

// Result:
// class ImportShadowing1
//   Real M;
// end ImportShadowing1;
// [flattening/modelica/scodeinst/ImportShadowing1.mo:17:3-17:9:writable] Notification: From here:
// [flattening/modelica/scodeinst/ImportShadowing1.mo:16:3-16:13:writable] Warning: Import P.M is shadowed by a local element.
//
// endResult
