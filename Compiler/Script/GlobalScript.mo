/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

encapsulated package GlobalScript
" file:        GlobalScript.mo
  package:     GlobalScript
  description: Types and constants for scripting modules

"

public import Absyn;
public import DAE;
public import FCore;
public import SCode;
public import Values;

public
uniontype SimulationOptions "these are the simulation/buildModel* options"
  record SIMULATION_OPTIONS "simulation/buildModel* options"
    DAE.Exp startTime "start time, default 0.0";
    DAE.Exp stopTime "stop time, default 1.0";
    DAE.Exp numberOfIntervals "number of intervals, default 500";
    DAE.Exp stepSize "stepSize, default (stopTime-startTime)/numberOfIntervals";
    DAE.Exp tolerance "tolerance, default 1e-6";
    DAE.Exp method "method, default 'dassl'";
    DAE.Exp fileNamePrefix "file name prefix, default ''";
    DAE.Exp options "options, default ''";
    DAE.Exp outputFormat "output format, default 'plt'";
    DAE.Exp variableFilter "variable filter, regex does whole string matching, i.e. it becomes ^.*$ in the runtime";
    DAE.Exp cflags "Compiler flags, in addition to MODELICAUSERCFLAGS";
    DAE.Exp simflags "Flags sent to the simulation executable (doesn't do anything for buildModel)";
  end SIMULATION_OPTIONS;
end SimulationOptions;

public
uniontype CompiledCFunction
  record CFunction
    Absyn.Path path;
    DAE.Type retType;
    Integer funcHandle;
    Real buildTime "the build time for this function";
    String loadedFromFile "the file we loaded this function from";
  end CFunction;
end CompiledCFunction;

public
uniontype Statement
"An Statement given in the interactive environment can either be
 an Algorithm statement or an expression.
 - GlobalScript.Statement"
  record IALG
    Absyn.AlgorithmItem algItem;
  end IALG;

  record IEXP
    Absyn.Exp exp;
    SourceInfo info;
  end IEXP;

end Statement;

public
uniontype Statements
  "Several interactive statements are used in Modelica scripts.
  - GlobalScript.Statements"
  record ISTMTS
    list<Statement> interactiveStmtLst "interactiveStmtLst" ;
    Boolean semicolon "semicolon; true = statement ending with a semicolon. The result will not be shown in the interactive environment." ;
  end ISTMTS;

end Statements;

public
uniontype InstantiatedClass "- Instantiated Class"
  record INSTCLASS
    Absyn.Path qualName "qualName ;  The F.Q.name of the inst:ed class" ;
    DAE.DAElist daeElementLst "daeElementLst ; The list of DAE elements" ;
    FCore.Graph env "env ; The env of the inst:ed class" ;
  end INSTCLASS;

end InstantiatedClass;

public
uniontype Variable "- GlobalScript.Variable"
  record IVAR
    Absyn.Ident varIdent "The variable identifier" ;
    Values.Value value "The value" ;
    DAE.Type type_ "The type of the expression" ;
  end IVAR;

end Variable;

public
uniontype LoadedFile
  "@author adrpo
   A file entry holder, needed to cache the file information
   so files are not loaded if not really necessary"
  record FILE
    String                  fileName            "The path of the file";
    Real                    loadTime            "The time the file was loaded";
    list<Absyn.Path>        classNamesQualified "The names of the classes from the file";
  end FILE;
end LoadedFile;

public
uniontype SymbolTable "- Interactive Symbol Table"
  record SYMBOLTABLE
    Absyn.Program ast "ast ; The ast" ;
    Option<SCode.Program> explodedAst "the explodedAst is invalidated every time the program is updated";
    list<InstantiatedClass> instClsLst "List of instantiated classes" ;
    list<Variable> lstVarVal "List of variables with values" ;
    list<CompiledCFunction> compiledFunctions "List of compiled functions, F.Q name + type + functionhandler" ;
    list<LoadedFile> loadedFiles "The list of the loaded files with their load time." ;
  end SYMBOLTABLE;

end SymbolTable;

public
uniontype Component "- a component in a class
  this is used in extracting all the components in all the classes"
  record COMPONENTITEM
    Absyn.Path the1 "the class where the component is" ;
    Absyn.Path the2 "the type of the component" ;
    Absyn.ComponentRef the3 "the name of the component" ;
  end COMPONENTITEM;

  record EXTENDSITEM
    Absyn.Path the1 "the class which is extended" ;
    Absyn.Path the2 "the class which is the extension" ;
  end EXTENDSITEM;

end Component;

public
uniontype Components
  record COMPONENTS
    list<Component> componentLst;
    Integer the "the number of components in list. used to optimize the get_dependency_on_class" ;
  end COMPONENTS;

end Components;

public
uniontype ComponentReplacement
  record COMPONENTREPLACEMENT
    Absyn.Path which1 "which class contain the old cref" ;
    Absyn.ComponentRef the2 "the old cref" ;
    Absyn.ComponentRef the3 "the new cref" ;
  end COMPONENTREPLACEMENT;

end ComponentReplacement;

public
uniontype ComponentReplacementRules
  record COMPONENTREPLACEMENTRULES
    list<ComponentReplacement> componentReplacementLst;
    Integer the "the number of rules" ;
  end COMPONENTREPLACEMENTRULES;

end ComponentReplacementRules;

public constant SymbolTable emptySymboltable =
     SYMBOLTABLE(Absyn.PROGRAM({},Absyn.TOP()),
                 NONE(),
                 {},
                 {},
                 {},
                 {}) "Empty Interactive Symbol Table" ;

annotation(__OpenModelica_Interface="frontend");
end GlobalScript;
