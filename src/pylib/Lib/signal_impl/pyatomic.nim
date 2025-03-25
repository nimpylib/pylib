

template Py_atomic_load_ptr*[T](obj: ptr T): T = atomicLoadN(obj, ATOMIC_SEQ_CST)
template Py_atomic_store_ptr*[T](obj: ptr T, value: T) = atomicStoreN(obj, value, ATOMIC_SEQ_CST)

template Py_atomic_load*[T](obj: T): T =
  bind Py_atomic_load_ptr
  Py_atomic_load_ptr(obj.addr)


template Py_atomic_store*[T](obj: T, value: T) =
  bind Py_atomic_store_ptr
  Py_atomic_store_ptr(obj.addr, value)

