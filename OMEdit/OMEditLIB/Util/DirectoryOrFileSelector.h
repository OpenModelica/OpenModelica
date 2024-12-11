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
 * @author adrian.pop@liu.se
 */

#ifndef DIRECTORYORFILESELECTOR_H
#define DIRECTORYORFILESELECTOR_H

#include <QWidget>
#include <QListWidget>
#include <QPushButton>

class Label;
class DirectoryOrFileSelector : public QWidget
{
  Q_OBJECT

public:
  DirectoryOrFileSelector(bool isDir, QString labelText = tr("List"), QWidget *parent = nullptr);

public:
  void setItems(const QStringList &items);
  QStringList items() const;

private slots:
  void addItem();
  void removeItem();

private:
  bool mIsDir;
  Label *mpItemLabel;
  QListWidget *mpItemListWidget;
  QPushButton *mpAddButton;
  QPushButton *mpRemoveButton;
};

#endif // DIRECTORYORFILESELECTOR_H
