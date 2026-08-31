/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#pragma once
#ifndef id8073C0EB_D490_45E7_9F4AE20BF9C28736
#define id8073C0EB_D490_45E7_9F4AE20BF9C28736

/*
 Mahder.Gebremedhin@liu.se  2020-10-12
*/

#include <algorithm>
#include <iostream>
#include <set>
#include <sstream>
#include <vector>

#ifdef _MSC_VER
#define NOMINMAX
#endif

namespace openmodelica { namespace parmodelica { namespace utility {

extern std::ostringstream log_stream;
std::ostream&             log(const char* pref);
std::ostream&             log();

extern std::ostringstream warning_stream;
std::ostream&             warning(const char* pref);
std::ostream&             warning();

extern std::ostringstream error_stream;
std::ostream&             error(const char* pref);
std::ostream&             error();

// debug only log
void indexed_dlog(int index, const std::string& message);
void eq_index_error(int index, const std::string& message);
void eq_index_fatal(int index, const std::string& message);

template <typename InputIterator1, typename InputIterator2>
bool has_intersection(InputIterator1 first1, InputIterator1 last1, InputIterator2 first2, InputIterator2 last2) {
    for (; first1 != last1; ++first1) {
        std::set<std::string>::iterator loc = std::find(first2, last2, (*first1));
        if (loc != last2) {
            return true;
        }
    }

    return false;
}

/* Slow. Use has_intersection instead. */
template <typename SetType>
bool set_find_anyof(const SetType& InSet1, const SetType& InSet2) {

    for (typename SetType::const_iterator iter = InSet1.begin(); iter != InSet1.end(); ++iter) {
        typename SetType::const_iterator loc = std::find(InSet2.begin(), InSet2.end(), (*iter));
        if (loc != InSet2.end()) {
            return true;
        }
    }

    return false;
}

template <typename T>
class pm_vector {
  protected:
    std::vector<T> int_vector;

  public:
    pm_vector(){};
    pm_vector(int i, T p) : int_vector(i, p){};

    typedef typename std::vector<T>::value_type             value_type;
    typedef typename std::vector<T>::iterator               iterator;
    typedef typename std::vector<T>::const_iterator         const_iterator;
    typedef typename std::vector<T>::reverse_iterator       reverse_iterator;
    typedef typename std::vector<T>::const_reverse_iterator const_reverse_iterator;
    typedef typename std::vector<T>::reference              reference;
    typedef typename std::vector<T>::const_reference        const_reference;
    typedef typename std::vector<T>::size_type              size_type;

    std::vector<T>& get_vector() { return int_vector; };

    size_type size() const { return int_vector.size(); }
    size_type capacity() const { return int_vector.capacity(); }
    bool      empty() const { return int_vector.empty(); }

    void resize(size_type n, value_type val = value_type()) { int_vector.resize(n, val); }

    iterator       begin() { return int_vector.begin(); }
    const_iterator begin() const { return int_vector.begin(); }

    iterator       end() { return int_vector.end(); }
    const_iterator end() const { return int_vector.end(); }

    reverse_iterator       rbegin() { return int_vector.rbegin(); }
    const_reverse_iterator rbegin() const { return int_vector.rbegin(); }

    reverse_iterator       rend() { return int_vector.rend(); }
    const_reverse_iterator rend() const { return int_vector.rend(); }

    void push_back(const_reference p) { int_vector.push_back(p); };
    void push_front(const_reference p) { int_vector.push_front(p); };

    reference       back() { return int_vector.back(); }
    const_reference back() const { return int_vector.back(); }

    reference       front() { return int_vector.front(); }
    const_reference front() const { return int_vector.front(); }

    template <class InputIterator>
    void insert(iterator pos, InputIterator first, InputIterator last) {
        return int_vector.insert(pos, first, last);
    }

    iterator insert(iterator pos, const T& val) { return int_vector.insert(pos, val); }
    iterator erase(iterator pos) { return int_vector.erase(pos); }

    void clear() { int_vector.clear(); }

    reference       operator[](const size_type index) { return int_vector[index]; }
    const_reference operator[](const size_type index) const { return int_vector[index]; }

    reference       at(const size_type index) { return int_vector[index]; }
    const_reference at(const size_type index) const { return int_vector[index]; }
};

}}} // namespace openmodelica::parmodelica::utility

#endif // header
