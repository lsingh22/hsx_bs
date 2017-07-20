! program to follow one point until it hits the wall

subroutine follow_to_wall

  use points_module
  use options_module
  use lcfs_module
  use div_module
  use coil_module

  double precision,dimension(3) :: p, b, pxyz
  integer :: i,j,isin, inside_vessel,outfile, istate
  integer :: axis_index, interp_index
  double precision :: phi, phiin, r, z, axis_phi, rmag, zmag, pi
  double precision :: linear_interpolate
  double precision :: rline, zline, magline
  double precision :: dphi, totcur, dist, magb
  double precision :: distance_to_lcfs, dist_lcfs

  
  
  
  !call write_coils()
  !call read_input()
  ! print *, 'number of LCFS:', num_lcfs


  ! get the points
  call get_points()
  outfile = 1
 
  
  !file to write output
  if (my_pn == 0) &
       open (unit=outfile,file=trim(adjustl(results_file)),status='unknown')
  !write (1,'(3(F9.6,2X))') p(1:3)
  
  ! start by setting connection length to zero for each point
  allocate(conn_length(points_number))
  conn_length=0.0

   
  points_move(:,:) = points_start(:,:)

  do j=points_ind_begin,points_ind_end
     points_complete(j) = 1
     


     ! set the current point
     current_point = j
     write(lf,*),'point number',j

     call pol2cart(points_move(j,:), pxyz)
     call compute_full_bs(pxyz, b)
     magb = (b(1)**2 + b(2)**2 + b(3)**2)**0.5


     write(lf,'(4(F12.7,2X))'), points_move(j,:), magb
     


     do i=1,n_iter
     	! keep track of number of steps for limiter calculation
     	current_step=i
        
        ! Skip points that already hit
        if (points_hit(j) == 1) then
           cycle
        end if
       
        call follow_field(points_move(j,:), points_dphi, dist, &
             istate)
        
                 
        !write (*,*) 'istate',istate
        if (istate < 0) then
           
           points_complete(j) = 0
           exit
        end if
        

        conn_length(j)=conn_length(j)+dist


        !for writing B field
        call pol2cart(points_move(j,:), pxyz)
        call compute_full_bs(pxyz, b)
        magb = (b(1)**2 + b(2)**2 + b(3)**2)**0.5

!***********DIFFUSION*****************
        ! Do diffusion=1, random diffusion
        if (use_diffusion.eq.1) then
           !write (*,'(3(F15.7,2X))'),points_move(j,:)
           call diffuse_point(points_move(j,:), p, dist, temperature,&
                d_perp, diffusion_species)
           points_move(j,:) = p
           !write (*,*) 'after diffusion'
        end if

        ! Do diffusion = 2: boozer diffusion
        if ((use_diffusion.eq.2).and.(modulo(i, int(boozer_phi)) == 0)) then
           write (lf,'(4(F15.7,2X))'),points_move(j,:), magb
           call diffuse_boozer(points_move(j,:), p, boozer_step)
           points_move(j,:) = p
        end if
!***********END DIFFUSION****************
        if (modulo(i, log_freq) == 0) then   
          if (num_lcfs > 0) then 
            ! print *, 'number of LCFS:', num_lcfs
            dist_lcfs = distance_to_lcfs(points_move(j,1), points_move(j,2), &
                points_move(j,3))
            write (lf,'(5(F15.7,2X))'),points_move(j,:), conn_length(j), dist_lcfs
          else
            write (lf,'(4(F15.7,2X))'),points_move(j,:), magb
          end if
        end if
        
        
        ! write the new point
        !write (1,'(3(F9.6,2X))') p(1:3)
     enddo
  enddo

  if (num_procs > 1) call gather_results
  if (my_pn == 0) call record_output(outfile)
  

  call dealloc_points()
  call deallocate_coils()


end subroutine follow_to_wall

subroutine record_output(filenum)
  use points_module
  use limiter_module
  use div_module
  use vessel_module
  implicit none
  
  integer :: j,k,filenum
  
  do j=1,points_number
     if (points_complete(j) == 1) then
        write (filenum,*) 'point number',j,' completed orbit'
     else
        write (filenum,*) 'point number',j,' did NOT complete orbit'
     end if
     write (filenum,'(A,3(F15.7,2X))') 'start: ',points_start(j,:)
     if (points_hit(j).eq.1) then
        write (filenum,'(A,3(F15.7,2X))') 'end:   ',points_end(j,:)
     else
        write (filenum,'(A,3(F15.7,2X))') 'end:   ',points_move(j,:)
     end if
     write (filenum,'(A,3(F15.7,2X))') 'connection length: ', conn_length(j)
     if (num_vessels.gt.0) then
        write (filenum,*) 'hit wall:',points_hit_vessel(j)
     end if
     if (num_divertors.gt.0) then
        write (filenum,*) 'hit divertor:', points_hit_divertor(j)
     end if
     if (num_limiters.gt.0) then
        write (filenum,*) 'hit limiter:', points_hit_limiter(j)
     end if
     write (filenum,*) '------------------'
  enddo  
  
end subroutine record_output
