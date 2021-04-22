
This runs 3 test cases to show issues we had with thread-private 
arrays and calling functions from target regions with IBM Fortran OpenMP:

The 3 test cases (which you can run through the script "./script.sh" on
an interactive job on Summit are:
1) reproducer using "declare target" 
2) reproducer using manual inline instead of "declare target" 
3) reproducer using "declare target" and manual thread-private arrays

The output I see is below. The important thing to note:

 - In the "function call" case, the runtime increase with each iteration.
 - This kills performance for iterative solvers.
 - The overhead goes away if we manually inline (case 2) or if we split the array
manually ourselves (case 3), but it would be nice if this would work as in case 1
(much less overhead for the programmer).


```
bash-4.2$ ./script.sh
 ****** Testing Fortran version:

 ****** Case 1: Run with function call:
** main   === End of Compilation 1 ===
** j1_0000   === End of Compilation 2 ===
** genr70_p_gpu_0000   === End of Compilation 3 ===
1501-510  Compilation successful for file f.F90.
          wall time        1.6
          wall time        1.7
          wall time        1.9
          wall time        2.2
          wall time        2.5
          wall time        2.7
          wall time        3.0
          wall time        3.3
          wall time        3.6
          wall time        3.9

 ****** Case 2: Run with manual inline:
** main   === End of Compilation 1 ===
** j1_0000   === End of Compilation 2 ===
** genr70_p_gpu_0000   === End of Compilation 3 ===
1501-510  Compilation successful for file f.F90.
          wall time        1.6
          wall time        1.3
          wall time        1.3
          wall time        1.3
          wall time        1.3
          wall time        1.3
          wall time        1.3
          wall time        1.3
          wall time        1.3
          wall time        1.3

 ****** Case 3: Run with function call and manually splitting array:
** array_storage   === End of Compilation 1 ===
** main   === End of Compilation 2 ===
** j1_0000   === End of Compilation 3 ===
** genr70_p_gpu_0000   === End of Compilation 4 ===
1501-510  Compilation successful for file split.F90.
          wall time        0.7
          wall time        0.3
          wall time        0.3
          wall time        0.3
          wall time        0.3
          wall time        0.3
          wall time        0.3
          wall time        0.3
          wall time        0.3
          wall time        0.3

```

