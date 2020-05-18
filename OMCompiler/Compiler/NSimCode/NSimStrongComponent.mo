/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
* c/o Linköpings universitet, Department of Computer and Information Science,
* SE-58183 Linköping, Sweden.
*
* All rights reserved.
*
* THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
* THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
* ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
* RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
* ACCORDING TO RECIPIENTS CHOICE.
*
* The OpenModelica software and the Open Source Modelica
* Consortium (OSMC) Public License (OSMC-PL) are obtained
* from OSMC, either from the above address,
* from the URLs: http://www.ida.liu.se/projects/OpenModelica or
* http://www.openmodelica.org, and in the OpenModelica distribution.
* GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
*
* This program is distributed WITHOUT ANY WARRANTY; without
* even the implied warranty of  MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
* IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
*
* See the full OSMC Public License conditions for more details.
*
*/
encapsulated package NSimStrongComponent
"file:        NSimStrongComponent.mo
 package:     NSimStrongComponent
 description: This file contains the data types and functions for strong
              components in simulation code phase.
"

protected
  // OF imports
  import DAE;

  // NF imports
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Statement = NFStatement;

  // Backend imports
  import BEquation = NBEquation;

  // SimCode imports
  import NSimVar.SimVar;

public
  uniontype Block
    "A single block from BLT transformation."

    record RESIDUAL
      "Single residual equation of the form
      0 = exp"
      Integer index;
      Expression exp;
      DAE.ElementSource source;
      BEquation.EquationAttributes eqAttr;
    end RESIDUAL;

    record SIMPLE_ASSIGN
      "Simple assignment or solved inner equation of (casual) tearing set
      (Dynamic Tearing) with constraints on the solvability
      lhs := rhs"
      Integer index;
      ComponentRef lhs "left hand side of equation";
      Expression rhs;
      DAE.ElementSource source;
      // ToDo: this needs to be added for tearing later on
      //Option<BackendDAE.Constraints> constraints;
      BEquation.EquationAttributes eqAttr;
    end SIMPLE_ASSIGN;

    record ARRAY_ASSIGN
      "Array assignment where the left hand side can be an array constructor.
      {a, b, ...} := rhs"
      Integer index;
      Expression lhs;
      Expression rhs;
      DAE.ElementSource source;
      BEquation.EquationAttributes eqAttr;
    end ARRAY_ASSIGN;

    record ALIAS
      "Simple alias assignment pointing to the alias variable."
      Integer index;
      Integer aliasOf;
    end ALIAS;

    record ALGORITHM
      "An algorithm section."
      // ToDo: do we need to keep inputs/outputs here?
      Integer index;
      list<Statement> statements;
      BEquation.EquationAttributes eqAttr;
    end ALGORITHM;

    record INVERSE_ALGORITHM
      "An algorithm section that had to be inverted."
      Integer index;
      list<Statement> statements;
      list<ComponentRef> knownOutputs "this is a subset of output crefs of the original algorithm, which are already known";
      Boolean insideNonLinearSystem;
      BEquation.EquationAttributes eqAttr;
    end INVERSE_ALGORITHM;

    record IF
      "An if section."
      // ToDo: Should this even exist outside algorithms? Any if equation has to be
      // converted to an if expression, even if that means it will be residual.
      Integer index;
      BEquation.IfEquationBody body;
      DAE.ElementSource source;
      BEquation.EquationAttributes eqAttr;
    end IF;

    record WHEN
      "A when section."
      Integer index;
      Boolean initialCall "true, if top-level branch with initial()";
      BEquation.WhenEquationBody body;
      DAE.ElementSource source;
      BEquation.EquationAttributes eqAttr;
    end WHEN;

    record FOR
      "A for loop section used for non scalarized models."
      Integer index;
      Expression range;
      ComponentRef lhs;
      Expression rhs;
      DAE.ElementSource source;
      BEquation.EquationAttributes eqAttr;
    end FOR;

    record LINEAR
      "Linear algebraic loop."
      LinearSystem system;
      Option<LinearSystem> alternativeTearing;
      BEquation.EquationAttributes eqAttr;
    end LINEAR;

    record NONLINEAR
      "Nonlinear algebraic loop."
      NonlinearSystem system;
      Option<NonlinearSystem> alternativeTearing;
      BEquation.EquationAttributes eqAttr;
    end NONLINEAR;

    record HYBRID
      "Hyprid system containing both continuous and discrete equations."
      Integer index;
      Block continuous;
      list<SimVar> discreteVars;
      list<Block> discreteEqs;
      Integer indexHybridSystem;
      BEquation.EquationAttributes eqAttr;
    end HYBRID;

    // ToDo ALGEBRAIC_SYSTEM -> ask Andreas, only for OMSI?
  end Block;

  uniontype LinearSystem
    record LINEAR_SYSTEM
      Integer index;
      Boolean partOfMixed;
      Boolean tornSystem;
      list<SimVar> vars;
      list<Expression> beqs; //ToDo what is this? binding expressions?
      list<tuple<Integer, Integer, Block>> simJac; // ToDo: is this the old jacobian structure?
      /* solver linear tearing system */
      list<Block> residual;
      Option<Jacobian> jacobianMatrix;
      list<DAE.ElementSource> sources;
      Integer indexLinearSystem;
      Integer nUnknowns "Number of variables that are solved in this system. Needed because 'crefs' only contains the iteration variables.";
      Boolean partOfJac "if TRUE then this system is part of a jacobian matrix";
    end LINEAR_SYSTEM;
  end LinearSystem;

  uniontype NonlinearSystem
    record NONLINEAR_SYSTEM
      Integer index;
      list<Block> blocks;
      list<ComponentRef> crefs;
      Integer indexNonLinearSystem;
      Integer nUnknowns "Number of variables that are solved in this system. Needed because 'crefs' only contains the iteration variables.";
      Option<Jacobian> jacobianMatrix;
      Boolean homotopySupport;
      Boolean mixedSystem;
      Boolean tornSystem;
    end NONLINEAR_SYSTEM;
  end NonlinearSystem;

  uniontype Jacobian
    record JACOBIAN
      // ToDo
    end JACOBIAN;
  end Jacobian;

  annotation(__OpenModelica_Interface="backend");
end NSimStrongComponent;
