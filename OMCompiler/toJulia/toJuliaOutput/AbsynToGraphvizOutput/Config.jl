  module Config

#= Not fully automatically generated =#
  using MetaModelica

  struct _1_x end
  struct _2_x end
  struct _3_0 end
  struct _3_1 end
  struct _3_2 end
  struct _3_3 end
  struct latest end

 struct LanguageStandard
   _1_x
   _2_x
   _3_0
   _3_1
   _3_2
   latest
 end

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

        import Flags

        import System



         #= +t =#
        function typeinfo()::Bool
              local outBoolean::Bool

              outBoolean = Flags.getConfigBool(Flags.TYPE_INFO)
          outBoolean
        end

        function splitArrays()::Bool
              local outBoolean::Bool

              outBoolean = ! Flags.getConfigBool(Flags.KEEP_ARRAYS)
          outBoolean
        end

        function modelicaOutput()::Bool
              local outBoolean::Bool

              outBoolean = Flags.getConfigBool(Flags.MODELICA_OUTPUT)
          outBoolean
        end

        function noProc()::ModelicaInteger
              local outInteger::ModelicaInteger

              outInteger = noProcWork(Flags.getConfigInt(Flags.NUM_PROC))
          outInteger
        end

        function noProcWork(inProc::ModelicaInteger)::ModelicaInteger
              local outInteger::ModelicaInteger

              outInteger = begin
                @match inProc begin
                  0  => begin
                    System.numProcessors()
                  end

                  _  => begin
                      inProc
                  end
                end
              end
          outInteger
        end

        function latency()::ModelicaReal
              local outReal::ModelicaReal

              outReal = Flags.getConfigReal(Flags.LATENCY)
          outReal
        end

        function bandwidth()::ModelicaReal
              local outReal::ModelicaReal

              outReal = Flags.getConfigReal(Flags.BANDWIDTH)
          outReal
        end

        function simulationCg()::Bool
              local outBoolean::Bool

              outBoolean = Flags.getConfigBool(Flags.SIMULATION_CG)
          outBoolean
        end

         #= @author: adrpo
         returns: 'gcc' or 'msvc'
         usage: omc [+target=gcc|msvc], default to 'gcc'. =#
        function simulationCodeTarget()::String
              local outCodeTarget::String

              outCodeTarget = Flags.getConfigString(Flags.TARGET)
          outCodeTarget
        end

        function classToInstantiate()::String
              local modelName::String

              modelName = Flags.getConfigString(Flags.INST_CLASS)
          modelName
        end

        function silent()::Bool
              local outBoolean::Bool

              outBoolean = Flags.getConfigBool(Flags.SILENT)
          outBoolean
        end

        function versionRequest()::Bool
              local outBoolean::Bool

              outBoolean = Flags.getConfigBool(Flags.SHOW_VERSION)
          outBoolean
        end

        function helpRequest()::Bool
              local outBoolean::Bool

              outBoolean = ! stringEq(Flags.getConfigString(Flags.HELP), "")
          outBoolean
        end

         #= returns: the flag number representing the accepted grammer. Instead of using
         booleans. This way more extensions can be added easily.
         usage: omc [-g=Modelica|MetaModelica|ParModelica|Optimica], default to 'Modelica'. =#
        function acceptedGrammar()::ModelicaInteger
              local outGrammer::ModelicaInteger

              outGrammer = Flags.getConfigEnum(Flags.GRAMMAR)
          outGrammer
        end

         #= returns: true if MetaModelica grammar is accepted or false otherwise
         usage: omc [-g=Modelica|MetaModelica|ParModelica|Optimica], default to 'Modelica'. =#
        function acceptMetaModelicaGrammar()::Bool
              local outBoolean::Bool

              outBoolean = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.METAMODELICA)
          outBoolean
        end

         #= returns: true if ParModelica grammar is accepted or false otherwise
         usage: omc [-g=Modelica|MetaModelica|ParModelica|Optimica], default to 'Modelica'. =#
        function acceptParModelicaGrammar()::Bool
              local outBoolean::Bool

              outBoolean = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PARMODELICA)
          outBoolean
        end

         #= returns: true if Optimica grammar is accepted or false otherwise
         usage: omc [-g=Modelica|MetaModelica|ParModelica|Optimica], default to 'Modelica'. =#
        function acceptOptimicaGrammar()::Bool
              local outBoolean::Bool

              outBoolean = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.OPTIMICA)
          outBoolean
        end

         #= returns: true if Optimica grammar is accepted or false otherwise
         usage: omc [-g=Modelica|MetaModelica|ParModelica|Optimica], default to 'Modelica'. =#
        function acceptPDEModelicaGrammar()::Bool
              local outBoolean::Bool

              outBoolean = intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PDEMODELICA)
          outBoolean
        end

         #= returns what flag was given at start
             omc [+annotationVersion=3.x]
           or via the API
             setAnnotationVersion(\\\"3.x\\\");
           for annotations: 1.x or 2.x or 3.x =#
        function getAnnotationVersion()::String
              local annotationVersion::String

              annotationVersion = Flags.getConfigString(Flags.ANNOTATION_VERSION)
          annotationVersion
        end

         #= setAnnotationVersion(\\\"3.x\\\");
           for annotations: 1.x or 2.x or 3.x =#
        function setAnnotationVersion(annotationVersion::String)
              Flags.setConfigString(Flags.ANNOTATION_VERSION, annotationVersion)
        end

         #= returns what flag was given at start
           omc [+noSimplify]
         or via the API
           setNoSimplify(true|false); =#
        function getNoSimplify()::Bool
              local noSimplify::Bool

              noSimplify = Flags.getConfigBool(Flags.NO_SIMPLIFY)
          noSimplify
        end

        function setNoSimplify(noSimplify::Bool)
              Flags.setConfigBool(Flags.NO_SIMPLIFY, noSimplify)
        end

         #= Returns the vectorization limit that is used to determine how large an array
          can be before it no longer is expanded by Static.crefVectorize. =#
        function vectorizationLimit()::ModelicaInteger
              local limit::ModelicaInteger

              limit = Flags.getConfigInt(Flags.VECTORIZATION_LIMIT)
          limit
        end

         #= Sets the vectorization limit, see vectorizationLimit above. =#
        function setVectorizationLimit(limit::ModelicaInteger)
              Flags.setConfigInt(Flags.VECTORIZATION_LIMIT, limit)
        end

         #= Returns the id for the default OpenCL device to be used. =#
        function getDefaultOpenCLDevice()::ModelicaInteger
              local defdevid::ModelicaInteger

              defdevid = Flags.getConfigInt(Flags.DEFAULT_OPENCL_DEVICE)
          defdevid
        end

         #= Sets the default OpenCL device to be used. =#
        function setDefaultOpenCLDevice(defdevid::ModelicaInteger)
              Flags.setConfigInt(Flags.DEFAULT_OPENCL_DEVICE, defdevid)
        end

        function showAnnotations()::Bool
              local show::Bool

              show = Flags.getConfigBool(Flags.SHOW_ANNOTATIONS)
          show
        end

        function setShowAnnotations(show::Bool)
              Flags.setConfigBool(Flags.SHOW_ANNOTATIONS, show)
        end

        function showStructuralAnnotations()::Bool
              local show::Bool

              show = Flags.getConfigBool(Flags.SHOW_STRUCTURAL_ANNOTATIONS)
          show
        end

        function showStartOrigin()::Bool
              local show::Bool

              show = Flags.isSet(Flags.SHOW_START_ORIGIN)
          show
        end

        function getRunningTestsuite()::Bool
              local runningTestsuite::Bool

              runningTestsuite = ! stringEq(Flags.getConfigString(Flags.RUNNING_TESTSUITE), "")
          runningTestsuite
        end

        function getRunningWSMTestsuite()::Bool
              local runningTestsuite::Bool

              runningTestsuite = Flags.getConfigBool(Flags.RUNNING_WSM_TESTSUITE)
          runningTestsuite
        end

        function getRunningTestsuiteFile()::String
              local tempFile::String #= File containing a list of files created by running this test so rtest can remove them after =#

              tempFile = Flags.getConfigString(Flags.RUNNING_TESTSUITE)
          tempFile #= File containing a list of files created by running this test so rtest can remove them after =#
        end

         #= @author: adrpo
          flag to tell us if we should evaluate parameters in annotations =#
        function getEvaluateParametersInAnnotations()::Bool
              local shouldEvaluate::Bool

              shouldEvaluate = Flags.getConfigBool(Flags.EVAL_PARAMS_IN_ANNOTATIONS)
          shouldEvaluate
        end

         #= @author: adrpo
          flag to tell us if we should evaluate parameters in annotations =#
        function setEvaluateParametersInAnnotations(shouldEvaluate::Bool)
              Flags.setConfigBool(Flags.EVAL_PARAMS_IN_ANNOTATIONS, shouldEvaluate)
        end

         #= flag to tell us if we should ignore some errors (when evaluating icons) =#
        function getGraphicsExpMode()::Bool
              local graphicsExpMode::Bool

              graphicsExpMode = Flags.getConfigBool(Flags.GRAPHICS_EXP_MODE)
          graphicsExpMode
        end

         #= flag to tell us if we should ignore some errors (when evaluating icons) =#
        function setGraphicsExpMode(graphicsExpMode::Bool)
              Flags.setConfigBool(Flags.GRAPHICS_EXP_MODE, graphicsExpMode)
        end

        function orderConnections()::Bool
              local show::Bool

              show = Flags.getConfigBool(Flags.ORDER_CONNECTIONS)
          show
        end

        function setOrderConnections(show::Bool)
              Flags.setConfigBool(Flags.ORDER_CONNECTIONS, show)
        end

        function getPreOptModules()::List
              local outStringLst::List

              outStringLst = Flags.getConfigStringList(Flags.PRE_OPT_MODULES)
          outStringLst
        end

        function getPostOptModules()::List
              local outStringLst::List

              outStringLst = Flags.getConfigStringList(Flags.POST_OPT_MODULES)
          outStringLst
        end

        function getPostOptModulesDAE()::List
              local outStringLst::List

              outStringLst = Flags.getConfigStringList(Flags.POST_OPT_MODULES_DAE)
          outStringLst
        end

        function getInitOptModules()::List
              local outStringLst::List

              outStringLst = Flags.getConfigStringList(Flags.INIT_OPT_MODULES)
          outStringLst
        end

        function setPreOptModules(inStringLst::List)
              Flags.setConfigStringList(Flags.PRE_OPT_MODULES, inStringLst)
        end

        function setPostOptModules(inStringLst::List)
              Flags.setConfigStringList(Flags.POST_OPT_MODULES, inStringLst)
        end

        function getIndexReductionMethod()::String
              local outString::String

              outString = Flags.getConfigString(Flags.INDEX_REDUCTION_METHOD)
          outString
        end

        function setIndexReductionMethod(inString::String)
              Flags.setConfigString(Flags.INDEX_REDUCTION_METHOD, inString)
        end

        function getCheapMatchingAlgorithm()::ModelicaInteger
              local outInteger::ModelicaInteger

              outInteger = Flags.getConfigInt(Flags.CHEAPMATCHING_ALGORITHM)
          outInteger
        end

        function setCheapMatchingAlgorithm(inInteger::ModelicaInteger)
              Flags.setConfigInt(Flags.CHEAPMATCHING_ALGORITHM, inInteger)
        end

        function getMatchingAlgorithm()::String
              local outString::String

              outString = Flags.getConfigString(Flags.MATCHING_ALGORITHM)
          outString
        end

        function setMatchingAlgorithm(inString::String)
              Flags.setConfigString(Flags.MATCHING_ALGORITHM, inString)
        end

        function getTearingMethod()::String
              local outString::String

              outString = Flags.getConfigString(Flags.TEARING_METHOD)
          outString
        end

        function setTearingMethod(inString::String)
              Flags.setConfigString(Flags.TEARING_METHOD, inString)
        end

        function getTearingHeuristic()::String
              local outString::String

              outString = Flags.getConfigString(Flags.TEARING_HEURISTIC)
          outString
        end

        function setTearingHeuristic(inString::String)
              Flags.setConfigString(Flags.TEARING_HEURISTIC, inString)
        end

         #= Default is set by +simCodeTarget=C =#
        function simCodeTarget()::String
              local target::String

              target = Flags.getConfigString(Flags.SIMCODE_TARGET)
          target
        end

        function setsimCodeTarget(inString::String)
              Flags.setConfigString(Flags.SIMCODE_TARGET, inString)
        end

        function getLanguageStandard()::LanguageStandard
              local outStandard::LanguageStandard

              outStandard = intLanguageStandard(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD))
          outStandard
        end

        function setLanguageStandard(inStandard::LanguageStandard)
              Flags.setConfigEnum(Flags.LANGUAGE_STANDARD, languageStandardInt(inStandard))
        end

        function languageStandardAtLeast(inStandard::LanguageStandard)::Bool
              local outRes::Bool

              local std::LanguageStandard

              std = getLanguageStandard()
              outRes = intGe(languageStandardInt(std), languageStandardInt(inStandard))
          outRes
        end

        function languageStandardAtMost(inStandard::LanguageStandard)::Bool
              local outRes::Bool

              local std::LanguageStandard

              std = getLanguageStandard()
              outRes = intLe(languageStandardInt(std), languageStandardInt(inStandard))
          outRes
        end

        function languageStandardInt(inStandard::LanguageStandard)::ModelicaInteger
              local outValue::ModelicaInteger

              local lookup::ModelicaInteger[LanguageStandard] = array(10, 20, 30, 31, 32, 33, 1000)

              outValue = lookup[inStandard]
          outValue
        end

        function intLanguageStandard(inValue::ModelicaInteger)::LanguageStandard
              local outStandard::LanguageStandard

              outStandard = begin
                @match inValue begin
                  10  => begin
                    LanguageStandard._1_x
                  end

                  20  => begin
                    LanguageStandard._2_x
                  end

                  30  => begin
                    LanguageStandard._3_0
                  end

                  31  => begin
                    LanguageStandard._3_1
                  end

                  32  => begin
                    LanguageStandard._3_2
                  end

                  33  => begin
                    LanguageStandard._3_3
                  end

                  1000  => begin
                    LanguageStandard.latest
                  end
                end
              end
          outStandard
        end

        function languageStandardString(inStandard::LanguageStandard)::String
              local outString::String

              local lookup::String[LanguageStandard] = array("1.x", "2.x", "3.0", "3.1", "3.2", "3.3", "3.3")
               #= /*Change this to latest version if you add more versions!*/ =#

              outString = lookup[inStandard]
          outString
        end

        function setLanguageStandardFromMSL(inLibraryName::String)
              local current_std::LanguageStandard

              current_std = getLanguageStandard()
              if current_std != LanguageStandard.latest
                return
              end
               #=  If we selected an MSL version manually, we respect that choice.
               =#
              () = begin
                  local version::String
                  local new_std_str::String
                  local new_std::LanguageStandard
                  local show_warning::Bool
                @matchcontinue inLibraryName begin
                  (_)  => begin
                      @assert ("Modelica", version) == listHead(System.strtok(inLibraryName, " ")), listRest(System.strtok(inLibraryName, " "))
                      new_std = versionStringToStd(version)
                      if new_std == current_std
                        return
                      end
                      setLanguageStandard(new_std)
                      show_warning = hasLanguageStandardChanged(current_std)
                      new_std_str = languageStandardString(new_std)
                      if show_warning
                      end
                    ()
                  end

                  (_)  => begin
                      ()
                  end
                end
              end
        end

        function hasLanguageStandardChanged(inOldStandard::LanguageStandard)::Bool
              local outHasChanged::Bool

               #=  If the old standard wasn't set by the user, then we consider it to have
               =#
               #=  changed only if the new standard is 3.0 or less. This is to avoid
               =#
               #=  printing a notice if the user loads e.g. MSL 3.1.
               =#
              outHasChanged = languageStandardAtMost(LanguageStandard._3_0)
          outHasChanged
        end

        function versionStringToStd(inVersion::String)::LanguageStandard
              local outStandard::LanguageStandard

              local version::List

              version = System.strtok(inVersion, ".")
              outStandard = versionStringToStd2(version)
          outStandard
        end

        function versionStringToStd2(inVersion::List)::LanguageStandard
              local outStandard::LanguageStandard

              outStandard = begin
                @match inVersion begin
                  "1" <| _  => begin
                    LanguageStandard._1_x
                  end

                  "2" <| _  => begin
                    LanguageStandard._2_x
                  end

                  "3" <| "0" <| _  => begin
                    LanguageStandard._3_0
                  end

                  "3" <| "1" <| _  => begin
                    LanguageStandard._3_1
                  end

                  "3" <| "2" <| _  => begin
                    LanguageStandard._3_2
                  end

                  "3" <| "3" <| _  => begin
                    LanguageStandard._3_3
                  end

                  "3" <| _  => begin
                    LanguageStandard.latest
                  end
                end
              end
          outStandard
        end

        function showErrorMessages()::Bool
              local outShowErrorMessages::Bool

              outShowErrorMessages = Flags.getConfigBool(Flags.SHOW_ERROR_MESSAGES)
          outShowErrorMessages
        end

        function scalarizeMinMax()::Bool
              local outScalarizeMinMax::Bool

              outScalarizeMinMax = Flags.getConfigBool(Flags.SCALARIZE_MINMAX)
          outScalarizeMinMax
        end

        function scalarizeBindings()::Bool
              local outScalarizeBindings::Bool

              outScalarizeBindings = Flags.getConfigBool(Flags.SCALARIZE_BINDINGS)
          outScalarizeBindings
        end

        function intEnumConversion()::Bool
              local outIntEnumConversion::Bool

              outIntEnumConversion = Flags.getConfigBool(Flags.INT_ENUM_CONVERSION)
          outIntEnumConversion
        end

        function profileSome()::Bool
              local outBoolean::Bool

              outBoolean = 0 == System.strncmp(Flags.getConfigString(Flags.PROFILING_LEVEL), "blocks", 6)
          outBoolean
        end

        function profileAll()::Bool
              local outBoolean::Bool

              outBoolean = stringEq(Flags.getConfigString(Flags.PROFILING_LEVEL), "all")
          outBoolean
        end

        function profileHtml()::Bool
              local outBoolean::Bool

              outBoolean = stringEq(Flags.getConfigString(Flags.PROFILING_LEVEL), "blocks+html")
          outBoolean
        end

        function profileFunctions()::Bool
              local outBoolean::Bool

              outBoolean = ! stringEq(Flags.getConfigString(Flags.PROFILING_LEVEL), "none")
          outBoolean
        end

        function dynamicTearing()::String
              local outString::String

              outString = Flags.getConfigString(Flags.DYNAMIC_TEARING)
          outString
        end

        function ignoreCommandLineOptionsAnnotation()::Bool
              local outBoolean::Bool

              outBoolean = Flags.getConfigBool(Flags.IGNORE_COMMAND_LINE_OPTIONS_ANNOTATION)
          outBoolean
        end

        function globalHomotopy()::Bool
              local outBoolean::Bool

              outBoolean = begin
                @match Flags.getConfigString(Flags.HOMOTOPY_APPROACH) begin
                  "equidistantLocal"  => begin
                    false
                  end

                  "adaptiveLocal"  => begin
                    false
                  end

                  "equidistantGlobal"  => begin
                    true
                  end

                  "adaptiveGlobal"  => begin
                    true
                  end
                end
              end
          outBoolean
        end

        function adaptiveHomotopy()::Bool
              local outBoolean::Bool

              outBoolean = begin
                @match Flags.getConfigString(Flags.HOMOTOPY_APPROACH) begin
                  "equidistantLocal"  => begin
                    false
                  end

                  "adaptiveLocal"  => begin
                    true
                  end

                  "equidistantGlobal"  => begin
                    false
                  end

                  "adaptiveGlobal"  => begin
                    true
                  end
                end
              end
          outBoolean
        end

         #= @autor: adrpo
         checks returns true if language standard is above or equal to Modelica 3.3 =#
        function synchronousFeaturesAllowed()::Bool
              local outRes::Bool

              local std::LanguageStandard = getLanguageStandard()

              outRes = intGe(languageStandardInt(std), 33)
          outRes
        end

  end
