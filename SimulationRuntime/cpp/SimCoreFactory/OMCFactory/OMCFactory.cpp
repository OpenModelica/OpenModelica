#include "stdafx.h"
#include <OMCFactory/OMCFactory.h>

OMCFactory::OMCFactory(PATH library_path, PATH modelicasystem_path)
    : _library_path(library_path)
    , _modelicasystem_path(modelicasystem_path)
{
}


void OMCFactory::UnloadAllLibs(void)
{
    map<string,shared_library>::iterator iter;
    for(iter = _modules.begin();iter!=_modules.end();++iter)
    {
        UnloadLibrary(iter->second);
    }
}


LOADERRESULT OMCFactory::LoadLibrary(string libName,type_map& current_map)
{
    
    shared_library lib;
        if(!load_single_library(current_map,libName,lib))
           return LOADER_ERROR;
     _modules.insert(std::make_pair(libName,lib)); 
return LOADER_SUCCESS;     
}

LOADERRESULT OMCFactory::UnloadLibrary(shared_library lib)
{	
    if(lib.is_open())
    {
       if(!lib.close())
            return LOADER_ERROR;
       else
           return LOADER_SUCCESS;
    }
    return LOADER_SUCCESS;  
}

