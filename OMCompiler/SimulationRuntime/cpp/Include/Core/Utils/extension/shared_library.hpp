/*
* Boost.Extension / shared_library:
*         Functions for shared_library loading.
*         A basic wrapper around the OS-specific calls.
*
* (C) Copyright Jeremy Pack 2008
* Distributed under the Boost Software License, Version 1.0. (See
* accompanying file LICENSE_1_0.txt or copy at
* http://www.boost.org/LICENSE_1_0.txt)
*
* See http://www.boost.org/ for latest version.
*/


#ifndef BOOST_EXTENSION_SHARED_LIBRARY_HPP
#define BOOST_EXTENSION_SHARED_LIBRARY_HPP



#include <string>

#include <Core/Utils/extension/common.hpp>
#include <Core/Utils/extension/impl/library_impl.hpp>
#include <boost/preprocessor/iteration/iterate.hpp>

namespace boost {
	namespace extensions {
		template <class TypeInfo>
		class basic_type_map;

		/** \brief A wrapper around OS-specific shared library functions.

		\note This class is inherently not type-safe. Carefully
		check the signature of the function or type in the shared library
		against the template arguments of the get functions.
		*/
		class shared_library {
		public:
			shared_library()
			{}
			/** shared_library constructor
			* \param location The relative or absolute path of the shared library.
			* \param auto_close An optional parameter which defaults to false.
			*        If set to true, the destructor will close this shared library
			*        if necessary.
			*/
			shared_library(const std::string& location, bool auto_close = false)
				: location_(location), handle_(0), auto_close_(auto_close) {
			}

			/** shared_library destructor
			* If auto_close_ was set to true in the constructor, this closes
			* the library if it is currently open.
			*/
			~shared_library() {
				if (handle_ && auto_close_)
					close();
			}

			/** \return true if the shared library is currently open
			* and referenced by this object.
			* \pre None.
			* \post None.
			*/
			bool is_open() const { return handle_ != 0; }

			/** \brief Open the shared library.
			* \return true if the shared library was opened successfully.
			* \pre None.
			* \post If true is returned, the shared library is opened and
			* get() can be called.
			*/
			bool open() {
				if (handle_)
					close();
				return (handle_ = impl::load_shared_library(location_.c_str())) != 0;
			}

			/** \brief Close the shared library.
			* This calls the OS specific close function for shared libraries.
			* Usually, this decrements the reference count of the shared library.
			* Once a shared library has a reference count of 0, it can be actually
			* unloaded at any time.
			* \return true if the close function was successful.
			* \pre is_open() == true.
			* \post is_open() == false.
			*/
			bool close() {
				return impl::close_shared_library(handle_);
			}

			/** \brief Call a special Extension function in the library.
			*
			* There is a special function called
			* boost_extension_exported_type_map_function which is commonly
			* used by shared libraries. The call function attempts to find
			* and call that function, given a type_map.
			*
			* \return true on success.
			* \param types A type_map that will be sent to the function.
			* \pre is_open() == true
			* \post None.
			*/
			template <class TypeInfo>
			bool call(basic_type_map<TypeInfo>& types) {
				void (*func)(basic_type_map<TypeInfo>&);
				func = get<void, basic_type_map<TypeInfo>&>
					("boost_extension_exported_type_map_function");
				if (func) {
					(*func)(types);
					return true;
				} else {
					return false;
				}
			}
			// If Doxygen is being run, use more readable definitions for the
			// documentation.
#ifdef BOOST_EXTENSION_DOXYGEN_INVOKED
			/** \brief Get a function reference.
			*
			* A templated function taking as template arguments the
			* type of the return value and parameters of a function
			* to look up in the shared library.
			*
			* This function must have been declared with the same
			* parameters and return type and marked as extern "C".
			*
			* Depending on platform and compiler settings, it may also
			* be necessary to prefix the function with BOOST_EXTENSION_DECL,
			* to make it externally visible.
			*
			* \warning If the function signature does not match, strange errors
			* can occur.
			* \pre is_open() == true.
			* \post None.
			*/
			template <class RetValue, class Params...>
			FunctionPtr<ReturnValue (Params...)>
				get(const std::string& name) const {
			}
#else
#define BOOST_PP_ITERATION_LIMITS (0, \
	BOOST_PP_INC(BOOST_EXTENSION_MAX_FUNCTOR_PARAMS) - 1)
#define BOOST_PP_FILENAME_1 "Core/Utils/extension/impl/shared_library.hpp"
#include BOOST_PP_ITERATE()
#endif
		protected:
			std::string location_;
			impl::library_handle handle_;
			bool auto_close_;
		};
	}  // namespace extensions
}  // namespace boost
#endif  // BOOST_EXTENSION_SHARED_LIBRARY_HPP
