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

#ifndef MMCACHE_H
#define MMCACHE_H

#include <memory>
#include <vector>
#include <unordered_map>
#include <stdexcept>

#include "MetaModelica.h"

namespace OpenModelica
{
  // Utility class to convert MetaModelica structures to C++ and cache them.
  // Since MetaModelica has no ownership semantics while a single owner is
  // desirable in C++, the cache keeps an owning pointer to the value until the
  // actual owner requests it and an observing pointer for the lifetime of the
  // cache.
  template<typename T>
  class MMCache
  {
    public:
      // Returns ownership of the converted value.
      std::unique_ptr<T> getOwnedPtr(MetaModelica::Record value)
      {
        auto it = _cache.find(value);

        if (it != _cache.end()) {
          // The value is already cached, transfer ownership of it to the caller.
          if (!it->second.owner) {
            throw std::runtime_error("MMCache::getOwnedPtr: " + it->second.ptr->str() + " already has an owner");
          }
          return std::move(it->second.owner);
        } else {
          // The node isn't cached, convert it and save an observing pointer to it in the cache.
          auto p = T::fromMM(value);
          _cache[value] = CacheEntry{nullptr, p.get()};
          // Initialize the node after caching it to avoid infinite recursion.
          if (p) p->initialize();
          // Transfer ownership to the caller.
          return p;
        }
      }

      std::vector<std::unique_ptr<T>> getOwnedPtrs(MetaModelica::Value value)
      {
        return value.mapVector([=](auto v) { return getOwnedPtr(v); });
      }

      // Returns an observing pointer to the value.
      T* getReference(MetaModelica::Record value)
      {
        auto it = _cache.find(value);

        if (it != _cache.end()) {
          // The node is already cached, return an observing pointer to it.
          return it->second.ptr;
        } else {
          // The node isn't cached, add it to the cache.
          auto p = T::fromMM(value);
          auto ptr = p.get();
          _cache[value] = CacheEntry{std::move(p), ptr};
          // Initialize the node after caching it to avoid infinite recursion.
          if (ptr) ptr->initialize();
          // Keep ownership of the node and only return an observing pointer to it.
          return ptr;
        }
      }

      std::vector<T*> getReferences(MetaModelica::Value value)
      {
        return value.mapVector([=](auto v) { return getReference(v); });
      }

    private:
      struct CacheEntry
      {
        std::unique_ptr<T> owner;
        T *ptr;
      };

      std::unordered_map<MetaModelica::Record, CacheEntry> _cache;
  };

  template<typename T>
  class MMSharedCache
  {
    public:
      // Returns ownership of the converted value.
      std::shared_ptr<T> getOwnedPtr(MetaModelica::Record value)
      {
        auto it = _cache.find(value);

        if (it != _cache.end()) {
          return it->second.owner;
        } else {
          // The node isn't cached, convert it and save an observing pointer to it in the cache.
          std::shared_ptr<T> p = T::fromMM(value);
          _cache[value] = CacheEntry{p, p.get()};
          return p;
        }
      }

      std::vector<std::shared_ptr<T>> getOwnedPtrs(MetaModelica::Value value)
      {
        return value.mapVector([=](auto v) { return getOwnedPtr(v); });
      }

      // Returns an observing pointer to the value.
      T* getReference(MetaModelica::Record value)
      {
        auto it = _cache.find(value);

        if (it != _cache.end()) {
          // The node is already cached, return an observing pointer to it.
          return it->second.ptr;
        } else {
          // The node isn't cached, add it to the cache.
          std::shared_ptr<T> p = T::fromMM(value);
          _cache[value] = CacheEntry{p, p.get()};
          return p.get();
        }
      }

      std::vector<T*> getReferences(MetaModelica::Value value)
      {
        return value.mapVector([=](auto v) { return getReference(v); });
      }

    private:
      struct CacheEntry
      {
        std::shared_ptr<T> owner;
        T *ptr;
      };

      std::unordered_map<MetaModelica::Record, CacheEntry> _cache;
  };
}

#endif /* MMCACHE_H */
