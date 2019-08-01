  module GC 


    using MetaModelica
    #= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
    using ExportAll
    #= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#

    @UniontypeDecl ProfStats

         #= /*
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
         * from the URLs: http:www.ida.liu.se/projects/OpenModelica or
         * http:www.openmodelica.org, and in the OpenModelica distribution.
         * GNU version 3 is obtained from: http:www.gnu.org/copyleft/gpl.html.
         *
         * This program is distributed WITHOUT ANY WARRANTY; without
         * even the implied warranty of  MERCHANTABILITY or FITNESS
         * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
         * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
         *
         * See the full OSMC Public License conditions for more details.
         *
         */ =#

        function gcollect()
            #= Defined in the runtime =#
        end

        function gcollectAndUnmap()
            #= Defined in the runtime =#
        end

        function enable()
            #= Defined in the runtime =#
        end

        function disable()
            #= Defined in the runtime =#
        end

        T = Any
        function free(data::T)
            #= Defined in the runtime =#
        end

        function expandHeap(sz::ModelicaReal #= To avoid the 32-bit signed limit on sizes =#)::Bool
              local success::Bool

            #= Defined in the runtime =#
          success
        end

        function setFreeSpaceDivisor(divisor::ModelicaInteger = 3)
            #= Defined in the runtime =#
        end

        function getForceUnmapOnGcollect()::Bool
              local res::Bool

            #= Defined in the runtime =#
          res
        end

        function setForceUnmapOnGcollect(forceUnmap::Bool)
            #= Defined in the runtime =#
        end

        function setMaxHeapSize(sz::ModelicaReal #= To avoid the 32-bit signed limit on sizes =#)
            #= Defined in the runtime =#
        end

          #= TODO: Support regular records in the bootstrapped compiler to avoid allocation to return the stats in the GC... =#
         @Uniontype ProfStats begin
              @Record PROFSTATS begin

                       heapsize_full::ModelicaInteger
                       free_bytes_full::ModelicaInteger
                       unmapped_bytes::ModelicaInteger
                       bytes_allocd_since_gc::ModelicaInteger
                       allocd_bytes_before_gc::ModelicaInteger
                       non_gc_bytes::ModelicaInteger
                       gc_no::ModelicaInteger
                       markers_m1::ModelicaInteger
                       bytes_reclaimed_since_gc::ModelicaInteger
                       reclaimed_bytes_before_gc::ModelicaInteger
              end
         end

        function profStatsStr(stats::ProfStats, head::String = "GC Profiling Stats: ", delimiter::String = "\n  ")::String
              local str::String

              str = begin
                @match stats begin
                  PROFSTATS()  => begin
                    head + delimiter + "heapsize_full: " + intString(stats.heapsize_full) + delimiter + "free_bytes_full: " + intString(stats.free_bytes_full) + delimiter + "unmapped_bytes: " + intString(stats.unmapped_bytes) + delimiter + "bytes_allocd_since_gc: " + intString(stats.bytes_allocd_since_gc) + delimiter + "allocd_bytes_before_gc: " + intString(stats.allocd_bytes_before_gc) + delimiter + "total_allocd_bytes: " + intString(stats.bytes_allocd_since_gc + stats.allocd_bytes_before_gc) + delimiter + "non_gc_bytes: " + intString(stats.non_gc_bytes) + delimiter + "gc_no: " + intString(stats.gc_no) + delimiter + "markers_m1: " + intString(stats.markers_m1) + delimiter + "bytes_reclaimed_since_gc: " + intString(stats.bytes_reclaimed_since_gc) + delimiter + "reclaimed_bytes_before_gc: " + intString(stats.reclaimed_bytes_before_gc)
                  end
                end
              end
          str
        end

        function getProfStats()::ProfStats
              local stats::ProfStats

              local heapsize_full::ModelicaInteger
              local free_bytes_full::ModelicaInteger
              local unmapped_bytes::ModelicaInteger
              local bytes_allocd_since_gc::ModelicaInteger
              local allocd_bytes_before_gc::ModelicaInteger
              local non_gc_bytes::ModelicaInteger
              local gc_no::ModelicaInteger
              local markers_m1::ModelicaInteger
              local bytes_reclaimed_since_gc::ModelicaInteger
              local reclaimed_bytes_before_gc::ModelicaInteger

               #= Inner, dummy function to preserve the full integer sizes =#
              function GC_get_prof_stats_modelica()::Tuple
                    local stats::Tuple

                  #= Defined in the runtime =#
                stats
              end

              (heapsize_full, free_bytes_full, unmapped_bytes, bytes_allocd_since_gc, allocd_bytes_before_gc, non_gc_bytes, gc_no, markers_m1, bytes_reclaimed_since_gc, reclaimed_bytes_before_gc) = GC_get_prof_stats_modelica()
              stats = PROFSTATS(heapsize_full, free_bytes_full, unmapped_bytes, bytes_allocd_since_gc, allocd_bytes_before_gc, non_gc_bytes, gc_no, markers_m1, bytes_reclaimed_since_gc, reclaimed_bytes_before_gc)
          stats
        end

    #= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
    @exportAll()
  end