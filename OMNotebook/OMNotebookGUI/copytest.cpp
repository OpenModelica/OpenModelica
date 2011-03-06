/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

//#include "cell.h"
#include "textcell.h"
#include "cellfactory.h"

using namespace std;
using namespace IAEX;


int main(int argc, char *argv[])
{

   CellFactory *f = new CellFactory();

   TextCell *t = f->createCell("text"); //new TextCell();

   t->setText("Hello COPY");

   TextCell *c = f->copyCell(t);


   cout << "Original: " << t->text() << endl;
   cout << "Copied text: " << c->text() << endl;

   t->setText("Changed");

   cout << "Changed orig: " << t->text() << endl;
   cout << "copy " << c->text() << endl;

   return 0;
}
