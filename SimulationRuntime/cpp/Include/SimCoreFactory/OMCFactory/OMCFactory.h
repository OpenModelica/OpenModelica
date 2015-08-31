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
typedef int LOADERRESULT;
class ISimController;
struct SimSettings;

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
  virtual std::pair<boost::shared_ptr<ISimController>,SimSettings> createSimulation(int argc, const char* argv[], std::map<std::string, std::string> &opts);

protected:
  /** merge command line args with built-in args and adapt OMEdit args to Cpp */
  std::vector<const char *> preprocessArguments(int argc, const char* argv[], std::map<std::string, std::string> &opts);

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

  //boost::shared_ptr<ISimController> _simController;
  std::map<string,shared_library> _modules;
  std::string _defaultLinSolver;
  std::string _defaultNonLinSolver;
  PATH _library_path;
  PATH _modelicasystem_path;
  boost::unordered_set<string> _argumentsToIgnore; //a set of arguments that should be ignored,
  std::string _overrideOMEdit; // unrecognized options if called from OMEdit
};
/** @} */ // end of simcorefactoryOMCFactory
