/*
 * Boost.Extension / typeinfo:
 *         implementations name management with RTTI
 *
 * (C) Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */


#ifndef BOOST_EXTENSION_TYPEINFO_HPP
#define BOOST_EXTENSION_TYPEINFO_HPP
#include <typeinfo>
namespace boost { namespace extensions {
template <class TypeInfo, class ClassType>
struct type_info_handler {
  static TypeInfo get_class_type();
};

class default_type_info {
public:
  default_type_info() : type_(&typeid(void)) {
  }
  default_type_info(const std::type_info& new_type) : type_(&new_type) {
  }
  default_type_info(const default_type_info& first) : type_(first.type_) {
  }
  const std::type_info& type() const {
    return *type_;
  }
  default_type_info& operator=(const default_type_info& first) {
    type_ = first.type_;
    return *this;
  }
private:
  const std::type_info* type_;
};
template <class ClassType>
struct type_info_handler<default_type_info, ClassType>
{
  static default_type_info get_class_type() {
    return default_type_info(typeid(ClassType));
  }
};
}}



#if defined(__MINGW32__) || defined(__GNUC__)
#include <cstring>
namespace boost { namespace extensions {
inline bool operator<(const default_type_info& first,
               const default_type_info& second) {
  return std::strcmp(first.type().name(), second.type().name()) < 0;
}

inline bool operator==(const default_type_info& first,
               const default_type_info& second) {
  return std::strcmp(first.type().name(), second.type().name()) == 0;
}

inline bool operator>(const default_type_info& first,
               const default_type_info& second) {
  return std::strcmp(first.type().name(), second.type().name()) > 0;
}
}}
#else
// This list should be expanded to all platforms that successfully
// compare type_info across shared library boundaries.
#if defined(__APPLE__) || \
    defined(BOOST_EXTENSION_FORCE_FAST_TYPEINFO)
namespace boost {
namespace extensions {
inline bool operator<(const default_type_info& first,
               const default_type_info& second) {
  return &first.type() < &second.type();
}

inline bool operator==(const default_type_info& first,
               const default_type_info& second) {
  return &first.type() == &second.type();
}

inline bool operator>(const default_type_info& first,
               const default_type_info& second) {
  return &first.type() > &second.type();
}
}}
#else
#if defined(_WIN32) || defined(__WIN32__) || defined(WIN32)
#include <string>
namespace boost { namespace extensions {
inline bool operator<(const default_type_info& first,
               const default_type_info& second) {
  return std::strcmp(first.type().raw_name(), second.type().raw_name()) < 0;
}

inline bool operator==(const default_type_info& first,
               const default_type_info& second) {
  return std::strcmp(first.type().raw_name(), second.type().raw_name()) == 0;
}

inline bool operator>(const default_type_info& first,
               const default_type_info& second) {
  return std::strcmp(first.type().raw_name(), second.type().raw_name()) > 0;
}
}  // namespace extensions
}  // namespace boost
#else  // OTHER OS
#include <string>
namespace boost { namespace extensions {
inline bool operator<(const default_type_info& first,
               const default_type_info& second) {
  return std::strcmp(first.type().name(), second.type().name()) < 0;
}

inline bool operator==(const default_type_info& first,
               const default_type_info& second) {
  return std::strcmp(first.type().name(), second.type().name()) == 0;
}

inline bool operator>(const default_type_info& first,
               const default_type_info& second) {
  return std::strcmp(first.type().name(), second.type().name()) > 0;
}
}  // namespace extensions
}  // namespace boost
#endif
#endif  // WINDOWS
#endif  // OS X
#endif  // BOOST_EXTENSION_TYPEINFO_HPP
