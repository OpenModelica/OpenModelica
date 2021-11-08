#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <sstream>
#include <stdexcept>
#include <vector>

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

  class ExpressionBase
  {
    public:
      enum class value_t
      {
        integer,
        real,
        boolean,
        string,
        cref,
        array,
        call,
        binary,
        unary,
        if_exp
      };

    public:
      virtual ~ExpressionBase() = default;
      virtual value_t type() const = 0;
      virtual bool isLiteral() const = 0;

      virtual std::unique_ptr<ExpressionBase> clone() const = 0;
      virtual Expression eval(const Expression::VariableEvaluator &var_eval) const = 0;

      virtual void print(std::ostream &os) const = 0;
  };

  class Integer : public ExpressionBase
  {
    public:
      Integer(int64_t value)
        : _value(value) {}

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Integer>(*this); }
      Expression eval(const Expression::VariableEvaluator&) const override { return Expression(_value); };

      value_t type() const override { return value_t::integer; }
      bool isLiteral() const override { return true; }
      int64_t value() const { return _value; }

      void print(std::ostream &os) const override;

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
      Expression eval(const Expression::VariableEvaluator&) const override { return Expression(_value); }

      value_t type() const override { return value_t::real; }
      bool isLiteral() const override { return true; }
      double value() const { return _value; }

      void print(std::ostream &os) const override;

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
      Expression eval(const Expression::VariableEvaluator&) const override { return Expression(_value); }

      value_t type() const override { return value_t::boolean; }
      bool isLiteral() const override { return true; }
      bool value() const { return _value; }

      void print(std::ostream &os) const override;

    private:
      bool _value;
  };

  class String : public ExpressionBase
  {
    public:
      String(std::string value)
        : _value(std::move(value)) {}

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<String>(*this); }
      Expression eval(const Expression::VariableEvaluator&) const override { return Expression(_value); }

      value_t type() const override { return value_t::string; }
      bool isLiteral() const override { return true; }
      const std::string& value() const { return _value; }

      void print(std::ostream &os) const override;

      static Expression parse(Tokenizer &tokenizer);

    private:
      std::string _value;
  };

  class Cref : public ExpressionBase
  {
    public:
      Cref(std::string name)
        : _name(std::move(name)) {}

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Cref>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval) const override;

      value_t type() const override { return value_t::cref; }
      bool isLiteral() const override { return false; }
      void print(std::ostream &os) const override;

      static Expression parse(std::string first_ident, Tokenizer &tokenizer);

    private:
      std::string _name;
  };

  class Array : public ExpressionBase
  {
    public:
      Array(std::vector<Expression> elements)
        : _elements(std::move(elements)) {}

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Array>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval) const override;

      value_t type() const override { return value_t::array; }
      bool isLiteral() const override;
      const std::vector<Expression>& elements() const { return _elements; }

      void print(std::ostream &os) const override;

      static Expression parse(Tokenizer &tokenizer);

    private:
      std::vector<Expression> _elements;
  };

  class Call : public ExpressionBase
  {
    public:
      Call(std::string name, std::vector<Expression> args)
        : _name(std::move(name)), _args(std::move(args)) {}

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Call>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval) const override;

      value_t type() const override { return value_t::call; }
      bool isLiteral() const override { return false; }
      const std::string& name() const { return _name; }
      bool isNamed(const std::string &name) const { return _name == name; }
      const std::vector<Expression>& args() const { return _args; }
      void setArg(size_t index, const Expression &e);

      void print(std::ostream &os) const override;

      static Expression parse(std::string name, Tokenizer &tokenizer);

    private:
      std::string _name;
      std::vector<Expression> _args;
  };

  class Binary : public ExpressionBase
  {
    public:
      enum operation
      {
        add,
        sub,
        mul,
        div,
        pow,
        add_ew,
        sub_ew,
        mul_ew,
        div_ew,
        pow_ew,
        logic_and,
        logic_or,
        equal,
        nequal,
        less,
        lesseq,
        greater,
        greatereq
      };

    public:
      Binary(Expression e1, operation op, Expression e2)
        : _e1(std::move(e1)), _op(op), _e2(std::move(e2)) {}

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Binary>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval) const override;

      value_t type() const override { return value_t::binary; }
      bool isLiteral() const override { return false; }
      void print(std::ostream &os) const override;

      static Expression parse(Expression e1, Tokenizer &tokenizer);

    private:
      Expression _e1;
      operation _op;
      Expression _e2;
  };

  class Unary : public ExpressionBase
  {
    public:
      enum operation
      {
        minus,
        logic_not,
      };

    public:
      Unary(operation op, Expression e)
        : _op(op), _e(std::move(e)) {}

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<Unary>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval) const override;

      value_t type() const override { return value_t::unary; }
      bool isLiteral() const override { return false; }
      void print(std::ostream &os) const override;

      static Expression parse(Tokenizer &tokenizer);

    private:
      operation _op;
      Expression _e;
  };

  class IfExp : public ExpressionBase
  {
    public:
      IfExp(Expression condition, Expression true_e, Expression false_e)
        : _condition(std::move(condition)), _true_e(std::move(true_e)),
          _false_e(std::move(false_e)) {}

      std::unique_ptr<ExpressionBase> clone() const override { return std::make_unique<IfExp>(*this); }
      Expression eval(const Expression::VariableEvaluator &var_eval) const override;

      value_t type() const override { return value_t::if_exp; }
      bool isLiteral() const override { return false; }
      void print(std::ostream &os) const override;

      static Expression parse(Tokenizer &tokenizer);

    private:
      Expression _condition;
      Expression _true_e;
      Expression _false_e;
  };

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

  Binary::operation parseOp(std::string str)
  {
    switch (str.size()) {
      case 1:
        switch (str[0]) {
          case '+': return Binary::add;
          case '-': return Binary::sub;
          case '*': return Binary::mul;
          case '/': return Binary::div;
          case '^': return Binary::pow;
          case '<': return Binary::less;
          case '>': return Binary::greater;
        }
        break;

      case 2:
        if (str[0] == '.') {
          switch (str[1]) {
            case '+': return Binary::add_ew;
            case '-': return Binary::sub_ew;
            case '*': return Binary::mul_ew;
            case '/': return Binary::div_ew;
            case '^': return Binary::pow_ew;
          }
        } else if (str[1] == '=') {
          switch (str[0]) {
            case '<': return Binary::lesseq;
            case '>': return Binary::greatereq;
            case '=': return Binary::equal;
          }
        } else if (str == "<>") {
          return Binary::nequal;
        } else if (str == "or") {
          return Binary::logic_or;
        }
        break;

      case 3:
        if (str == "and") {
          return Binary::logic_and;
        }
        break;
    }

    throw std::runtime_error("parseOp got invalid operator " + str);
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

  Binary::operation binaryOpFromToken(Token::token_t t)
  {
    switch (t) {
      case Token::ADD: return Binary::add;
      case Token::SUB: return Binary::sub;
      case Token::MUL: return Binary::mul;
      case Token::DIV: return Binary::div;
      case Token::POW: return Binary::pow;
      case Token::ADD_EW: return Binary::add_ew;
      case Token::SUB_EW: return Binary::sub_ew;
      case Token::MUL_EW: return Binary::mul_ew;
      case Token::DIV_EW: return Binary::div_ew;
      case Token::POW_EW: return Binary::pow_ew;
      case Token::AND: return Binary::logic_and;
      case Token::OR: return Binary::logic_or;
      case Token::EQUAL: return Binary::equal;
      case Token::NEQUAL: return Binary::nequal;
      case Token::LESS: return Binary::less;
      case Token::LESSEQ: return Binary::lesseq;
      case Token::GREATER: return Binary::greater;
      case Token::GREATEREQ: return Binary::greatereq;
      default:
        throw std::runtime_error("binaryOpFromToken got invalid token type");
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

      lhs = Expression(std::make_unique<Binary>(std::move(lhs), binaryOpFromToken(op), std::move(rhs)));
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

  void Integer::print(std::ostream &os) const
  {
    os << _value;
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

  Expression Real::parse(Tokenizer &tokenizer)
  {
    double d;
    auto tok = tokenizer.peekToken();
    std::istringstream ss(tok.data);
    ss >> d;
    tokenizer.popToken();
    return Expression(d);
  }

  void Boolean::print(std::ostream &os) const
  {
    os << (_value ? "true" : "false");
  }

  void String::print(std::ostream &os) const
  {
    os << '"' << _value << '"';
  }

  Expression String::parse(Tokenizer &tokenizer)
  {
    auto tok = tokenizer.peekToken();
    tokenizer.popToken();
    return Expression(tok.data);
  }

  Expression Cref::eval(const Expression::VariableEvaluator &var_eval) const
  {
    return Expression(var_eval(_name));
  }

  void Cref::print(std::ostream &os) const
  {
    os << _name;
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

  Expression Array::eval(const Expression::VariableEvaluator &var_eval) const
  {
    std::vector<Expression> elems;
    elems.reserve(_elements.size());

    for (auto &e: _elements) {
      elems.emplace_back(e.evaluate(var_eval));
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

  Expression Call::eval(const Expression::VariableEvaluator &var_eval) const
  {
    std::vector<Expression> args;
    args.reserve(_args.size());

    for (auto &a: _args) {
      args.emplace_back(a.evaluate(var_eval));
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

  Expression Binary::eval(const Expression::VariableEvaluator &var_eval) const
  {
    switch (_op) {
      case add:       return _e1.evaluate(var_eval) + _e2.evaluate(var_eval);
      case sub:       return _e1.evaluate(var_eval) - _e2.evaluate(var_eval);
      case mul:       return _e1.evaluate(var_eval) * _e2.evaluate(var_eval);
      case div:       return _e1.evaluate(var_eval) / _e2.evaluate(var_eval);
      case pow:       return _e1.evaluate(var_eval) ^ _e2.evaluate(var_eval);
      case add_ew:    return Expression::addEw(_e1.evaluate(var_eval), _e2.evaluate(var_eval));
      case sub_ew:    return Expression::subEw(_e1.evaluate(var_eval), _e2.evaluate(var_eval));
      case mul_ew:    return Expression::mulEw(_e1.evaluate(var_eval), _e2.evaluate(var_eval));
      case div_ew:    return Expression::divEw(_e1.evaluate(var_eval), _e2.evaluate(var_eval));
      case pow_ew:    return Expression::powEw(_e1.evaluate(var_eval), _e2.evaluate(var_eval));
      // Special handling of 'and' and 'or' to avoid evaluating both sides unless it's necessary.
      case logic_and: return expBinaryEWOp(_e1, _e2, [&] (auto &e1, auto &e2) {
                               return e1.evaluate(var_eval) && e2.evaluate(var_eval);
                             }, "and");
      case logic_or:  return expBinaryEWOp(_e1, _e2, [&] (auto &e1, auto &e2) {
                               return e1.evaluate(var_eval) || e2.evaluate(var_eval);
                             }, "or");
      case equal:     return Expression(_e1.evaluate(var_eval) == _e2.evaluate(var_eval));
      case nequal:    return Expression(_e1.evaluate(var_eval) != _e2.evaluate(var_eval));
      case less:      return Expression(_e1.evaluate(var_eval) < _e2.evaluate(var_eval));
      case lesseq:    return Expression(_e1.evaluate(var_eval) <= _e2.evaluate(var_eval));
      case greater:   return Expression(_e1.evaluate(var_eval) > _e2.evaluate(var_eval));
      case greatereq: return Expression(_e1.evaluate(var_eval) >= _e2.evaluate(var_eval));
    }

    throw std::runtime_error("Binary::eval unknown operator");
  }

  void Binary::print(std::ostream &os) const
  {
    os << "(";
    os << _e1;

    switch (_op) {
      case add: os << " + "; break;
      case sub: os << " - "; break;
      case mul: os << " * "; break;
      case div: os << " / "; break;
      case pow: os << " ^ "; break;
      case add_ew: os << " .+ "; break;
      case sub_ew: os << " .- "; break;
      case mul_ew: os << " .* "; break;
      case div_ew: os << " ./ "; break;
      case pow_ew: os << " .^ "; break;
      case logic_and: os << " and "; break;
      case logic_or: os << " or "; break;
      case equal: os << " == "; break;
      case nequal: os << " <> "; break;
      case less: os << " < "; break;
      case lesseq: os << " <= "; break;
      case greater: os << " > "; break;
      case greatereq: os << " >= "; break;
    }

    os << _e2;
    os << ")";
  }

  Expression Binary::parse(Expression e1, Tokenizer &tokenizer)
  {
    auto tok = tokenizer.peekToken();
    if (tok.type != Token::OPERATOR) {
      throw std::runtime_error("Binary::parse got invalid operator " + tok.string());
    }
    tokenizer.popToken();

    auto op = parseOp(tok.data);
    auto e2 = parseExp(tokenizer);

    return Expression(std::make_unique<Binary>(std::move(e1), op, std::move(e2)));
  }

  Expression Unary::eval(const Expression::VariableEvaluator &var_eval) const
  {
    switch (_op) {
      case minus: return -_e.evaluate(var_eval);
      case logic_not: return !_e.evaluate(var_eval);
    }

    throw std::runtime_error("Binary::eval unknown operator");
  }

  void Unary::print(std::ostream &os) const
  {
    switch (_op) {
      case minus: os << "-"; break;
      case logic_not: os << "not "; break;
    }

    os << _e;
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
        return Expression(std::make_unique<Unary>(Unary::minus, std::move(e)));
      }
    } else if (tok.type == Token::NOT) {
      tokenizer.popToken();
      auto e = parsePrimary(tokenizer);

      if (e.isBoolean()) {
        return Expression(!e.boolValue());
      } else {
        return Expression(std::make_unique<Unary>(Unary::logic_not, std::move(e)));
      }
    }

    throw std::runtime_error("Unary::parse got invalid operator " + tok.string());
  }

  Expression IfExp::eval(const Expression::VariableEvaluator &var_eval) const
  {
    return _condition.evaluate(var_eval).boolValue() ?
           _true_e.evaluate(var_eval) : _false_e.evaluate(var_eval);
  }

  void IfExp::print(std::ostream &os) const
  {
    os << "if " << _condition << " then " << _true_e << " else " << _false_e;
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
    : _value(std::make_unique<String>(value))
  {
  }

  /*!
   * \brief Expression::Expression
   * Constructs a String expression.
   * \param value
   */
  Expression::Expression(const QString &value)
    : _value(std::make_unique<String>(value.toStdString()))
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
  Expression Expression::evaluate(const VariableEvaluator &var_eval) const
  {
    return Expression(_value->eval(var_eval));
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
    return _value && _value->type() == ExpressionBase::value_t::integer;
  }

  /*!
   * \brief Expression::isReal
   * Checks if the Expression is a Real.
   * \return true if the Expression is a Real, otherwise false.
   */
  bool Expression::isReal() const
  {
    return _value && _value->type() == ExpressionBase::value_t::real;
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
    return _value && _value->type() == ExpressionBase::value_t::boolean;
  }

  /*!
   * \brief Expression::isBooleanish
   * Checks if the Expression can be type cast to Boolean, i.e. a numeric or
   * boolean value.
   * \return true if the Expression can be type cast to Boolean, otherwise false.
   */
  bool Expression::isBooleanish() const
  {
    if (!_value) return false;

    switch (_value->type()) {
      case ExpressionBase::value_t::boolean:
      case ExpressionBase::value_t::integer:
      case ExpressionBase::value_t::real:
        return true;

      default:
        return false;
    }
  }

  /*!
   * \brief Expression::isString
   * Checks if the Expression is a String.
   * \return true if the Expression is a String, otherwise false.
   */
  bool Expression::isString() const
  {
    return _value && _value->type() == ExpressionBase::value_t::string;
  }

  /*!
   * \brief Expression::isArray
   * Checks if the Expression is an array.
   * \return true if the Expression is an array, otherwise false.
   */
  bool Expression::isArray() const
  {
    return _value && _value->type() == ExpressionBase::value_t::array;
  }

  /*!
   * \brief Expression::isCall
   * Checks if the Expression is a function call.
   * \return true if the Expression is a call, otherwise false.
   */
  bool Expression::isCall() const
  {
    return _value && _value->type() == ExpressionBase::value_t::call;
  }

  /*!
   * \brief Expression::isCall
   * Checks if the Expression is a function call with the given name.
   * \return true if the Expression is a call with the given name, otherwise false.
   */
  bool Expression::isCall(const std::string &name) const
  {
    return _value &&
           _value->type() == ExpressionBase::value_t::call &&
           dynamic_cast<const Call&>(*_value).isNamed(name);
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
      return dynamic_cast<const Integer&>(*_value).value();
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
      return dynamic_cast<const Real&>(*_value).value();
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
    switch (_value->type()) {
      case ExpressionBase::value_t::integer:
        return dynamic_cast<const Integer&>(*_value).value();
      case ExpressionBase::value_t::real:
        return dynamic_cast<const Real&>(*_value).value() != 0.0;
      default:
        return dynamic_cast<const Boolean&>(*_value).value();
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
    return dynamic_cast<const String&>(*_value).value();
  }

  /*!
   * \brief Expression::QStringValue
   * Returns the QString value of the Expression if it's a String, or throws an
   * error if the Expression is not a String.
   * \return The QString value of the Expression.
   */
  QString Expression::QStringValue() const
  {
    return QString::fromStdString(dynamic_cast<const String&>(*_value).value());
  }

  /*!
   * \brief Expression::functionName
   * Checks if the Expression is a function call and then returns the function name
   * otherwise return empty string.
   * \return The QString value of the Expression function name.
   */
  QString Expression::functionName() const
  {
    if (_value && _value->type() == ExpressionBase::value_t::call) {
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
    return dynamic_cast<const Array&>(*_value).elements();
  }

  /*!
   * \brief Expression::args
   * Returns the arguments of the Expression if it's a call, or throws an error.
   * \return The arguments of the Expression.
   */
  const std::vector<Expression>& Expression::args() const
  {
    return dynamic_cast<const Call&>(*_value).args();
  }

  void Expression::setArg(size_t index, const Expression &e)
  {
    dynamic_cast<Call&>(*_value).setArg(index, e);
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
    } else if (e1.isInteger() && e2.isInteger()) {
      return e1.intValue() == e2.intValue();
    } else {
      return e1.realValue() == e2.realValue();
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
    } else if (e1.isInteger() && e2.isInteger()) {
      return e1.intValue() != e2.intValue();
    } else {
      return e1.realValue() != e2.realValue();
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
    } else if (e1.isInteger() && e2.isInteger()) {
      return e1.intValue() < e2.intValue();
    } else {
      return e1.realValue() < e2.realValue();
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
    } else if (e1.isInteger() && e2.isInteger()) {
      return e1.intValue() <= e2.intValue();
    } else {
      return e1.realValue() <= e2.realValue();
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
    } else if (e1.isInteger() && e2.isInteger()) {
      return e1.intValue() > e2.intValue();
    } else {
      return e1.realValue() > e2.realValue();
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
    } else if (e1.isInteger() && e2.isInteger()) {
      return e1.intValue() >= e2.intValue();
    } else {
      return e1.realValue() >= e2.realValue();
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
    e._value->print(os);
    return os;
  }
}
