package org.openmodelica;

import java.util.Arrays;
import java.util.List;

public class ModelicaArray<T extends ModelicaObject> extends ModelicaBaseArray<T> implements ModelicaObject {
  private static final long serialVersionUID = 2151613083277374538L;
  public int firstDim = 0;
  public int[] dims = null;
  private boolean isFlat = true;

  public ModelicaArray(ModelicaObject o) {
    setObject(o);
  }
  
  public ModelicaArray(T... objs) {
    for(T obj : objs) {
      add(obj);
    }
  }
  
  public ModelicaArray() {
  }
  
  public ModelicaArray(int i) {
    setSize(i);
  }
  
  public static<T extends ModelicaObject> ModelicaArray<ModelicaObject> createMultiDimArray(T[] flatArr, int firstDim, int... dims) {
    return createMultiDimArray(Arrays.asList(flatArr), firstDim, dims);
  }
  
  public static ModelicaArray<ModelicaObject> createMultiDimArray(List<? extends ModelicaObject> flatArr, int firstDim, int... dims) {
    if (firstDim == 0)
      throw new RuntimeException("Cannot create a multi-dim array with a zero-length dimension");
    int acc = firstDim;
    for (int i : dims)
      acc *= i;
    if (flatArr.size() != acc) {
      String dimsStr = ""+firstDim;
      for (int i : dims)
        dimsStr += "," + i;
      throw new RuntimeException(String.format("createMultiDimArray requires list and dimensions to match (was %d and %d) - dims were %s", flatArr.size(), acc, dimsStr));
    }
    if (dims.length > 0) {
      int[] dims2 = new int[dims.length-1];
      for (int i=0; i<dims.length-1; i++) {
        dims2[i] = dims[i+1];
      }      
      ModelicaArray<ModelicaObject> res = new ModelicaArray<ModelicaObject>(firstDim);
      
      int subLength = acc/firstDim;
      for (int i=0; i<firstDim; i++) {
        List<? extends ModelicaObject> subFlat = flatArr.subList(i*subLength, (i+1)*subLength);
        res.set(i, createMultiDimArray(subFlat, dims[0], dims2));
      }
      res.setDims(firstDim, dims);
      return res;
    } else {
      ModelicaArray<ModelicaObject> res = new ModelicaArray<ModelicaObject>(firstDim);
      for (int i=0; i<firstDim; i++)
        res.set(i, flatArr.get(i));
      res.setDims(firstDim, dims);
      return res;
    }
  }
  
  private void setDims(int firstDim, int[] dims) {
    this.firstDim = firstDim;
    this.dims = dims;
    this.isFlat = false;
  }

  @SuppressWarnings("unchecked")
  public void setMulDim(Object o, int... ixs) {
    ModelicaArray cur = this;
    for (int i=0; i<ixs.length-1; i++)
      cur = (ModelicaArray) cur.get(ixs[i]);
    cur.set(ixs[ixs.length-1], (T)o);
  }
  
  @SuppressWarnings("unchecked")
  public T getMulDim(int... ixs) {
    ModelicaArray cur = this;
    for (int i=0; i<ixs.length-1; i++)
      cur = (ModelicaArray) cur.get(ixs[i]);
    return (T)cur.get(ixs[ixs.length-1]);
  }
  
  public ModelicaArray(Class<T> c, List<ModelicaObject> objs) throws ModelicaObjectException {
    try {
      for(ModelicaObject obj : objs) {
        add(c.cast(obj));
      }
    } catch (Throwable t) {
      throw new ModelicaObjectException("Failed to create Modelica Array...");
    }
  }
  
  @SuppressWarnings("unchecked")
  public static ModelicaArray<? extends ModelicaObject> createModelicaArray(List<ModelicaObject> objs) throws ModelicaObjectException {
    if (objs.size() == 0)
      return new ModelicaArray();
    else
      return new ModelicaArray(objs.get(0).getClass(),objs);
  }
  
  public void unflattenModelicaArray() {
    setObject(createMultiDimArray(this, firstDim, dims));
  }
  
  public void flattenModelicaArray() {
    if (isFlat)
      return;
    ModelicaArray<ModelicaObject> res = new ModelicaArray<ModelicaObject>();
    for (ModelicaObject o : this) {
      if (o instanceof ModelicaArray<?>) {
        ModelicaArray<?> a = (ModelicaArray<?>) o;
        a.flattenModelicaArray();
        res.addAll(a);
      } else {
        res.add(o);
      }
    }
    res.firstDim = firstDim;
    res.dims = dims;
    res.isFlat = true;
    setObject(res);
  }
  
  public String toString() {
    String res = "{";
    for (int i=0; i<this.elementCount; i++) {
      if (i != 0)
        res += ",";
      res += this.get(i);
    }
    res += "}";
    return res;
  }
  
  @SuppressWarnings("unchecked")
  @Override
  public void setObject(ModelicaObject o) {
    ModelicaArray<T> arr = (ModelicaArray) o;
    this.clear();
    this.addAll(arr);
    this.firstDim = arr.firstDim;
    this.dims = arr.dims;
    this.isFlat = arr.isFlat;
  }

}
