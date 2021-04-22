#define SIZE 60
#define SIZE_ITERATIONS 100000

module array_storage
  double precision, allocatable :: mod_array(:,:)
  !$omp declare target to(mod_array)
end module array_storage

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
  use array_storage
  use omp_lib
  implicit none
  integer :: ncp,icp, mm, i, num_teams,num_threads,err
  double precision :: array(SIZE_ITERATIONS)
  double precision output
  num_teams = 128
  num_threads = 128

  allocate(mod_array((num_threads*num_teams),SIZE), stat=err)

  do icp=1,220
     !$omp target teams distribute parallel do num_teams(num_teams) thread_limit(num_threads) map(mod_array)
     do mm=1,SIZE_ITERATIONS
        call genr70_p_gpu_0000
! this is just for error checking: each thread sums up all the
! values in its private array and the stores in a shared array 
        output = 0
        do i=1,SIZE
           output = output + mod_array(omp_get_thread_num()+omp_get_team_num()*omp_get_num_threads(),i)
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

subroutine genr70_p_gpu_0000()
  use array_storage
  use omp_lib
  implicit none
  integer i
  !$omp declare target
                          
  do i=1,SIZE
     mod_array(omp_get_thread_num()+omp_get_team_num()*omp_get_num_threads(),i)=i
  enddo

end subroutine genr70_p_gpu_0000
