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
  std::vector<const char *> modifyArguments(int argc, const char* argv[], std::map<std::string, std::string> &opts);
  SimSettings readSimulationParameter(int argc, const char* argv[]);

  //boost::shared_ptr<ISimController> _simController;
  std::map<string,shared_library> _modules;
  std::string _defaultLinSolver;
  std::string _defaultNonLinSolver;
  PATH _library_path;
  PATH _modelicasystem_path;
};
/** @} */ // end of simcorefactoryOMCFactory
