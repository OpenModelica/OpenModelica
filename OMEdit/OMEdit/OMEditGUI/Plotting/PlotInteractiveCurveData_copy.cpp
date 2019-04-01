#include "PlotInteractiveCurveData.h"

QPointF PlotInteractiveCurveData::sample(size_t i) const
{
  return MainWindow::instance()->getSimulationDialog()->getOpcUaClient()->getVariables()->find(mVariableName).value().at(i);
}

size_t PlotInteractiveCurveData::size() const
{
  return MainWindow::instance()->getSimulationDialog()->getOpcUaClient()->getVariables()->find(mVariableName).value().size();
}

QRectF PlotInteractiveCurveData::boundingRect() const
{
  /* FIX: This should be much more nice */
  std::cout << "boundingRect() called!" << std::endl;
  QRectF plotArea;
  plotArea.setRect(0.0, 1.0, 50.0, 4.0);
  plotArea.moveBottom(2);

  return plotArea;
}
