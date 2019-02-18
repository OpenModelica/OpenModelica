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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "Model.h"
#include "Modeling/ModelWidgetContainer.h"

Model::Model(ModelWidget *pModelWidget)
{
  mModelName = pModelWidget->getLibraryTreeItem()->getNameStructure();
  mFilePath = pModelWidget->getLibraryTreeItem()->getFileName();

  foreach (Component *pComponent, pModelWidget->getDiagramGraphicsView()->getComponentsList()) {
    ComponentInformation componentInformation;
    componentInformation.mClassName = pComponent->getComponentInfo()->getClassName();
    componentInformation.mName = pComponent->getComponentInfo()->getName();
    componentInformation.mComment = pComponent->getComponentInfo()->getComment();
    componentInformation.mIsProtected = pComponent->getComponentInfo()->getProtected();
    componentInformation.mIsFinal = pComponent->getComponentInfo()->getFinal();
    componentInformation.mIsFlow = pComponent->getComponentInfo()->getFlow();
    componentInformation.mIsStream = pComponent->getComponentInfo()->getStream();
    componentInformation.mIsReplaceable = pComponent->getComponentInfo()->getReplaceable();
    componentInformation.mVariability = pComponent->getComponentInfo()->getVariablity();
    componentInformation.mIsInner = pComponent->getComponentInfo()->getInner();
    componentInformation.mIsOuter = pComponent->getComponentInfo()->getOuter();
    componentInformation.mCasuality = pComponent->getComponentInfo()->getCausality();
    componentInformation.mArrayIndex = pComponent->getComponentInfo()->getArrayIndex();
    componentInformation.mParameterValue = pComponent->getComponentInfo()->getParameterValue(MainWindow::instance()->getOMCProxy(), mModelName);

    mComponents.append(componentInformation);
  }
}
