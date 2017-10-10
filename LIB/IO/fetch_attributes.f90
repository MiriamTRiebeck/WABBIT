!> \file
!> \callgraph
! ********************************************************************************************
! WABBIT
! ============================================================================================
!> \name fetch_attributes.f90
!> \version 0.5
!> \author sm, engels
!
!> \brief read attributes time, domain size, total number of blocks, iteration from hdf5-file
!
!>
!! input:
!!           - parameter array
!!           - name of the file we want to read from
!!
!! output:
!!           - number of active blocks (light and heavy)
!!           - time and iteration
!!
!!
!! = log ======================================================================================
!! \n
!! 28/09/17 - create
!
! ********************************************************************************************

subroutine fetch_attributes(fname, params, lgt_n, hvy_n, time, iteration)

!---------------------------------------------------------------------------------------------
! modules

!---------------------------------------------------------------------------------------------
! variables

    implicit none

    !> file name
    character(len=*), intent(in)        :: fname
    !> user defined parameter structure
    type (type_params), intent(in)      :: params
    !> number of heavy and light active blocks
    integer(kind=ik), intent(inout)     :: lgt_n, hvy_n
    !> time (to be read from file)
    real(kind=rk), intent(inout)        :: time
    !> iteration (to be read from file)
    integer(kind=ik), intent(inout)     :: iteration

    ! file id integer
    integer(hid_t)                      :: file_id
    ! process rank
    integer(kind=ik)                    :: rank
    ! domain size we will get from file
    real(kind=rk), dimension(3)         :: domain



!---------------------------------------------------------------------------------------------
! variables initialization

    ! set MPI parameters
    rank = params%rank

!---------------------------------------------------------------------------------------------
! main body

    call check_file_exists(fname)

    ! open the file
    call open_file_hdf5( trim(adjustl(fname)), file_id, .false.)

    call read_attribute(fname, "blocks", "domain_size", domain)
    call read_attribute(fname, "blocks", "time", time)
    call read_attribute(fname, "blocks", "iteration", iteration)
    call read_attribute(fname, "blocks", "total_number_blocks", lgt_n)

    if (rank==0) then
        hvy_n = lgt_n/params%number_procs + modulo(lgt_n,params%number_procs)
    else
        hvy_n = lgt_n/params%number_procs
    end if

    if (rank==0) then
        write(*,'(40("~"))')
        write(*,'("Reading from file ",A)') trim(adjustl(fname))
        write(*,'("time=",g12.4') time
        write(*,'("Lx=",g12.4," Ly=",g12.4," Lz=",g12.4)') domain

        ! if the domain size doesn't match, proceed, but yell.
        if ((params%Lx.ne.domain(1)).or.(params%Ly.ne.domain(2)).or.(params%Lz.ne.domain(3))) then
            write (*,'(A)') " WARNING! Domain size mismatch."
            write (*,'("in memory:   Lx=",es12.4,"Ly=",es12.4,"Lz=",es12.4)') params%Lx, params%Ly, params%Lz
            write (*,'("but in file: Lx=",es12.4,"Ly=",es12.4,"Lz=",es12.4)') domain
            write (*,'(A)') "proceed, with fingers crossed."
        end if

    end if

    ! close file and HDF5 library
    call close_file_hdf5(file_id)


end subroutine fetch_attributes
