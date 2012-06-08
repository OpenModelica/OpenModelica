/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC)
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�ping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package OpenTURNS "
  file:        OpenTURNS.mo
  package:     OpenTURNS
  description: Connection to OpenTURNS, software for uncertainty propagation. The connection consists of two parts
  1. Generation of python script as input to OPENTURNS
  2. Generation and compilation of wrapper that calls the standard OpenModelica simulator and retrieves the final values 
  (after simulation has stopped at endTime) 

  RCS: $Id: OpenTURNS.mo 10958 2012-01-25 01:12:35Z wbraun $
  "

public 
import BackendDAE;
import DAE;
import Absyn;

protected
import CevalScript;
import SimCode;
import Interactive;
import System;
import BackendDump;
import BackendDAEUtil;
import List;
import BackendVariable;
import ExpressionDump;
import ComponentReference;
import BackendDAEOptimize;
import Expression;
import Util;

public function generateOpenTURNSInterface "generates the dll and the python script for connections with OpenTURNS"
  input BackendDAE.BackendDAE inDaelow;
  input DAE.FunctionTree inFunctionTree;
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input DAE.DAElist inDAElist;
  input String templateFile "the filename to the template file (python script)";
  output String scriptFile "the name of the generated file";
  
  protected
  String cname_str,fileNamePrefix,fileDir;
  list<String> libs;
  BackendDAE.BackendDAE dae;  
  SimCode.SimulationSettings simSettings;
algorithm
  cname_str := Absyn.pathString(inPath);
  fileNamePrefix := cname_str;
  simSettings := CevalScript.convertSimulationOptionsToSimCode(
    CevalScript.buildSimulationOptionsFromModelExperimentAnnotation(
      Interactive.setSymbolTableAST(Interactive.emptySymboltable,inProgram),inPath,fileNamePrefix)
  );
  //print("about to generate model code\ndae:\n");
  
  // Disabled for now (problem with building...)
  //BackendDump.dump(inDaelow);
  (dae,libs,fileDir,_,_,_) := SimCode.generateModelCode(inDaelow,inProgram,inDAElist,inPath,cname_str,SOME(simSettings),Absyn.FUNCTIONARGS({},{}));
  //print("..compiling, fileNamePrefix = "+&fileNamePrefix+&"\n");  
  CevalScript.compileModel(fileNamePrefix , libs, fileDir, "", "");
  
  dae := inDaelow;
  
   //print("generating python\n");  
  scriptFile := generatePythonScript(fileNamePrefix,templateFile,cname_str,dae);
end generateOpenTURNSInterface; 

protected function generatePythonScript "generates the python script as input to OpenTURNS, given a template file name"
  input String fileNamePrefix;
  input String templateFile;
  input String modelName;
  input BackendDAE.BackendDAE inDaelow;
  output String pythonFileName;
  protected
  String templateFileContent;
  String distributions,correlationMatrix;
  String collectionDistributions,inputDescriptions;
  String pythonFileContent;
  list<tuple<String,String>> distributionVarLst;
algorithm
  print("reached\n");
  templateFileContent := System.readFile(templateFile);
  
  //generate the different parts of the python file
  (distributions,distributionVarLst) := generateDistributions(inDaelow);
  correlationMatrix := generateCorrelationMatrix(inDaelow);
  collectionDistributions := generateCollectionDistributions(inDaelow,distributionVarLst);
  inputDescriptions  := generateInputDescriptions(inDaelow);    
  //
  pythonFileName := System.stringReplace(templateFile,"template",modelName);
  
  // Replace template markers
  pythonFileContent := System.stringReplace(templateFileContent,"<%distributions%>",distributions);
  pythonFileContent := System.stringReplace(pythonFileContent,"<%correlationMatrix%>",correlationMatrix);
  pythonFileContent := System.stringReplace(pythonFileContent,"<%collectionDistributions%>",collectionDistributions);
  pythonFileContent := System.stringReplace(pythonFileContent,"<%inputDescriptions%>",inputDescriptions);  
  
  //Write file
  //print("writing python script to file "+&pythonFileName+&"\n");
  System.writeFile(pythonFileName,pythonFileContent);
    
end generatePythonScript;

protected function generateDistributions "generates distibution code for the python script.
Goes throuh all variables and collects a set of unique distributions, then generates python code.

Example of python code.
distributionE = Beta(0.93, 3.2, 2.8e7, 4.8e7)
distributionF = LogNormal(30000, 9000, 15000, LogNormal.MUSIGMA)
distributionL = Uniform(250, 260)
distributionI = Beta(2.5, 4.0, 3.1e2, 4.5e2)
LogNormal_u = LogNormal(30000, 9000, 15000, LogNormal.MUSIGMA)
Corresponding Modelica model.

model A
	parameter Distribution distributionE = Beta(0.93, 3.2, 2.8e7, 4.8e7);
	parameter Distribution distributionF = LogNormal(30000, 9000, 15000, LogNormal.MUSIGMA);
	parameter Distribution distributionL = Uniform(250, 260);
	parameter Distribution distributionI = Beta(2.5, 4.0, 3.1e2, 4.5e2);	
  Real u(distribution = LogNormal(30000, 9000, 15000, LogNormal.MUSIGMA)); // distribution name becomes <instancename>+\"_\"+<distribution name> 
end A;

"
  input BackendDAE.BackendDAE dae;
  output String distributions;
  output list<tuple<String,String>> distributionVarLst;
  
protected
  list<BackendDAE.Var> varLst;
  list<DAE.Distribution> dists;  
  list<String> sLst;
  list<tuple<String,String>> distributionVarLst;
  String header;
algorithm
  dae := BackendDAEOptimize.removeParameters(dae);
  //print("removed parameters, dae:");
  //BackendDump.dump(dae);
  
  varLst := BackendDAEUtil.getAllVarLst(dae);
  varLst := List.select(varLst,BackendVariable.varHasDistributionAttribute);
  
  dists := List.map(varLst,BackendVariable.varDistribution);
  (sLst,distributionVarLst) := List.map1_2(List.threadTuple(dists,List.map(varLst,BackendVariable.varCref)),generateDistributionVariable,dae);
  header := "# "+&intString(listLength(sLst))+&" distributions from Modelica model\n";
  distributions := stringDelimitList(header::sLst,"\n");
end generateDistributions;

protected function generateDistributionVariable " generates a distribution variable for the python script "
   input tuple<DAE.Distribution,DAE.ComponentRef> tpl;
   input BackendDAE.BackendDAE dae;
   output String str;
   output tuple<String,String> distributionVar "the name of the python variable for the distribution and the description (Modelica variable name), used later for generating the collection"; 
algorithm
  (str,distributionVar) := matchcontinue(tpl,dae)
  local 
    String name,args,varName,distVar;
    DAE.Exp arr,sarr,e1,e2,e3,e2_1,e3_1;
    DAE.ComponentRef cr;
    list<DAE.Exp> expl1,expl2;
    
    
    case((DAE.DISTRIBUTION(DAE.SCONST(name),DAE.ARRAY(array=expl1),DAE.ARRAY(array=expl2)),cr),dae) equation
      // e.g. distributionL = Beta(0.93, 3.2, 2.8e7, 4.8e7)
      // TODO:  make sure that the arguments are in correct order by looking at the expl2 list containing strings of argument names
      args = stringDelimitList(List.map(expl1,ExpressionDump.printExpStr),",");
      varName = ComponentReference.crefModelicaStr(cr);
      distVar ="distribution"+&varName; 
      str = distVar+& " = " +& name +& "("+&args+&")\n";
    then (str,(varName,distVar));
    case((DAE.DISTRIBUTION(e1,e2,e3),cr),dae) equation
      ((e2_1,_)) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
      ((e3_1,_)) = BackendDAEUtil.extendArrExp((e3,(NONE(),false)));
      false = Expression.expEqual(e2,e2_1); // Prevent infinte recursion
      false = Expression.expEqual(e3,e3_1);
      //print("extended arr="+&ExpressionDump.printExpStr(e2_1)+&"\n");
      //print("extended sarr="+&ExpressionDump.printExpStr(e3_1)+&"\n");
      (str,distributionVar) = generateDistributionVariable((DAE.DISTRIBUTION(e1,e2_1,e3_1),cr),dae);
    then (str,distributionVar);
  end matchcontinue;
end generateDistributionVariable;

protected function generateCorrelationMatrix "
"
  input BackendDAE.BackendDAE dae;
  output String correlationMatrix;
algorithm
  correlationMatrix := "TODO2\n";    

end generateCorrelationMatrix;


protected function generateCollectionDistributions "
"
  input BackendDAE.BackendDAE dae;
  input list<tuple<String,String>> distributionVarLst;
  output String collectionDistributions;
protected
  String collectionVarName;
algorithm
  collectionVarName := "collectionMarginals";
  collectionDistributions := "# Initialization of the distribution collection:\n"
  +&collectionVarName+&" = DistributionCollection()\n"
  +&stringDelimitList(List.map1(distributionVarLst,generateCollectionDistributions2,(collectionVarName,dae)),"\n");   
end generateCollectionDistributions;

protected function generateCollectionDistributions2 "help function"
  input tuple<String,String> distVarTpl;
  input tuple<String,BackendDAE.BackendDAE> tpl;
  output String str;
algorithm
  str := Util.tuple21(tpl)+& ".add(Distribution(" +& Util.tuple22(distVarTpl) +& ",\"" +&Util.tuple21(distVarTpl)+&"\"))";  
end generateCollectionDistributions2;

protected function generateInputDescriptions "
"
  input BackendDAE.BackendDAE dae;
  output String inputDescriptions;
algorithm
  inputDescriptions := "TODO4\n";   

end generateInputDescriptions;
    
end OpenTURNS;