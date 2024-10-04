// name: PreviousTest
// keywords: synchronous features
// status: correct

model PreviousTest
  output Integer x(start=1,fixed=true);
equation
  x = -previous(x);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end PreviousTest;


// Result:
// class PreviousTest
//   output Integer x(start = 1, fixed = true);
// equation
//   x = -previous(x);
// end PreviousTest;
// endResult
