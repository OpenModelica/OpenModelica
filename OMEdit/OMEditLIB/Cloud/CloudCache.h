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

#ifndef CLOUDCACHE_H
#define CLOUDCACHE_H

#include "Cloud/CloudMount.h"

#include <functional>

/*!
 * \brief Keeps a mount's working copy across a restart of the application.
 *
 * A no-op natively, where the working copy is a real directory. In the browser it
 * is in memory, so without this every reload re-downloads the package. IndexedDB
 * rather than PersistentStorage's localStorage: package contents are far larger,
 * and nothing here runs during startup, so waiting for the database is fine.
 */
namespace CloudCache
{
  bool isAvailable();

  //! Mirror the working copy. Cheap enough to call after every save.
  void save(const CloudMount &mount);

  //! Puts the cache back and reports how many files arrived. done() is always
  //! invoked from the event loop, never inside the caller's frame.
  void restore(const CloudMount &mount, const std::function<void(int)> &done);

  //! Forget a mount's contents; for an unmount.
  void forget(const CloudMount &mount);
}

#endif // CLOUDCACHE_H
