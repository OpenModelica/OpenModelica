encapsulated package ExecStat "Timing / measuring memory for different parts of the compiler"

protected

import ClockIndexes;
import Error;
import GCExt;
import Global;
import Flags;
import System;
import StringUtil;

public

function execStatReset
algorithm
  System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT);
  System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT_CUMULATIVE);
  setGlobalRoot(Global.gcProfilingIndex, GCExt.getProfStats());
end execStatReset;

function execStat
  "Prints an execution stat on the format:
  *** %name% -> time: %time%, memory %memory%
  Where you provide name, and time is the time since the last call using this
  index (the clock is reset after each call). The memory is the total memory
  consumed by the compiler at this point in time.
  "
  input String name;
protected
  Real t, total;
  String timeStr, totalTimeStr, gcStr;
  Integer memory, oldMemory, heapsize_full, free_bytes_full, since, before;
  GCExt.ProfStats stats, oldStats;
algorithm
  if Flags.isSet(Flags.EXEC_STAT) then
    for i in if Flags.isSet(Flags.EXEC_STAT_EXTRA_GC) then {1,2} else {1} loop
      if i==2 then
        GCExt.gcollect();
      end if;
      (stats as GCExt.PROFSTATS(bytes_allocd_since_gc=since, allocd_bytes_before_gc=before, heapsize_full=heapsize_full, free_bytes_full=free_bytes_full)) := GCExt.getProfStats();
      memory := since+before;
      oldStats := getGlobalRoot(Global.gcProfilingIndex);
      GCExt.PROFSTATS(bytes_allocd_since_gc=since, allocd_bytes_before_gc=before) := oldStats;
      oldMemory := since+before;
      t := System.realtimeTock(ClockIndexes.RT_CLOCK_EXECSTAT);
      total := System.realtimeTock(ClockIndexes.RT_CLOCK_EXECSTAT_CUMULATIVE);
      timeStr := System.snprintff("%.4g", 20, t);
      totalTimeStr := System.snprintff("%.4g", 20, total);
      if Flags.isSet(Flags.GC_PROF) then
        gcStr := GCExt.profStatsStr(stats, head="", delimiter=" / ");
        Error.addMessage(Error.EXEC_STAT_GC, {name + (if i==2 then " GC" else ""), timeStr, totalTimeStr, gcStr});
      else
        Error.addMessage(Error.EXEC_STAT, {name + (if i==2 then " GC" else ""), timeStr, totalTimeStr,
            StringUtil.bytesToReadableUnit(memory-oldMemory, maxSizeInUnit=500, significantDigits=4),
            StringUtil.bytesToReadableUnit(memory, maxSizeInUnit=500, significantDigits=4),
            StringUtil.bytesToReadableUnit(free_bytes_full, maxSizeInUnit=500, significantDigits=4),
            StringUtil.bytesToReadableUnit(heapsize_full, maxSizeInUnit=500, significantDigits=4)
        });
      end if;
      System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT);
      setGlobalRoot(Global.gcProfilingIndex, stats);
    end for;
  end if;
end execStat;

annotation(__OpenModelica_Interface="util");
end ExecStat;
