# OpenMP tests

# dgemm_batch

This is a small mini-app showing DGEMM and batched DGEMM with OpenMP and the Intel compiler

## Compile and run:

```
# non-batched
 > ifx t.F90 -i8 -fiopenmp -fopenmp-targets=spir64 -g -fsycl -qmkl  -lmkl_sycl -lsycl
 > ./a.out

# batched
 > ifx t.F90 -DBATCH_VERSION -i8 -fiopenmp -fopenmp-targets=spir64 -g -fsycl -qmkl  -lmkl_sycl -lsycl
 > ./a.out
```
