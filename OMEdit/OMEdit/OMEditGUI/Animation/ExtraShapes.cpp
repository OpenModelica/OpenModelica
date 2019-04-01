/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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


/*!
 * \brief absoluteVector
 * \param the input vector
 * gets the length of a vector
 * \return the length
 */
float absoluteVector(osg::Vec3f vec)
{
  return std::sqrt(std::pow(vec[0], 2) + std::pow(vec[1], 2) + std::pow(vec[2], 2));
}

/*!
 * \brief normalize
 * \param the input vector
 * normalizes a vector
 * \return the normalized vector
 */
osg::Vec3f normalizeVec(osg::Vec3f vec) {
  float abs = absoluteVector(vec);
  return osg::Vec3f(vec[0]/abs, vec[1] / abs, vec[2] / abs);
}




/*!
 * \brief Pipecylinder::Pipecylinder
 * creates a pipe or pipecylinder geometry
 */
Pipecylinder::Pipecylinder(float rI, float rO, float l) :
  osg::Geometry()
{
  const int nEdges = 16;
  double phi = 2 * M_PI/nEdges;
  int vertIdx = 0;
  //VERTICES
  osg::Vec3Array* vertices = new osg::Vec3Array;
  osg::Vec3Array* normals = new osg::Vec3Array;
  osg::Vec2Array* texcoords = new osg::Vec2Array;
  float radiusRatioShift = rI/rO*0.5f;
  //we need so set the vertices multiple times to have a unique set of vertices per facet.
  //Thats needed for the normals which are assigned per vertex.
  //Also keep in mind to normalize the normals

  //THE BASE PLANE VERTICES
  // inner base ring
  for (int i = 0; i < nEdges; i++)  {
    vertices->push_back(osg::Vec3(sin(phi*i)*rI, cos(phi*i)*rI, 0));
    normals->push_back(osg::Vec3(0.0f,0.0f,-1.0f));
    texcoords->push_back(osg::Vec2((sin(phi*i)*radiusRatioShift)+0.5f, (cos(phi*i)*radiusRatioShift)+0.5f));
    vertIdx++;
  }
  // outer base ring
  for (int i = 0; i < nEdges; i++)  {
    vertices->push_back(osg::Vec3(sin(phi*i)*rO, cos(phi*i)*rO, 0));
    normals->push_back(osg::Vec3(0.0f,0.0f,-1.0f));
    texcoords->push_back((osg::Vec2((sin(phi*i)*0.5f)+0.5f, (cos(phi*i)*0.5f)+0.5f)));
    vertIdx++;
  }
  //THE TOP PLANE VERTICES
  // inner end ring
  for (int i = 0; i < nEdges; i++) {
    vertices->push_back(osg::Vec3(sin(phi*i)*rI, cos(phi*i)*rI, l));
    normals->push_back(osg::Vec3(0.0f,0.0f,1.0f));
    texcoords->push_back(osg::Vec2((sin(phi*i)*radiusRatioShift)+0.5f, (cos(phi*i)*radiusRatioShift)+0.5f));
    vertIdx++;
  }
  // outer end ring
  for (int i = 0; i < nEdges; i++) {
    vertices->push_back(osg::Vec3(sin(phi*i)*rO, cos(phi*i)*rO, l));
    normals->push_back(osg::Vec3(0.0f,0.0f,1.0f));
    texcoords->push_back(osg::Vec2((sin(phi*i)*0.5f)+0.5f, (cos(phi*i)*0.5f)+0.5f));
    vertIdx++;
  }

  //BASE AND TOP PLANES
  // base plane bottom (since the planes share the same normals, we can use vertices multiple times to create planes)
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

  // base plane top (since the planes share the same normals, we can use vertices multiple times to create planes)
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

  //AND AGAIN FOR THE OUTER LATERAL PLANES
  for (int i = 0; i < nEdges; i++)  {
  int j = i+1;
  // the vertices
    vertices->push_back(osg::Vec3(sin(phi*i)*rO, cos(phi*i)*rO, 0));
    vertices->push_back(osg::Vec3(sin(phi*j)*rO, cos(phi*j)*rO, 0));
    vertices->push_back(osg::Vec3(sin(phi*j)*rO, cos(phi*j)*rO, l));
    vertices->push_back(osg::Vec3(sin(phi*i)*rO, cos(phi*i)*rO, l));
    // the normals
    double phiN = phi*(i+0.5);
    normals->push_back(normalizeVec(osg::Vec3(sin(phiN)*rO, cos(phiN)*rO, 0)));
    normals->push_back(normalizeVec(osg::Vec3(sin(phiN)*rO, cos(phiN)*rO, 0)));
    normals->push_back(normalizeVec(osg::Vec3(sin(phiN)*rO, cos(phiN)*rO, 0)));
    normals->push_back(normalizeVec(osg::Vec3(sin(phiN)*rO, cos(phiN)*rO, 0)));
    //the texture coordinates
    texcoords->push_back(osg::Vec2(1.0f*i/(nEdges), 1.0f));
    texcoords->push_back(osg::Vec2(1.0f*j/(nEdges), 1.0f));
    texcoords->push_back(osg::Vec2(1.0f*j/(nEdges), 0.0f));
    texcoords->push_back(osg::Vec2(1.0f*i/(nEdges), 0.0f));
    //the planes
    basePlane = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 0);
    basePlane->push_back(vertIdx);
    basePlane->push_back(vertIdx+1);
    basePlane->push_back(vertIdx+2);
    basePlane->push_back(vertIdx+3);
    this->addPrimitiveSet(basePlane);
    vertIdx = vertIdx+4;
  }

    //AND AGAIN FOR THE INNER LATERAL PLANES
  for (int i = 0; i < nEdges; i++)  {
  int j = i+1;
  // the vertices
    vertices->push_back(osg::Vec3(sin(phi*i)*rI, cos(phi*i)*rI, 0));
    vertices->push_back(osg::Vec3(sin(phi*j)*rI, cos(phi*j)*rI, 0));
    vertices->push_back(osg::Vec3(sin(phi*j)*rI, cos(phi*j)*rI, l));
    vertices->push_back(osg::Vec3(sin(phi*i)*rI, cos(phi*i)*rI, l));
    // the normals
    double phiN = phi*(i+0.5);
    normals->push_back(normalizeVec(osg::Vec3(-sin(phiN)*rI, -cos(phiN)*rI, 0)));
    normals->push_back(normalizeVec(osg::Vec3(-sin(phiN)*rI, -cos(phiN)*rI, 0)));
    normals->push_back(normalizeVec(osg::Vec3(-sin(phiN)*rI, -cos(phiN)*rI, 0)));
    normals->push_back(normalizeVec(osg::Vec3(-sin(phiN)*rI, -cos(phiN)*rI, 0)));
    //the texture coordinates
    texcoords->push_back(osg::Vec2(1.0f*i/(nEdges), 0.0f));
    texcoords->push_back(osg::Vec2(1.0f*j/(nEdges), 0.0f));
    texcoords->push_back(osg::Vec2(1.0f*j/(nEdges), 1.0f));
    texcoords->push_back(osg::Vec2(1.0f*i/(nEdges), 1.0f));
    //the planes
    basePlane = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 0);
    basePlane->push_back(vertIdx);
    basePlane->push_back(vertIdx+1);
    basePlane->push_back(vertIdx+2);
    basePlane->push_back(vertIdx+3);
    this->addPrimitiveSet(basePlane);
    vertIdx = vertIdx+4;
  }

  this->setVertexArray(vertices);
  this->setNormalArray(normals);
  this->setTexCoordArray(0,texcoords);
  this->setNormalBinding( osg::Geometry::BIND_PER_VERTEX);
}

/*!
 * \brief Spring::getNormal
 * \param the input vector
 * \param the length of the out vector
 * gets an arbitrary normal to the input vector
 * \return the normal
 */
osg::Vec3f Spring::getNormal(osg::Vec3f vec, float length) {
  osg::Vec3f vecN = normalizeVec(vec);
  osg::Vec3f vecN_Abs = osg::Vec3f(std::abs(vecN[0]), std::abs(vecN[1]), std::abs(vecN[2]));

  //Get max value in vec
  float maxVal = std::fmaxf(std::fmaxf(vecN_Abs[0], vecN_Abs[1] ), vecN_Abs[2]);
  int imax = 0;
  if (vecN_Abs[0] == maxVal)
    imax = 0;
  else if (vecN_Abs[1] == maxVal)
    imax = 1;
  else
    imax = 2;

  int rest[2] = {0,0};

  switch (imax) {
  case(0) : rest[0] = 1; rest[1] = 2 ; break;
  case(1) : rest[0] = 0; rest[1] = 2 ; break;
  case(2) : rest[0] = 0; rest[1] = 1 ; break;
  }
  //calc a normal vector
  osg::Vec3f n = osg::Vec3f(0, 0, 0);
  n[rest[0]] = 1;
  n[rest[1]] = 1;
  n[imax] = -(vecN[rest[0]] + vecN[rest[1]]) / vecN[imax];
  n = normalizeVec(n);
  n[0] = n[0] * length;
  n[1] = n[1] * length;
  n[2] = n[2] * length;
  return n;
}


/*!
 * \brief Spring::angleBetweenVectors
 * \param vector1
 * \param vector2
 * gets the angle between 2 vectors
 * \return the angle
 */
float Spring::angleBetweenVectors(osg::Vec3f vec1, osg::Vec3f vec2)
{
  float scalarProduct = vec1[0] * vec2[0] + vec1[1] * vec2[1] + vec1[2] * vec2[2];
  return (std::acos(scalarProduct/(absoluteVector(vec1)*absoluteVector(vec2)))/* / M_PI * 180*/);
}

/*!
 * \brief Spring::rotateX
 * \param vector1
 * \param angle
 * rotates the vector around the cartesian x axis with angle phi
 * \return the rotated vector
 */
osg::Vec3f Spring::rotateX(osg::Vec3f vec, float phi)
{
  return osg::Vec3f(  vec[0],
            vec[1] * std::cos(phi) - vec[2] * std::sin(phi),
            vec[1] * std::sin(phi) + vec[2] * std::cos(phi));
}

/*!
 * \brief Spring::rotateY
 * \param vector1
 * \param angle
 * rotates the vector around the cartesian y axis with angle phi
 * \return the rotated vector
 */
osg::Vec3f Spring::rotateY(osg::Vec3f vec, float phi)
{
  return osg::Vec3f(  vec[2] * std::sin(phi) + vec[0] * std::cos(phi),
            vec[1],
            vec[2] * std::cos(phi) - vec[0] * std::sin(phi));
}

/*!
 * \brief Spring::rotateZ
 * \param vector1
 * \param angle
 * rotates the vector around the cartesian z axis with angle phi
 * \return the rotated vector
 */
osg::Vec3f Spring::rotateZ(osg::Vec3f vec, float phi)
{
  return osg::Vec3f(  vec[0] * std::cos(phi) - vec[1] * std::sin(phi),
            vec[0] * std::sin(phi) + vec[1] * std::cos(phi),
            vec[2]);
}

/*!
 * \brief Spring::rotateArbitraryAxis_expensive
 * \param vector1
 * \param rotation axis
 * \param angle
 * rotates the vector around the given axis with angle phi, this is a bit odd, use rotateArbitraryAxis
 * \return the rotated vector
 */
osg::Vec3f Spring::rotateArbitraryAxis_expensive(osg::Vec3f vec, osg::Vec3f axis,  float phi)
{
  //this is how I would do it by hand.  Check out rotateArbitraryAxis, thats the shortest formula.
  //There is also still something wrong in here
  osg::Vec3f axisN = normalizeVec(axis);
  osg::Vec3f aux = vec;
  //angle between vec and x, rotate in xz-plane
  float phiX = angleBetweenVectors(axisN, osg::Vec3f(1, 0, 0));
  aux = rotateX(aux, phiX);
  //angle between vec and x, rotate in z axis
  float phiY = angleBetweenVectors(axisN, osg::Vec3f(0, 1, 0));
  aux = rotateY(aux, phiY);
  // rotate around z
  aux = rotateZ(aux, phi);
  // and reverse
  aux = rotateY(aux,  -phiY);
  aux = rotateX(aux,  -phiX);
  return aux;
}

/*!
 * \brief Spring::rotateArbitraryAxis
 * \param vector1
 * \param rotation axis
 * \param angle
 * rotates the vector around the given axis with angle phi
 * \return the rotated vector
 */
osg::Vec3f Spring::rotateArbitraryAxis(osg::Vec3f vec, osg::Vec3f axis, float phi)
{
  osg::Vec3f axisN = normalizeVec(axis);
  float M1_1 = (1 - std::cos(phi)) * axisN[0] * axisN[0] + std::cos(phi) * 1 + std::sin(phi) * 0;
  float M1_2 = (1 - std::cos(phi)) * axisN[0] * axisN[1] + std::cos(phi) * 0 + std::sin(phi) * (-axisN[2]);
  float M1_3 = (1 - std::cos(phi)) * axisN[0] * axisN[2] + std::cos(phi) * 0 + std::sin(phi) * (axisN[1]);
  float M2_1 = (1 - std::cos(phi)) * axisN[0] * axisN[1] + std::cos(phi) * 0 + std::sin(phi) * (axisN[2]);
  float M2_2 = (1 - std::cos(phi)) * axisN[1] * axisN[1] + std::cos(phi) * 1 + std::sin(phi) * 0;
  float M2_3 = (1 - std::cos(phi)) * axisN[1] * axisN[2] + std::cos(phi) * 0 + std::sin(phi) * (-axisN[0]);
  float M3_1 = (1 - std::cos(phi)) * axisN[0] * axisN[2] + std::cos(phi) * 0 + std::sin(phi) * (-axisN[1]);
  float M3_2 = (1 - std::cos(phi)) * axisN[1] * axisN[2] + std::cos(phi) * 0 + std::sin(phi) * (axisN[0]);
  float M3_3 = (1 - std::cos(phi)) * axisN[2] * axisN[2] + std::cos(phi) * 1 + std::sin(phi) * 0;
  return osg::Vec3f(M1_1*vec[0]+ M1_2*vec[1]+ M1_3*vec[2], M2_1*vec[0] + M2_2*vec[1] + M2_3*vec[2], M3_1*vec[0] + M3_2*vec[1] + M3_3*vec[2]);
}


/*!
 * \brief Spring::Spring
 * \param center radius of the coil
 * \param radius of the wire
 * \param number of windings
 * \param the length
 * creates an osg spring geometry
 */
Spring::Spring(float r, float rWire, float nWindings, float l) :
  osg::Geometry()
{
  float R = r;
  float L = l;
  float RWIRE = rWire;
  float NWIND = nWindings;

  const int ELEMENTS_WINDING = 10;
  const int ELEMENTS_CONTOUR = 6;

  this->getPrimitiveSetList().clear();

  //the inner line points
  int numSegments = (ELEMENTS_WINDING * NWIND) + 1;
  mpSplineVertices = new osg::Vec3Array(numSegments);

  for (int segIdx = 0; segIdx < numSegments; segIdx++)
  {
    float x = std::sin(2 * M_PI / ELEMENTS_WINDING * segIdx) * R;
    float y = std::cos(2 * M_PI / ELEMENTS_WINDING * segIdx) * R;
    float z = L / numSegments * segIdx;
    (*mpSplineVertices)[segIdx].set(osg::Vec3(x,y,z));
  }

  //the outer points for the facettes
  int numVertices = (numSegments + 1)*ELEMENTS_CONTOUR;
  mpOuterVertices = new osg::Vec3Array(numVertices);
  osg::Vec3f normal;
  osg::Vec3f v1;
  osg::Vec3f v2;
  int vertIdx = 0;
  for (int i = 0; i < numSegments-1; i++)
  {
    v1 = mpSplineVertices->at(i);
    v2 = mpSplineVertices->at(i + 1);
    normal = osg::Vec3f(v2[0] - v1[0], v2[1] - v1[1], v2[2] - v1[2]);
    osg::Vec3f vec0 = normal;
    normal = getNormal(normal, RWIRE);
    for (int i1 = 0; i1 < ELEMENTS_CONTOUR; i1++)
    {
      float angle = M_PI * 2 / ELEMENTS_CONTOUR * i1;
      osg::Vec3f a1 = rotateArbitraryAxis(normal, vec0, angle);
      (*mpOuterVertices)[vertIdx].set(osg::Vec3f((v1[0] + a1[0]), (v1[1] + a1[1]), (v1[2] + a1[2])));
      vertIdx++;
    }
  }

  // pass the created vertex array to the points geometry object.
  this->setVertexArray(mpOuterVertices);

  //PLANES
  // base plane bottom
  osg::DrawElementsUInt* basePlane = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 0);
  int numFacettes = ELEMENTS_CONTOUR * (numSegments - 2);
  for (int i = 0; i < numFacettes; i++) {
    basePlane = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 0);
    basePlane->push_back(i);
    basePlane->push_back(i + 1);
    basePlane->push_back(i + ELEMENTS_CONTOUR);
    basePlane->push_back(i + ELEMENTS_CONTOUR-1);
    this->addPrimitiveSet(basePlane);
  }
  //std::cout << "NUM " << mpOuterVertices->size() << std::endl;
  //this->addPrimitiveSet(new osg::DrawArrays(osg::PrimitiveSet::POINTS, 0, mpOuterVertices->size()));
}


/*!
 * \brief getAutoCADRGB
 * get rgb color values for AutoCAD colorcoding accoridng to: http://sub-atomic.com/~moses/acadcolors.html
 * \param int colorCode
 */
osg::Vec4f getAutoCADRGB(int colorCode)
{
  osg::Vec4f col;
  switch (colorCode)
  {
  case(0) :
    col = osg::Vec4f(0.0f / 255.0f, 0.0f / 255.0f, 0.0f / 255.0f, 1.0);
    break;
  case(1) :
    col = osg::Vec4f(255.0f / 255.0f, 0.0f / 255.0f, 0.0f / 255.0f, 1.0);
    break;
  case(2) :
    col = osg::Vec4f(255.0f / 255.0f, 255.0f / 255.0f, 0.0f / 255.0f, 1.0);
    break;
  case(3) :
    col = osg::Vec4f(0.0f / 255.0f, 255.0f / 255.0f, 0.0f / 255.0f, 1.0);
    break;
  case(4) :
    col = osg::Vec4f(0.0f / 255.0f, 255.0f / 255.0f, 255.0f / 255.0f, 1.0);
    break;
  case(30) :
    col = osg::Vec4f(255.0f / 255.0f, 127.0f / 255.0f, 0.f / 255.0f, 1.0);
    break;
  case(251) :
    col = osg::Vec4f(80.0f / 255.0f, 80.0f / 255.0f, 80.0f / 255.0f, 1.0);
    break;
  default:
    col = osg::Vec4f(0 / 255, 0 / 255, 0 / 255, 1.0);
    break;
  }
  return col;
}

/*!
 * \brief constructor for DXF3dFace
 */
DXF3dFace::DXF3dFace()
  :
  vec1(),
    vec2(),
    vec3(),
    vec4(),
  layer(""),
  colorCode(0),
  color()
{
}

/*!
 * \brief desctructor for DXF3dFace
 */
DXF3dFace::~DXF3dFace()
{
}

/*!
 * \brief DXF3dFace::dumpDXF3DFace
 * dumps information aboput 3d face on stdout
 */
void DXF3dFace::dumpDXF3DFace()
{
  std::cout << "3-DFACE (" << vec1[0] <<", " << vec1[1]<<", "<< vec1[2]<<")"
                   <<"(" << vec2[0] <<", " << vec2[1]<<", "<< vec2[2]<<")"
                   << "("<< vec3[0] << ", "<< vec3[1]<<", "<< vec3[2] << ")"
                   <<"(" << vec4[0] << ", "<< vec4[1]<<", "<< vec4[2]<< ")" <<std::endl;

}

/*!
 * \brief DXF3dFace::fill3dFace
 * fills a 3d face object with information from the textstream
 * \param QTextStream* stream
 */
QString DXF3dFace::fill3dFace(QTextStream* stream)
{
  QString line = "";
  int done = 0;
  int lineCode = 0;
  while (!done)
  {
    line = stream->readLine();
    if (!line.compare("3DFACE"))
    {
      done = 1;
    }
    lineCode = line.toInt();

    switch (lineCode)
    {
    case (8) :
      //layer name
      layer = stream->readLine().toInt();
      break;
    case (62) :
      //color number
      colorCode = stream->readLine().toInt();
      color = getAutoCADRGB(colorCode);
      break;
    case (10) :
      //first corner x
      vec1[0] = stream->readLine().toDouble();
      break;
    case (20) :
      //first corner y
      vec1[1] = stream->readLine().toDouble();
      break;
    case (30) :
      //first corner z
      vec1[2] = stream->readLine().toDouble();
      break;
    case (11) :
      //second corner x
      vec2[0] = stream->readLine().toDouble();
      break;
    case (21) :
      //second corner y
      vec2[1] = stream->readLine().toDouble();
      break;
    case (31) :
      //second corner z
      vec2[2] = stream->readLine().toDouble();
      break;
    case (12) :
      //third corner x
      vec3[0] = stream->readLine().toDouble();
      break;
    case (22) :
      //third corner y
      vec3[1] = stream->readLine().toDouble();
      break;
    case (32) :
      //third corner z
      vec3[2] = stream->readLine().toDouble();
      break;
    case (13) :
      //fourth corner x
      vec4[0] = stream->readLine().toDouble();
      break;
    case (23) :
      //fourth corner y
      vec4[1] = stream->readLine().toDouble();
      break;
    case (33) :
      //fourth corner z
      vec4[2] = stream->readLine().toDouble();
      break;
    case (70) :
      //invisible edge flag
      stream->readLine().toInt();
      break;
    default:
      done = 1;
      break;
    }
  }
  return line;
}

/*!
 * \brief DXF3dFace::calcNormals
 * calculates normal vector for the facet
 */
osg::Vec3f DXF3dFace::calcNormals()
{
  osg::Vec3f v1 = osg::Vec3f(vec1[0]- vec2[0], vec1[1] - vec2[1], vec1[2] - vec2[2]);
  osg::Vec3f v2 = osg::Vec3f(vec1[0] - vec3[0], vec1[1] - vec3[1], vec1[2] - vec3[2]);
  osg::Vec3f normal =  normalize(cross(normalize(v1), normalize(v2)));
  return normal;
}

/*!
 * \brief DXFile constructor
 * \param std::string filename
 */
DXFile::DXFile(std::string filename)
  : osg::Geometry()
{
  // parse dxf file and fill 3dface objects
  fileName = filename;
  QFile* dxfFile = new QFile(QString::fromStdString(filename));
  if (dxfFile->open(QIODevice::ReadOnly))
  {
    QTextStream* in = new QTextStream(dxfFile);
    //count all 3d faces
    int num3dFaces = in->readAll().count(QString("3DFACE"));

    //reset textstream
    in->seek(0);

    // prepare drawing objects
    osg::ref_ptr<osg::Vec3Array> vertices = new osg::Vec3Array(num3dFaces * 4);
    osg::ref_ptr<osg::Vec4Array> colors = new osg::Vec4Array(num3dFaces * 4);
    osg::ref_ptr<osg::Vec3Array> normals = new osg::Vec3Array(num3dFaces * 4);

    // fill face objects
    DXF3dFace* faces = new DXF3dFace[num3dFaces];
    QString line = in->readLine();
    int faceIdx = 0;

    int done = 0;
    while (!done)
    {
      if (!line.compare("SECTION")) {
        int secID = in->readLine().toInt();
        //std::cout << "enter section" << secID << std::endl;
        line = in->readLine();
      }
      else if (!line.compare("ENTITIES")) {
        int entityID = in->readLine().toInt();
        //std::cout << "enter entity" << entityID << std::endl;
        line = in->readLine();
      }
      else if (!line.compare("3DFACE")) {
        //std::cout << "fill face entity" << std::endl;

        //add vertices
        line = faces[faceIdx].fill3dFace(in);
        (*vertices)[(faceIdx*4) + 0] = faces[faceIdx].vec1;
        (*vertices)[(faceIdx * 4) + 1] = faces[faceIdx].vec2;
        (*vertices)[(faceIdx * 4) + 2] = faces[faceIdx].vec3;
        (*vertices)[(faceIdx * 4) + 3] = faces[faceIdx].vec4;
        //add colors
        (*colors)[(faceIdx * 4) + 0] = faces[faceIdx].color;
        (*colors)[(faceIdx * 4) + 1] = faces[faceIdx].color;
        (*colors)[(faceIdx * 4) + 2] = faces[faceIdx].color;
        (*colors)[(faceIdx * 4) + 3] = faces[faceIdx].color;
        //add normals
        (*normals)[(faceIdx * 4) + 0] = faces[faceIdx].calcNormals();
        (*normals)[(faceIdx * 4) + 1] = faces[faceIdx].calcNormals();
        (*normals)[(faceIdx * 4) + 2] = faces[faceIdx].calcNormals();
        (*normals)[(faceIdx * 4) + 3] = faces[faceIdx].calcNormals();

        faceIdx = faceIdx + 1;
      }
      else if (!line.compare("ENDSEC")) {
        //std::cout << "close section" << std::endl;
        line = in->readLine();
      }
      else if (!line.compare("EOF")) {
        done = 1;
      }
      else {
        line = in->readLine();
      }
    }
    dxfFile->close();

    //add planes
    this->setVertexArray(vertices);
    for (int i = 0; i < num3dFaces; i++)
    {
      if (faces[i].vec1 == faces[i].vec4) {
        //std::cout << "its a triangle" << std::endl;
        //faces[i].dumpDXF3DFace();
        osg::ref_ptr<osg::DrawElementsUInt> facette = new osg::DrawElementsUInt(osg::PrimitiveSet::TRIANGLES, 3);
        (*facette)[0] = (i * 4) + 0;
        (*facette)[1] = (i * 4) + 1;
        (*facette)[2] = (i * 4) + 2;
        this->addPrimitiveSet(facette);
      }
      else
      {
        //std::cout << "its a quad" << std::endl;
        osg::ref_ptr<osg::DrawElementsUInt> facette = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 4);
        (*facette)[0] = (i * 4) + 0;
        (*facette)[1] = (i * 4) + 1;
        (*facette)[2] = (i * 4) + 2;
        (*facette)[3] = (i * 4) + 3;
        this->addPrimitiveSet(facette);
      }
    }
    //add normals
    this->setNormalArray(normals);
    this->setNormalBinding(osg::Geometry::BIND_PER_VERTEX);
    //add colors
    this->setColorArray(colors);
    this->setColorBinding(osg::Geometry::BIND_PER_VERTEX);
  }
}

