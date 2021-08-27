#pragma once
/** @defgroup simcorefactory SimCoreFactory
 *  Base module for all object factories
 *  @{
 */

template<class T>
struct ObjectFactory
{
  ObjectFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
            : _library_path(library_path)
            , _modelicasystem_path(modelicasystem_path)
            , _config_path(config_path)
    {
    _factory = shared_ptr<T>(new T(library_path, modelicasystem_path));
  }

  virtual ~ObjectFactory() {};

protected:
    shared_ptr<T> _factory;
    PATH _library_path;
    PATH _modelicasystem_path;
    PATH _config_path;
};
/** @} */ // end of simcorefactoryBodas