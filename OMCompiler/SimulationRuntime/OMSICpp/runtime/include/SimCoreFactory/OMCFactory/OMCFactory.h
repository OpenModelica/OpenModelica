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
  virtual shared_ptr<ISimController> createSimController();
protected:
  /**
   * This function handles complex c-runtime arguments like "-override=startTime=0,...". The
   * arguments are separated correctly returned as vector. Furthermore the are added to the given
   * opts-map (old values are overwritten).
   * @param argc Number of arguments in the argv-array.
   * @param argv The command line arguments as c-string array.
   * @param opts Already parsed command line arguments (as key-value-pairs)
   * @return All arguments as simple entries.
   */
  std::vector<const char *> handleComplexCRuntimeArguments(int argc, const char* argv[], std::map<std::string, std::string> &opts);

  /**
   * Replace all argument names that are part of the arguments-to-replace-map.
   * @param argc Number of arguments in the argv-array.
   * @param argv The command line arguments as c-string array.
   * @param opts Already parsed command line arguments (as key-value-pairs)
   * @return All arguments including the replaced strings.
   */
  std::vector<const char *> handleArgumentsToReplace(int argc, const char* argv[], std::map<std::string, std::string> &opts);

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
   * format and options that should be ignored.
   * It parses a long option that starts with one dash, like '-port=12345' and put it into the 'unrecognized' category.
   * If an option is detected which is part of the arguments to ignore list, it is put into the 'ignored' category.
   * @param The argument that should be handled.
   * @return The pair of category and value that should be used for the given argument.
   */
  pair<string, string> parseIngoredAndWrongFormatOption(const string &s);

  void fillArgumentsToIgnore();
  void fillArgumentsToReplace();

  virtual shared_ptr<ISimController> loadSimControllerLib(PATH simcontroller_path, type_map simcontroller_type_map);

  //shared_ptr<ISimController> _simController;
  map<string,shared_library> _modules;
  string _defaultLinSolver;
  string _defaultNonLinSolver;
  PATH _library_path;
  PATH _modelicasystem_path;
  unordered_set<string> _argumentsToIgnore; //a set of arguments that should be ignored
  std::map<string, string> _argumentsToReplace; //a mapping to replace arguments (e.g. -r=... -> -F=...)
  std::string _overrideOMEdit; // unrecognized options if called from OMEdit
};
/** @} */ // end of simcorefactoryOMCFactory
