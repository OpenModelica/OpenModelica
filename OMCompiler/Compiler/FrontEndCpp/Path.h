#ifndef PATH_H
#define PATH_H

#include <string>
#include <vector>
#include <iosfwd>

#include "MetaModelica.h"

namespace OpenModelica
{
  class Path
  {
    public:
      Path(std::vector<std::string> path, bool fullyQualified = false);
      Path(MetaModelica::Record value);

      void push_back(std::string name) noexcept;
      void pop_back() noexcept;

      bool isIdent() const noexcept;
      bool isQualified() const noexcept;
      bool isFullyQualified() const noexcept;

      const std::string& front() const noexcept;
      const std::string& back() const noexcept;
      Path rest() const noexcept;
      std::pair<std::string, Path> splitFront() const noexcept;
      std::pair<Path, std::string> splitBack() const noexcept;
      Path fullyQualify() const noexcept;
      Path unqualify() const noexcept;

      std::string str() const noexcept;

      friend std::ostream& operator<< (std::ostream &os, const Path &path) noexcept;

    private:
      std::vector<std::string> _names;
      bool _fullyQualified;
  };

  std::ostream& operator<< (std::ostream &os, const Path &path) noexcept;
}

#endif /* PATH_H */
