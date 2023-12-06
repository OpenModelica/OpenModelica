#include <ostream>

#include "SourceInfo.h"

using namespace OpenModelica;

extern record_description SourceInfo_SOURCEINFO__desc;

SourceInfo::SourceInfo() noexcept
  : _isReadOnly{false}, _lineNumberStart{0}, _columnNumberStart{0},
    _lineNumberEnd{0}, _columnNumberEnd{0}, _lastModification{0.0}
{

}

SourceInfo::SourceInfo(MetaModelica::Record value)
  : _filename{value[0].toString()}, _isReadOnly{value[1].toBool()},
    _lineNumberStart{value[2].toInt()}, _columnNumberStart{value[3].toInt()},
    _lineNumberEnd{value[4].toInt()}, _columnNumberEnd{value[5].toInt()},
    _lastModification{0.0}
{

}

SourceInfo::SourceInfo(std::string filename, bool readonly, int64_t line_start, int64_t column_start,
    int64_t line_end, int64_t column_end, double modified) noexcept
  : _filename{filename}, _isReadOnly{readonly},
    _lineNumberStart{line_start}, _columnNumberStart{column_start},
    _lineNumberEnd{line_end}, _columnNumberEnd{column_end},
    _lastModification{modified}
{

}

SourceInfo::operator MetaModelica::Value() const noexcept
{
  return MetaModelica::Record{0, SourceInfo_SOURCEINFO__desc, {
    MetaModelica::Value{_filename},
    MetaModelica::Value{_isReadOnly},
    MetaModelica::Value{_lineNumberStart},
    MetaModelica::Value{_columnNumberStart},
    MetaModelica::Value{_lineNumberEnd},
    MetaModelica::Value{_columnNumberEnd},
    MetaModelica::Value{_lastModification}
  }};
}

const SourceInfo& SourceInfo::dummyInfo() noexcept
{
  static SourceInfo info{"", false, 0, 0, 0, 0, 0.0};
  return info;
}

std::ostream& OpenModelica::operator<< (std::ostream &os, const SourceInfo &info) noexcept
{
  os << '[' << info.filename() << ':'
     << info.lineNumberStart() << ':'
     << info.columnNumberStart() << '-'
     << info.lineNumberEnd() << ':'
     << info.columnNumberEnd() << ':'
     << (info.isReadOnly() ? "readonly" : "writable") << ']';
  return os;
}
