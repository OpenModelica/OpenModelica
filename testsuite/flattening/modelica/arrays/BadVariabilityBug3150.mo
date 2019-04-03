// name: BadVariabilityBug3150 [BUG: https://trac.openmodelica.org/OpenModelica/ticket/3150]
// keywords: array
// status: incorrect
//
// Testing the array reduction constant-ness calculation
//

model BadVariabilityBug3150

  package Medium
    constant Boolean singleState = false;
  end Medium;

  parameter Integer nReg(min = 2) = 2;

  model CoilRegister  "Register for a heat exchanger"
    constant Boolean initialize_p1 = not Medium.singleState;
  end CoilRegister;

  CoilRegister[nReg] hexReg(initialize_p1 = array(i == 1 and not Medium.singleState for i in 1:nReg));
end BadVariabilityBug3150;


// Result:
// Error processing file: BadVariabilityBug3150.mo
// [flattening/modelica/arrays/BadVariabilityBug3150.mo:20:29-20:101:writable] Error: Component hexReg[2].initialize_p1 of variability CONST has binding false of higher variability PARAM.
// Error: Error occurred while flattening model BadVariabilityBug3150
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
