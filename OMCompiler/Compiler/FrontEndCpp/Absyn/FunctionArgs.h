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

#ifndef ABSYN_FUNCTIONARGS_H
#define ABSYN_FUNCTIONARGS_H

#include <memory>
#include <iosfwd>

#include "MetaModelica.h"

namespace OpenModelica::Absyn
{
  class Expression;

  class FunctionArgs
  {
    public:
      static constexpr int FUNCTIONARGS = 0;
      static constexpr int FOR_ITER_FARG = 1;

    public:
      class Base
      {
        public:
          virtual ~Base() = default;

          virtual std::unique_ptr<Base> clone() const noexcept = 0;
          virtual MetaModelica::Value toAbsyn() const noexcept = 0;
          virtual void print(std::ostream &os) const noexcept = 0;
      };

    public:
      FunctionArgs(MetaModelica::Record value);
      FunctionArgs(const FunctionArgs &other) noexcept;
      FunctionArgs(FunctionArgs &&other) = default;

      FunctionArgs& operator= (const FunctionArgs &other) noexcept;
      FunctionArgs& operator= (FunctionArgs &&other) = default;

      MetaModelica::Value toAbsyn() const noexcept;

      void print(std::ostream &os) const noexcept;

    private:
      std::unique_ptr<Base> _impl;
  };

  std::ostream& operator<< (std::ostream &os, const FunctionArgs &args) noexcept;
}

#endif /* ABSYN_FUNCTIONARGS_H */
