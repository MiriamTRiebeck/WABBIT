subroutine create_mask_2D(mask, x0, dx, Bs, g )
    implicit none

    ! grid
    integer(kind=ik), intent(in) :: Bs, g
    !> mask term for every grid point of this block
    real(kind=rk), dimension(:,:), intent(inout) :: mask
    !> spacing and origin of block
    real(kind=rk), dimension(2), intent(in) :: x0, dx

    if (size(mask,1) /= Bs+2*g) call abort(777109,"wrong array size, there's pirates, captain!")

    ! usually, the routine should not be called with no penalization, but if it still
    ! happens, do nothing.
    if ( params_acm%penalization .eqv. .false.) return

    select case(params_acm%geometry)
    case('cylinder')
      call draw_cylinder( mask, x0, dx, Bs, g )
    case('two-cylinders')
      call draw_two_cylinders( mask, x0, dx, Bs, g )
    case('none')
      mask = 0.0_rk
    case default
      call abort(120001,"ERROR: geometry for VPM is unknown"//params_acm%geometry)
    end select

end subroutine create_mask_2D


subroutine draw_cylinder(mask, x0, dx, Bs, g )

    use module_params
    use module_precision

    implicit none

    ! grid
    integer(kind=ik), intent(in)                              :: Bs, g
    !> mask term for every grid point of this block
    real(kind=rk), dimension(:,:), intent(out)     :: mask
    !> spacing and origin of block
    real(kind=rk), dimension(2), intent(in)                   :: x0, dx

    ! auxiliary variables
    real(kind=rk)                                             :: x, y, r, h
    ! loop variables
    integer(kind=ik)                                          :: ix, iy

!---------------------------------------------------------------------------------------------
! variables initialization
    if (size(mask,1) /= Bs+2*g) call abort(777109,"wrong array size, there's pirates, captain!")

    ! reset mask array
    mask = 0.0_rk

!---------------------------------------------------------------------------------------------
! main body


    ! parameter for smoothing function (width)
    h = 1.5_rk*max(dx(1), dx(2))

    do iy=1, Bs+2*g
       y = dble(iy-(g+1)) * dx(2) + x0(2) - params_acm%x_cntr(2)
       do ix=1, Bs+2*g
           x = dble(ix-(g+1)) * dx(1) + x0(1) - params_acm%x_cntr(1)
           ! distance from center of cylinder
           r = dsqrt(x*x + y*y)
           if (params_acm%smooth_mask) then
               call smoothstep(mask(ix,iy), r, params_acm%R_cyl, h)
           else
               ! if point is inside the cylinder, set mask to 1
               if (r <= params_acm%R_cyl) then
                   mask(ix,iy) = 1.0_rk
               else
                   mask(ix,iy) = 0.0_rk
               end if
           end if
       end do
    end do

end subroutine draw_cylinder



subroutine draw_two_cylinders( mask, x0, dx, Bs, g)

  use module_params
  use module_precision

  implicit none

  ! grid
  integer(kind=ik), intent(in)                   :: Bs, g
  !> mask term for every grid point of this block
  real(kind=rk), dimension(:,:), intent(out)     :: mask
  !> spacing and origin of block
  real(kind=rk), dimension(2), intent(in)        :: x0, dx

  ! auxiliary variables
  real(kind=rk)         :: x1, x2, y1, y2, R, cx1, cx2, cy1,&
  cy2, r_1, r_2, h, mask1, mask2
  ! loop variables
  integer(kind=ik)      :: ix, iy

  !---------------------------------------------------------------------------------------------
  ! variables initialization
  if (size(mask,1) /= Bs+2*g) call abort(777109,"wrong array size, there's pirates, captain!")

  ! reset mask array
  mask = 0.0_rk
  mask1 = 0.0_rk
  mask2 = 0.0_rk

  !---------------------------------------------------------------------------------------------
  ! main body

  ! center of the first cylinder
  cx1 = 0.5884_rk*params_acm%Lx
  cy1 = 0.4116_rk*params_acm%Ly

  ! center of the second cylinder
  cx2 = 0.4116_rk*params_acm%Lx
  cy2 = 0.5884_rk*params_acm%Ly

  ! radius of the cylinders
  R = params_acm%R_cyl
  ! parameter for smoothing function (width)
  h = 1.5_rk*max(dx(1), dx(2))

  do iy=1, Bs+2*g
    y1 = dble(iy-(g+1)) * dx(2) + x0(2) - cy1
    y2 = dble(iy-(g+1)) * dx(2) + x0(2) - cy2
    do ix=1, Bs+2*g
      x1 = dble(ix-(g+1)) * dx(1) + x0(1) - cx1
      x2 = dble(ix-(g+1)) * dx(1) + x0(1) - cx2
      ! distance from center of cylinder 1
      r_1 = dsqrt(x1*x1 + y1*y1)
      ! distance from center of cylinder 2
      r_2 = dsqrt(x2*x2 + y2*y2)
      if (params_acm%smooth_mask) then
        call smoothstep(mask1, r_1, R, h)
        call smoothstep(mask2, r_2, R, h)
        mask(ix,iy) = mask1 + mask2
      else
        ! if point is inside one of the cylinders, set mask to 1
        if (r_1 <= R) then
          mask(ix,iy) = 1.0_rk
        elseif ( r_2 <= R) then
          mask(ix,iy) = 1.0_rk
        else
          mask(ix,iy) = 0.0_rk
        end if
      end if
    end do
  end do


end subroutine draw_two_cylinders