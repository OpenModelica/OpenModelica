/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef UTIL_H
#define UTIL_H

#include <cstdint>
#include <iterator>
#include <string_view>
#include <ostream>
#include <vector>

namespace OpenModelica
{
  namespace Util
  {
    // Utility class to simplify printing a container as a delimited list.
    // Ex: std::cout << printList({1, 2, 3}, "+"); => 1+2+3
    //     std::cout << '{' << printList({1, 2, 3}) << '}'; => {1, 2, 3}
    template<typename Iterator>
    struct printList
    {
      template<typename Container>
      printList(const Container &container, std::string_view delimiter = ", ")
        : _first{std::begin(container)}, _last{std::end(container)}, _delimiter{delimiter} {}

      printList(Iterator first, Iterator last, std::string_view delimiter = ", ")
        : _first{std::move(first)}, _last{std::move(last)}, _delimiter{delimiter} {}

      Iterator _first;
      Iterator _last;
      std::string_view _delimiter;
    };

    // Deduction guide to allow the container constructor to work.
    template<typename Container>
    printList(const Container &container, std::string_view = ", ") -> printList<typename Container::const_iterator>;

    template<typename Iterator>
    std::ostream& operator<< (std::ostream &os, printList<Iterator> printer)
    {
      if (printer._first != printer._last) {
        os << *printer._first;
        ++printer._first;
      }

      while (printer._first != printer._last) {
        os << printer._delimiter << *printer._first;
        ++printer._first;
      }

      return os;
    }

    template<typename Container>
    void printPtrList(std::ostream &os, const Container &container, std::string_view delimiter = ", ")
    {
      auto first = std::begin(container);
      auto last = std::end(container);

      if (first != last) {
        os << **first;
        ++first;
      }

      while (first != last) {
        os << delimiter << **first;
        ++first;
      }
    }

    template<typename T>
    std::vector<T> cloneVector(const std::vector<T> &v)
    {
      std::vector<T> res;
      res.reserve(v.size());
      for (const auto &e: v) res.emplace_back(e->clone());
      return res;
    }

    template<typename T>
    inline void hashCombine(std::size_t &seed, const T &v)
    {
      // Magic numbers from boost::hash_combine.
      const std::uint64_t m = 0xe9846af9b1a615d;
      seed += 0x9e3779b9 + std::hash<T>{}(v);
      seed ^= seed >> 32;
      seed *= m;
      seed ^= seed >> 32;
      seed *= m;
      seed ^= seed >> 28;
    }
  }
}

#endif /* UTIL_H */
