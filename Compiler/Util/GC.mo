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

encapsulated package GC

function gcollect
external "C" GC_gcollect() annotation(Library = {"omcgc"});
end gcollect;

function gcollectAndUnmap
external "C" GC_gcollect_and_unmap() annotation(Library = {"omcgc"});
end gcollectAndUnmap;

function enable
external "C" GC_enable() annotation(Library = {"omcgc"});
end enable;

function disable
external "C" GC_disable() annotation(Library = {"omcgc"});
end disable;

function expandHeap
  input Real sz "To avoid the 32-bit signed limit on sizes";
  output Boolean success;
external "C" success=GC_expand_hp_dbl(sz) annotation(Include="#define GC_expand_hp_dbl(sz) GC_expand_hp(sz)",Library = {"omcgc"});
end expandHeap;

function setFreeSpaceDivisor
  input Integer divisor = 3;
external "C" GC_set_free_space_divisor(divisor) annotation(Include="#define GC_set_free_space_divisor_int(divisor) GC_set_free_space_divisor(divisor)",Library = {"omcgc"},Documentation(info="<html>
<p>NOTE: Do not set <3 as that seems to interfere with parallel threads.</p>
</html>"));
end setFreeSpaceDivisor;

function getForceUnmapOnGcollect
  output Boolean res;
  external "C" res=GC_get_force_unmap_on_gcollect() annotation(Library = {"omcgc"});
end getForceUnmapOnGcollect;

function setForceUnmapOnGcollect
  input Boolean forceUnmap;
  external "C" GC_set_force_unmap_on_gcollect(forceUnmap) annotation(Library = {"omcgc"});
end setForceUnmapOnGcollect;

uniontype ProfStats "TODO: Support regular records in the bootstrapped compiler to avoid allocation to return the stats in the GC..."
  record PROFSTATS
    Integer heapsize_full, free_bytes_full, unmapped_bytes, bytes_allocd_since_gc, allocd_bytes_before_gc, non_gc_bytes, gc_no, markers_m1, bytes_reclaimed_since_gc, reclaimed_bytes_before_gc;
  end PROFSTATS;
end ProfStats;

function profStatsStr
  input ProfStats stats;
  input String head = "GC Profiling Stats: ";
  input String delimiter = "\n  ";
  output String str;
algorithm
  str := match stats
    case PROFSTATS() then
      head + delimiter +
      "heapsize_full: " + intString(stats.heapsize_full) + delimiter +
      "free_bytes_full: " + intString(stats.free_bytes_full) + delimiter +
      "unmapped_bytes: " + intString(stats.unmapped_bytes) + delimiter +
      "bytes_allocd_since_gc: " + intString(stats.bytes_allocd_since_gc) + delimiter +
      "allocd_bytes_before_gc: " + intString(stats.allocd_bytes_before_gc) + delimiter +
      "total_allocd_bytes: " + intString(stats.bytes_allocd_since_gc+stats.allocd_bytes_before_gc) + delimiter +
      "non_gc_bytes: " + intString(stats.non_gc_bytes) + delimiter +
      "gc_no: " + intString(stats.gc_no) + delimiter +
      "markers_m1: " + intString(stats.markers_m1) + delimiter +
      "bytes_reclaimed_since_gc: " + intString(stats.bytes_reclaimed_since_gc) + delimiter +
      "reclaimed_bytes_before_gc: " + intString(stats.reclaimed_bytes_before_gc);
  end match;
end profStatsStr;

function getProfStats
  output ProfStats stats;
protected
  Integer heapsize_full, free_bytes_full, unmapped_bytes, bytes_allocd_since_gc, allocd_bytes_before_gc, non_gc_bytes, gc_no, markers_m1, bytes_reclaimed_since_gc, reclaimed_bytes_before_gc;
protected
  function GC_get_prof_stats_modelica "Inner, dummy function to preserve the full integer sizes"
    output tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> stats;
  external "C" stats=GC_get_prof_stats_modelica()
    annotation(Include="
static inline modelica_metatype GC_get_prof_stats_modelica()
{
#if (GC_VERSION_MAJOR == 7) && (GC_VERSION_MINOR >= 5)
  struct GC_prof_stats_s info;
  GC_get_prof_stats(&info,sizeof(struct GC_prof_stats_s));
  return mmc_mk_box10(
    0,
    mmc_mk_icon(info.heapsize_full),
    mmc_mk_icon(info.free_bytes_full),
    mmc_mk_icon(info.unmapped_bytes),
    mmc_mk_icon(info.bytes_allocd_since_gc),
    mmc_mk_icon(info.allocd_bytes_before_gc),
    mmc_mk_icon(info.non_gc_bytes),
    mmc_mk_icon(info.gc_no),
    mmc_mk_icon(info.markers_m1),
    mmc_mk_icon(info.bytes_reclaimed_since_gc),
    mmc_mk_icon(info.reclaimed_bytes_before_gc));
#else /* GC_prof_stats_s NOT available */
  return mmc_mk_box10(
    0,
    mmc_mk_icon(0),
    mmc_mk_icon(0),
    mmc_mk_icon(0),
    mmc_mk_icon(0),
    mmc_mk_icon(0),
    mmc_mk_icon(0),
    mmc_mk_icon(0),
    mmc_mk_icon(0),
    mmc_mk_icon(0),
    mmc_mk_icon(0));
#endif
}

",Library = {"omcgc"});
  end GC_get_prof_stats_modelica;
algorithm
  (heapsize_full, free_bytes_full, unmapped_bytes, bytes_allocd_since_gc, allocd_bytes_before_gc, non_gc_bytes, gc_no, markers_m1, bytes_reclaimed_since_gc, reclaimed_bytes_before_gc) := GC_get_prof_stats_modelica();
  stats := PROFSTATS(heapsize_full, free_bytes_full, unmapped_bytes, bytes_allocd_since_gc, allocd_bytes_before_gc, non_gc_bytes, gc_no, markers_m1, bytes_reclaimed_since_gc, reclaimed_bytes_before_gc);
annotation(Documentation(info="<html>
<p>Query GC profiling information.</p>
</html>"));
end getProfStats;

annotation(__OpenModelica_Interface="util");
end GC;
