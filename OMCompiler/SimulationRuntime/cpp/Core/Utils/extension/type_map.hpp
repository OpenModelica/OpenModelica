/*
 * Boost.Extension / factory map:
 *         map of factories (for the implementations)
 *
 * (C) Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */

#ifndef BOOST_EXTENSION_TYPE_MAP_HPP
#define BOOST_EXTENSION_TYPE_MAP_HPP

#include <map>
#include <Core/Utils/extension/impl/typeinfo.hpp>
#include <boost/static_assert.hpp>
#include <boost/type_traits/remove_const.hpp>

namespace boost {
namespace extensions {

/** \brief A collection of types.
  * \tparam TypeInfo The type used for TypeInfo. By default,
  *         RTTI is used, but users can define their own TypeInfo.
  *         See impl/typeinfo.hpp.
  *
  * The `type_map` class is used for holding an arbitrary collection
  * of types - no more than one of each type.
  * In general, standard usage is as follows:
  *
  * \code
  * type_map types;
  * // This will add an integer to the type_map, or retrieve
  * // one if it already exists.
  * int& first_int(types.get());
  * first_int = 5;
  * // This will make second_int point to the same value
  * // as first_int.
  * int& second_int(types.get());
  * second_int = 10;
  * // Now first_int is 10.
  * // It is also possible to use arbitrary types in the map,
  * // as long as they are default constructible.
  * std::set<std::string>& my_string(types.get());
  * \endcode
  */
template <class TypeInfo>
class basic_type_map {
public:

#ifndef BOOST_EXTENSION_DOXYGEN_INVOKED
  class type_map_convertible {
  public:
    friend class basic_type_map<TypeInfo>;
    ~type_map_convertible() {
      for (typename std::map<TypeInfo, generic_type_holder*>::iterator
           it =instances_.begin(); it != instances_.end(); ++it) {
        delete it->second;
      }
    }
    template <class Type>
    operator Type&() {
      typedef typename remove_const<Type>::type StoredType;
      TypeInfo t =
        type_info_handler<TypeInfo, StoredType>
          ::get_class_type();
      typename std::map<TypeInfo, generic_type_holder*>::iterator
        it = instances_.find(t);

      type_holder<StoredType>* holder;
      if (it == instances_.end()) {
        holder = new type_holder<StoredType>;
        it = instances_.insert(std::make_pair(t, holder)).first;
      }
      else {
        holder = static_cast<type_holder<StoredType>*>(it->second);
      }
      return holder->val;
    }

  private:
    struct generic_type_holder {
      virtual ~generic_type_holder() {}
    };

    // T must be default constructible.
    template <class T>
    struct type_holder : generic_type_holder {
      T val;
    };
    std::map<TypeInfo, generic_type_holder*> instances_;
  };

  size_t size() {
    return convertible_.instances_.size();
  }

  bool empty() {
    return convertible_.instances_.empty();
  }

  type_map_convertible& get() {
    return convertible_;
  }
#endif
  /** \brief Retrieve a given type from the type_map.
    *
    * This is the only method users should ever need to use.
    * By calling it with a template argument `Type`, a reference
    * to the single object of that type will be returned, after
    * being created if necessary.
    * It is possible to omit the template parameter if it is clear
    * from context:
    * \code
    * type_map types;
    * int& my_int(types.get());
    * \endcode
    * \tparam Type The type of the object to return a reference to.
    */
  template <class Type>
  Type& get() {
    return convertible_;
  }
private:
  type_map_convertible convertible_;

};
/** A typedef for convenience - provides the most common
  * type of basic_factory_map.
  */
typedef basic_type_map<default_type_info> type_map;

/** A macro to use as a generic
  * function declaration for
  * functions in shared libraries
  * taking a reference to type_map
  * and returning void.
  */
#define BOOST_EXTENSION_TYPE_MAP_FUNCTION \
extern "C" \
void BOOST_EXTENSION_EXPORT_DECL \
boost_extension_exported_type_map_function \
  (boost::extensions::type_map& types)

} // namespace extensions
} // namespace boost

#endif  // BOOST_EXTENSION_TYPE_MAP_HPP
