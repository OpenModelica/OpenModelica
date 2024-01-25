// name: Comments
// keywords:
// status: correct
// cflags: -d=newInst -f
//

model Comments "Model to test comments in Flat Modelica output"
  Real x "Some variable" annotation(Evaluate = false);
  Real y "Some other variable";
equation
  x + y = 0 "Some equation" annotation(__A = true);
  x - y = 1 "Some other equation";
  annotation(version = "1.0.0");
end Comments;

// Result:
// package 'Comments'
//   model 'Comments' "Model to test comments in Flat Modelica output"
//     Real 'x' "Some variable" annotation(Evaluate = false);
//     Real 'y' "Some other variable";
//   equation
//     'x' + 'y' = 0.0 "Some equation";
//     'x' - 'y' = 1.0 "Some other equation";
//   end 'Comments';
// end 'Comments';
// endResult
