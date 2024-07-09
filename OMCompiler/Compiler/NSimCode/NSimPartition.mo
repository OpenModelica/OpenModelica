/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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
encapsulated uniontype NSimPartition
"file:        NSimPartition.mo
 package:     NSimPartition
 description: This file contains the data types and functions for clocked partitions
              in simulation code phase.
"
public
  // self import
  import SimPartition = NSimPartition;

  // simcode imports
  import NSimStrongComponent.Block;
  import NSimVar.SimVar;

  // backend imports
  import NBPartitioning.BClock;

  // import old simcode
  import OldSimCode = SimCode;

  type SimPartitions = list<SimPartition>;

  record BASE_PARTITION
    BClock baseClock;
    list<SimPartition> subPartitions;
  end BASE_PARTITION;

  record SUB_PARTITION
    list<tuple<SimVar, Boolean /*previous*/>> vars;
    list<Block> equations;
    list<Block> removedEquations;
    BClock subClock;
    Boolean holdEvents;
  end SUB_PARTITION;

  function createSubPartition
    input BClock subClock;
    input list<Block> equations;
    output SimPartition part;
  algorithm
    part := SUB_PARTITION({}, equations, {}, subClock, false);
  end createSubPartition;

  function createBasePartitions
    input UnorderedMap<BClock, SimPartitions> clock_collector;
    output SimPartitions baseParts = {};
  protected
    BClock baseClock;
    SimPartitions subClocks;
  algorithm
    for tpl in UnorderedMap.toList(clock_collector) loop
      (baseClock, subClocks) := tpl;
      baseParts := BASE_PARTITION(baseClock, subClocks) :: baseParts;
    end for;
  end createBasePartitions;

  function listToString
    input list<SimPartition> parts;
    input output String str = "";
    input String header = "";
  protected
    String indent = str;
  algorithm
    str := if header <> "" then StringUtil.headline_3(header) else "";
    for part in parts loop
      str := str + toString(part, indent);
    end for;
  end listToString;

  function toString
    input SimPartition part;
    input output String str = "";
  algorithm
    str := match part
      case BASE_PARTITION() then "[BASE] Partition " + BClock.toString(part.baseClock) + List.toString(part.subPartitions, function toString(str = str), "", "\n", "\n", "\n");
      case SUB_PARTITION()  then "[SUB-] Partition " + BClock.toString(part.subClock) + List.toString(part.equations, function Block.toString(str = str), "", "\n", "\n", "\n");
      else "[ERR-]";
    end match;
  end toString;

  function toStringShort
    input SimPartition part;
    output String str;
  algorithm
    str := match part
      case BASE_PARTITION() then "[BASE] Partition " + BClock.toString(part.baseClock);
      case SUB_PARTITION()  then "[SUB-] Partition " + BClock.toString(part.subClock);
      else "[ERR-]";
    end match;
  end toStringShort;

  function convertBase
    input SimPartition part;
    output OldSimCode.ClockedPartition oldPart;
  algorithm
    oldPart := match part
      case BASE_PARTITION() then OldSimCode.CLOCKED_PARTITION(
        baseClock     = BClock.convertBase(part.baseClock),
        subPartitions = list(convertSub(sub) for sub in part.subPartitions));
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for non-base partition:\n" + toString(part)});
      then fail();
    end match;
  end convertBase;

  function convertSub
    input SimPartition part;
    output OldSimCode.SubPartition oldPart;
  algorithm
    oldPart := match part
      case SUB_PARTITION() then OldSimCode.SUBPARTITION(
        vars                = {},
        equations           = list(Block.convert(blck) for blck in part.equations),
        removedEquations    = list(Block.convert(blck) for blck in part.removedEquations),
        subClock            = BClock.convertSub(part.subClock),
        holdEvents          = part.holdEvents);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for non-base partition:\n" + toString(part)});
      then fail();
    end match;
  end convertSub;

  annotation(__OpenModelica_Interface="backend");
end NSimPartition;