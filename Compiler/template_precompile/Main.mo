/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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
 * from Link�pings University, either from the above address,
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

package Main
"
  file:        Main.mo
  package:     Precompile
  description: Precompiles templates for faster code generation

  RCS: $Id: Error.mo 3863 2009-02-13 18:56:21Z sjoelund.se $
  "

import Templates;

function main
  input list<String> arg;
protected
  list<Templates.CompiledTemplateSet> cTemplates;
algorithm
  /* Use print instead of the template engine because TemplCG.PrintTemplateTreeSequence
   * has already been written. That function shouldn't use the template engine because
   * it is used as debug print for the engine itself (and could cause infinite loops
   * if something goes wrong).
   */
   
  print("/*
 * Auto-generated file containing pre-compiled templates for
 * fast code generation. Do not edit manually.
 */
  
package CompiledTemplates

import TemplCG;

record CompiledTemplateSet
  String name;
  TemplCG.TemplateTreeSequence generateFunctions;
  TemplCG.TemplateTreeSequence generateFunctionBodies;
end CompiledTemplateSet;

uniontype TemplateType
  record GEN_FUNCTIONS end GEN_FUNCTIONS;
  record GEN_BODIES end GEN_BODIES;
end TemplateType;

public function getTemplateFromSet
  input CompiledTemplateSet set;
  input TemplateType ty;
  output TemplCG.TemplateTreeSequence out;
algorithm
  out := matchcontinue (set,ty)
    local
      TemplCG.TemplateTreeSequence out;
    case (CompiledTemplateSet(generateFunctions = out), GEN_FUNCTIONS()) then out;
    case (CompiledTemplateSet(generateFunctionBodies = out), GEN_BODIES()) then out;
  end matchcontinue;
end getTemplateFromSet;

constant list<CompiledTemplateSet> availableTemplates = {\n");
  cTemplates := Templates.CompileTemplateSets(Templates.templateList);
  Templates.PrintCompiledTemplates(cTemplates);
  print("};\n");
  print("end CompiledTemplates;\n");
end main;

end Main;

