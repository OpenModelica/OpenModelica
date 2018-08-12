#include "FunctionArgumentDialog.h"

#include "LibraryTreeWidget.h"
#include "Component/Component.h"

#include <QGridLayout>
#include <QLabel>
#include <QLineEdit>

FunctionArgumentDialog::FunctionArgumentDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *parent):
  QDialog(parent), mpLibraryTreeItem(pLibraryTreeItem)
{
  setWindowTitle(pLibraryTreeItem->getNameStructure());
  QGridLayout *pGrid = new QGridLayout();

  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  mComponents = pOMCProxy->getComponents(pLibraryTreeItem->getNameStructure());
  QString comment = pOMCProxy->getClassComment(pLibraryTreeItem->getNameStructure());

  int row = 0;
  pGrid->addWidget(new QLabel(comment), row++, 0, 1, 4);

  for (int i = 0; i < mComponents.size(); ++i) {
    ComponentInfo *pComponent = mComponents[i];
    if (!isInput(pComponent))
      continue;

    pGrid->addWidget(new QLabel(pComponent->getName()), row, 0);

    QLabel *typeLabel = new QLabel(pComponent->getClassName());
    QFont typeFont;
    typeFont.setBold(true);
    typeLabel->setFont(typeFont);
    pGrid->addWidget(typeLabel, row, 1);

    QLabel *commentLabel = new QLabel(pComponent->getComment());
    QFont commentFont;
    commentFont.setItalic(true);
    commentLabel->setFont(commentFont);
    pGrid->addWidget(commentLabel, row, 2);

    QLineEdit *pEditor = new QLineEdit();
    mEditors.append(pEditor);
    pGrid->addWidget(pEditor, row, 3);
    ++row;
  }

  QDialogButtonBox *pButtons = new QDialogButtonBox(
        QDialogButtonBox::StandardButton::Ok |
        QDialogButtonBox::StandardButton::Cancel);
  pGrid->addWidget(pButtons, row, 0, 1, 4);
  connect(pButtons, SIGNAL(accepted()), SLOT(accept()));
  connect(pButtons, SIGNAL(rejected()), SLOT(reject()));

  setLayout(pGrid);
}

QString FunctionArgumentDialog::getFunctionCallCommand()
{
  QString result = mpLibraryTreeItem->getNameStructure() + "(";
  int inputArgIndex = 0;
  for (int i = 0; i < mComponents.size(); ++i) {
    ComponentInfo *pComponent = mComponents[i];
    if (!isInput(pComponent))
      continue;

    QString value = mEditors[inputArgIndex]->text();

    if (inputArgIndex != 0) {
      result += ", ";
    }

    if (pComponent->getClassName() == "String") {
      result += "\"" + value + "\"";
    } else {
      result += value;
    }

    ++inputArgIndex;
  }
  result += ")";
  return result;
}

bool FunctionArgumentDialog::isInput(ComponentInfo *pComponentInfo)
{
  return pComponentInfo->getCausality() == "input";
}
