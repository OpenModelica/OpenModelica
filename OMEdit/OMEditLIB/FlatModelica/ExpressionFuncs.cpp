#include <stdexcept>
#include <cstdio>
#include <cmath>
#include <limits>

#include "ExpressionFuncs.h"

namespace FlatModelica
{
  Expression evalAbs(const Expression &x)
  {
    if (x.isInteger()) {
      return Expression(std::abs(x.toInteger()));
    } else {
      return Expression(std::abs(x.toReal()));
    }
  }

  Expression evalSign(const Expression &x)
  {
    auto v = x.toReal();
    return Expression(int64_t{v > 0 ? 1 : (v < 0 ? -1 : 0)});
  }

  Expression evalSqrt(const Expression &x)
  {
    auto v = x.toReal();

    if (v < 0) {
      throw std::runtime_error("Invalid argument " + x.toString() + " to sqrt()");
    }

    return Expression(std::sqrt(v));
  }

  template<typename ... Args>
  std::string format_string(const std::string &format, Args ... args)
  {
    auto buf_size = std::snprintf(nullptr, 0, format.c_str(), args ...) + 1;

    if (buf_size <= 0) {
      throw std::runtime_error("Invalid format string");
    }

    auto buf = std::make_unique<char[]>(buf_size);
    std::snprintf(buf.get(), buf_size, format.c_str(), args ...);
    return std::string(buf.get(), buf.get() + buf_size - 1);
  }

  Expression evalString(const std::vector<Expression> &args)
  {
    switch (args.size()) {
      case 2: // String(r, format)
        return Expression(format_string("%" + args[1].toString(), args[0].toReal()));

      case 3: // String(i, minimumLength, leftJustified)
        return Expression(format_string(
            (args[2].toBoolean() ? "%-" : "%") + args[1].toString() + "d",
            args[0].toInteger()
          ));

      case 4: // String(r, significantDigits, mininumLength, leftJustified)
        return Expression(format_string(
          (args[3].toBoolean() ? "%-" : "%") + args[2].toString() + "." + args[1].toString() + "g",
          args[0].toReal()
        ));
    }

    return Expression(args[0].toString());
  }

  Expression evalDiv(const Expression &x, const Expression &y)
  {
    if (x.isInteger() && y.isInteger()) {
      return Expression(x.toInteger() / y.toInteger());
    } else {
      return Expression(x.toReal() / y.toReal());
    }
  }

  Expression evalMod(const Expression &x, const Expression &y)
  {
    if (x.isInteger() && y.isInteger()) {
      auto ix = x.toInteger();
      auto iy = y.toInteger();
      auto res = ix % iy;

      if ((iy > 0 && res < 0) || (iy < 0 && res > 0)) {
        res += iy;
      }

      return Expression(res);
    } else {
      auto rx = x.toReal();
      auto ry = y.toReal();
      return Expression(rx - std::floor(rx / ry) * ry);
    }
  }

  Expression evalRem(const Expression &x, const Expression &y)
  {
    if (x.isInteger() && y.isInteger()) {
      auto ix = x.toInteger();
      auto iy = y.toInteger();
      return Expression(ix - ix / iy * iy);
    } else {
      auto rx = x.toReal();
      auto ry = y.toReal();
      return Expression(rx - rx / ry * ry);
    }
  }

  Expression evalCeil(const Expression &x)
  {
    return Expression(std::ceil(x.toReal()));
  }

  Expression evalFloor(const Expression &x)
  {
    return Expression(std::floor(x.toReal()));
  }

  Expression evalInteger(const Expression &x)
  {
    return Expression(static_cast<int64_t>(std::floor(x.toReal())));
  }

  Expression evalSin(const Expression &x)
  {
    return Expression(std::sin(x.toReal()));
  }

  Expression evalCos(const Expression &x)
  {
    return Expression(std::cos(x.toReal()));
  }

  Expression evalTan(const Expression &x)
  {
    return Expression(std::tan(x.toReal()));
  }

  Expression evalAsin(const Expression &x)
  {
    return Expression(std::asin(x.toReal()));
  }

  Expression evalAcos(const Expression &x)
  {
    return Expression(std::acos(x.toReal()));
  }

  Expression evalAtan(const Expression &x)
  {
    return Expression(std::atan(x.toReal()));
  }

  Expression evalAtan2(const Expression &x, const Expression &y)
  {
    return Expression(std::atan2(x.toReal(), y.toReal()));
  }

  Expression evalSinh(const Expression &x)
  {
    return Expression(std::sinh(x.toReal()));
  }

  Expression evalCosh(const Expression &x)
  {
    return Expression(std::cosh(x.toReal()));
  }

  Expression evalTanh(const Expression &x)
  {
    return Expression(std::tanh(x.toReal()));
  }

  Expression evalExp(const Expression &x)
  {
    return Expression(std::exp(x.toReal()));
  }

  Expression evalLog(const Expression &x)
  {
    return Expression(std::log(x.toReal()));
  }

  Expression evalLog10(const Expression &x)
  {
    return Expression(std::log10(x.toReal()));
  }

  Expression evalNdim(const Expression &A)
  {
    return Expression(static_cast<int64_t>((A.ndims())));
  }

  Expression evalSize(const Expression &A)
  {
    std::vector<Expression> res;
    const Expression *e = &A;

    while (e->isArray()) {
      auto &elems = e->elements();
      res.emplace_back(static_cast<int64_t>(elems.size()));

      if (elems.empty()) {
        break;
      }

      e = &elems[0];
    }

    return Expression(std::move(res));
  }

  Expression evalSize(const Expression &A, const Expression &i)
  {
    return Expression(static_cast<int64_t>(A.size(i.toInteger())));
  }

  Expression evalScalar(const Expression &A)
  {
    if (A.isArray()) {
      auto &elems = A.elements();

      if (elems.size() != 1) {
        throw std::runtime_error("Invalid argument " + A.toString() + " to scalar()");
      }

      return evalScalar(elems[0]);
    } else {
      return A;
    }
  }

  Expression evalVector(const Expression &A)
  {
    auto ndims = A.ndims();
    std::vector<Expression> elems;

    if (ndims == 0) {
      elems.emplace_back(A);
    } else if (ndims == 1) {
      elems = A.elements();
    } else {
      throw std::runtime_error("Invalid argument " + A.toString() + " to vector()");
    }

    return Expression(std::move(elems));
  }

  Expression evalMatrix(const Expression &A)
  {
    throw std::runtime_error("evalMatrix: not implemented yet");
  }

  Expression evalIdentity(const Expression &n)
  {
    if (!n.isNumber()) {
      throw std::runtime_error("Invalid argument " + n.toString() + " to identity()");
    }

    auto in = n.toInteger();

    std::vector<Expression> rows;
    rows.reserve(in);

    for (auto i = 0; i < in; ++i) {
      std::vector<Expression> row;

      for (auto j = 0; j < in; ++j) {
        row.emplace_back(i == j ? 1 : 0);
      }

      rows.emplace_back(row);
    }

    return Expression(std::move(rows));
  }

  Expression evalDiagonal(const Expression &v)
  {
    if (v.ndims() != 1) {
      throw std::runtime_error("Invalid argument " + v.toString() + " to diagonal()");
    }

    auto &elems = v.elements();
    auto n = elems.size();

    std::vector<Expression> rows;
    rows.reserve(n);

    for (auto i = 0u; i < n; ++i) {
      std::vector<Expression> row;

      for (auto j = 0u; j < n; ++j) {
        row.emplace_back(i == j ? elems[i] : Expression(0));
      }

      rows.emplace_back(row);
    }

    return Expression(std::move(rows));
  }

  template<class InputIt>
  Expression evalFill_impl(const Expression &value, InputIt first, InputIt last)
  {
    Expression res = value;

    for (auto it = first; it != last; ++it) {
      res = Expression(std::vector<Expression>(it->toInteger(), res));
    }

    return res;
  }

  Expression evalZeros(const std::vector<Expression> &args)
  {
    return evalFill_impl(Expression(int64_t{0}), args.rbegin(), args.rend());
  }

  Expression evalOnes(const std::vector<Expression> &args)
  {
    return evalFill_impl(Expression(int64_t{1}), args.rbegin(), args.rend());
  }

  Expression evalFill(const std::vector<Expression> &args)
  {
    return evalFill_impl(args[0], args.rbegin(), --args.rend());
  }

  Expression evalMin(const Expression &x, const Expression &y)
  {
    return x < y ? x : y;
  }

  Expression evalMin(const Expression &A)
  {
    if (A.isArray()) {
      Expression res(std::numeric_limits<double>::max());

      for (auto &e: A.elements()) {
        res = evalMin(res, evalMin(e));
      }

      return res;
    } else {
      return A;
    }
  }

  Expression evalMax(const Expression &x, const Expression &y)
  {
    return x < y ? y : x;
  }

  Expression evalMax(const Expression &A)
  {
    if (A.isArray()) {
      Expression res(std::numeric_limits<double>::min());

      for (auto &e: A.elements()) {
        res = evalMax(res, evalMax(e));
      }

      return res;
    } else {
      return A;
    }
  }

  Expression evalSum(const Expression &A)
  {
    if (A.isArray()) {
      Expression res(0);

      for (auto &e: A.elements()) {
        res += evalSum(e);
      }

      return res;
    } else {
      return A;
    }
  }

  Expression evalProduct(const Expression &A)
  {
    if (A.isArray()) {
      Expression res(1);

      for (auto &e: A.elements()) {
        res *= evalSum(e);
      }

      return res;
    } else {
      return A;
    }
  }

  Expression evalTranspose(const Expression &A)
  {
    if (A.ndims() < 2) {
      throw std::runtime_error("Invalid argument " + A.toString() + " to transpose()");
    }

    auto &elems = A.elements();
    std::vector<std::vector<Expression>> trans;
    trans.resize(elems.size());

    for (auto &row: elems) {
      auto it = trans.begin();

      for (auto &e: row.elements()) {
        it->emplace_back(e);
        ++it;
      }
    }

    std::vector<Expression> arr;

    for (auto &row: trans) {
      arr.emplace_back(row);
    }

    return Expression(std::move(arr));
  }

  Expression evalSymmetric(const Expression &A)
  {
    if (A.ndims() != 2) {
      throw std::runtime_error("Invalid argument " + A.toString() + " to symmetric()");
    }

    auto &elems = A.elements();
    auto n = elems.size();

    if (elems[0].elements().size() != n) {
      throw std::runtime_error("Invalid argument " + A.toString() + " to symmetric()");
    }

    // Make a vector with pointers to the rows, so we don't have to call
    // elements() over and over.
    std::vector<const std::vector<Expression>*> rows;
    rows.reserve(n);

    for (auto &row: elems) {
      rows.emplace_back(&row.elements());
    }

    std::vector<Expression> res;
    res.reserve(n);

    for (auto i = 0u; i < n; ++i) {
      std::vector<Expression> el;
      el.reserve(n);
      for (auto j = 0u; j < n; ++j) {
        el.emplace_back(i > j ? (*rows[j])[i] : (*rows[i])[j]);
      }
      res.emplace_back(el);
    }

    return Expression(std::move(res));
  }

  Expression evalCat(const std::vector<Expression> &args)
  {
    throw std::runtime_error("evalCat: not implemented yet");
  }
}
