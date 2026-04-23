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
