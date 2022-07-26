// name: PureImpure2
// keywords:
// status: correct
// cflags: -d=newInst --std=3.2
//
// Checks that pure/impure are allowed in Modelica 3.2 when not using --strict.
//

pure function f1
end f1;

impure function f2
end f2;

model PureImpure2
end PureImpure2;

// Result:
// class PureImpure2
// end PureImpure2;
// endResult
