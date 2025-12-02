#ifndef UTIL_H
#define UTIL_H

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
    //     std::cout << '{' << printList({1, 2, 3}) << '}'; => {1,2,3}
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
  }
}

#endif /* UTIL_H */
