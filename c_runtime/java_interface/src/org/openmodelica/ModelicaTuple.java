package org.openmodelica;

import java.util.List;

public class ModelicaTuple extends ModelicaBaseArray<ModelicaObject> implements ModelicaObject {
  private static final long serialVersionUID = -5901839591369712274L;
  
  public ModelicaTuple(ModelicaObject o) {
    setObject(o);
  }
  
  public ModelicaTuple() {
  }
  
  public ModelicaTuple(ModelicaObject... objs) {
    for(ModelicaObject obj : objs) {
      add(obj);
    }
  }
  
  public ModelicaTuple(List<ModelicaObject> objs) {
    for(ModelicaObject obj : objs) {
      add(obj);
    }
  }
  
  public String toString() {
    StringBuffer buf = new StringBuffer();
    printToBuffer(buf);
    return buf.toString();
  }

  @Override
  public void setObject(ModelicaObject o) {
    ModelicaTuple arr = (ModelicaTuple) o;
    this.clear();
    this.addAll(arr);
  }

  @Override
  public void printToBuffer(StringBuffer buffer) {
    buffer.append("(");
    for (int i=0; i<this.elementCount; i++) {
      if (i != 0)
        buffer.append(",");
      get(i).printToBuffer(buffer);
    }
    buffer.append(")");
  }
}
