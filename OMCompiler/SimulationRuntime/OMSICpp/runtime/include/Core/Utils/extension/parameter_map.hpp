/*
 * Boost.Reflection / paramater map (store parameter information for calls)
 *
 * (C) Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */


#ifndef BOOST_EXTENSION_PARAMETER_MAP_HPP
#define BOOST_EXTENSION_PARAMETER_MAP_HPP
#include <boost/extension/impl/typeinfo.hpp>
#include <boost/extension/parameter.hpp>
#include <exception>
#include <map>
#include <string>
#include <vector>

namespace boost { namespace extensions {
class parameter_unavailable_exception : public std::exception {
public:
  virtual const char * what() {
    return "Type not found in parameter_map";
  }
};

template <class Info = std::string,
          class TypeInfo = extensions::default_type_info>
class basic_parameter_map
  : protected std::multimap<Info, generic_parameter<TypeInfo>*> {
public:
  ~basic_parameter_map() {
    for (typename map_type::iterator it = begin(); it != end(); ++it) {
      delete it->second;
    }
  }
  typedef std::multimap<Info, generic_parameter<TypeInfo>*> map_type;
  using map_type::equal_range;
  using map_type::begin;
  using map_type::end;
  using map_type::insert;

  /** \brief Return all parameters matching the TypeInfo and Info.
    *
    * Given a type (D) and Info (ie, string describing the parameter),
    * return a vector containing all generic_parameters that match,
    * or can be converted to the given type.
    *
    * \return Matching parameters.
    * \pre None.
    * \post None.
    * \param Info The Info (ie, name) describing the parameter needed.
    * \tparam D The type of parameter to return.
    */
  template <class D>
  std::vector<generic_parameter<TypeInfo>*> get(const Info& info) {
    std::vector<generic_parameter<TypeInfo>*> parameters;
    std::pair<typename map_type::iterator, typename map_type::iterator> its
      = equal_range(info);
    for (typename map_type::iterator current = its.first;
         current != its.second; ++current) {
      generic_parameter<TypeInfo>& p = *current->second;
      if (p.template can_cast<D>()) {
        parameters.push_back(current->second);
      }
    }
    return parameters;
  }

  /** \brief Return true if the given parameter exists.
    *
    * Given a type (D) and Info (ie, string describing the parameter),
    * return true if the element exists in the parameter_map.
    *
    * \return True if the parameter exists.
    * \pre None.
    * \post None.
    * \param Info The Info (ie, name) describing the parameter needed.
    * \tparam D The type of parameter to search for.
    */
  template <class D>
  bool has(const Info& info) const {
    std::pair<typename map_type::const_iterator,
              typename map_type::const_iterator> its
      = equal_range(info);
    for (typename map_type::const_iterator current = its.first;
         current != its.second; ++current) {
      generic_parameter<TypeInfo>& p = *current->second;
      if (p.template can_cast<D>()) {
        return true;
      }
    }
    return false;
  }

  /** \brief Return the first matching parameter.
    *
    * Given a type (D) and Info (ie, string describing the parameter),
    * return first parameter matching, or that can be converted to that
    * type.
    *
    * \return The first matching parameter.
    * \pre None.
    * \post None.
    * \param Info The Info (ie, name) describing the parameter needed.
    * \tparam D The type of parameter to search for.
    */
  template <class D>
  generic_parameter<TypeInfo>* get_first(const Info& info) {
    std::pair<typename map_type::iterator, typename map_type::iterator> its
      = equal_range(info);
    for (typename map_type::iterator current = its.first;
         current != its.second; ++current) {
      generic_parameter<TypeInfo>& p = *current->second;
      if (p.template can_cast<D>()) {
        return &p;
      }
    }
    return 0;
  }
};
typedef basic_parameter_map<> parameter_map;
}}

#endif  // BOOST_EXTENSION_PARAMETER_MAP_HPP
