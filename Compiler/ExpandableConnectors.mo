/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package ExpandableConnectors
" file:	       ExpandableConnectors.mo
  package:     ExpandableConnectors
  description: ExpandableConnectors translates Absyn to SCode intermediate form
 
  RCS: $Id$
 
  This module contains functions to handle expandable connectors:
  
PHASE_1
  A partial instantiation (only components) from all classes appearing in
  connect(expandable, non-expandable) should be done first in their correct
  environment. This should be done without flattening of arrays or structural
  components because you need to go from an instantiated component in the environment
  back to an SCode.COMPONENT definition.
  
PHASE_2  
  The connect equations referring to expandable connectors should be collected.
  The expandable connectors should be patched with the new components from connects 
  (that connect(expandable, non-expandable))
  
PHASE_3
  The expandable connectors should be patched so that a union of all expandable connectors
  connected via connect(expandable, expandable) is achieved.
  
PHASE_4  
  The expandable connectors should be patched so that a union of all expandable connectors
  connected via inner-outer is achieved.

PHASE_5  
  Generate a new program that has the new expandable connectors."

public import SCode;
public import InstanceHierarchy;

protected import Absyn;
protected import Debug;

public function elaborateExpandableConnectors
  input SCode.Program inProgram;
  input Boolean hasExpandableConnectors "this phase is done only if this flag is true!";
  output InstanceHierarchy.InstanceHierarchy outIH;
  output SCode.Program outProgram;
algorithm
 (outIH, outProgram) := matchcontinue(inProgram, hasExpandableConnectors)
   local
     InstanceHierarchy.InstanceHierarchy ih;
     SCode.Program programWithPatchedExpandableConnectors;
     
   case (inProgram, /* false */_) 
     then (InstanceHierarchy.emptyInstanceHierarchy, inProgram);
       
   case (inProgram, true) 
     equation
        (ih, programWithPatchedExpandableConnectors) = elaborate(InstanceHierarchy.emptyInstanceHierarchy, inProgram);        
     then 
       (ih, programWithPatchedExpandableConnectors);
  end matchcontinue;
end elaborateExpandableConnectors;

protected function elaborate
  input InstanceHierarchy.InstanceHierarchy inIH;
  input SCode.Program inProgram;
  output InstanceHierarchy.InstanceHierarchy outIH;
  output SCode.Program outProgram;
algorithm
  (outIH, outProgram) := matchcontinue(inIH, inProgram)
    local 
      InstanceHierarchy.InstanceHierarchy ih;
      SCode.Program program;
      
    case (inIH, inProgram)         
      equation
        // PHASE_1
        // build the instance hierarchy
        ih = InstanceHierarchy.createInstanceHierarchyFromProgram(inIH, NONE(), inProgram); 
        Debug.fcall2("dumpIH", InstanceHierarchy.dumpInstanceHierarchy, ih, 0);
        Debug.fcall("dumpIH", print, "\n\n");        
        // PHASE_2
        // add components from connect(expandable, non-expandable)
        ih = addComponentsFromNonExpandableConnectors(ih);
        // PHASE_3
        // make union of components from connect(expandable, expandable)
        ih = makeUnionOfConnectedExpandableConnectors(ih);
        // PHASE_4
        // make union of components from inner expandable outer expandable
        ih = makeUnionOfInnerOuterExpandableConnectors(ih);
        // PHASE_5
        // replace expandable connectors in program with the new ones from IH
        (ih, program) = replaceExpandableConnectorsInProgram(ih, inProgram);
      then (ih, program);
  end matchcontinue;
end elaborate;

function addComponentsFromNonExpandableConnectors
"@author: adrpo
 add components from connect(expandable, non-expandable)"
  input InstanceHierarchy.InstanceHierarchy inIH;
  output InstanceHierarchy.InstanceHierarchy outIH;
algorithm  
  outIH := matchcontinue(inIH)
    local 
      InstanceHierarchy.InstanceHierarchy ih; 
    case inIH
      equation
        ih = inIH;
      then ih;
  end matchcontinue;
end addComponentsFromNonExpandableConnectors;

function makeUnionOfConnectedExpandableConnectors
"@author: adrpo
 make union of components from connect(expandable, expandable)"
  input InstanceHierarchy.InstanceHierarchy inIH;
  output InstanceHierarchy.InstanceHierarchy outIH;
algorithm  
  outIH := matchcontinue(inIH)
    local 
      InstanceHierarchy.InstanceHierarchy ih; 
    case inIH
      equation
        ih = inIH;
      then ih;
  end matchcontinue;
end makeUnionOfConnectedExpandableConnectors;

function makeUnionOfInnerOuterExpandableConnectors
"@author: adrpo
 make union of components from inner expandable outer expandable"
  input InstanceHierarchy.InstanceHierarchy inIH;
  output InstanceHierarchy.InstanceHierarchy outIH;
algorithm  
  outIH := matchcontinue(inIH)
    local 
      InstanceHierarchy.InstanceHierarchy ih; 
    case inIH
      equation
        ih = inIH;
      then ih;
  end matchcontinue;
end makeUnionOfInnerOuterExpandableConnectors;


function replaceExpandableConnectorsInProgram
"@author: adrpo
 replace expandable connectors in program with the ones from IH"
  input InstanceHierarchy.InstanceHierarchy inIH;
  input SCode.Program inProgram;
  output InstanceHierarchy.InstanceHierarchy outIH;
  output SCode.Program outProgram;
algorithm  
  (outIH, outProgram) := matchcontinue(inIH, inProgram)
    local 
      InstanceHierarchy.InstanceHierarchy ih;
      SCode.Program prg; 
      
    case (ih, prg)
      equation
        
      then (ih, prg);
  end matchcontinue;
end replaceExpandableConnectorsInProgram;

end ExpandableConnectors;