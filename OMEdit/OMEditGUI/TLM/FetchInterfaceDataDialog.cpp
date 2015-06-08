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

#include "FetchInterfaceDataDialog.h"

FetchInterfaceDataDialog::FetchInterfaceDataDialog(LibraryTreeNode *pLibraryTreeNode, MainWindow *pMainWindow)
  : QDialog(pMainWindow, Qt::WindowTitleHint), mpMainWindow(pMainWindow), mpLibraryTreeNode(pLibraryTreeNode)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Fetch Interface Data")).append(" - ")
                 .append(mpLibraryTreeNode->getNameStructure()));
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(550);
  mpLibraryTreeNode = pLibraryTreeNode;
  // progress
  mpProgressLabel = new Label(tr("Fetching interface data for <b>%1</b>...").arg(mpLibraryTreeNode->getNameStructure()));
  mpProgressLabel->setTextFormat(Qt::RichText);
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  // cancel button
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(cancelFetchingInterfaceData()));
  // try again button
  mpFetchAgainButton = new QPushButton(tr("Fetch Again"));
  mpFetchAgainButton->setEnabled(false);
  connect(mpFetchAgainButton, SIGNAL(clicked()), SLOT(fetchAgainInterfaceData()));
  // output
  mpOutputLabel = new Label(Helper::output);
  mpOutputTextBox = new QPlainTextEdit;
  // main Layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  pMainGridLayout->setContentsMargins(5, 5, 5, 5);
  pMainGridLayout->addWidget(mpProgressLabel, 0, 0, 1, 3);
  pMainGridLayout->addWidget(mpProgressBar, 1, 0);
  pMainGridLayout->addWidget(mpCancelButton, 1, 1);
  pMainGridLayout->addWidget(mpFetchAgainButton, 1, 2);
  pMainGridLayout->addWidget(mpOutputLabel, 2, 0, 1, 3);
  pMainGridLayout->addWidget(mpOutputTextBox, 3, 0, 1, 3);
  setLayout(pMainGridLayout);
}

