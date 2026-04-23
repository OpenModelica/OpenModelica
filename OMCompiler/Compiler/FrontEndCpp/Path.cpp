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

#include <cassert>
#include <sstream>
#include <ostream>

#include "Util.h"
#include "Path.h"

using namespace OpenModelica;

constexpr int FULLYQUALIFIED = 2;
constexpr int QUALIFIED = 0;
constexpr int IDENT = 1;

extern record_description Absyn_Path_FULLYQUALIFIED__desc;
extern record_description Absyn_Path_QUALIFIED__desc;
extern record_description Absyn_Path_IDENT__desc;

Path::Path(std::vector<std::string> path, bool fullyQualified)
  : _names{std::move(path)}, _fullyQualified{fullyQualified}
{
  assert(!_names.empty());
}

Path::Path(std::string_view path)
{
  if (!path.empty() && path[0] == '.') {
    _fullyQualified = true;
    path.remove_prefix(1);
  }

  while (!path.empty()) {
    auto pos = path.find('.', 0);
    _names.emplace_back(path.substr(0, pos));
    path.remove_prefix(pos == path.npos ? path.size() : pos + 1);
  }

  assert(!_names.empty());
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

MetaModelica::Value Path::toAbsyn() const noexcept
{
  MetaModelica::Value res = MetaModelica::Record(IDENT, Absyn_Path_IDENT__desc, {MetaModelica::Value(_names.back())});

  for (auto it = ++_names.rbegin(); it != _names.rend(); ++it) {
    res = MetaModelica::Record(QUALIFIED, Absyn_Path_QUALIFIED__desc, {MetaModelica::Value(*it), res});
  }

  if (_fullyQualified) {
    res = MetaModelica::Record(FULLYQUALIFIED, Absyn_Path_FULLYQUALIFIED__desc, {res});
  }

  return res;
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

std::size_t Path::size() const noexcept
{
  return _names.size();
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
