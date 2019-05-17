/*
 * Boost.Extension / adaptable_factory:
 *         factory to register the implementations and create them,
 *         without binding the parameter types into the factory type.
 *
 * (C) Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */

#ifndef BOOST_EXTENSION_ADAPTABLE_FACTORY_HPP
#define BOOST_EXTENSION_ADAPTABLE_FACTORY_HPP

#include <string>
#include <vector>

#include <boost/bind.hpp>
#include <Core/Utils/extension/common.hpp>
#include <boost/extension/impl/create.hpp>
#include <boost/function.hpp>
#include <boost/extension/parameter_map.hpp>

namespace boost {
namespace extensions {
namespace impl {
#ifndef BOOST_EXTENSION_DOXYGEN_INVOKED
# define BOOST_PP_ITERATION_LIMITS \
  (0, BOOST_PP_INC(BOOST_EXTENSION_MAX_FUNCTOR_PARAMS) - 1)
# define BOOST_PP_FILENAME_1 <boost/extension/impl/adaptable_factory_free_functions.hpp>
# include BOOST_PP_ITERATE()
#endif  // BOOST_EXTENSION_DOXYGEN_INVOKED
}  // namespace impl

/** This class is a function object that returns
  * new instances of type Interface, using factories that
  * take parameters described in the variable length
  * list Params...
  */
template <class Interface, class Info = std::string,
          class TypeInfo = default_type_info>
class adaptable_factory {
public:
  /** \brief Default constructor.
    * On creation, this adaptable_factory is empty.
    */
  adaptable_factory() : functor_func_(0), func_(0), check_func_(0) {}

  /** \brief Standard copy constructor.
    */
  adaptable_factory(adaptable_factory<Interface> const& first) : func_(first.func_) {}

  /** \brief Standard assignment operator.
    */
  adaptable_factory& operator=(adaptable_factory<Interface> const& first) {
    this->func_ = first->func_;
    return *this;
  }

  /** Returns an instance of Interface (but does NOT retain ownership of the instance).
    * \param map A parameter map to search for the parameters for this function.
    * \return An instance of Interface, if all of the needed parameters are found in map.
    * Otherwise, it returns NULL.
    * \pre is_valid() == true.
    * \post None.
    */
  Interface* create(boost::extensions::parameter_map& map) const {
    return (*func_)(map, parameter_names_);
  }

  /** Generate a `boost::function` object that can be reused to create
    * instances of `Interface` based on the data in the _parameter_map_.
    * If the _parameter_map_ does not contain all of the needed parameters,
    * then calling `empty()` on the returned function object will return
    * true.
    * \return An instance of Interface, if all of the needed parameters are found in map.
    * Otherwise, it returns NULL.
    * \pre is_valid() == true.
    * \post None.
    */
  function<Interface* ()> get_function(
      boost::extensions::parameter_map& map) const {
    return (*functor_func_)(map, parameter_names_);
  }

  /** Returns a map of the TypeInfo/Info pairs describing any parameters still
    * needed before this function can be called.
    * \param map A parameter map to search for the parameters for this function.
    * \return TypeInfo/Info pairs for any missing parameters.
    * \pre is_valid() == true.
    * \post None.
    */
  std::vector<std::pair<TypeInfo, Info> > get_missing_params(
      const boost::extensions::parameter_map& map) const {
    return (*check_func_)(map, parameter_names_);
  }

  /** \brief Returns true if set has been called.
    *
    * Until set is called, a adaptable_factory cannot be used. This
    * function can be used to determine if set has been called.
    * \pre None.
    * \post None.
    * \return True if the adaptable_factory is initialized (ie, set has been called).
    */
  bool is_valid() const { return this->func_ != 0; }

/* For Doxygen, and for easier readability by users, a
 * simplified version of this class's set function is provided, but never
 * compiled.
 */
#ifdef BOOST_EXTENSION_DOXYGEN_INVOKED

  /** \brief Set the factory function for this adaptable_factory.
    *
    * This sets the factory function
    * to the constructor for type D.
    * It takes as arguments Info about each parameter
    * in the constructor.
    * Example:
    * \code
    * adaptable_factory<Base, int, int> f;
    * f.set<Derived>();
    * \endcode
    * \param parameter_names A variable length list of Info
    * to describe the parameters of the constructor.
    * \pre None.
    * \post None.
    */
  template <class Derived, class Params...>
  void set(Info parameter_names...) {}
#else

# define BOOST_PP_ITERATION_LIMITS \
  (0, BOOST_PP_INC(BOOST_EXTENSION_MAX_FUNCTOR_PARAMS) - 1)
# define BOOST_PP_FILENAME_1 <boost/extension/impl/adaptable_factory_set.hpp>
# include BOOST_PP_ITERATE()
private:
  function<Interface* ()> (*functor_func_)(
    boost::extensions::basic_parameter_map<Info>& map,
    const std::vector<Info>& names);
  Interface* (*func_)(
    boost::extensions::basic_parameter_map<Info>& map,
    const std::vector<Info>& names);
  std::vector<std::pair<TypeInfo, Info> >  (*check_func_)(
    const boost::extensions::basic_parameter_map<Info>& map,
    const std::vector<Info>& names);
  std::vector<Info> parameter_names_;
#endif  // BOOST_EXTENSION_DOXYGEN_INVOKED
};
}  // namespace extensions
}  // namespace boost

#endif  // BOOST_EXTENSION_FACTORY_HPP
