// name: OperatorOverloadConstructor2
// keywords: operator overload constructor
// status: correct
//
//

package Gas
  constant Definition O2 = Definition(0);
end Gas;

operator record Definition
  Real x;

  encapsulated operator 'constructor'
    function fromDataRecord
      input .SolutionState state;
      output .Definition result(x = state.T);
    end fromDataRecord;

    function fromFormationEnergies
      input Real MM = 1;
      input Real z = 0;
      output .Definition result(x = MM + z);
    end fromFormationEnergies;
  end 'constructor';
end Definition;

operator record SolutionState
  Real T;

  encapsulated operator 'constructor'
    import SolutionState;

    function fromValues
      input Real T = 298.15;
      output SolutionState result(T = T);
    end fromValues;
  end 'constructor';
end SolutionState;

function electroChemicalPotentialPure
  input Definition definition;
  input SolutionState solution;
  output Real electroChemicalPotentialPure;
algorithm
  electroChemicalPotentialPure := 1;
end electroChemicalPotentialPure;

model OperatorOverloadConstructor2
  SolutionState heatingSolution = SolutionState(T = 273.15 + 1*time);
  Real uO2 = electroChemicalPotentialPure(Gas.O2, heatingSolution);
end OperatorOverloadConstructor2;

// Result:
// function Definition "Automatically generated record constructor for Definition"
//   input Real x;
//   output Definition res;
// end Definition;
//
// function Definition.'constructor'.fromDataRecord
//   input SolutionState state;
//   output Definition result;
// end Definition.'constructor'.fromDataRecord;
//
// function Definition.'constructor'.fromFormationEnergies
//   input Real MM = 1.0;
//   input Real z = 0.0;
//   output Definition result;
// end Definition.'constructor'.fromFormationEnergies;
//
// function SolutionState "Automatically generated record constructor for SolutionState"
//   input Real T;
//   output SolutionState res;
// end SolutionState;
//
// function SolutionState.'constructor'.fromValues
//   input Real T = 298.15;
//   output SolutionState result;
// end SolutionState.'constructor'.fromValues;
//
// function electroChemicalPotentialPure
//   input Definition definition;
//   input SolutionState solution;
//   output Real electroChemicalPotentialPure;
// algorithm
//   electroChemicalPotentialPure := 1.0;
// end electroChemicalPotentialPure;
//
// class OperatorOverloadConstructor2
//   Real heatingSolution.T;
//   Real uO2 = electroChemicalPotentialPure(Definition(0.0), heatingSolution);
// equation
//   heatingSolution = SolutionState.'constructor'.fromValues(273.15 + time);
// end OperatorOverloadConstructor2;
// endResult
