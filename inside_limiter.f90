subroutine allocate_limiter()

  use limiter_module
  implicit none
  integer :: filenum = 22

  open(filenum, file=limiter_file, status='old', form = 'formatted')
  read(filenum,*) limiter_size(1:2)

  allocate(limiter(limiter_size(1),limiter_size(2)))
  
  limiter(:,:)=0
  
  close(filenum)

end subroutine allocate_limiter

subroutine load_limiter()

  use limiter_module
  implicit none

  integer :: i,j
  integer :: filenum = 22
  real, dimension(2) :: dummy

  open(filenum,file=limiter_file,status='old',form='formatted')
  

  ! the first two value should give the number of toroidal and poloidal
  ! points respectively.
  read(filenum,*)
 

  !do i=1,limiter_size(1)
     do j=1,limiter_size(2)
        read(filenum,*) dummy
        	limiter(:,j)=dummy
     enddo
  !enddo
  close(filenum)
  
end subroutine load_limiter


! note, point is in r,z,phi
integer function inside_limiter(r,z,phi)

use limiter_module

implicit none

real :: Xpoint, Ypoint, dist_plane, delta, r, z, phi
integer :: in_polygon, poly_size, is_near_helical_plane
real, dimension(3) :: bvector, baxis, dist_axis
real, dimension(4) :: Xpoly, Ypoly
real, dimension(3) :: point, pointc, HC_out, HC_up, HC_up_mag, HC_up_norm

! use pre-calculated values of the location of the magnetic axis in QHS and the B field vector at this location

if (num_limiters.le.0) then
   inside_limiter = 0
   return
end if

bvector=(/0.0,0.43765823,0.24171643/)
baxis=(/1.4454,0.0,0.0/)
delta=0.01

  point=(/r,z,phi/)
  
  ! print *, 'point in limiter=', point

  call pol2cart(point,pointc)
 

! use the B field vector as the normal vector to the helical plane. Find the distance to this plane by using the dot product.
dist_axis=pointc-baxis
dist_plane=dot_product(dist_axis,bvector)

! print *, dist_plane

if (abs(dist_plane) > delta) then
   is_near_helical_plane=0
   inside_limiter=0
   return
else if (dist_plane <= delta) then

	! print *, 'performing limiter check'

	poly_size=size(limiter(1,:))

	Xpoly=limiter(1,:)
	Ypoly=limiter(2,:)

	! need to project point into 2D plane
	! we'll do this in the same way that Chris Clark does in his matlab scripts
	! the 2d HC plane is defined by an 'out' coordinate: the x axis
	! and an 'up' coordinate, defined by the y anc z coordinates together

	HC_out=(/1.0,0.0,0.0/)

	! compute the cross product between HC_out and bvector (the normal vector)
	HC_up(1)=(HC_out(2)*bvector(3)-HC_out(3)*bvector(2))
	HC_up(2)=(HC_out(3)*bvector(1)-HC_out(1)*bvector(3))
	HC_up(3)=(HC_out(1)*bvector(2)-HC_out(2)*bvector(1))

	! normalize HC_up

	HC_up_mag=sqrt(HC_up(1)**2 + HC_up(2)**2 + HC_up(3)**2)	
	
	HC_up_norm=HC_up/HC_up_mag

	
	! print *, HC_up_norm

	! find the dot product 
	Xpoint= pointc(1) 

	Ypoint= dot_product(pointc,HC_up_norm) 


	! now we can work within the 2d helical plane
	! use in_polygon to see if the point hits the limiter	


	inside_limiter=in_polygon(Xpoint, Ypoint, Xpoly, Ypoly, poly_size)
	
	! print *, 'inside_limiter=', inside_limiter

end if



end function inside_limiter


