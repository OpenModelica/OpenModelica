/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#pragma once
/** @defgroup simcorefactoryOMCFactory SimCoreFactory.OMCFactory
 *  Object factories for  gcc/msvc build and linux and windows targets
 *  @{
 */
#define LOADER_SUCCESS                      ( 0  )
#define LOADER_ERROR                        ( -1 )
#define LOADER_ERROR_UNDEFINED_REFERENCES   ( -2 )
#define LOADER_ERROR_FILE_NOT_FOUND         ( -3 )
#define LOADER_ERROR_FUNC_NOT_FOUND         ( -4 )

/** Minimal OMCFactory for statically linked solvers */
class BaseOMCFactory {
  public:
    BaseOMCFactory() {}
    BaseOMCFactory(PATH library_path, PATH modelicasystem_path) {}
    ~BaseOMCFactory() {}
};

typedef int LOADERRESULT;
class ISimController;
struct SimSettings;

/**
 * Create a dynamically linked simulator and serve for solver factories
 */
class OMCFactory
{
public:
  OMCFactory();
  OMCFactory(PATH library_path, PATH modelicasystem_path);
  virtual ~OMCFactory();

  virtual void UnloadAllLibs();
  virtual LOADERRESULT LoadLibrary(string libName, type_map& current_map);
  virtual LOADERRESULT UnloadLibrary(shared_library lib);

  /**
   * Create SimController and SimSettings.
   * @param argc number of command line arguments
   * @param argv command line arguments of main function
   * @param opts default options that are overridden with argv
   */
  virtual std::pair<shared_ptr<ISimController>,SimSettings> createSimulation(int argc, const char* argv[], std::map<std::string, std::string> &opts);

protected:
  /**
   * This function handles overridden options, e.g. from OMEdit "-endTime=10".
   * Furthermore they are added to the given opts-map (old values are overwritten).
   * @param argc Number of arguments in the argv-array.
   * @param argv The command line arguments as c-string array.
   * @param opts Already parsed command line arguments (as key-value-pairs)
   * @return All arguments as simple entries.
   */
  std::vector<const char *> handleOverrides(int argc, const char* argv[], std::map<std::string, std::string> &opts);

  /**
   * Evaluate all given command line arguments and store their values into the SimSettings structure.
   * @param argc Number of arguments in the argv-array.
   * @param argv The command line arguments as c-string array.
   * @throws SIMULATION_ERROR If "--help" was passed as argument - the error code is set to "SUPRESS".
   * @return The created SimSettings-structure.
   */
  SimSettings readSimulationParameter(int argc, const char* argv[]);

  /**
   * This helper-function is invoked by the boost program option library and will handle options in the c-runtime
   * format, replacing them with correcponding cpp options.
   * @param The argument that should be handled.
   * @return The pair of category and value that should be used for the given argument.
   */
  pair<string, string> replaceCRuntimeArguments(const string &arg);

  void fillArgumentsToIgnore();
  void fillArgumentsToReplace();

  virtual shared_ptr<ISimController> loadSimControllerLib(PATH simcontroller_path, type_map simcontroller_type_map);

  //shared_ptr<ISimController> _simController;
  map<string,shared_library> _modules;
  string _defaultLinSolver;
  std::vector<string> _defaultNonLinSolvers;
  PATH _library_path;
  PATH _modelicasystem_path;
  unordered_set<string> _argumentsToIgnore; //a set of arguments that should be ignored
  std::map<string, string> _argumentsToReplace; //a mapping to replace arguments (e.g. -r=... -> -F=...)
};
/** @} */ // end of simcorefactoryOMCFactory
