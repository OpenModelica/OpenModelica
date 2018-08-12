#ifndef FUNCTIONPARAMETERDIALOG_H
#define FUNCTIONPARAMETERDIALOG_H

#include <QDialog>

class LibraryTreeItem;
class ComponentInfo;
class QLineEdit;

class FunctionArgumentDialog : public QDialog
{
public:
  explicit FunctionArgumentDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *parent = 0);
  QString getFunctionCallCommand();
private:
  bool isInput(ComponentInfo *pComponentInfo);

  LibraryTreeItem *mpLibraryTreeItem;
  QList<ComponentInfo*> mComponents;
  QList<QLineEdit*> mEditors;
};

#endif // FUNCTIONPARAMETERDIALOG_H
