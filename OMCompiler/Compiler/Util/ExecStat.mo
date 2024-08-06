encapsulated package ExecStat "Timing / measuring memory for different parts of the compiler"

protected

import ClockIndexes;
import Error;
import GCExt;
import Global;
import Flags;
import System;
import StringUtil;

constant String timeFormat = "%.4g"; // Why not "%.9f"?
constant Integer timeMaxLength = 20; // Why not 21?
constant Integer memoryMaxSizeInUnit = 500; // Why not 512?
constant Integer memorySignificantDigits = 4; // Why not 3?

public

function execStatReset
algorithm
  setGlobalRoot(Global.gcProfilingIndex, GCExt.getProfStats());
  System.realtimeClear(ClockIndexes.RT_CLOCK_EXECSTAT);
  System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT);
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
  function snprintff
    input Real val;
    output String str = System.snprintff(timeFormat, timeMaxLength, val);
  end snprintff;
  function bytesToReadableUnit
    input Real bytes;
    output String str = StringUtil.bytesToReadableUnit(bytes, memorySignificantDigits, memoryMaxSizeInUnit);
  end bytesToReadableUnit;
algorithm
  if Flags.isSet(Flags.EXEC_STAT) then
    for i in if Flags.isSet(Flags.EXEC_STAT_EXTRA_GC) then {1,2} else {1} loop
      if i==2 then
        GCExt.gcollect();
      end if;
      t := System.realtimeAccumulate(ClockIndexes.RT_CLOCK_EXECSTAT);
      total := System.realtimeAccumulated(ClockIndexes.RT_CLOCK_EXECSTAT);
      (stats as GCExt.PROFSTATS(bytes_allocd_since_gc=since, allocd_bytes_before_gc=before, heapsize_full=heapsize_full, free_bytes_full=free_bytes_full)) := GCExt.getProfStats();
      memory := since+before;
      oldStats := getGlobalRoot(Global.gcProfilingIndex);
      GCExt.PROFSTATS(bytes_allocd_since_gc=since, allocd_bytes_before_gc=before) := oldStats;
      oldMemory := since+before;
      timeStr := snprintff(t);
      totalTimeStr := snprintff(total);
      if Flags.isSet(Flags.GC_PROF) then
        gcStr := GCExt.profStatsStr(stats, head="", delimiter=" / ");
        Error.addMessage(Error.EXEC_STAT_GC, {name + (if i==2 then " GC" else ""), timeStr, totalTimeStr, gcStr});
      else
        Error.addMessage(Error.EXEC_STAT, {name + (if i==2 then " GC" else ""), timeStr, totalTimeStr,
            bytesToReadableUnit(memory-oldMemory),
            bytesToReadableUnit(memory),
            bytesToReadableUnit(free_bytes_full),
            bytesToReadableUnit(heapsize_full)
        });
      end if;
      setGlobalRoot(Global.gcProfilingIndex, stats);
      System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT);
    end for;
  end if;
end execStat;

annotation(__OpenModelica_Interface="util");
end ExecStat;
