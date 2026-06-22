// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/Corba.mo`'s `external "C"`
// declarations. Upstream these bind `runtime/Corba_omc.cpp` (the real CORBA
// connection, built only with `--with-omniORB`/`--with-MICO`) or, in a build
// configured without CORBA, the `runtime/corbaimpl_stub_omc.c` stub.
//
// The Rust port is built WITHOUT CORBA, so this module mirrors the stub:
//   * `Corba_haveCorba()` returns 0 → `haveCorba()` returns `false`.
//   * Every other entry point prints the "CORBA disabled" message and
//     `MMC_THROW()`s → here a recoverable MetaModelica failure (`bail!`).
// Because `haveCorba()` reports false, omc selects ZMQ/stdin communication and
// none of the failing entry points are ever reached at runtime.
//
// `Corba` is listed in `HANDWRITTEN_TOP_PACKAGES` (mmtorust/src/codegen.rs) so
// its codegen is skipped in favour of this file.

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

use anyhow::{Result, bail};
use arcstr::ArcStr;

/// `Corba_haveCorba` — the stub build reports CORBA unavailable.
pub fn haveCorba() -> bool {
    false
}

pub(crate) fn setObjectReferenceFilePath(_inObjectReferenceFilePath: ArcStr) -> Result<()> {
    bail!("CORBA disabled. Configure with --with-omniORB (or --with-MICO) and recompile to enable.");
}

pub(crate) fn setSessionName(_inSessionName: ArcStr) -> Result<()> {
    bail!("CORBA disabled. Configure with --with-omniORB (or --with-MICO) and recompile to enable.");
}

pub fn initialize() -> Result<()> {
    bail!("CORBA disabled. Configure with --with-omniORB (or --with-MICO) and recompile to enable.");
}

pub fn waitForCommand() -> Result<ArcStr> {
    bail!("CORBA disabled. Configure with --with-omniORB (or --with-MICO) and recompile to enable.");
}

pub fn sendreply(_inString: ArcStr) -> Result<()> {
    bail!("CORBA disabled. Configure with --with-omniORB (or --with-MICO) and recompile to enable.");
}

pub fn close() -> Result<()> {
    bail!("CORBA disabled. Configure with --with-omniORB (or --with-MICO) and recompile to enable.");
}
