#!/bin/bash

# Fortran version
echo " ****** Testing Fortran version:"

# test with noinline
echo ""
echo " ****** Case 1: Run with function call:"
xlf_r -qsmp=omp -qoffload f.F90 
# without "OMP_NUM_TEAMS=2" we get a memory error
OMP_NUM_TEAMS=2 jsrun -n 1 -c 1 -a 1 -g 1 ./a.out

# test with inline
echo ""
echo " ****** Case 2: Run with manual inline:"
xlf_r -qsmp=omp -qoffload -DINLINE_ROUTINE f.F90 
OMP_NUM_TEAMS=2 jsrun -n 1 -c 1 -a 1 -g 1 ./a.out

# test with manual partitioning of the array
echo ""
echo " ****** Case 3: Run with function call and manually splitting array:"
xlf_r -qsmp=omp -qoffload split.F90 
# no restriction on OMP_NUM_TEAMS here
jsrun -n 1 -c 1 -a 1 -g 1 ./a.out
