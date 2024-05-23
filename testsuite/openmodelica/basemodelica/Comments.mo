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
  annotation(version = "1.0.0", experiment(StopTime = 1.0));
end Comments;

// Result:
// //! base 0.1.0
// package 'Comments'
//   model 'Comments' "Model to test comments in Flat Modelica output"
//     Real 'x' "Some variable" annotation(Evaluate = false);
//     Real 'y' "Some other variable";
//   equation
//     'x' + 'y' = 0.0 "Some equation";
//     'x' - 'y' = 1.0 "Some other equation";
//     annotation(experiment(StopTime = 1.0));
//   end 'Comments';
// end 'Comments';
// endResult
