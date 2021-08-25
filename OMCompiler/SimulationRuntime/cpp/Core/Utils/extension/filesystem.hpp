/*
 * Boost.Extension / filesystem functions:
 *         functions to navigate folders/directories and get the libraries
 *
 * (C) Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */

#ifndef BOOST_EXTENSION_FILESYSTEM_HPP
#define BOOST_EXTENSION_FILESYSTEM_HPP
//  These functions require the boost.filesystem library
#include <boost/filesystem/path.hpp>
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/convenience.hpp>
#include <boost/extension/factory_map.hpp>
#include <Core/Utils/extension/convenience.hpp>

namespace boost {namespace extensions {

inline void load_all_libraries(factory_map & current_zone,
                               const char * directory,
                               const char * external_function_name,
                               int max_depth = 0)
{
  if (max_depth < 0) return; //  Recursion base case
  filesystem::directory_iterator end_file_iter;
  boost::filesystem::path dir_path(directory);
  filesystem::directory_iterator file_iter(dir_path);
  for( ;file_iter!=end_file_iter; ++file_iter)
  {
    if (is_directory(*file_iter))
    {
      load_all_libraries(current_zone, directory, file_iter->string().c_str(),
                         max_depth - 1);
    }
    else if (is_library(filesystem::extension(*file_iter).c_str()))
    {
      load_single_library(current_zone, file_iter->string().c_str(),
                          external_function_name);
    }
  }
}




}}



#endif
