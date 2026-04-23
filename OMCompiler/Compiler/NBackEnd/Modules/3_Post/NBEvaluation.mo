/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NBEvaluation
"file:        NBEvaluation.mo
 package:     NBEvaluation
 description: This file contains the functions to create and analyze the
              evaluation dependency graph.
              This graph is used for the different evaluation stages.
"

public
  import BackendDAE = NBackendDAE;
  import Module = NBModule;
  import Partition = NBPartition.Partition;
  import StrongComponent = NBStrongComponent;

protected
  // Old Backend imports
  import OldBackendDAE = BackendDAE;

public
  uniontype Stages
    record STAGES
      Boolean dynamicEval;
      Boolean algebraicEval;
      Boolean zerocrossEval;
      Boolean discreteEval;
    end STAGES;

    function convert
      input Stages stages;
      output OldBackendDAE.EvaluationStages oldEvalStages;
    algorithm
      oldEvalStages := OldBackendDAE.EVALUATION_STAGES(
        dynamicEval   = stages.dynamicEval,
        algebraicEval = stages.algebraicEval,
        zerocrossEval = stages.zerocrossEval,
        discreteEval  = stages.discreteEval);
    end convert;
  end Stages;

  constant Stages DEFAULT_STAGES = STAGES(true, true, false, true);

  function removeDummies
    "removes the dummy components in a partition
    Note: will be expanded into removeConstantComponents()"
    input output BackendDAE bdae;
  algorithm
    bdae := match bdae
      case BackendDAE.MAIN() algorithm
        bdae.ode        := list(removeDummyComponents(p) for p in bdae.ode);
        bdae.algebraic  := list(removeDummyComponents(p) for p in bdae.algebraic);
        bdae.ode_event  := list(removeDummyComponents(p) for p in bdae.ode_event);
        bdae.alg_event  := list(removeDummyComponents(p) for p in bdae.alg_event);
      then bdae;
      else bdae;
    end match;
  end removeDummies;

  function removeDummyComponents
    input output Partition part;
  algorithm
    part.strongComponents := Util.applyOption(part.strongComponents, function Array.filter(fun = StrongComponent.isDummy));
  end removeDummyComponents;

  annotation(__OpenModelica_Interface="backend");
end NBEvaluation;
