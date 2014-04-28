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

encapsulated package HpcOmSimCode

  public import HashTableCrILst;

  public uniontype MemoryMap //stores information to organize the memory for the parallel code in an efficient way
    record MEMORYMAP_ARRAY
      array<tuple<Integer,Integer>> positionMapping; //map each simCodeVar to a memory (array) position and to arrayIdx
      Integer floatArraySize; //arrayIdx: 1
      HashTableCrILst.HashTable scVarNameIdxMapping; //maps each var-name to the scVar-idx
    end MEMORYMAP_ARRAY;
  end MemoryMap;
  
	public uniontype Task
	  record CALCTASK //Task which calculates something
	    Integer weighting;
	    Integer index;
	    Real calcTime;
	    Real timeFinished;
	    Integer threadIdx;
	    list<Integer> eqIdc;
	  end CALCTASK;
	  record CALCTASK_LEVEL
	    list<Integer> eqIdc;
	    list<Integer> nodeIdc; //indices of the graph-node
	  end CALCTASK_LEVEL;
	  record ASSIGNLOCKTASK //Task which assignes a lock
	    String lockId;
	  end ASSIGNLOCKTASK;
	  record RELEASELOCKTASK //Task which releases a lock
	    String lockId;
	  end RELEASELOCKTASK;
	  record TASKEMPTY //Dummy Task
	  end TASKEMPTY;
	end Task;
	
	public uniontype Schedule   // stores all scheduling-informations
	  record LEVELSCHEDULE
	    list<list<Task>> tasksOfLevels; //List of tasks solved in the same level in parallel
	  end LEVELSCHEDULE;
	  record THREADSCHEDULE
	    array<list<Task>> threadTasks; //List of tasks assigned to the thread <%idx%>
	    list<String> lockIdc;
	  end THREADSCHEDULE;
	  record TASKDEPSCHEDULE
	    list<tuple<Task,list<Integer>>> tasks; //topological sorted tasks with <taskIdx, parentTaskIdc>
	  end TASKDEPSCHEDULE;
	  record EMPTYSCHEDULE  // a dummy schedule. used if there is no ODE-system
	  end EMPTYSCHEDULE;
	end Schedule;

end HpcOmSimCode;