  include "mkl_omp_offload.f90"
  program main
    implicit none
    integer NBASIS
    integer NddiChunk
    integer NACT
    integer NCOR
    integer NVIR,NddiChunk_max,NAUXBAS,kAuxStart,kAuxEnd

    ! coronene c24
    NBASIS = 384
    NddiChunk = 1512
    NACT = 54
    NCOR = 24
    NVIR = 282
    NddiChunk_max = 1512
    NAUXBAS = 1512
    kAuxStart = 1
    kAuxEnd = 1512

    call wrap( &
         NCOR,NACT,NVIR,NBASIS,NAUXBAS, &
         NddiChunk,NddiChunk_max, &
         KAuxStart,KAuxEnd )

  end program main

  subroutine wrap( &
       NCOR,NACT,NVIR,NBASIS,NAUXBAS, &
       NddiChunk,NddiChunk_max, &
       KAuxStart,KAuxEnd )
    USE IFPORT
    implicit none
    integer NBASIS,i,j
    integer NddiChunk
    integer NACT
    integer NCOR
    integer NVIR,NddiChunk_max,NAUXBAS,kAuxStart,kAuxEnd
    double precision :: VEC_CPU(NBASIS,NBASIS)
    double precision :: VEC_GPU(NBASIS,NBASIS)
    double precision,allocatable :: T11_cpu(:,:) 
    double precision,allocatable,dimension(:) :: I32_cpu
    double precision,allocatable :: T11_gpu(:,:) 
    double precision,allocatable,dimension(:) :: I32_gpu

    ALLOCATE(I32_cpu(NBASIS*NBASIS*NddiChunk_max))
    ALLOCATE(I32_gpu(NBASIS*NBASIS*NddiChunk_max))
    ALLOCATE(T11_cpu(NBASIS*NACT,NddiChunk_max))
    ALLOCATE(T11_gpu(NBASIS*NACT,NddiChunk_max))

    ! fill inputs with random data
    do i=1,NBASIS*NBASIS*NddiChunk_max
       I32_cpu(i) = rand(1)*1000
       I32_gpu(i) = I32_cpu(i)
    enddo
    do i=1,NBASIS*NACT
       do j=1,NddiChunk_max
          T11_cpu(i,j) = rand(1)*1000
          T11_gpu(i,j) = T11_cpu(i,j)
       enddo
    enddo

    do i=1,NBASIS
       do j=1,NBASIS
          VEC_cpu(i,j) = rand(1)*1000
          VEC_gpu(i,j) = VEC_cpu(i,j)
       enddo
    enddo


    ! GPU version
    CALL RIMP2_I32_TRANSF_gpu_IRIS &
         (I32_gpu,VEC_gpu,T11_gpu, &
         NCOR,NACT,NVIR,NBASIS,NAUXBAS, &
         NddiChunk,NddiChunk_max, &
         KAuxStart,KAuxEnd)

    ! CPU version
    call RIMP2_I32_TRANSF_cpu &
         (I32_cpu,VEC_cpu,T11_cpu, &
         NCOR,NACT,NVIR,NBASIS,NAUXBAS, &
         NddiChunk,NddiChunk_max, &
         KAuxStart,KAuxEnd)

    ! compare the results
    do i=1,NBASIS*NBASIS*NddiChunk_max
       if( abs(I32_gpu(i)-I32_cpu(i)) > 0.000001) then
          print *, "FAILED AT",i
          print *, "CPU:", I32_cpu(i)
          print *, "GPU:", I32_gpu(i)
          call abort
       endif
    enddo

  end subroutine wrap

  SUBROUTINE RIMP2_I32_TRANSF_gpu_IRIS &
       (I32,VEC,T11, &
       NCOR,NACT,NVIR,NBASIS,NAUXBAS, &
       NddiChunk,NddiChunk_max, &
       LddiAuxStart,LddiAuxEnd)

    use omp_lib

#if defined(MKL_ILP64)
    use onemkl_blas_omp_offload_ilp64
#else
    use onemkl_blas_omp_offload_lp64
#endif

    implicit double precision(a-h,o-z)

    double precision,parameter :: ONE=1.0D00,ZERO=0.0D00

    double precision :: I32(NBASIS*NBASIS*NddiChunk)
    double precision :: T11(NBASIS*NACT,NddiChunk_max)
    double precision :: VEC(NBASIS*NBASIS)

    integer :: &
         NCOR,NACT,NVIR,NBASIS,NAUXBAS, &
         NddiChunk,NddiChunk_max, &
         LddiAuxStart,LddiAuxEnd

    ! =======================================================================
    !     GPU CODE BLOCK
    ! =======================================================================

    !! MAP I32,VEC TO GPU
    !$omp target enter data map(to:I32)
    !$omp target enter data map(to:VEC)
    !$omp target enter data map(alloc:T11)

    !$omp target variant dispatch use_device_ptr(I32,VEC,T11)
    CALL DGEMM('T','N', &
         NACT,NBASIS*NddiChunk, NBASIS,  &
         ONE, VEC(NCOR*NBASIS+1),NBASIS, &
         I32,NBASIS,                &
         ZERO, T11,NACT)
    !$omp end target variant dispatch

    DO LL=LddiAuxStart,LddiAuxEnd
       !$omp target variant dispatch use_device_ptr(I32,VEC,T11) 
       CALL DGEMM('T','T', &
            NVIR,NACT,NBASIS,                &
            ONE,VEC((NCOR+NACT)*NBASIS+1),NBASIS,&
            T11(1,LL-LddiAuxStart+1),NACT,     &
            ZERO,I32(NVIR*NACT*(LL-LddiAuxStart)+1),NVIR)
       !$omp end target variant dispatch
    ENDDO

    ! copy transformed I32 from GPU to CPU
    !$omp target update from(I32)


    !$omp target exit data map(release:I32,VEC,T11)
  END SUBROUTINE RIMP2_I32_TRANSF_gpu_IRIS
  ! ***************************

  SUBROUTINE RIMP2_I32_TRANSF_cpu &
       (I32,VEC,T11, &
       NCOR,NACT,NVIR,NBASIS,NAUXBAS, &
       NddiChunk,NddiChunk_max, &
       LddiAuxStart,LddiAuxEnd)

    implicit double precision(a-h,o-z)

    double precision,parameter :: ONE=1.0D00,ZERO=0.0D00

    double precision :: I32(NBASIS*NBASIS*NddiChunk)
    double precision :: T11(NBASIS*NACT,NddiChunk_max)
    double precision :: VEC(NBASIS*NBASIS)

    integer :: &
         NCOR,NACT,NVIR,NBASIS,NAUXBAS, &
         NddiChunk,NddiChunk_max, &
         LddiAuxStart,LddiAuxEnd

    ! =======================================================================
    !     CPU CODE BLOCK
    ! =======================================================================

    CALL DGEMM('T','N', &
         NACT,NBASIS*NddiChunk, NBASIS,    &
         ONE, VEC(NCOR*NBASIS+1),NBASIS,        &
         I32,NBASIS,                  &
         ZERO, T11,NACT)

    DO LL=LddiAuxStart,LddiAuxEnd
       CALL DGEMM('T','T', &
            NVIR,NACT,NBASIS,                &
            ONE,VEC((NCOR+NACT)*NBASIS+1),NBASIS,&
            T11(1,LL-LddiAuxStart+1),NACT,     &
            ZERO,I32(NVIR*NACT*(LL-LddiAuxStart)+1),NVIR)
    ENDDO

  END SUBROUTINE RIMP2_I32_TRANSF_cpu
  ! ***************************
