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

public import BackendDAE;

protected import BackendDAEOptimize;
protected import HpcOmBenchmarkExt;

public function timeForCalculation
" author: marcusw
  date: 2013-06-10
  Estimates the time (in ms) which is needed to calculate the given component.
"
  input BackendDAE.StrongComponent icomponent;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output Integer processingTime;
  
protected
  Integer op1,op2;
  Integer mulCost, addCost;
  
algorithm
    ((op1,op2,_)) := BackendDAEOptimize.countOperationstraverseComps({icomponent},isyst,ishared,(0,0,0));
    mulCost := HpcOmBenchmarkExt.requiredTimeForMult();
    addCost := HpcOmBenchmarkExt.requiredTimeForAdd();
    processingTime := addCost * op1 + mulCost * op2;
end timeForCalculation;

end HpcOmBenchmark;