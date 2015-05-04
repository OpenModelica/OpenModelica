// name: BadVariabilityBug3150 [BUG: https://trac.openmodelica.org/OpenModelica/ticket/3150]
// keywords: array
// status: correct
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
// class BadVariabilityBug3150
//   parameter Integer nReg(min = 2) = 2;
//   constant Boolean hexReg[1].initialize_p1 = true;
//   constant Boolean hexReg[2].initialize_p1 = false;
// end BadVariabilityBug3150;
// endResult
