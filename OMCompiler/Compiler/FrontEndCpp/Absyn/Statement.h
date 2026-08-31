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

#ifndef ABSYN_STATEMENT_H
#define ABSYN_STATEMENT_H

#include <memory>
#include <string>
#include <string_view>
#include <optional>
#include <vector>
#include <utility>
#include <iosfwd>

#include "Comment.h"
#include "SourceInfo.h"
#include "Expression.h"

namespace OpenModelica::Absyn
{
  class StatementConcept;

  class Statement
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
      Statement(MetaModelica::Record value);
      Statement(const Statement &other) noexcept;
      Statement(Statement &&other) = default;

      Statement& operator= (const Statement &other) noexcept;
      Statement& operator= (Statement &&other) = default;

      MetaModelica::Value toSCode() const noexcept;
      static MetaModelica::Value toSCodeList(const std::vector<Statement> &stmts) noexcept;

      void print(std::ostream &os, std::string_view indent = {}) const noexcept;

    private:
      std::unique_ptr<Base> _impl;
  };

  std::ostream& operator<< (std::ostream &os, const Statement &stmt) noexcept;

  class AssignmentStatement : public Statement::Base
  {
    public:
      AssignmentStatement(MetaModelica::Record value);

      std::unique_ptr<Statement::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _lhs;
      Expression _rhs;
  };

  class IfStatement : public Statement::Base
  {
    public:
      using Branch = std::pair<Expression, std::vector<Statement>>;

    public:
      IfStatement(MetaModelica::Record value);

      std::unique_ptr<Statement::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      std::vector<Branch> _branches;
      std::vector<Statement> _else;
  };

  class ForStatement : public Statement::Base
  {
    public:
      ForStatement(MetaModelica::Record value, bool parallel = false);

      std::unique_ptr<Statement::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      std::string _iterator;
      std::optional<Expression> _range;
      std::vector<Statement> _body;
      bool _parallel;
  };

  class WhileStatement : public Statement::Base
  {
    public:
      WhileStatement(MetaModelica::Record value);

      std::unique_ptr<Statement::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _condition;
      std::vector<Statement> _body;
  };

  class WhenStatement : public Statement::Base
  {
    public:
      using Branch = std::pair<Expression, std::vector<Statement>>;

    public:
      WhenStatement(MetaModelica::Record value);

      std::unique_ptr<Statement::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      std::vector<Branch> _branches;
  };

  class AssertStatement : public Statement::Base
  {
    public:
      AssertStatement(MetaModelica::Record value);

      std::unique_ptr<Statement::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _condition;
      Expression _message;
      Expression _level;
  };

  class TerminateStatement : public Statement::Base
  {
    public:
      TerminateStatement(MetaModelica::Record value);

      std::unique_ptr<Statement::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _message;
  };

  class ReinitStatement : public Statement::Base
  {
    public:
      ReinitStatement(MetaModelica::Record value);

      std::unique_ptr<Statement::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _variable;
      Expression _exp;
  };

  class CallStatement : public Statement::Base
  {
    public:
      CallStatement(MetaModelica::Record value);

      std::unique_ptr<Statement::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _callExp;
  };

  class ReturnStatement : public Statement::Base
  {
    public:
      ReturnStatement(MetaModelica::Record value);

      std::unique_ptr<Statement::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;
  };

  class BreakStatement : public Statement::Base
  {
    public:
      BreakStatement(MetaModelica::Record value);

      std::unique_ptr<Statement::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os) const noexcept override;
  };
}

#endif /* ABSYN_STATEMENT_H */
