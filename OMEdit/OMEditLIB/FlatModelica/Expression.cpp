/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <sstream>
#include <stdexcept>
#include <array>
#include <vector>

#include <QJsonArray>
#include <QJsonObject>
#include <QJsonDocument>

#include "ExpressionFuncs.h"
#include "Expression.h"

namespace FlatModelica
{
  constexpr uint64_t djb2_hash(const char *str)
  {
    uint64_t hash = 5381;

    while (auto c = *str++) {
      hash = hash*31 + c;
    }

    return hash;
  }

  constexpr uint64_t djb2_qHash(const QChar *str)
  {
    uint64_t hash = 5381;

    for (auto c = *str; !c.isNull(); c = *++str) {
      hash = hash*31 + c.unicode();
    }

    return hash;
  }

  struct Token
  {
    enum token_t {
      OPEN_PAREN,
      CLOSE_PAREN,
      OPEN_BRACE,
      CLOSE_BRACE,
      OPEN_BRACKET,
      CLOSE_BRACKET,
      COMMA,
      DOT,
      OPERATOR,
      ADD,
      SUB,
      MUL,
      DIV,
      POW,
      ADD_EW,
      SUB_EW,
      MUL_EW,
      DIV_EW,
      POW_EW,
      AND,
      OR,
      NOT,
      EQUAL,
      NEQUAL,
      LESS,
      LESSEQ,
      GREATER,
      GREATEREQ,
      DIGIT,
      INTEGER,
      REAL,
      STRING,
      IDENTIFIER,
      END_OF_DATA
    };

    std::string string() const
    {
      switch (type) {
        case OPEN_PAREN: return "(";
        case CLOSE_PAREN: return ")";
        case OPEN_BRACE: return "{";
        case CLOSE_BRACE: return "}";
        case OPEN_BRACKET: return "[";
        case CLOSE_BRACKET: return "]";
        case COMMA: return ",";
        case DOT: return ".";
        case ADD: return "+";
        case SUB: return "-";
        case MUL: return "*";
        case DIV: return "/";
        case POW: return "^";
        case ADD_EW: return ".+";
        case SUB_EW: return ".-";
        case MUL_EW: return ".*";
        case DIV_EW: return "./";
        case POW_EW: return ".^";
        case AND: return "and";
        case OR: return "or";
        case NOT: return "not";
        case EQUAL: return "==";
        case NEQUAL: return "<>";
        case LESS: return "<";
        case LESSEQ: return "<=";
        case GREATER: return ">";
        case GREATEREQ: return ">=";
        case STRING: return "\"";
        case END_OF_DATA: return "EOF";
        default: return data;
      }
    }

    bool isOperator() const
    {
      return type >= OPERATOR && type <= GREATEREQ;
    }

    token_t type;
    std::string data;
  };

  class Tokenizer
  {
    public:
      Tokenizer(std::string str)
        : _str(std::move(str)), _cur(_str.begin()), _next(_str.begin())
      {
        nextToken();
      }

      const Token& peekToken() const
      {
        return _token;
      }

      void popToken()
      {
        if (_cur == _str.cend()) {
          throw std::runtime_error("Tokenizer ran out of data");
        }

        _cur = _next;
        nextToken();
      }

    private:
      void nextToken()
      {
        _next = _cur;

        // Skip spaces
        while (_next != _str.cend() && *_next == ' ') {
          ++_next;
        }

        _token.type = peekTokenType();

        switch (_token.type) {
          case Token::OPERATOR:
            _token.type = readOperator();
            break;

          case Token::DIGIT:
            readNumber();
            break;

          case Token::STRING:
            readString();
            break;

          case Token::IDENTIFIER:
            if (*_next == '\'') {
              readQuotedIdentifier();
            } else {
              readIdentifier();
            }
            break;

          default:
            ++_next;
            break;
        }
      }

      Token::token_t peekTokenType()
      {
        if (_next == _str.cend()) {
          return Token::END_OF_DATA;
        }

        switch (*_next) {
          case '(': return Token::OPEN_PAREN;
          case ')': return Token::CLOSE_PAREN;
          case '{': return Token::OPEN_BRACE;
          case '}': return Token::CLOSE_BRACE;
          case '[': return Token::OPEN_BRACKET;
          case ']': return Token::CLOSE_BRACKET;
          case ',': return Token::COMMA;
          case '.': return Token::OPERATOR;
          case '+': return Token::OPERATOR;
          case '-': return Token::OPERATOR;
          case '*': return Token::OPERATOR;
          case '/': return Token::OPERATOR;
          case '^': return Token::OPERATOR;
          case '<': return Token::OPERATOR;
          case '>': return Token::OPERATOR;
          case '=': return Token::OPERATOR;
          case '"': return Token::STRING;
          case ' ':
            ++_next;
            return peekTokenType();
          case '0':
          case '1':
          case '2':
          case '3':
          case '4':
          case '5':
          case '6':
          case '7':
          case '8':
          case '9': return Token::DIGIT;

          default: return Token::IDENTIFIER;
        }
      }

      Token::token_t readOperator()
      {
        switch (*_next) {
          case '+': ++_next; return Token::ADD;
          case '-': ++_next; return Token::SUB;
          case '*': ++_next; return Token::MUL;
          case '/': ++_next; return Token::DIV;
          case '^': ++_next; return Token::POW;
          case '.':
            ++_next;

            if (_next != _str.cend()) {
              switch (*_next) {
                case '+': ++_next; return Token::ADD_EW;
                case '-': ++_next; return Token::SUB_EW;
                case '*': ++_next; return Token::MUL_EW;
                case '/': ++_next; return Token::DIV_EW;
                case '^': ++_next; return Token::POW_EW;
              }
            }

            return Token::DOT;

          case '<':
            ++_next;

            if (_next != _str.cend()) {
              switch (*_next) {
                case '>': ++_next; return Token::NEQUAL;
                case '=': ++_next; return Token::LESSEQ;
              }
            }

            return Token::LESS;

          case '>':
            ++_next;

            if (_next != _str.cend() && *_next == '=') {
              ++_next;
              return Token::GREATEREQ;
            }

            return Token::GREATER;

          case '=':
            ++_next;

            if (_next == _str.cend()) {
              throw std::runtime_error(std::string("readOperator unexpected end of data"));
            } else if (*_next == '=') {
              ++_next;
              return Token::EQUAL;
            }
            break;
        }

        throw std::runtime_error(std::string("readOperator got unknown operator ") + *_next);
      }

      void readDigits()
      {
        while (_next != _str.cend() && std::isdigit(*_next)) ++_next;
      }

      void readNumber()
      {
        auto start = _next;
        _token.type = Token::INTEGER;

        readDigits();

        if (_next != _str.cend() && *_next == '.') {
          _token.type = Token::REAL;
          ++_next;
          readDigits();
        }

        if (_next != _str.cend() && *_next == 'e') {
          _token.type = Token::REAL;
          ++_next;
          readDigits();
        }

        _token.data = std::string(start, _next);
      }

      void readString()
      {
        bool escaped = false;
        auto start = ++_next;

        for (; _next != _str.cend(); ++_next) {
          if (escaped) {
            escaped = false;
            continue;
          }

          if (*_next == '"') {
            auto end = _next;
            ++_next;
            _token.data = std::string(start, end);
            return;
          } else if (*_next == '\\') {
            escaped = true;
          }
        }

        throw std::runtime_error("Tokenizer got non-terminated string.");
      }

      void readQuotedIdentifier()
      {
        bool escaped = false;
        auto start = ++_next;

        for (; _next != _str.cend(); ++_next) {
          if (escaped) {
            escaped = false;
            continue;
          }

          if (*_next == '\'') {
            auto end = _next;
            ++_next;
            _token.data = std::string(start, end);
            return;
          } else if (*_next == '\\') {
            escaped = true;
          }
        }

        throw std::runtime_error("Tokenizer got non-terminated string.");
      }

      void readIdentifier()
      {
        bool escaped = false;
        auto start = _next;

        for (; _next != _str.cend(); ++_next) {
          if (escaped) {
            escaped = false;
            continue;
          }

          if (!((*_next >= 'a' && *_next <= 'z') || (*_next >= 'A' && *_next <= 'Z') ||
                (*_next >= '0' && *_next <= '9') || *_next == '_')) {
            break;
          }
        }

        _token.data = std::string(start, _next);

        if (_token.data == "and") {
          _token.type = Token::AND;
        } else if (_token.data == "or") {
          _token.type = Token::OR;
        } else if (_token.data == "not") {
          _token.type = Token::NOT;
        }
      }

    private:
      std::string _str;
      std::string::const_iterator _cur;
      std::string::const_iterator _next;
      Token _token;
  };

  class Operator
  {
    public:
      enum OpType
      {
        Add,
        Sub,
        Mul,
        Div,
        Pow,
        AddEW,
        SubEW,
        MulEW,
        DivEW,
        PowEW,
        And,
        Or,
        Equal,
        NotEqual,
        Less,
        LessEq,
        Greater,
        GreaterEq,
        Not,
        Unknown
      };

      Operator();
      Operator(const std::string &str);
      Operator(Token::token_t t);
      Operator(OpType op);

      OpType type() const { return _op; }
      const std::string& toString() const;

      void deserialize(const QJsonValue &value);
      QJsonValue serialize() const;

    private:
      OpType parse(const std::string &str);
      OpType parse(Token::token_t t);

    private:
      OpType _op;
  };

  class ExpressionBase
  {
    public:
      virtual ~ExpressionBase() = default;

      static std::unique_ptr<ExpressionBase> deserialize(const QJsonValue &value);
      virtual QJsonValue serialize() const = 0;

      virtual bool isInteger()    const { return false; }
      virtual bool isReal()       const { return false; }
      virtual bool isBoolean()    const { return false; }
      virtual bool isBooleanish() const { return false; }
      virtual bool isString()     const { return false; }
      virtual bool isArray()      const { return false; }
      virtual bool isCall()       const { return false; }
      virtual bool isEnum()       const { return false; }
      virtual bool isLiteral() const = 0;

      virtual std::unique_ptr<ExpressionBase> clone() const = 0;
      virtual Expression eval(const Expression::VariableEvaluator &var_eval, int recursion_level = 0) const = 0;

      virtual void print(std::ostream &os) const = 0;
  };

  class Integer : public ExpressionBase
  {
    public:
      Integer(int64_t value)
        : _value(value) {}

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Integer>(*this); }
      Expression eval(const Expression::VariableEvaluator&, int) const override { return Expression(_value); }

      bool isInteger() const override { return true; }
      bool isBooleanish() const override { return true; }
      bool isLiteral() const override { return true; }
      int64_t value() const { return _value; }

      void print(std::ostream &os) const override;
      QJsonValue serialize() const override;

      static Expression parse(Tokenizer &tokenizer);

    private:
      int64_t _value;
  };

  class Real : public ExpressionBase
  {
    public:
      Real(double value)
        : _value(value) {}

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Real>(*this); }
      Expression eval(const Expression::VariableEvaluator&, int) const override { return Expression(_value); }

      bool isReal() const override { return true; }
      bool isBooleanish() const override { return true; }
      bool isLiteral() const override { return true; }
      double value() const { return _value; }

      void print(std::ostream &os) const override;
      QJsonValue serialize() const override;

      static Expression parse(Tokenizer &tokenizer);

    private:
      double _value;
  };

  class Boolean : public ExpressionBase
  {
    public:
      Boolean(bool value)
        : _value(value) {}

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Boolean>(*this); }
      Expression eval(const Expression::VariableEvaluator&, int) const override { return Expression(_value); }

      bool isBoolean() const override { return true; }
      bool isBooleanish() const override { return true; }
      bool isLiteral() const override { return true; }
      bool value() const { return _value; }

      void print(std::ostream &os) const override;
      QJsonValue serialize() const override;

    private:
      bool _value;
  };

  class String : public ExpressionBase
  {
    public:
      String(std::string value)
        : _value(std::move(value)) {}

      String(const QJsonValue &value);

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<String>(*this); }
      Expression eval(const Expression::VariableEvaluator&, int) const override { return Expression(_value); }

      bool isString() const override { return true; }
      bool isLiteral() const override { return true; }
      const std::string& value() const { return _value; }

      void print(std::ostream &os) const override;
      QJsonValue serialize() const override;

      static Expression parse(Tokenizer &tokenizer);

    private:
      std::string _value;
  };

  class Enum : public ExpressionBase
  {
  public:
    Enum(std::string name, int index)
      : _name(std::move(name)), _index(index) {}

    Enum(const QJsonObject &value);

    std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Enum>(*this); }
    Expression eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const override;

    bool isEnum() const override { return true; }
    bool isLiteral() const override { return true; }
    const std::string& value() const { return _name; }
    int index() const { return _index; }
    void print(std::ostream &os) const override;
    QJsonValue serialize() const override;

  private:
    std::string _name;
    int _index;
  };

  class Cref : public ExpressionBase
  {
    public:
      Cref(std::string name)
        : _name(std::move(name)) {}

      Cref(const QJsonObject &value);

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Cref>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const override;

      bool isLiteral() const override { return false; }
      void print(std::ostream &os) const override;
      QJsonValue serialize() const override;

      static Expression parse(std::string first_ident, Tokenizer &tokenizer);

    private:
      std::string _name;
  };

  class Array : public ExpressionBase
  {
    public:
      Array(std::vector<Expression> elements)
        : _elements(std::move(elements)) {}

      Array(const QJsonArray &value);

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Array>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const override;

      bool isArray() const override { return true; }
      bool isLiteral() const override;
      const std::vector<Expression>& elements() const { return _elements; }

      void print(std::ostream &os) const override;
      QJsonValue serialize() const override;

      static Expression parse(Tokenizer &tokenizer);

    private:
      std::vector<Expression> _elements;
  };

  class Range : public ExpressionBase
  {
    public:
      Range(Expression start, Expression step, Expression stop)
        : _start(std::move(start)), _step(std::move(step)), _stop(std::move(stop)) {}

      Range(const QJsonObject &value);

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Range>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const override;

      bool isLiteral() const override;

      void print(std::ostream &os) const override;
      QJsonValue serialize() const override;

    private:
      Expression _start;
      Expression _step;
      Expression _stop;
  };

  class Call : public ExpressionBase
  {
    public:
      Call(std::string name, std::vector<Expression> args)
        : _name(std::move(name)), _args(std::move(args)), _is_record(false) {}

      Call(const QJsonObject &value, bool isRecord);

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Call>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const override;

      bool isCall() const override { return true; }
      bool isLiteral() const override { return false; }
      const std::string& name() const { return _name; }
      bool isNamed(const std::string &name) const { return _name == name; }
      const std::vector<Expression>& args() const { return _args; }
      void setArg(size_t index, const Expression &e);

      void print(std::ostream &os) const override;
      QJsonValue serialize() const override;

      static Expression parse(std::string name, Tokenizer &tokenizer);

    private:
      std::string _name;
      std::vector<Expression> _args;
      bool _is_record;
  };

  class Iterator
  {
    public:
      Iterator(std::string name, Expression range)
        : _name(std::move(name)), _range(std::move(range)) {}

      Iterator(const QJsonValue &value);

      const std::string& name() const { return _name; }
      const Expression& range() const { return _range; }

      QJsonValue serialize() const;

    private:
      std::string _name;
      Expression _range;
  };

  class IteratorCall : public ExpressionBase
  {
    public:
      IteratorCall(std::string name, Expression exp, std::vector<Iterator> iterators)
        : _name(std::move(name)), _exp(std::move(exp)), _iterators(std::move(iterators)) {}

      IteratorCall(const QJsonObject &value);

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<IteratorCall>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const override;

      bool isLiteral() const override { return false; }

      void print(std::ostream &os) const override;
      QJsonValue serialize() const override;

    private:
      std::string _name;
      Expression _exp;
      std::vector<Iterator> _iterators;
  };

  class Binary : public ExpressionBase
  {
    public:
      Binary(Expression e1, Operator op, Expression e2)
        : _e1(std::move(e1)), _op(op), _e2(std::move(e2)) {}

      Binary(const QJsonObject &value);

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Binary>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const override;

      bool isLiteral() const override { return false; }
      void print(std::ostream &os) const override;
      QJsonValue serialize() const override;

      static Expression parse(Expression e1, Tokenizer &tokenizer);

    private:
      Expression _e1;
      Operator _op;
      Expression _e2;
  };

  class Unary : public ExpressionBase
  {
    public:
      Unary(Operator op, Expression e)
        : _op(op), _e(std::move(e)) {}

      Unary(const QJsonObject &value);

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Unary>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const override;

      bool isLiteral() const override { return false; }
      void print(std::ostream &os) const override;
      QJsonValue serialize() const override;

      static Expression parse(Tokenizer &tokenizer);

    private:
      Operator _op;
      Expression _e;
  };

  class IfExp : public ExpressionBase
  {
    public:
      IfExp(Expression condition, Expression true_e, Expression false_e)
        : _condition(std::move(condition)), _true_e(std::move(true_e)),
          _false_e(std::move(false_e)) {}

      IfExp(const QJsonObject &value);

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<IfExp>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const override;

      bool isLiteral() const override { return false; }
      void print(std::ostream &os) const override;
      QJsonValue serialize() const override;

      static Expression parse(Tokenizer &tokenizer);

    private:
      Expression _condition;
      Expression _true_e;
      Expression _false_e;
  };

  Operator::Operator()
    : _op(Unknown)
  {
  }

  Operator::Operator(const std::string &str)
    : _op(parse(str))
  {
  }

  Operator::Operator(Token::token_t t)
    : _op(parse(t))
  {
  }

  Operator::Operator(OpType op)
    : _op(op)
  {
  }

  Operator::OpType Operator::parse(const std::string &str)
  {
    switch (str.size()) {
      case 1:
        switch (str[0]) {
          case '+': return Add;
          case '-': return Sub;
          case '*': return Mul;
          case '/': return Div;
          case '^': return Pow;
          case '<': return Less;
          case '>': return Greater;
        }
        break;

      case 2:
        if (str[0] == '.') {
          switch (str[1]) {
            case '+': return AddEW;
            case '-': return SubEW;
            case '*': return MulEW;
            case '/': return DivEW;
            case '^': return PowEW;
          }
        } else if (str[1] == '=') {
          switch (str[0]) {
            case '<': return LessEq;
            case '>': return GreaterEq;
            case '=': return Equal;
          }
        } else if (str == "<>") {
          return NotEqual;
        } else if (str == "or") {
          return Or;
        }
        break;

      case 3:
        if (str == "and") {
          return And;
        } else if (str == "not") {
          return Not;
        }
        break;
    }

    throw std::runtime_error("Operator::parse got invalid operator " + str);
  }

  Operator::OpType Operator::parse(Token::token_t t)
  {
    switch (t) {
      case Token::ADD: return Add;
      case Token::SUB: return Sub;
      case Token::MUL: return Mul;
      case Token::DIV: return Div;
      case Token::POW: return Pow;
      case Token::ADD_EW: return AddEW;
      case Token::SUB_EW: return SubEW;
      case Token::MUL_EW: return MulEW;
      case Token::DIV_EW: return DivEW;
      case Token::POW_EW: return PowEW;
      case Token::AND: return And;
      case Token::OR: return Or;
      case Token::EQUAL: return Equal;
      case Token::NEQUAL: return NotEqual;
      case Token::LESS: return Less;
      case Token::LESSEQ: return LessEq;
      case Token::GREATER: return Greater;
      case Token::GREATEREQ: return GreaterEq;
      default:
        throw std::runtime_error("Operator::parse got invalid token type");
    }
  }

  const std::string& Operator::toString() const
  {
    static const std::array<std::string, 20> symbols = {
      "+", "-", "*", "/", "^", ".+", ".-", ".*", "./", ".^", "and", "or", "==", "<>", "<", "<=", ">", ">=", "not", "?"
    };

    return symbols[static_cast<int>(_op)];
  }

  void Operator::deserialize(const QJsonValue &value)
  {
    if (!value.isString()) {
      throw std::runtime_error("Expression: invalid JSON binary operator: " + value.toString().toStdString());
    }

    _op = parse(value.toString().toStdString());
  }

  QJsonValue Operator::serialize() const
  {
    return toString().data();
  }

  std::ostream& operator<< (std::ostream &os, Operator op)
  {
    os << op.toString();
    return os;
  }

  Expression parseParentheses(Tokenizer &tokenizer);
  Expression parseIdentifierExp(Tokenizer &tokenizer);

  Expression parsePrimary(Tokenizer &tokenizer)
  {
    switch (tokenizer.peekToken().type) {
      case Token::OPEN_PAREN: return parseParentheses(tokenizer);
      case Token::OPEN_BRACE: return Array::parse(tokenizer);
      case Token::INTEGER:    return Integer::parse(tokenizer);
      case Token::REAL:       return Real::parse(tokenizer);
      case Token::STRING:     return String::parse(tokenizer);
      case Token::SUB:        return Unary::parse(tokenizer);
      case Token::NOT:        return Unary::parse(tokenizer);
      case Token::IDENTIFIER: return parseIdentifierExp(tokenizer);
      default:
        throw std::runtime_error("parsePrimary got unknown token " + tokenizer.peekToken().string());
    }
  }

  Expression parseExp_1(Tokenizer &tokenizer, Expression lhs, int priority);

  Expression parseExp(Tokenizer &tokenizer)
  {
    return parseExp_1(tokenizer, parsePrimary(tokenizer), 0);
  }

  int opPriority(Token::token_t op)
  {
    switch (op) {
      case Token::ADD: return 5;
      case Token::SUB: return 5;
      case Token::MUL: return 6;
      case Token::DIV: return 6;
      case Token::POW: return 7;
      case Token::ADD_EW: return 5;
      case Token::SUB_EW: return 5;
      case Token::MUL_EW: return 6;
      case Token::DIV_EW: return 6;
      case Token::POW_EW: return 7;
      case Token::AND: return 2;
      case Token::OR: return 1;
      default: return 4;
    }
  }

  Expression parseExp_1(Tokenizer &tokenizer, Expression lhs, int min_priority)
  {
    while (tokenizer.peekToken().isOperator() &&
           opPriority(tokenizer.peekToken().type) >= min_priority) {
      auto tok = tokenizer.peekToken();
      auto op = tok.type;
      tokenizer.popToken();
      auto rhs = parsePrimary(tokenizer);

      while (tokenizer.peekToken().isOperator() &&
             opPriority(tokenizer.peekToken().type) > opPriority(op)) {
        rhs = parseExp_1(tokenizer, std::move(rhs), opPriority(op) + 1);
      }

      lhs = Expression(std::make_unique<Binary>(std::move(lhs), op, std::move(rhs)));
    }

    return lhs;
  }

  Expression parseParentheses(Tokenizer &tokenizer)
  {
    auto tok = tokenizer.peekToken();
    if (tok.type != Token::OPEN_PAREN) {
      throw std::runtime_error("parseParentheses expected (, got " + tok.string());
    }
    tokenizer.popToken();

    Expression e = parseExp(tokenizer);

    tok = tokenizer.peekToken();
    if (tok.type != Token::CLOSE_PAREN) {
      throw std::runtime_error("parseParentheses expected ), got " + tok.string());
    }
    tokenizer.popToken();

    return e;
  }

  Expression parseIdentifierExp(Tokenizer &tokenizer)
  {
    auto tok = tokenizer.peekToken();
    if (tok.type != Token::IDENTIFIER) {
      throw std::runtime_error("parseIdentifierExp got unknown token " + tok.string());
    }
    tokenizer.popToken();

    if (tok.data == "true") {
      return Expression(true);
    } else if (tok.data == "false") {
      return Expression(false);
    } else if (tok.data == "if") {
      return IfExp::parse(tokenizer);
    } else if (tokenizer.peekToken().type == Token::OPEN_PAREN) {
      return Call::parse(tok.data, tokenizer);
    } else {
      return Cref::parse(tok.data, tokenizer);
    }
  }

  std::vector<Expression> parseCommaList(Tokenizer &tokenizer)
  {
    std::vector<Expression> elems;

    if (tokenizer.peekToken().type == Token::CLOSE_PAREN ||
        tokenizer.peekToken().type == Token::CLOSE_BRACE ||
        tokenizer.peekToken().type == Token::CLOSE_BRACKET) {
      return elems;
    }

    while (true) {
      elems.emplace_back(parseExp(tokenizer));

      if (tokenizer.peekToken().type == Token::COMMA) {
        tokenizer.popToken();
      } else {
        break;
      }
    }

    return elems;
  }

  void printCommaList(std::ostream &os, const std::vector<Expression> &expl)
  {
    for (auto it = expl.begin(); it != expl.end(); ++it) {
      if (it != expl.begin()) os << ",";
      os << *it;
    }
  }

  // Applies a unary operation to the elements of the given array Expression and
  // returns a new array Expression with the results.
  template<class UnaryOp>
  Expression expUnaryOp(const Expression &e, UnaryOp op)
  {
    auto &elems = e.elements();
    std::vector<Expression> res;
    res.reserve(elems.size());
    std::transform(elems.begin(), elems.end(), std::back_inserter(res), op);
    return Expression(std::move(res));
  }

  // Applies a binary operation to each pair of elements from the two given
  // array Expressions and returns a new array Expression with the results.
  // If the arrays do not have the same number of elements an error is thrown
  // using the given operator name.
  template<class BinOp>
  Expression expBinaryEWArrayOp(const Expression &e1, const Expression &e2, BinOp op, const std::string &op_name)
  {
    auto &elems1 = e1.elements();
    auto &elems2 = e2.elements();

    if (elems1.size() != elems2.size()) {
      throw std::runtime_error("Expression: invalid operation " + e1.toString() + " " + op_name + " " + e2.toString());
    }

    std::vector<Expression> elems;
    std::transform(elems1.begin(), elems1.end(), elems2.begin(), std::back_inserter(elems), op);
    return Expression(std::move(elems));
  }

  // Applies a binary operation to each combination of the given scalar and the
  // elements of the given array and returns a new array Expression with the
  // results.
  template<class BinOp>
  Expression expBinaryScalarArrayOp(const Expression &scalar, const Expression &arr, BinOp op)
  {
    if (arr.isArray()) {
      return expUnaryOp(arr, [&] (auto &e) {
        return expBinaryScalarArrayOp(scalar, e, op);
      });
    } else {
      return op(scalar, arr);
    }
  }

  // Applies a binary operation to each combination of the elements of the given
  // array and the given scalar and returns a new array Expression with the
  // results.
  template<class BinOp>
  Expression expBinaryArrayScalarOp(const Expression &arr, const Expression &scalar, BinOp op)
  {
    if (arr.isArray()) {
      return expUnaryOp(arr, [&] (auto &e) {
        return expBinaryScalarArrayOp(e, scalar, op);
      });
    } else {
      return op(scalar, arr);
    }
  }

  // Applies a binary operation element-wise to the two given Expressions, each
  // of which may be either an array or a scalar, and returns a new Expression
  // with the result. If the expressions are arrays with different number of
  // elements an error is thrown using the given operator name.
  template<class BinOp>
  Expression expBinaryEWOp(const Expression &e1, const Expression &e2, BinOp op, const std::string &op_name)
  {
    bool is_array1 = e1.isArray();
    bool is_array2 = e2.isArray();

    if (is_array1 && is_array2) {
      return expBinaryEWArrayOp(e1, e2, op, op_name);
    } else if (is_array1) {
      return expBinaryArrayScalarOp(e1, e2, op);
    } else if (is_array2) {
      return expBinaryScalarArrayOp(e1, e2, op);
    } else {
      return op(e1, e2);
    }
  }

  class json_error : public std::exception
  {
    public:
      json_error(const QString &msg, const QJsonValue &value)
      {
        QString err = msg;

        switch (value.type()) {
          case QJsonValue::Null:
            err += "null";
            break;

          case QJsonValue::Bool:
            err += value.toBool() ? "true" : "false";
            break;

          case QJsonValue::Double:
            err += QString::number(value.toDouble());
            break;

          case QJsonValue::String:
            err += value.toString();
            break;

          case QJsonValue::Array:
            err += QJsonDocument(value.toArray()).toJson();
            break;

          case QJsonValue::Object:
            err += QJsonDocument(value.toObject()).toJson();
            break;

          case QJsonValue::Undefined:
            err += "undefined";
            break;
        }

        _error = err.toStdString();
      }

      const char* what() const noexcept override { return _error.c_str(); }

    private:
      std::string _error;
  };

  std::unique_ptr<ExpressionBase> parseJsonNumber(const QJsonValue &value)
  {
    auto val = value.toDouble();

    if (val == std::trunc(val)) {
      return std::make_unique<Integer>(static_cast<int64_t>(val));
    }

    return std::make_unique<Real>(val);
  }

  std::unique_ptr<ExpressionBase> parseJsonObject(const QJsonObject &value)
  {
    auto kind = value["$kind"];

    if (kind.isString()) {
      switch (djb2_qHash(kind.toString().data())) {
        case djb2_hash("enum"):              return std::make_unique<Enum>(value);
        case djb2_hash("clock"):             return std::make_unique<Cref>(value);
        case djb2_hash("cref"):              return std::make_unique<Cref>(value);
        case djb2_hash("typename"):          return std::make_unique<Cref>(value);
        case djb2_hash("range"):             return std::make_unique<Range>(value);
        //case djb2_hash("tuple"):             return std::make_unique<Tuple>(value);
        case djb2_hash("record"):            return std::make_unique<Call>(value, true);
        case djb2_hash("call"):              return std::make_unique<Call>(value, false);
        case djb2_hash("iterator_call"):     return std::make_unique<IteratorCall>(value);
        case djb2_hash("binary_op"):         return std::make_unique<Binary>(value);
        case djb2_hash("unary_op"):          return std::make_unique<Unary>(value);
        case djb2_hash("if"):                return std::make_unique<IfExp>(value);
        //case djb2_hash("sub"):               return std::make_unique<Subscripted>(value);
        //case djb2_hash("tuple_element"):     return std::make_unique<TupleElement>(value);
        //case djb2_hash("record_element"):    return std::make_unique<RecordElement>(value);
        //case djb2_hash("function"):          return std::make_unique<Function>(value);
      }
    }

    throw json_error("Expression: unsupported JSON object ", value);
    return nullptr;
  }

  std::unique_ptr<ExpressionBase> ExpressionBase::deserialize(const QJsonValue &value)
  {
    switch (value.type()) {
      case QJsonValue::Bool:   return std::make_unique<Boolean>(value.toBool());
      case QJsonValue::Double: return parseJsonNumber(value);
      case QJsonValue::String: return std::make_unique<String>(value);
      case QJsonValue::Array:  return std::make_unique<Array>(value.toArray());
      case QJsonValue::Object: return parseJsonObject(value.toObject());
      default: break;
    }

    throw json_error("Expression: unsupported JSON value ", value);
  }

  void Integer::print(std::ostream &os) const
  {
    os << _value;
  }

  QJsonValue Integer::serialize() const
  {
    return {static_cast<qint64>(_value)};
  }

  Expression Integer::parse(Tokenizer &tokenizer)
  {
    int64_t i;
    auto tok = tokenizer.peekToken();
    std::istringstream ss(tok.data);
    ss >> i;
    tokenizer.popToken();
    return Expression(i);
  }

  void Real::print(std::ostream &os) const
  {
    os << _value;
  }

  QJsonValue Real::serialize() const
  {
    return {_value};
  }

  Expression Real::parse(Tokenizer &tokenizer)
  {
    double d;
    auto tok = tokenizer.peekToken();
    std::istringstream ss(tok.data);
    ss >> d;
    tokenizer.popToken();
    return Expression(d);
  }

  QJsonValue Boolean::serialize() const
  {
    return _value;
  }

  void Boolean::print(std::ostream &os) const
  {
    os << (_value ? "true" : "false");
  }

  String::String(const QJsonValue &value)
    : String(value.toString().toStdString())
  {

  }

  void String::print(std::ostream &os) const
  {
    os << '"' << _value << '"';
  }

  QJsonValue String::serialize() const
  {
    return _value.data();
  }

  Expression String::parse(Tokenizer &tokenizer)
  {
    auto tok = tokenizer.peekToken();
    tokenizer.popToken();
    return Expression(tok.data);
  }

  Enum::Enum(const QJsonObject &value)
  {
    _name = value["name"].toString().toStdString();
    _index = value["index"].toInt();
  }

  Expression Enum::eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const
  {
    Q_UNUSED(var_eval);
    Q_UNUSED(recursion_level);
    return Expression(_name, _index);
  }

  void Enum::print(std::ostream &os) const
  {
    os << _name;
  }

  QJsonValue Enum::serialize() const
  {
    return QJsonObject{
      {"$kind", "enum"},
      { "name", QString::fromStdString(_name)},
      {"index", _index}
    };
  }

  Cref::Cref(const QJsonObject &value)
  {
    auto const parts = value["parts"];

    if (!parts.isArray()) {
      throw json_error("Expression: invalid JSON component reference: ", value);
    }

    auto const parts_array = parts.toArray();

    for (const auto &part: parts_array) {
      auto part_obj = part.toObject();
      auto name = part_obj["name"];

      if (!name.isString()) {
        throw json_error("Expression: invalid JSON component reference part: ", part);
      }

      if (!_name.empty()) {
        _name += '.';
      }

      _name += name.toString().toStdString();

      auto const subs = part_obj["subscripts"].toArray();

      if (!subs.empty()) {
        std::string subs_str;

        for (const auto& sub: subs) {
          if (!subs_str.empty()) {
            subs_str += ",";
          }

          if (sub.isString()) {
            subs_str += sub.toString().toStdString();
          } else {
            Expression sub_exp;
            sub_exp.deserialize(sub);
            subs_str += sub_exp.toString();
          }
        }

        _name += '[' + subs_str + ']';
      }
    }
  }

  Expression Cref::eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const
  {
    if (recursion_level > 100) {
      throw std::runtime_error("Recursion limit reached");
    }

    return var_eval(_name).evaluate(var_eval, recursion_level + 1);
  }

  void Cref::print(std::ostream &os) const
  {
    os << _name;
  }

  QJsonValue Cref::serialize() const
  {
    return QJsonObject{
      {"$kind", "cref"},
      {"parts", QJsonArray{{QJsonObject{{"name", _name.data()}}}}}
    };
  }

  Expression Cref::parse(std::string first_ident, Tokenizer &tokenizer)
  {
    std::ostringstream ss;
    ss << first_ident;

    while (true) {
      auto t = tokenizer.peekToken();

      if (t.type == Token::OPEN_BRACKET) {
        tokenizer.popToken();
        ss << "[";
        printCommaList(ss, parseCommaList(tokenizer));
        ss << "]";

        auto tok = tokenizer.peekToken();
        if (tok.type != Token::CLOSE_BRACKET) {
          throw std::runtime_error("Cref::parse expected ], got " + tok.string());
        }
        tokenizer.popToken();
      } else if (t.type == Token::DOT) {
        ss << '.';
        tokenizer.popToken();

        auto tok = tokenizer.peekToken();
        if (tok.type != Token::IDENTIFIER) {
          throw std::runtime_error("Cref::parse expected identifier, got " + tok.string());
        }
        tokenizer.popToken();

        ss << tok.data;
      } else {
        break;
      }
    }

    return Expression(std::make_unique<Cref>(ss.str()));
  }

  Array::Array(const QJsonArray &value)
  {
    for (const auto &e: value) {
      _elements.emplace_back(ExpressionBase::deserialize(e));
    }
  }

  Expression Array::eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const
  {
    std::vector<Expression> elems;
    elems.reserve(_elements.size());

    for (auto &e: _elements) {
      elems.emplace_back(e.evaluate(var_eval, recursion_level));
    }

    return Expression(std::move(elems));
  }

  bool Array::isLiteral() const
  {
    return std::any_of(_elements.begin(), _elements.end(),
      [] (const Expression &e) {
        return e.isLiteral();
      }
    );
  }

  void Array::print(std::ostream &os) const
  {
    os << '{';
    printCommaList(os, _elements);
    os << '}';
  }

  QJsonValue Array::serialize() const
  {
    QJsonArray arr;

    for (auto &e: _elements) {
      arr.push_back(e.serialize());
    }

    return {std::move(arr)};
  }

  Expression Array::parse(Tokenizer &tokenizer)
  {
    auto tok = tokenizer.peekToken();
    if (tok.type != Token::OPEN_BRACE) {
      throw std::runtime_error("Array::parse expected {, got " + tok.string());
    }
    tokenizer.popToken();

    auto elems = parseCommaList(tokenizer);

    tok = tokenizer.peekToken();
    if (tok.type != Token::CLOSE_BRACE) {
      throw std::runtime_error("Array::parse expected }, got " + tok.string());
    }
    tokenizer.popToken();

    return Expression(std::move(elems));
  }

  Range::Range(const QJsonObject &value)
  {
    auto start = value.find("start");

    if (start == value.end()) {
      throw json_error("Expression: missing range start in ", value);
    }

    _start.deserialize(*start);

    auto stop = value.find("stop");

    if (stop == value.end()) {
      throw json_error("Expression: missing range stop in ", value);
    }

    _stop.deserialize(*stop);

    auto step = value.find("step");

    if (step != value.end()) {
      _step.deserialize(*step);
    }
  }

  Expression Range::eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const
  {
    auto start = _start.evaluate(var_eval, recursion_level);
    auto stop = _stop.evaluate(var_eval, recursion_level);
    auto step = _step.isNull() ? Expression() : _step.evaluate(var_eval, recursion_level);
    return Expression(std::make_unique<Range>(std::move(start), std::move(step), std::move(stop)));
  }

  bool Range::isLiteral() const
  {
    return _start.isLiteral() && _step.isLiteral() && _stop.isLiteral();
  }

  void Range::print(std::ostream &os) const
  {
    os << _start << ':';

    if (!_step.isNull()) {
      os << _step << ':';
    }

    os << _stop;
  }

  QJsonValue Range::serialize() const
  {
    QJsonObject obj;
    obj.insert("$kind", "range");
    obj.insert("start", _start.serialize());

    if (!_step.isNull()) {
      obj.insert("step", _step.serialize());
    }

    obj.insert("stop", _stop.serialize());
    return obj;
  }

  Call::Call(const QJsonObject &value, bool isRecord)
    : _is_record(isRecord)
  {
    auto name = value["name"];

    if (!name.isString()) {
      throw json_error("Expression: invalid JSON function call name: ", name);
    }

    _name = name.toString().toStdString();

    auto args = value[isRecord ? "elements" : "arguments"];

    if (!args.isArray()) {
      throw json_error("Expression: invalid JSON function call arguments: ", args);
    }

    for (const auto &e: args.toArray()) {
      _args.emplace_back(ExpressionBase::deserialize(e));
    }
  }

  Expression Call::eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const
  {
    std::vector<Expression> args;
    args.reserve(_args.size());

    for (auto &a: _args) {
      args.emplace_back(a.evaluate(var_eval, recursion_level));
    }

    switch (djb2_hash(_name.c_str())) {
      // 3.7.1
      case djb2_hash("abs"): return evalAbs(args[0]);
      case djb2_hash("sign"): return evalSign(args[0]);
      case djb2_hash("sqrt"): return evalSqrt(args[0]);
      case djb2_hash("String"): return evalString(args);
      // 3.7.2
      case djb2_hash("div"): return evalDiv(args[0], args[1]);
      case djb2_hash("mod"): return evalDiv(args[0], args[1]);
      case djb2_hash("rem"): return evalDiv(args[0], args[1]);
      case djb2_hash("ceil"): return evalCeil(args[0]);
      case djb2_hash("floor"): return evalFloor(args[0]);
      case djb2_hash("integer"): return evalInteger(args[0]);
      // 3.7.3
      case djb2_hash("sin"): return evalSin(args[0]);
      case djb2_hash("cos"): return evalCos(args[0]);
      case djb2_hash("tan"): return evalTan(args[0]);
      case djb2_hash("asin"): return evalAsin(args[0]);
      case djb2_hash("acos"): return evalAcos(args[0]);
      case djb2_hash("atan"): return evalAtan(args[0]);
      case djb2_hash("atan2"): return evalAtan2(args[0], args[1]);
      case djb2_hash("sinh"): return evalSinh(args[0]);
      case djb2_hash("cosh"): return evalCosh(args[0]);
      case djb2_hash("tanh"): return evalTanh(args[0]);
      case djb2_hash("exp"): return evalExp(args[0]);
      case djb2_hash("log"): return evalLog(args[0]);
      case djb2_hash("log10"): return evalLog10(args[0]);
      // 3.7.5
      case djb2_hash("noEvent"): return args[0];
      case djb2_hash("smooth"): return args[0];
      // 10.3.1
      case djb2_hash("ndim"): return evalNdim(args[0]);
      case djb2_hash("size"): return args.size() == 2 ? evalSize(args[0], args[1]) : evalSize(args[0]);
      // 10.3.2
      case djb2_hash("scalar"): return evalScalar(args[0]);
      case djb2_hash("vector"): return evalVector(args[0]);
      case djb2_hash("matrix"): return evalMatrix(args[0]);
      // 10.3.3
      case djb2_hash("identity"): return evalIdentity(args[0]);
      case djb2_hash("diagonal"): return evalDiagonal(args[0]);
      case djb2_hash("zeros"): return evalZeros(args);
      case djb2_hash("ones"): return evalOnes(args);
      case djb2_hash("fill"): return evalFill(args);
      // 10.3.4
      case djb2_hash("min"): return args.size() == 2 ? evalMin(args[0], args[1]) : evalMin(args[0]);
      case djb2_hash("max"): return args.size() == 2 ? evalMax(args[0], args[1]) : evalMin(args[0]);
      case djb2_hash("sum"): return evalSum(args[0]);
      case djb2_hash("product"): return evalProduct(args[0]);
      // 10.3.5
      // outerProduct, cross and skew are simplified away by the frontend.
      case djb2_hash("transpose"): return evalTranspose(args[0]);
      case djb2_hash("symmetric"): return evalSymmetric(args[0]);
      // 10.4.2
      case djb2_hash("cat"): return evalCat(args);
    }

    return Expression(std::make_unique<Call>(_name, std::move(args)));
  }

  void Call::setArg(size_t index, const Expression &e)
  {
    if (index < _args.size()) {
      _args[index] = e;
    }
  }

  void Call::print(std::ostream &os) const
  {
    os << _name << '(';

    for (auto it = _args.begin(); it != _args.end(); ++it) {
      if (it != _args.begin()) os << ",";
      os << *it;
    }

    os << ')';
  }

  QJsonValue Call::serialize() const
  {
    QJsonObject obj;
    obj.insert("name", QString::fromStdString(_name));

    QJsonArray args;
    for (auto &e: _args) {
      args.push_back(e.serialize());
    }

    if (_is_record) {
      obj.insert("$kind", "record");
      obj.insert("elements", std::move(args));
    } else {
      obj.insert("$kind", "call");
      obj.insert("arguments", std::move(args));
    }

    return obj;
  }

  Expression Call::parse(std::string name, Tokenizer &tokenizer)
  {
    auto tok = tokenizer.peekToken();
    if (tok.type != Token::OPEN_PAREN) {
      throw std::runtime_error("Call::parse expected (, got " + tok.string());
    }
    tokenizer.popToken();

    auto args = parseCommaList(tokenizer);

    tok = tokenizer.peekToken();
    if (tok.type != Token::CLOSE_PAREN) {
      throw std::runtime_error("Call::parse expected ), got " + tok.string());
    }
    tokenizer.popToken();

    return Expression(std::make_unique<Call>(name, std::move(args)));
  }

  Iterator::Iterator(const QJsonValue &value)
  {
    if (!value.isObject()) {
      throw json_error("Expression: invalid iterator expression: ", value);
    }

    auto obj = value.toObject();
    auto name = obj["name"];

    if (!name.isString()) {
      throw json_error("Expression: invalid iterator name: ", name);
    }

    _name = name.toString().toStdString();

    auto range = obj.find("range");

    if (range == obj.end()) {
      throw json_error("Expression: missing iterator range in ", value);
    }

    _range.deserialize(*range);
  }

  QJsonValue Iterator::serialize() const
  {
    QJsonObject obj;
    obj.insert("name", _name.c_str());
    obj.insert("range", _range.serialize());
    return obj;
  }

  std::ostream& operator<< (std::ostream &os, const Iterator &i)
  {
    os << i.name() << " in " << i.range();
    return os;
  }

  IteratorCall::IteratorCall(const QJsonObject &value)
  {
    auto name = value["name"];

    if (!name.isString()) {
      throw json_error("Expression: invalid JSON iterator call name: ", name);
    }

    _name = name.toString().toStdString();
    _exp.deserialize(value["exp"]);

    auto iters = value["iterators"];

    if (!iters.isArray()) {
      throw json_error("Expression: invalid JSON iterator call iterators: ", iters);
    }

    for (const auto &i: iters.toArray()) {
      _iterators.emplace_back(i);
    }
  }

  Expression IteratorCall::eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const
  {
    Q_UNUSED(var_eval);
    Q_UNUSED(recursion_level);
    return Expression(std::make_unique<IteratorCall>(*this));
  }

  void IteratorCall::print(std::ostream &os) const
  {
    bool is_array = _name == "$array";

    if (is_array) {
      os << '{';
    } else {
      os << _name << '(';
    }

    os << _exp << " for ";

    for (auto it = _iterators.begin(); it != _iterators.end(); ++it) {
      if (it != _iterators.begin()) os << ", ";
      os << *it;
    }

    os << (is_array ? '}' : ')');
  }

  QJsonValue IteratorCall::serialize() const
  {
    QJsonObject obj;
    obj.insert("$kind", "iterator_call");
    obj.insert("name", _name.c_str());
    obj.insert("exp", _exp.serialize());

    QJsonArray iters;
    for (auto &i: _iterators) {
      iters.push_back(i.serialize());
    }
    obj.insert("iterators", std::move(iters));

    return obj;
  }

  Binary::Binary(const QJsonObject &value)
  {
    _e1.deserialize(value["lhs"]);
    _op.deserialize(value["op"]);
    _e2.deserialize(value["rhs"]);
  }

  Expression Binary::eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const
  {
    switch (_op.type()) {
      case Operator::Add:       return _e1.evaluate(var_eval, recursion_level) + _e2.evaluate(var_eval, recursion_level);
      case Operator::Sub:       return _e1.evaluate(var_eval, recursion_level) - _e2.evaluate(var_eval, recursion_level);
      case Operator::Mul:       return _e1.evaluate(var_eval, recursion_level) * _e2.evaluate(var_eval, recursion_level);
      case Operator::Div:       return _e1.evaluate(var_eval, recursion_level) / _e2.evaluate(var_eval, recursion_level);
      case Operator::Pow:       return _e1.evaluate(var_eval, recursion_level) ^ _e2.evaluate(var_eval, recursion_level);
      case Operator::AddEW:     return Expression::addEw(_e1.evaluate(var_eval, recursion_level), _e2.evaluate(var_eval, recursion_level));
      case Operator::SubEW:     return Expression::subEw(_e1.evaluate(var_eval, recursion_level), _e2.evaluate(var_eval, recursion_level));
      case Operator::MulEW:     return Expression::mulEw(_e1.evaluate(var_eval, recursion_level), _e2.evaluate(var_eval, recursion_level));
      case Operator::DivEW:     return Expression::divEw(_e1.evaluate(var_eval, recursion_level), _e2.evaluate(var_eval, recursion_level));
      case Operator::PowEW:     return Expression::powEw(_e1.evaluate(var_eval, recursion_level), _e2.evaluate(var_eval, recursion_level));
      // Special handling of 'and' and 'or' to avoid evaluating both sides unless it's necessary.
      case Operator::And: return expBinaryEWOp(_e1, _e2, [&] (auto &e1, auto &e2) {
                               return e1.evaluate(var_eval, recursion_level) && e2.evaluate(var_eval, recursion_level);
                             }, "and");
      case Operator::Or:  return expBinaryEWOp(_e1, _e2, [&] (auto &e1, auto &e2) {
                               return e1.evaluate(var_eval, recursion_level) || e2.evaluate(var_eval, recursion_level);
                             }, "or");
      case Operator::Equal:     return Expression(_e1.evaluate(var_eval, recursion_level) == _e2.evaluate(var_eval, recursion_level));
      case Operator::NotEqual:  return Expression(_e1.evaluate(var_eval, recursion_level) != _e2.evaluate(var_eval, recursion_level));
      case Operator::Less:      return Expression(_e1.evaluate(var_eval, recursion_level) < _e2.evaluate(var_eval, recursion_level));
      case Operator::LessEq:    return Expression(_e1.evaluate(var_eval, recursion_level) <= _e2.evaluate(var_eval, recursion_level));
      case Operator::Greater:   return Expression(_e1.evaluate(var_eval, recursion_level) > _e2.evaluate(var_eval, recursion_level));
      case Operator::GreaterEq: return Expression(_e1.evaluate(var_eval, recursion_level) >= _e2.evaluate(var_eval, recursion_level));
      default: break;
    }

    throw std::runtime_error("Binary::eval unknown operator");
  }

  void Binary::print(std::ostream &os) const
  {
    os << "(";
    os << _e1;
    os << " " << _op << " ";
    os << _e2;
    os << ")";
  }

  QJsonValue Binary::serialize() const
  {
    return QJsonObject{
      {"$kind", "binary_op"},
      {  "lhs", _e1.serialize()},
      {   "op", _op.serialize()},
      {  "rhs", _e2.serialize()}
    };
  }

  Expression Binary::parse(Expression e1, Tokenizer &tokenizer)
  {
    auto tok = tokenizer.peekToken();
    if (tok.type != Token::OPERATOR) {
      throw std::runtime_error("Binary::parse got invalid operator " + tok.string());
    }
    tokenizer.popToken();

    auto op = Operator(tok.data);
    auto e2 = parseExp(tokenizer);

    return Expression(std::make_unique<Binary>(std::move(e1), op, std::move(e2)));
  }

  Unary::Unary(const QJsonObject &value)
  {
    _e.deserialize(value["exp"]);
    _op.deserialize(value["op"]);
  }

  Expression Unary::eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const
  {
    switch (_op.type()) {
      case Operator::Sub: return -_e.evaluate(var_eval, recursion_level);
      case Operator::Not: return !_e.evaluate(var_eval, recursion_level);
      default: break;
    }

    throw std::runtime_error("Unary::eval unknown operator");
  }

  void Unary::print(std::ostream &os) const
  {
    os << _op;
    // add space for not operator
    if (_op.type() == Operator::Not) {
      os << " ";
    }
    os << _e;
  }

  QJsonValue Unary::serialize() const
  {
    return QJsonObject{
      {"$kind", "unary_op"},
      {   "op", _op.serialize()},
      {  "exp", _e.serialize()}
    };
  }

  Expression Unary::parse(Tokenizer &tokenizer)
  {
    auto tok = tokenizer.peekToken();

    if (tok.type == Token::SUB) {
      tokenizer.popToken();
      auto e = parsePrimary(tokenizer);

      if (e.isNumber()) {
        return e.isInteger() ? Expression(-e.intValue()) : Expression(-e.realValue());
      } else {
        return Expression(std::make_unique<Unary>(Operator::Sub, std::move(e)));
      }
    } else if (tok.type == Token::NOT) {
      tokenizer.popToken();
      auto e = parsePrimary(tokenizer);

      if (e.isBoolean()) {
        return Expression(!e.boolValue());
      } else {
        return Expression(std::make_unique<Unary>(Operator::Not, std::move(e)));
      }
    }

    throw std::runtime_error("Unary::parse got invalid operator " + tok.string());
  }

  IfExp::IfExp(const QJsonObject &value)
  {
    _condition.deserialize(value["condition"]);
    _true_e.deserialize(value["true"]);
    _false_e.deserialize(value["false"]);
  }

  Expression IfExp::eval(const Expression::VariableEvaluator &var_eval, int recursion_level) const
  {
    return _condition.evaluate(var_eval, recursion_level).boolValue() ?
           _true_e.evaluate(var_eval, recursion_level) : _false_e.evaluate(var_eval, recursion_level);
  }

  void IfExp::print(std::ostream &os) const
  {
    os << "if " << _condition << " then " << _true_e << " else " << _false_e;
  }

  QJsonValue IfExp::serialize() const
  {
    return QJsonObject{
      {    "$kind", "if"},
      {"condition", _condition.serialize()},
      {     "true", _true_e.serialize()},
      {    "false", _false_e.serialize()}
    };
  }

  Expression IfExp::parse(Tokenizer &tokenizer)
  {
    auto condition = parseExp(tokenizer);

    auto tok = tokenizer.peekToken();
    if (tok.data != "then") {
      throw std::runtime_error("IfExp::parse expected 'then', got " + tok.string());
    }
    tokenizer.popToken();

    auto true_e = parseExp(tokenizer);

    tok = tokenizer.peekToken();
    if (tok.data != "else") {
      throw std::runtime_error("IfExp::parse expected 'else', got " + tok.string());
    }
    tokenizer.popToken();

    auto false_e = parseExp(tokenizer);

    return Expression(std::make_unique<IfExp>(std::move(condition), std::move(true_e), std::move(false_e)));
  }

  /*!
   * \brief Expression::Expression
   * Constructs an expression with no value.
   */
  Expression::Expression() = default;

  /*!
   * \brief Expression::Expression
   * Constructs an Integer expression.
   * \param value
   */
  Expression::Expression(int value)
    : _value(std::make_unique<Integer>(value))
  {
  }

  /*!
   * \brief Expression::Expression
   * Constructs an Integer expression.
   * \param value
   */
  Expression::Expression(int64_t value)
    : _value(std::make_unique<Integer>(value))
  {
  }

  /*!
   * \brief Expression::Expression
   * Constructs a Real expression.
   * \param value
   */
  Expression::Expression(double value)
    : _value(std::make_unique<Real>(value))
  {
  }

  /*!
   * \brief Expression::Expression
   * Constructs a Boolean expression.
   * \param value
   */
  Expression::Expression(bool value)
    : _value(std::make_unique<Boolean>(value))
  {
  }

  /*!
   * \brief Expression::Expression
   * Constructs a String expression.
   * \param value
   */
  Expression::Expression(std::string value)
    : _value(std::make_unique<String>(std::move(value)))
  {
  }

  /*!
   * \brief Expression::Expression
   * Constructs a String expression.
   * \param value
   */
  Expression::Expression(const char *value)
    : Expression(std::string(value))
  {
  }

  /*!
   * \brief Expression::Expression
   * Constructs a String expression.
   * \param value
   */
  Expression::Expression(const QString &value)
    : Expression(value.toStdString())
  {
  }

  /*!
   * \brief Expression::Expression
   * Constructs an Array expression.
   * \param elements
   */
  Expression::Expression(std::vector<Expression> elements)
    : _value(std::make_unique<Array>(std::move(elements)))
  {
  }

  /*!
   * \brief Expression::Expression
   * Constructs an Enum expression.
   * \param elements
   */
  Expression::Expression(std::string value, int index)
    : _value(std::make_unique<Enum>(std::move(value), index))
  {

  }

  /*!
   * \brief Expression::Expression
   * Constructs an expression from an ExpressionBase pointer.
   * Only for internal use by the Expression class.
   * \param value
   */
  Expression::Expression(std::unique_ptr<ExpressionBase> value)
    : _value(std::move(value))
  {
  }

  /*!
   * \brief Expression::~Expression
   * Destructor for Expression.
   * Needs to be implemented here since it will otherwise be automatically
   * generated in the header where ExpressionBase is only forward-declared.
   */
  Expression::~Expression() = default;

  /*!
   * \brief Expression::parse
   * Parses a string representing a flat Modelica expression.
   * \param string
   * \return An Expression representing the flat Modelica expression.
   */
  Expression Expression::parse(std::string string)
  {
    Tokenizer tokenizer(std::move(string));
    return parseExp(tokenizer);
  }

  /*!
   * \brief Expression::parse
   * Parses a QString representing a flat Modelica expression.
   * \param string
   * \return An Expression representing the flat Modelica expression.
   */
  Expression Expression::parse(const QString &str)
  {
    return parse(str.toStdString());
  }

  /*!
   * \brief Expression::deserialize
   * Deserializes the Expression from a Json value.
   * \param value
   */
  void Expression::deserialize(const QJsonValue &value)
  {
    _value = ExpressionBase::deserialize(value);
  }

  QJsonValue Expression::serialize() const
  {
    return _value ? _value->serialize() : QJsonValue();
  }

  /*!
   * \brief Expression::Expression
   * Copy constructor for Expression.
   * \param other
   */
  Expression::Expression(const Expression &other)
    : _value(other._value ? other._value->clone() : nullptr)
  {
  }

  /*!
   * \brief Expression::operator=
   * Assignment operator for Expression.
   * \param other
   */
  Expression& Expression::operator= (const Expression &other) noexcept
  {
    return *this = Expression(other);
  }

  /*!
   * \brief Expression::Expression
   * Move constructor for Expression.
   * \param other
   */
  Expression::Expression(Expression &&other)
    : _value(std::move(other._value))
  {
  }

  /*!
   * \brief Expression::operator=
   * Move assignment operator for Expression.
   * \param other
   */
  Expression& Expression::operator= (Expression &&other) noexcept
  {
    _value = std::move(other._value);
    return *this;
  }

  /*!
   * \brief Expression::evaluate
   * Evaluates an Expression to a literal Expression. Any variables in the
   * expression are evaluated using the given callback that takes a variable
   * name as a string and returns the variables value as a double.
   * \param var_eval
   */
  Expression Expression::evaluate(const VariableEvaluator &var_eval, int recursion_level) const
  {
    return _value ? Expression(_value->eval(var_eval, recursion_level)) : Expression();
  }

  /*!
   * \brief Expression::isNull
   * Checks if the Expression contains a value or not.
   * \return true if the Expression has no value, otherwise false.
   */
  bool Expression::isNull() const
  {
    return _value == nullptr;
  }

  /*!
   * \brief Expression::isLiteral
   * Checks if the Expression is a literal, i.e. is a scalar value or an array
   * of scalar values.
   * \return true if the Expression is a literal, otherwise false.
   */
  bool Expression::isLiteral() const
  {
    return _value && _value->isLiteral();
  }

  /*!
   * \brief Expression::isInteger
   * Checks if the Expression is an Integer.
   * \return true if the Expression is an Integer, otherwise false.
   */
  bool Expression::isInteger() const
  {
    return _value && _value->isInteger();
  }

  /*!
   * \brief Expression::isReal
   * Checks if the Expression is a Real.
   * \return true if the Expression is a Real, otherwise false.
   */
  bool Expression::isReal() const
  {
    return _value && _value->isReal();
  }

  /*!
   * \brief Expression::isEnum
   * Checks if the Expression is a Enum.
   * \return true if the Expression is a Enum, otherwise false.
   */
  bool Expression::isEnum() const
  {
    return _value && _value->isEnum();
  }

  /*!
   * \brief Expression::isNumber
   * Checks if the Expression is an Integer or Real.
   * \return true if the Expression is a number, otherwise false.
   */
  bool Expression::isNumber() const
  {
    return isInteger() || isReal();
  }

  /*!
   * \brief Expression::isBoolean
   * Checks if the Expression is a Boolean.
   * \return true if the Expression is a Boolean, otherwise false.
   */
  bool Expression::isBoolean() const
  {
    return _value && _value->isBoolean();
  }

  /*!
   * \brief Expression::isBooleanish
   * Checks if the Expression can be type cast to Boolean, i.e. a numeric or
   * boolean value.
   * \return true if the Expression can be type cast to Boolean, otherwise false.
   */
  bool Expression::isBooleanish() const
  {
    return _value && _value->isBooleanish();
  }

  /*!
   * \brief Expression::isString
   * Checks if the Expression is a String.
   * \return true if the Expression is a String, otherwise false.
   */
  bool Expression::isString() const
  {
    return _value && _value->isString();
  }

  /*!
   * \brief Expression::isArray
   * Checks if the Expression is an array.
   * \return true if the Expression is an array, otherwise false.
   */
  bool Expression::isArray() const
  {
    return _value && _value->isArray();
  }

  /*!
   * \brief Expression::isCall
   * Checks if the Expression is a function call.
   * \return true if the Expression is a call, otherwise false.
   */
  bool Expression::isCall() const
  {
    return _value && _value->isCall();
  }

  /*!
   * \brief Expression::isCall
   * Checks if the Expression is a function call with the given name.
   * \return true if the Expression is a call with the given name, otherwise false.
   */
  bool Expression::isCall(const std::string &name) const
  {
    return isCall() && dynamic_cast<const Call&>(*_value).isNamed(name);
  }

  /*!
   * \brief Expression::ndims
   * Returns the number of dimensions an Expression has if it's an array,
   * otherwise 0 (even if it's e.g. a function call that returns an array).
   * \return The number of dimensions of the Expression.
   */
  size_t Expression::ndims() const
  {
    if (isArray()) {
      auto &elems = elements();
      return elems.empty() ? 1 : 1 + elems[0].ndims();
    } else {
      return 0;
    }
  }

  /*!
   * \brief Expression::size
   * Returns the number of elements in an array, or 0 if the expression is not
   * an array.
   * \return The size of the expression.
   */
  size_t Expression::size() const
  {
    return size(0);
  }

  /*!
   * \brief Expression::size
   * Returns the size of the given dimension, or 0 if the Expression has no such
   * dimension.
   * \param dimension The index of the dimension.
   * \return The size of the given dimension.
   */
  size_t Expression::size(size_t dimension) const
  {
    if (!isArray()) {
      return 0;
    }

    auto &elems = elements();

    if (dimension <= 0 || elems.empty()) {
      return elems.size();
    } else {
      return elems[0].size(dimension - 1);
    }
  }

  /*!
   * \brief Expression::intValue
   * Converts an Integer or Real expression to an integer value, or throws an
   * error if the Expression is not convertible.
   * \return The integer value of the Expression.
   */
  int64_t Expression::intValue() const
  {
    if (isReal()) {
      return static_cast<int64_t>(dynamic_cast<const Real&>(*_value).value());
    } else {
      auto p = dynamic_cast<Integer*>(_value.get());

      if (!p) {
        throw std::runtime_error("Expression::intValue: empty expression");
      }

      return p->value();
    }
  }

  /*!
   * \brief Expression::realValue
   * Converts an Integer or Real expression to a floating-point value, or throws
   * an error if the Expression is not convertible.
   * \return The floating-point value of the Expression.
   */
  double Expression::realValue() const
  {
    if (isInteger()) {
      return static_cast<double>(dynamic_cast<const Integer&>(*_value).value());
    } else {
      auto p = dynamic_cast<Real*>(_value.get());

      if (!p) {
        throw std::runtime_error("Expression::realValue: empty expression");
      }

      return p->value();
    }
  }

  /*!
   * \brief Expression::boolValue
   * Converts a Boolean, Integer, or Real expression to a boolean value, or
   * throws an error if the Expression is not convertible.
   * \return The boolean value of the Expression.
   */
  bool Expression::boolValue() const
  {
    if (isInteger()) {
      return dynamic_cast<const Integer&>(*_value).value();
    } else if (isReal()) {
      return dynamic_cast<const Real&>(*_value).value() != 0.0;
    } else {
      auto p = dynamic_cast<Boolean*>(_value.get());

      if (!p) {
        throw std::runtime_error("Expression::boolValue: empty expression");
      }

      return p->value();
    }
  }

  /*!
   * \brief Expression::stringValue
   * Returns the string value of the Expression if it's a String, or throws an
   * error if the Expression is not a String.
   * \return The string value of the Expression.
   */
  std::string Expression::stringValue() const
  {
    auto p = dynamic_cast<String*>(_value.get());

    if (!p) {
      throw std::runtime_error("Expression::stringValue: empty expression");
    }

    return p->value();
  }

  /*!
   * \brief Expression::enumValue
   * Returns the index value of the Expression if it's an Enum, or throws an
   * error if the Expression is not an Enum.
   * \return
   */
  std::string Expression::enumValue() const
  {
    auto p = dynamic_cast<Enum*>(_value.get());

    if (!p) {
      throw std::runtime_error("Expression::enumValue: empty expression");
    }

    return p->value();
  }

  /*!
   * \brief Expression::enumIndex
   * Returns the index of the Expression if it's an Enum, or throws an
   * error if the Expression is not an Enum.
   * \return
   */
  int Expression::enumIndex() const
  {
    auto p = dynamic_cast<Enum*>(_value.get());

    if (!p) {
      throw std::runtime_error("Expression::enumIndex: empty expression");
    }

    return p->index();
  }

  /*!
   * \brief Expression::QStringValue
   * Returns the QString value of the Expression if it's a String, or throws an
   * error if the Expression is not a String.
   * \return The QString value of the Expression.
   */
  QString Expression::QStringValue() const
  {
    return QString::fromStdString(stringValue());
  }

  /*!
   * \brief Expression::functionName
   * Checks if the Expression is a function call and then returns the function name
   * otherwise return empty string.
   * \return The QString value of the Expression function name.
   */
  QString Expression::functionName() const
  {
    if (isCall()) {
      return QString::fromStdString(dynamic_cast<const Call&>(*_value).name());
    }
    return QString("");
  }

  /*!
   * \brief Expression::toString
   * Unparses the Expression into a string.
   * \return The string representation of the Expression.
   */
  std::string Expression::toString() const
  {
    if (!_value) return std::string{};

    std::ostringstream ss;
    _value->print(ss);
    return ss.str();
  }

  /*!
   * \brief Expression::toString
   * Unparses the Expression into a string.
   * \return The QString representation of the Expression.
   */
  QString Expression::toQString() const
  {
    return QString::fromStdString(toString());
  }

  /*!
   * \brief Expression::elements
   * Returns the elements of the Expression if it's an array, or throws an error.
   * \return The elements of the Expression.
   */
  const std::vector<Expression>& Expression::elements() const
  {
    auto p = dynamic_cast<Array*>(_value.get());

    if (!p) {
      throw std::runtime_error("Expression::elements: empty expression");
    }

    return p->elements();
  }

  /*!
   * \brief Expression::args
   * Returns the arguments of the Expression if it's a call, or throws an error.
   * \return The arguments of the Expression.
   */
  const std::vector<Expression>& Expression::args() const
  {
    auto p = dynamic_cast<Call*>(_value.get());

    if (!p) {
      throw std::runtime_error("Expression::args: empty expression");
    }

    return p->args();
  }

  void Expression::setArg(size_t index, const Expression &e)
  {
    auto p = dynamic_cast<Call*>(_value.get());

    if (!p) {
      throw std::runtime_error("Expression::setArg: empty expression");
    }

    return p->setArg(index, e);
  }

  /*!
   * \brief Expression::args
   * Returns the arguments of the Expression if it's a call, or throws an error.
   * \return The arguments of the Expression.
   */
  const Expression& Expression::arg(size_t index) const
  {
    return args()[index];
  }

  /*!
   * \brief Expression::operator+=
   * Adds another Expression to this Expression, or throws an error if such an
   * operation is invalid. Only defined for literal expressions.
   */
  Expression& Expression::operator+= (const Expression &other)
  {
    if (isInteger() && other.isInteger()) {
      // Integer + Integer
      _value = std::make_unique<Integer>(intValue() + other.intValue());
    } else if (isNumber() && other.isNumber()) {
      // Real + Real
      _value = std::make_unique<Real>(realValue() + other.realValue());
    } else if (isString() && other.isString()) {
      // String + String
      _value = std::make_unique<String>(stringValue() + other.stringValue());
    } else if (isArray() && other.isArray()) {
      // array + array
      *this = expBinaryEWArrayOp(*this, other, std::plus<Expression>{}, "+");
    } else {
      throw std::runtime_error("Expression: invalid operation " + toString() + " + " + other.toString());
    }

    return *this;
  }

  /*!
   * \brief Expression::operator-=
   * Subtracts another Expression from this Expression, or throws an error if
   * such an operation is invalid. Only defined for literal expressions.
   */
  Expression& Expression::operator-= (const Expression &other)
  {
    if (isInteger() && other.isInteger()) {
      // Integer - Integer
      _value = std::make_unique<Integer>(intValue() - other.intValue());
    } else if (isNumber() && other.isNumber()) {
      // Real - Real
      _value = std::make_unique<Real>(realValue() - other.realValue());
    } else if (isArray() && other.isArray()) {
      // array - array
      *this = expBinaryEWArrayOp(*this, other, std::minus<Expression>{}, "-");
    } else {
      throw std::runtime_error("Expression: invalid operation " + toString() + " - " + other.toString());
    }

    return *this;
  }

  /*!
   * \brief Expression::operator*=
   * Multiplies this Expression with another Expression, or throws an error if
   * such an operation is invalid. Only defined for literal expressions.
   */
  Expression& Expression::operator*= (const Expression &other)
  {
    auto dim_count1 = ndims();
    auto dim_count2 = other.ndims();

    if (dim_count1 == 0 && dim_count2 == 0) {
      // scalar * scalar
      if (isInteger() && other.isInteger()) {
        _value = std::make_unique<Integer>(intValue() * other.intValue());
      } else if (isNumber() && other.isNumber()) {
        _value = std::make_unique<Real>(realValue() * other.realValue());
      } else {
        throw std::runtime_error("Expression: invalid operation " + toString() + " * " + other.toString());
      }
    } else if (dim_count1 == 0) {
      // scalar * array
      *this = expBinaryScalarArrayOp(*this, other, std::multiplies<Expression>{});
    } else if (dim_count2 == 0) {
      // array * scalar
      *this = expBinaryArrayScalarOp(*this, other, std::multiplies<Expression>{});
    } else if (dim_count1 == 1 && dim_count2 == 1) {
      // vector * vector
      *this = evalSum(expBinaryEWArrayOp(*this, other, std::multiplies<Expression>{}, "*"));
    } else if (dim_count1 == 1 && dim_count2 == 2) {
      // vector * matrix
      Expression trans = evalTranspose(other);
      *this = expUnaryOp(trans, [&] (auto &e) {
        return *this * e;
      });
    } else if (dim_count1 == 2 && dim_count2 == 1) {
      // matrix * vector
      *this = expUnaryOp(*this, [&] (auto &e) {
        return e * other;
      });
    } else if (dim_count1 == 2 && dim_count2 == 2) {
      // matrix * matrix
      *this = expUnaryOp(*this, [&] (auto &r) {
        return expUnaryOp(evalTranspose(other), [&] (auto &c) {
          return r * c;
        });
      });
    } else {
      throw std::runtime_error("Expression: invalid operation " + toString() + " * " + other.toString());
    }

    return *this;
  }

  /*!
   * \brief Expression::operator/=
   * Divides this expression by another expression, or throws an error if such
   * an operation is invalid. Only defined for literal expressions.
   */
  Expression& Expression::operator/= (const Expression &other)
  {
    if (isNumber() && other.isNumber()) {
      // scalar / scalar
      _value = std::make_unique<Real>(realValue() / other.realValue());
    } else if (isArray() && other.isNumber()) {
      // array / scalar
      *this = expBinaryArrayScalarOp(*this, other, std::divides<Expression>{});
    } else {
      throw std::runtime_error("Expression: invalid operation " + toString() + " / " + other.toString());
    }

    return *this;
  }

  /*!
   * \brief Expression::operator^=
   * Raises this expression to the power of another expression, or throws an
   * error such an operation is invalid. Only defined for literal expressions.
   */
  Expression& Expression::operator^= (const Expression &other)
  {
    if (isNumber() && other.isNumber()) {
      // scalar ^ scalar
      _value = std::make_unique<Real>(std::pow(realValue(), other.realValue()));
    } else if (ndims() == 2 && other.isNumber()) {
      // matrix ^ scalar
      auto n = other.intValue();

      if (n == 0) {
        *this = evalIdentity(other);
      } else if (n != 1) {
        Expression e = *this;
        for (int i = 0; i < n - 1; ++i) {
          *this *= e;
        }
      }
    } else {
      throw std::runtime_error("Expression: invalid operation " + toString() + " ^ " + other.toString());
    }

    return *this;
  }

  /*!
   * \brief Expression::addEw
   * Returns 'e1 .+ e2', or throws an error if such an operation is invalid.
   * Only defined for literal expressions.
   * \return A new Expression containing the result.
   */
  Expression Expression::addEw(const Expression &e1, const Expression &e2)
  {
    return expBinaryEWOp(e1, e2, std::plus<Expression>{}, ".+");
  }

  /*!
   * \brief Expression::subEw
   * Returns 'e1 .- e2', or throws an error if such an operation is invalid.
   * Only defined for literal expression.
   * \return A new Expression containing the result.
   */
  Expression Expression::subEw(const Expression &e1, const Expression &e2)
  {
    return expBinaryEWOp(e1, e2, std::minus<Expression>{}, ".-");
  }

  /*!
   * \brief Expression::mulEw
   * Returns 'e1 .* e2', or throws an error if such an operation is invalid.
   * Only defined for literal expression.
   * \return A new Expression containing the result.
   */
  Expression Expression::mulEw(const Expression &e1, const Expression &e2)
  {
    return expBinaryEWOp(e1, e2, std::multiplies<Expression>{}, ".*");
  }

  /*!
   * \brief Expression::divEw
   * Returns 'e1 ./ e2', or throws an error if such an operation is invalid.
   * Only defined for literal expression.
   * \return A new Expression containing the result.
   */
  Expression Expression::divEw(const Expression &e1, const Expression &e2)
  {
    return expBinaryEWOp(e1, e2, std::divides<Expression>{}, "./");
  }

  /*!
   * \brief Expression::powEw
   * Returns 'e1 .^ e2', or throws an error if such an operation is invalid.
   * Only defined for literal expression.
   * \return A new Expression containing the result.
   */
  Expression Expression::powEw(const Expression &e1, const Expression &e2)
  {
    return expBinaryEWOp(e1, e2, std::bit_xor<Expression>{}, ".^");
  }

  /*!
   * \brief Expression::operator-
   * Returns the negated Expression, or throws an error is such an operation is
   * invalid. Only defined for literal expressions.
   * \return A new Expression containing the result.
   */
  Expression Expression::operator- () const
  {
    if (isInteger()) {
      return Expression(-intValue());
    } else if (isReal()) {
      return Expression(-realValue());
    } else if (isArray()) {
      return expUnaryOp(*this, [&] (auto &e) { return -e; });
    } else {
      throw std::runtime_error("Expression: invalid operator -" + toString());
    }
  }

  /*!
   * \brief Expression::operator!
   * Returns the logically negated Expression, or throws an error is such an
   * operation is invalid. Only defined for literal expressions.
   * \return A new Expression containing the result.
   */
  Expression Expression::operator! () const
  {
    if (isArray()) {
      return expUnaryOp(*this, [&] (auto &e) { return !e; });
    } else {
      return Expression(!boolValue());
    }
  }

  /*!
   * \brief Expression::operator&&
   * Returns 'e1 and e2', or throws an error if such an operation is invalid.
   * Only defined for literal expressions.
   * \return A new Expression containing the result.
   */
  Expression operator&& (const Expression &e1, const Expression &e2)
  {
    return Expression(e1.boolValue() && e2.boolValue());
  }

  /*!
   * \brief Expression::operator||
   * Returns 'e1 or e2', or throws an error if such an operation is invalid.
   * Only defined for literal expressions.
   * \return A new Expression containing the result.
   */
  Expression operator|| (const Expression &e1, const Expression &e2)
  {
    return Expression(e1.boolValue() || e2.boolValue());
  }

  /*!
   * \brief Expression::operator==
   * Returns whether the expressions are equivalent, or throws an error if they
   * can't be compared. Only defined for literal scalar expressions.
   * \return true if e1 is equivalent to e2, otherwise false.
   */
  bool operator== (const Expression &e1, const Expression &e2)
  {
    if (e1.isBoolean() || e2.isBoolean()) {
      return e1.boolValue() == e2.boolValue();
    } else if (e1.isString() && e2.isString()) {
      return e1.stringValue() == e2.stringValue();
    } else if (e1.isEnum() && e2.isEnum()) {
      return e1.enumIndex() == e2.enumIndex();
    } else if (e1.isInteger() && e2.isInteger()) {
      return e1.intValue() == e2.intValue();
    } else if (e1.isNumber() && e2.isNumber()) {
      return e1.realValue() == e2.realValue();
    } else {
      return false;
    }
  }

  /*!
   * \brief Expression::operator!=
   * Returns whether the expressions are not equivalent, or throws an error if
   * they can't be compared. Only defined for literal scalar expressions.
   * \return true if e1 is not equivalent to e2, otherwise false.
   */
  bool operator!= (const Expression &e1, const Expression &e2)
  {
    if (e1.isBoolean() || e2.isBoolean()) {
      return e1.boolValue() != e2.boolValue();
    } else if (e1.isString() && e2.isString()) {
      return e1.stringValue() != e2.stringValue();
    } else if (e1.isEnum() && e2.isEnum()) {
      return e1.enumIndex() != e2.enumIndex();
    } else if (e1.isInteger() && e2.isInteger()) {
      return e1.intValue() != e2.intValue();
    } else if (e1.isNumber() && e2.isNumber()) {
      return e1.realValue() != e2.realValue();
    } else {
      return false;
    }
  }

  /*!
   * \brief Expression::operator<
   * Returns whether e1 is less than e2, or throws an error if they can't be
   * compared. Only defined for literal scalar expressions.
   * \return true if e1 is less than e2, otherwise false.
   */
  bool operator< (const Expression &e1, const Expression &e2)
  {
    if (e1.isBoolean() || e2.isBoolean()) {
      return e1.boolValue() < e2.boolValue();
    } else if (e1.isString() && e2.isString()) {
      return e1.stringValue() < e2.stringValue();
    } else if (e1.isEnum() && e2.isEnum()) {
      return e1.enumIndex() < e2.enumIndex();
    } else if (e1.isInteger() && e2.isInteger()) {
      return e1.intValue() < e2.intValue();
    } else if (e1.isNumber() && e2.isNumber()) {
      return e1.realValue() < e2.realValue();
    } else {
      return false;
    }
  }

  /*!
   * \brief Expression::operator<=
   * Returns whether e1 is less than or equivalent to e2, or throws an error if
   * they can't be compared. Only defined for literal scalar expressions.
   * \return true if e1 is less than or equivalent to e2, otherwise false.
   */
  bool operator<= (const Expression &e1, const Expression &e2)
  {
    if (e1.isBoolean() || e2.isBoolean()) {
      return e1.boolValue() <= e2.boolValue();
    } else if (e1.isString() && e2.isString()) {
      return e1.stringValue() <= e2.stringValue();
    } else if (e1.isEnum() && e2.isEnum()) {
      return e1.enumIndex() <= e2.enumIndex();
    } else if (e1.isInteger() && e2.isInteger()) {
      return e1.intValue() <= e2.intValue();
    } else if (e1.isNumber() && e2.isNumber()) {
      return e1.realValue() <= e2.realValue();
    } else {
      return false;
    }
  }

  /*!
   * \brief Expression::operator>
   * Returns whether e1 is greater than e2, or throws an error if they can't be
   * compared. Only defined for literal scalar expressions.
   * \return true if e1 is greater than e2, otherwise false.
   */
  bool operator> (const Expression &e1, const Expression &e2)
  {
    if (e1.isBoolean() || e2.isBoolean()) {
      return e1.boolValue() > e2.boolValue();
    } else if (e1.isString() && e2.isString()) {
      return e1.stringValue() > e2.stringValue();
    } else if (e1.isEnum() && e2.isEnum()) {
      return e1.enumIndex() > e2.enumIndex();
    } else if (e1.isInteger() && e2.isInteger()) {
      return e1.intValue() > e2.intValue();
    } else if (e1.isNumber() && e2.isNumber()) {
      return e1.realValue() > e2.realValue();
    } else {
      return false;
    }
  }

  /*!
   * \brief Expression::operator>=
   * Returns whether e1 is greater than or equivalent to e2, or throws an error
   * if they can't be compared. Only defined for literal scalar expressions.
   * \return true if e1 is greater than or equivalent to e2, otherwise false.
   */
  bool operator>= (const Expression &e1, const Expression &e2)
  {
    if (e1.isBoolean() || e2.isBoolean()) {
      return e1.boolValue() >= e2.boolValue();
    } else if (e1.isString() && e2.isString()) {
      return e1.stringValue() >= e2.stringValue();
    } else if (e1.isEnum() && e2.isEnum()) {
      return e1.enumIndex() >= e2.enumIndex();
    } else if (e1.isInteger() && e2.isInteger()) {
      return e1.intValue() >= e2.intValue();
    } else if (e1.isNumber() && e2.isNumber()) {
      return e1.realValue() >= e2.realValue();
    } else {
      return false;
    }
  }

  Expression operator+ (Expression lhs, const Expression &rhs)
  {
    return lhs += rhs;
  }

  Expression operator- (Expression lhs, const Expression &rhs)
  {
    return lhs -= rhs;
  }

  Expression operator* (Expression lhs, const Expression &rhs)
  {
    return lhs *= rhs;
  }

  Expression operator/ (Expression lhs, const Expression &rhs)
  {
    return lhs /= rhs;
  }

  Expression operator^ (Expression lhs, const Expression &rhs)
  {
    return lhs ^= rhs;
  }

  std::ostream& operator<< (std::ostream &os, const Expression &e)
  {
    if (e._value) {
      e._value->print(os);
    } else {
      os << "NIL";
    }
    return os;
  }
}
