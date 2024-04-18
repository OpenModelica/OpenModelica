#ifndef SOURCEINFO_H
#define SOURCEINFO_H

#include "MetaModelica.h"
#include <string>
#include <iosfwd>

namespace OpenModelica
{
  class SourceInfo
  {
    public:
      SourceInfo() noexcept;
      SourceInfo(MetaModelica::Record value);
      SourceInfo(std::string filename, bool readonly, int64_t line_start, int64_t column_start,
          int64_t line_end, int64_t column_end, double modified) noexcept;

      operator MetaModelica::Value() const noexcept;

      static const SourceInfo& dummyInfo() noexcept;

      const std::string& filename() const noexcept { return _filename; }
      bool isReadOnly() const noexcept { return _isReadOnly; }
      int64_t lineNumberStart() const noexcept { return _lineNumberStart; }
      int64_t lineNumberEnd() const noexcept { return _lineNumberEnd; }
      int64_t columnNumberStart() const noexcept { return _columnNumberStart; }
      int64_t columnNumberEnd() const noexcept { return _columnNumberEnd; }

    private:
      std::string _filename;
      bool _isReadOnly;
      int64_t _lineNumberStart;
      int64_t _columnNumberStart;
      int64_t _lineNumberEnd;
      int64_t _columnNumberEnd;
      double _lastModification;
  };

  std::ostream& operator<< (std::ostream &os, const SourceInfo &info) noexcept;
}

#endif /* SOURCEINFO_H */
