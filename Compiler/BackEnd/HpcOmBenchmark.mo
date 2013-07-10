/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
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
 * from Linköping University, either from the above address,
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

encapsulated package HpcOmBenchmark
" file:        HpcOmBenchmark.mo
  package:     HpcOmBenchmark
  description: HpcOmBenchmark contains the whole logic to measure the communication and processing time.

  RCS: $Id: HpcOmBenchmark.mo 15486 2013-06-10 11:12:35Z marcusw $
"

protected import HpcOmBenchmarkExt;

public function benchSystem
  output tuple<tuple<Integer,Integer>,tuple<Integer,Integer>> oTime; //required time for <op,com>
  
protected
  Integer comCostM,comCostN,opCostM,opCostN;
  list<Integer> opCosts, comCosts;
  String s1,s2;
algorithm
    opCosts := HpcOmBenchmarkExt.requiredTimeForOp();
    true := listLength(opCosts) == 2;
    opCostM := listGet(opCosts,1); //m
    opCostN := listGet(opCosts,2); //n
    s1 := intString(opCostM);
    s2 := intString(opCostN);
    //print("Test op y= " +& s1 +& " * x + " +& s2 +& "\n");
    
    comCosts := HpcOmBenchmarkExt.requiredTimeForComm();
    comCostM := listGet(comCosts,1); //m
    comCostN := listGet(comCosts,2); //n
    s1 := intString(comCostM);
    s2 := intString(comCostN);
    //print("Test comm y= " +& s1 +& " * x + " +& s2 +& "\n");
    
    oTime := ((opCostM,opCostN),(comCostM,comCostN));
end benchSystem;

end HpcOmBenchmark;