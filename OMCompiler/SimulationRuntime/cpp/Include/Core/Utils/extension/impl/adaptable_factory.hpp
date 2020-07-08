/*
 * Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */


// No header guard - this file is intended to be included multiple times.

# define N BOOST_PP_ITERATION()

public:
template <class Interface, class Derived
          BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, class Param)>

private:
template <class Interface, class Derived
          BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, class Param)>
static Interface* create_func() {


}

template <class Interface, class Derived
          BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, class Param)>
static void check_func() {

}


template <class T BOOST_PP_COMMA_IF(N)  BOOST_PP_ENUM_PARAMS(N, class Param) >
class factory<T BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, Param) >
{
public:

  template <class D>
  void set() {
    this->func = &impl::create_function<
        T, D BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N,Param)
      >::create;
  }

  factory() : func(0) {}

  factory(factory<T> const& first) : func(first.func) {}

  factory& operator=(factory<T> const& first) {
    this->func = first->func;
    return *this;
  }

  bool is_valid() const { return this->func != 0; }

  T* create(BOOST_PP_ENUM_BINARY_PARAMS(N, Param, p)) const {
    if (this->func) {
      return this->func(BOOST_PP_ENUM_PARAMS(N, p));
    }
    else {
      return 0;
    }
  }

private:
  typedef T* (*func_ptr_type)(BOOST_PP_ENUM_PARAMS(N, Param));
  func_ptr_type func;
};

#undef N

