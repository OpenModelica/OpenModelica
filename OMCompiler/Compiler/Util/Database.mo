/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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

encapsulated package Database
" file:        Database.mo
  package:     Database
  description: This module contains functionality for creating and using SQlite databases.

  $Id$

  This package provides functionality for creating and using databases.
  It is a wrapper to SQlite."

public function open "opens a datbase with the given index and the given name. fails if it cannot do it."
  input Integer index "the index, max 1024";
  input String name "the name of the file or :memory: to have an in-memory database";

  external "C" Database_open(index, name) annotation(Library = "omcruntime");
end open;

public function query "query a datbase with the given index (previously open). fails if it cannot do it."
  input Integer index "the index, max 1024";
  input String sql "the sql query string";
  output list<tuple<String,String>> result "returns a list of tuples (columnName, value)";

  external "C" result = Database_query(index, sql) annotation(Library = "omcruntime");
end query;

annotation(__OpenModelica_Interface="util");
end Database;
