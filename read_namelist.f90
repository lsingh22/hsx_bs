subroutine read_namelist

  use points_module
  use coil_module
  use limiter_module
  use vessel_module
  use div_module
  use options_module
  use lcfs_module
  use mgrid_module

  implicit none

  integer :: numargs, iostat
  integer :: filenum, i
  character*72 :: input_file
  
  namelist / flf / points_file, points_number, points_dphi, n_iter, &
       num_periods, num_main_coils, is_mirrored, coil_file_input, &
       skip_value, num_aux_coils, aux_file, aux_percent, aux_flag, mgrid_file, &
       use_diffusion, diffusion_species, d_perp, temperature, boozer_step,&
       boozer_phi, axis_file, use_vessel, vessel_file, num_limiters,&
       lim_file, num_divertors, div_file, num_lcfs, lcfs_file 

  filenum = 10
  input_file = 'flf.namelist'
  open(filenum, file=trim(input_file), status='old')
  read(filenum, nml=flf, iostat=iostat)

  !Initialize coils
  if (num_main_coils >= 1) then
     coil_type = 1
     write(*,*) 'num_main_coils', num_main_coils
     allocate(main_files(num_main_coils))
     main_files(:) = ''
     !main count includes all coils not just for one period
     main_count = num_main_coils * num_periods * (is_mirrored + 1)
     allocate(main_current(main_count))
     main_current(:) = 0.0
     if (num_aux_coils >= 1) then
        allocate(aux_percent(num_aux_coils))
        aux_percent(:) = 0.0
     end if
     call coil_namelist(filenum)
  end if

  
end subroutine read_namelist

!Read the info in the subsection of the namelist for coils
!This is the info about the coil file names, and the currents
!Also includes the information for the aux coils
!Needs to be in a separate place because we need to pre-initialize it
subroutine coil_namelist(filenum)

  use coil_module
  implicit none

  integer :: filenum, iostat, i

  namelist / coils / main_files, main_current, aux_percent, main_current_repeat
  read(filenum, nml=coils, iostat=iostat)
  

  do i = 1,num_main_coils
     main_files(i) = trim(main_files(i))
     if (main_files(i) == '') write(*,*) 'not all files may have been loaded'
  end do

  if (main_current_repeat == 1) then
     do i = 2,num_main_coils
        main_current(i) = main_current(1)
     end do
  end if
  
end subroutine coil_namelist
