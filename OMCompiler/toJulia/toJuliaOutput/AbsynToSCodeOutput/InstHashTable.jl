  module InstHashTable


    using MetaModelica
    #= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
    using ExportAll
    #= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#

    @UniontypeDecl CachedInstItem
    FuncHashKey = Function
    FuncKeyEqual = Function
    FuncKeyStr = Function
    FuncValueStr = Function

         #= /*
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
        import Connect
        import ConnectionGraph
        import ClassInf
        import DAE
        import FCore
        import InstTypes
        import Prefix
        import SCode

        import Flags
        import Global
        import OperatorOverloading

        Key = Absyn.Path
        Value = CachedInstItems
        CachedInstItemInputs = Tuple
        CachedInstItemOutputs = Tuple
        CachedPartialInstItemInputs = Tuple
        CachedPartialInstItemOutputs = Tuple
        CachedInstItems = IList

        function init()
              local ht::HashTable

               #= /* adrpo: reuse it if is already there! */ =#
              try
                ht = getGlobalRoot(Global.instHashIndex)
                ht = BaseHashTable.clear(ht)
                setGlobalRoot(Global.instHashIndex, ht)
              catch
                setGlobalRoot(Global.instHashIndex, emptyInstHashTable())
              end
        end

        function release()
              setGlobalRoot(Global.instHashIndex, emptyInstHashTable())
              OperatorOverloading.initCache()
        end

        function get(k::Key)::Value
              local v::Value

              local ht::HashTable

              ht = getGlobalRoot(Global.instHashIndex)
              v = BaseHashTable.get(k, ht)
          v
        end

         @Uniontype CachedInstItem begin
               #=  *important* inputs/outputs for instClassIn
               =#

              @Record FUNC_instClassIn begin

                       inputs::CachedInstItemInputs
                       outputs::CachedInstItemOutputs
              end

               #=  *important* inputs/outputs for partialInstClassIn
               =#

              @Record FUNC_partialInstClassIn begin

                       inputs::CachedPartialInstItemInputs
                       outputs::CachedPartialInstItemOutputs
              end
         end

        function addToInstCache(fullEnvPathPlusClass::Absyn.Path, fullInstOpt::Option, partialInstOpt::Option)
              _ = begin
                  local fullInst::CachedInstItem
                  local partialInst::CachedInstItem
                  local instHash::HashTable
                  local opt::Option
                  local lst::IList
                   #=  nothing is we have -d=noCache
                   =#
                @matchcontinue (fullEnvPathPlusClass, fullInstOpt, partialInstOpt) begin
                  (_, _, _)  => begin
                      @match false = Flags.isSet(Flags.CACHE)
                    ()
                  end

                  (_, SOME(_), SOME(_))  => begin
                      instHash = getGlobalRoot(Global.instHashIndex)
                      instHash = BaseHashTable.add((fullEnvPathPlusClass, list(fullInstOpt, partialInstOpt)), instHash)
                      setGlobalRoot(Global.instHashIndex, instHash)
                    ()
                  end

                  (_, NONE(), SOME(_))  => begin
                      instHash = getGlobalRoot(Global.instHashIndex)
                      @match list(opt, _) = BaseHashTable.get(fullEnvPathPlusClass, instHash)
                      instHash = BaseHashTable.add((fullEnvPathPlusClass, list(opt, partialInstOpt)), instHash)
                      setGlobalRoot(Global.instHashIndex, instHash)
                    ()
                  end

                  (_, NONE(), SOME(_))  => begin
                      instHash = getGlobalRoot(Global.instHashIndex)
                      instHash = BaseHashTable.add((fullEnvPathPlusClass, list(NONE(), partialInstOpt)), instHash)
                      setGlobalRoot(Global.instHashIndex, instHash)
                    ()
                  end

                  (_, SOME(_), NONE())  => begin
                      instHash = getGlobalRoot(Global.instHashIndex)
                      @match _ <| (@match list(SOME(_)) = lst) = BaseHashTable.get(fullEnvPathPlusClass, instHash)
                      instHash = BaseHashTable.add((fullEnvPathPlusClass, fullInstOpt <| lst), instHash)
                      setGlobalRoot(Global.instHashIndex, instHash)
                    ()
                  end

                  (_, SOME(_), NONE())  => begin
                      instHash = getGlobalRoot(Global.instHashIndex)
                      instHash = BaseHashTable.add((fullEnvPathPlusClass, list(fullInstOpt, NONE())), instHash)
                      setGlobalRoot(Global.instHashIndex, instHash)
                    ()
                  end

                  _  => begin
                      ()
                  end
                end
              end
               #=  we have them both
               =#
               #=  we have a partial inst result and the full in the cache
               =#
               #=  see if we have a full inst here
               =#
               #=  we have a partial inst result and the full is NOT in the cache
               =#
               #=  see if we have a full inst here
               =#
               #=  failed above {SOME(fullInst),_} = get(fullEnvPathPlusClass, instHash);
               =#
               #=  we have a full inst result and the partial in the cache
               =#
               #=  see if we have a partial inst here
               =#
               #=  we have a full inst result and the partial is NOT in the cache
               =#
               #=  see if we have a partial inst here
               =#
               #=  failed above {_,SOME(partialInst)} = get(fullEnvPathPlusClass, instHash);
               =#
               #=  we failed above??!!
               =#
        end

        HashTableKeyFunctionsType = Tuple

        HashTable = Tuple









         #= Don't actually print what is stored in the value... It's too damn long. =#
        function opaqVal(v::Value)::String
              local str::String

              str = "OPAQUE_VALUE"
          str
        end

         #= Returns an empty HashTable. =#
        function emptyInstHashTable()::HashTable
              local hashTable::HashTable

              hashTable = emptyInstHashTableSized(Flags.getConfigInt(Flags.INST_CACHE_SIZE))
              OperatorOverloading.initCache()
          hashTable
        end

         #= Returns an empty HashTable, using the given bucket size. =#
        function emptyInstHashTableSized(size::ModelicaInteger)::HashTable
              local hashTable::HashTable

              hashTable = BaseHashTable.emptyHashTableWork(size, (AbsynUtil.pathHashMod, AbsynUtil.pathEqual, AbsynUtil.pathStringDefault, opaqVal))
          hashTable
        end

    #= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
    @exportAll()
  end