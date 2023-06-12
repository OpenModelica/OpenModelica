#include <cassert>
#include <sstream>
#include <ostream>

#include "Util.h"
#include "Path.h"

using namespace OpenModelica;

constexpr int FULLYQUALIFIED = 2;
constexpr int QUALIFIED = 0;
constexpr int IDENT = 1;

Path::Path(std::vector<std::string> path, bool fullyQualified)
  : _names{std::move(path)}, _fullyQualified{fullyQualified}
{
  assert(!path.empty());
}

Path::Path(MetaModelica::Record value)
  : _fullyQualified{value.index() == 2}
{
  MetaModelica::Record v = value;

  while (v.index() == FULLYQUALIFIED) {
    v = v[0];
  }

  while (v.index() == QUALIFIED) {
    _names.push_back(v[0].toString());
    v = v[1];
  }

  _names.push_back(v[0].toString());
}

void Path::push_back(std::string name) noexcept
{
  _names.emplace_back(std::move(name));
}

void Path::pop_back() noexcept
{
  assert(_names.size() > 1);
  _names.pop_back();
}

bool Path::isIdent() const noexcept
{
  return _names.size() == 1;
}

bool Path::isQualified() const noexcept
{
  return _names.size() > 1;
}

bool Path::isFullyQualified() const noexcept
{
  return _fullyQualified;
}

const std::string& Path::front() const noexcept
{
  return _names.front();
}

const std::string& Path::back() const noexcept
{
  return _names.back();
}

Path Path::rest() const noexcept
{
  assert(_names.size() > 1);
  Path p = *this;
  p._names.pop_back();
  return p;
}

Path Path::fullyQualify() const noexcept
{
  return {_names, true};
}

Path Path::unqualify() const noexcept
{
  return {_names, false};
}

std::string Path::str() const noexcept
{
  std::ostringstream ss;
  ss << *this;
  return ss.str();
}

std::ostream& OpenModelica::operator<< (std::ostream &os, const Path &path) noexcept
{
  if (path._fullyQualified) os << '.';
  os << Util::printList(path._names, ".");
  return os;
}
