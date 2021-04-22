#define SIZE 60
#define SIZE_ITERATIONS 100000

program main
  use omp_lib
  implicit none
  integer i
  double precision w1, w2

  do i=1,10
     w1=omp_get_wtime()
     call j1_0000()
     w2=omp_get_wtime()
     write(*,'(a20,f10.1)') "wall time ", w2-w1
  enddo

end program main

subroutine j1_0000()
  implicit none
  integer :: ncp,icp, mm, i
  double precision :: d00p(SIZE)
  double precision :: array(SIZE_ITERATIONS)
  double precision output
  do icp=1,220

     !$omp target teams distribute parallel do &
     !$omp private(d00p) map(array)
     do mm=1,SIZE_ITERATIONS
#ifdef INLINE_ROUTINE
        do i=1,SIZE
           d00p(i)=i
        enddo
#else
        call genr70_p_gpu_0000(d00p)
#endif
! this is just for error checking: each thread sums up all the
! values in its private array and the stores in a shared array 
        output = 0
        do i=1,SIZE
           output = output + d00p(i)
        enddo
        array(mm) = output

     enddo
     !$omp end target teams distribute parallel do  

! check the error
     do mm=1,SIZE_ITERATIONS
        if( abs(array(mm) - (SIZE*(SIZE+1))/2) > 0.000001) then
           print *, "error", array(mm), (SIZE*(SIZE+1))/2
           stop 1
        endif
     enddo

  enddo

end subroutine j1_0000

subroutine genr70_p_gpu_0000(d00p)
  implicit none
  integer i
  double precision :: d00p(SIZE)
  !$omp declare target   

  do i=1,SIZE
     d00p(i)=i
  enddo
end subroutine genr70_p_gpu_0000
