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
/*
 * @author Volker Waurich <volker.waurich@tu-dresden.de>
 */

#include "ExtraShapes.h"
#include <iostream>

Pipecylinder::Pipecylinder(float rI, float rO, float l) :
	osg::Geometry()
{
	const int nEdges = 20;
	double phi = 2 * M_PI/nEdges;

	//VERTICES
	osg::Vec3Array* vertices = new osg::Vec3Array;
	// inner base ring
	for (int i = 0; i < nEdges; i++)	{
		vertices->push_back(osg::Vec3(sin(phi*i)*rI, cos(phi*i)*rI, 0));
	}
	// outer base ring
	for (int i = 0; i < nEdges; i++)	{
		vertices->push_back(osg::Vec3(sin(phi*i)*rO, cos(phi*i)*rO, 0));
	}
	// inner end ring
	for (int i = 0; i < nEdges; i++) {
		vertices->push_back(osg::Vec3(sin(phi*i)*rI, cos(phi*i)*rI, l));
	}
	// outer end ring
	for (int i = 0; i < nEdges; i++) {
		vertices->push_back(osg::Vec3(sin(phi*i)*rO, cos(phi*i)*rO, l));
	}
	this->setVertexArray(vertices);

	//PLANES
	// base plane bottom
	osg::DrawElementsUInt* basePlane = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 0);
	basePlane->push_back(0);
	basePlane->push_back(nEdges-1);
	basePlane->push_back(2*nEdges-1);
	basePlane->push_back(nEdges);
	this->addPrimitiveSet(basePlane);

	for (int i = 0; i < (nEdges-1); i++) {
		basePlane = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 0);
		basePlane->push_back(0 + i);
		basePlane->push_back(1 + i);
		basePlane->push_back(nEdges +1 +i);
		basePlane->push_back(nEdges + 0 + i);
		this->addPrimitiveSet(basePlane);
	}

	// base plane top
	basePlane = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 0);
	basePlane->push_back(0+2*nEdges);
	basePlane->push_back(nEdges - 1 + 2 * nEdges);
	basePlane->push_back(2 * nEdges - 1 + 2 * nEdges);
	basePlane->push_back(nEdges + 2 * nEdges);
	this->addPrimitiveSet(basePlane);

	for (int i = (2 * nEdges); i < (nEdges - 1 + (2 * nEdges)); i++) {
		basePlane = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 0);
		basePlane->push_back(0 + i);
		basePlane->push_back(1 + i);
		basePlane->push_back(nEdges + 1 + i);
		basePlane->push_back(nEdges + 0 + i);
		this->addPrimitiveSet(basePlane);
	}

	//inner lateral planes
	basePlane = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 0);
	basePlane->push_back(0);
	basePlane->push_back(nEdges - 1);
	basePlane->push_back(3 * nEdges-1);
	basePlane->push_back(2 * nEdges);
	this->addPrimitiveSet(basePlane);

	for (int i = 0; i < (nEdges - 1); i++) {
		basePlane = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 0);
		basePlane->push_back(i);
		basePlane->push_back(i+1);
		basePlane->push_back(i + 1 + 2*nEdges);
		basePlane->push_back(i + 2*nEdges);
		this->addPrimitiveSet(basePlane);
	}
	//outer lateral planes
	basePlane = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 0);
	basePlane->push_back(nEdges);
	basePlane->push_back(2*nEdges - 1);
	basePlane->push_back(4 * nEdges-1);
	basePlane->push_back(3 * nEdges);
	this->addPrimitiveSet(basePlane);

	//outer lateral planes
	for (int i = nEdges; i < (2*nEdges - 1); i++) {
		basePlane = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 0);
		basePlane->push_back(i);
		basePlane->push_back(i + 1);
		basePlane->push_back(i + 1 + 2 * nEdges);
		basePlane->push_back(i + 2 * nEdges);
		this->addPrimitiveSet(basePlane);
	}
}
