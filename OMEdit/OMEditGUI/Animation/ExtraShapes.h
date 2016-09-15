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

#ifndef EXTRASHAPES_H
#define EXTRASHAPES_H

#include <osg/Node>
#include <osg/Group>
#include <osg/Geode>
#include <osg/Geometry>
#include <osg/Shape>

class Pipecylinder : public osg::Geometry
{
public:
	Pipecylinder(float rI, float rO, float l);
	~Pipecylinder() {};
};


class Spring : public osg::Geometry
{
public:
	Spring(float r, float rCoil, float nWindings,  float l);
	~Spring() {};
private:
   osg::Vec3f getNormal(osg::Vec3f vec, float length = 1);
   osg::Vec3f normalize(osg::Vec3f vec);
   osg::Vec3f rotateX(osg::Vec3f vec, float phi);
   osg::Vec3f rotateY(osg::Vec3f vec, float phi);
   osg::Vec3f rotateZ(osg::Vec3f vec, float phi);
   osg::Vec3f rotateArbitraryAxis_expensive(osg::Vec3f vec, osg::Vec3f axis, float phi);
   osg::Vec3f rotateArbitraryAxis(osg::Vec3f vec, osg::Vec3f axis, float phi);
   float absoluteVector(osg::Vec3f vec);
   float angleBetweenVectors(osg::Vec3f vec1, osg::Vec3f vec2);

   osg::Vec3Array* mpOuterVertices;
   osg::Vec3Array* mpSplineVertices;
};

#endif //end EXTRASHAPES_H
