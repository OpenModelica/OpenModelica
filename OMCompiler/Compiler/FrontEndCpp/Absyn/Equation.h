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

#ifndef ABSYN_EQUATION_H
#define ABSYN_EQUATION_H

#include <memory>
#include <string>
#include <string_view>
#include <iosfwd>

#include "Expression.h"
#include "Comment.h"
#include "SourceInfo.h"

namespace OpenModelica::Absyn
{
  class Equation
  {
    public:
      class Base
      {
        public:
          Base(Comment comment, SourceInfo info);
          virtual ~Base() = default;

          virtual std::unique_ptr<Base> clone() const noexcept = 0;
          virtual MetaModelica::Value toSCode() const noexcept = 0;
          virtual void print(std::ostream &os) const noexcept = 0;

        protected:
          Comment _comment;
          SourceInfo _info;
      };

    public:
      Equation(MetaModelica::Record value);
      Equation(const Equation &other) noexcept;
      Equation(Equation &&other) = default;

      Equation& operator= (const Equation &other) noexcept;
      Equation& operator= (Equation &&other) = default;

      MetaModelica::Value toSCode() const noexcept;
      static MetaModelica::Value toSCodeList(const std::vector<Equation> &eqs) noexcept;

      void print(std::ostream &os, std::string_view indent = {}) const noexcept;

    private:
      std::unique_ptr<Base> _impl;
  };

  std::ostream& operator<< (std::ostream &os, const Equation &eq) noexcept;

  class EqualityEquation : public Equation::Base
  {
    public:
      EqualityEquation(MetaModelica::Record value);

      std::unique_ptr<Equation::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _lhs;
      Expression _rhs;
  };

  class IfEquation : public Equation::Base
  {
    public:
      using Branch = std::pair<Expression, std::vector<Equation>>;

    public:
      IfEquation(MetaModelica::Record value);

      std::unique_ptr<Equation::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      std::vector<Branch> _branches;
      std::vector<Equation> _else;
  };

  class ConnectEquation : public Equation::Base
  {
    public:
      ConnectEquation(MetaModelica::Record value);

      std::unique_ptr<Equation::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _lhs;
      Expression _rhs;
  };

  class ForEquation : public Equation::Base
  {
    public:
      ForEquation(MetaModelica::Record value);

      std::unique_ptr<Equation::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      std::string _iterator;
      std::optional<Expression> _range;
      std::vector<Equation> _body;
  };

  class WhenEquation : public Equation::Base
  {
    public:
      using Branch = std::pair<Expression, std::vector<Equation>>;

    public:
      WhenEquation(MetaModelica::Record value);

      std::unique_ptr<Equation::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      std::vector<Branch> _branches;
  };

  class AssertEquation : public Equation::Base
  {
    public:
      AssertEquation(MetaModelica::Record value);

      std::unique_ptr<Equation::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _condition;
      Expression _message;
      Expression _level;
  };

  class TerminateEquation : public Equation::Base
  {
    public:
      TerminateEquation(MetaModelica::Record value);

      std::unique_ptr<Equation::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _message;
  };

  class ReinitEquation : public Equation::Base
  {
    public:
      ReinitEquation(MetaModelica::Record value);

      std::unique_ptr<Equation::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _variable;
      Expression _exp;
  };

  class CallEquation : public Equation::Base
  {
    public:
      CallEquation(MetaModelica::Record value);

      std::unique_ptr<Equation::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _callExp;
  };
}

#endif /* ABSYN_EQUATION_H */
