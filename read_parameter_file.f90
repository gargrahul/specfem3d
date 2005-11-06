!=====================================================================
!
!          S p e c f e m 3 D  B a s i n  V e r s i o n  1 . 3
!          --------------------------------------------------
!
!                 Dimitri Komatitsch and Jeroen Tromp
!    Seismological Laboratory - California Institute of Technology
!         (c) California Institute of Technology July 2005
!
!    A signed non-commercial agreement is required to use this program.
!   Please check http://www.gps.caltech.edu/research/jtromp for details.
!           Free for non-commercial academic research ONLY.
!      This program is distributed WITHOUT ANY WARRANTY whatsoever.
!      Do not redistribute this program without written permission.
!
!=====================================================================

  subroutine read_parameter_file(LATITUDE_MIN,LATITUDE_MAX,LONGITUDE_MIN,LONGITUDE_MAX, &
        UTM_X_MIN,UTM_X_MAX,UTM_Y_MIN,UTM_Y_MAX,Z_DEPTH_BLOCK, &
        NER_SEDIM,NER_BASEMENT_SEDIM,NER_16_BASEMENT,NER_MOHO_16,NER_BOTTOM_MOHO, &
        NEX_XI,NEX_ETA,NPROC_XI,NPROC_ETA,NTSTEP_BETWEEN_OUTPUT_SEISMOS,NSTEP,UTM_PROJECTION_ZONE,DT, &
        ATTENUATION,USE_OLSEN_ATTENUATION,HARVARD_3D_GOCAD_MODEL,TOPOGRAPHY,LOCAL_PATH,NSOURCES, &
        THICKNESS_TAPER_BLOCK_HR,THICKNESS_TAPER_BLOCK_MR,VP_MIN_GOCAD,VP_VS_RATIO_GOCAD_TOP,VP_VS_RATIO_GOCAD_BOTTOM, &
        OCEANS,IMPOSE_MINIMUM_VP_GOCAD,HAUKSSON_REGIONAL_MODEL,ANISOTROPY, &
        BASEMENT_MAP,MOHO_MAP_LUPEI,ABSORBING_CONDITIONS, &
        MOVIE_SURFACE,MOVIE_VOLUME,CREATE_SHAKEMAP,SAVE_DISPLACEMENT, &
        NTSTEP_BETWEEN_FRAMES,USE_HIGHRES_FOR_MOVIES,HDUR_MOVIE, &
        SAVE_MESH_FILES,PRINT_SOURCE_TIME_FUNCTION,NTSTEP_BETWEEN_OUTPUT_INFO, &
        SUPPRESS_UTM_PROJECTION,MODEL,USE_REGULAR_MESH,SIMULATION_TYPE,SAVE_FORWARD)

  implicit none

  include "constants.h"

  integer NER_SEDIM,NER_BASEMENT_SEDIM,NER_16_BASEMENT,NER_MOHO_16,NER_BOTTOM_MOHO, &
            NEX_XI,NEX_ETA,NPROC_XI,NPROC_ETA,NTSTEP_BETWEEN_OUTPUT_SEISMOS,NSTEP,UTM_PROJECTION_ZONE,SIMULATION_TYPE
  integer NSOURCES,NTSTEP_BETWEEN_FRAMES,NTSTEP_BETWEEN_OUTPUT_INFO

  double precision UTM_X_MIN,UTM_X_MAX,UTM_Y_MIN,UTM_Y_MAX,Z_DEPTH_BLOCK, UTM_MAX
  double precision LATITUDE_MIN,LATITUDE_MAX,LONGITUDE_MIN,LONGITUDE_MAX,DT,HDUR_MOVIE
  double precision THICKNESS_TAPER_BLOCK_HR,THICKNESS_TAPER_BLOCK_MR,VP_MIN_GOCAD,VP_VS_RATIO_GOCAD_TOP,VP_VS_RATIO_GOCAD_BOTTOM

  logical HARVARD_3D_GOCAD_MODEL,TOPOGRAPHY,ATTENUATION,USE_OLSEN_ATTENUATION, &
          OCEANS,IMPOSE_MINIMUM_VP_GOCAD,HAUKSSON_REGIONAL_MODEL, &
          BASEMENT_MAP,MOHO_MAP_LUPEI,ABSORBING_CONDITIONS,SAVE_FORWARD
  logical MOVIE_SURFACE,MOVIE_VOLUME,CREATE_SHAKEMAP,SAVE_DISPLACEMENT,USE_HIGHRES_FOR_MOVIES
  logical ANISOTROPY,SAVE_MESH_FILES,PRINT_SOURCE_TIME_FUNCTION,SUPPRESS_UTM_PROJECTION,USE_REGULAR_MESH

  character(len=150) LOCAL_PATH,MODEL

! local variables
  integer ios,icounter,isource,idummy,NEX_MAX

  double precision DEPTH_BLOCK_KM,RECORD_LENGTH_IN_SECONDS,hdur,minval_hdur

  character(len=150) dummystring

  open(unit=IIN,file='DATA/Par_file',status='old')

  call read_value_integer(SIMULATION_TYPE)
  call read_value_logical(SAVE_FORWARD)

  call read_value_double_precision(LATITUDE_MIN)
  call read_value_double_precision(LATITUDE_MAX)
  call read_value_double_precision(LONGITUDE_MIN)
  call read_value_double_precision(LONGITUDE_MAX)
  call read_value_double_precision(DEPTH_BLOCK_KM)
  call read_value_integer(UTM_PROJECTION_ZONE)
  call read_value_logical(SUPPRESS_UTM_PROJECTION)

  call read_value_integer(NEX_XI)
  call read_value_integer(NEX_ETA)
  call read_value_integer(NPROC_XI)
  call read_value_integer(NPROC_ETA)

! convert basin size to UTM coordinates and depth of mesh to meters
  call utm_geo(LONGITUDE_MIN,LATITUDE_MIN,UTM_X_MIN,UTM_Y_MIN,UTM_PROJECTION_ZONE,ILONGLAT2UTM,SUPPRESS_UTM_PROJECTION)
  call utm_geo(LONGITUDE_MAX,LATITUDE_MAX,UTM_X_MAX,UTM_Y_MAX,UTM_PROJECTION_ZONE,ILONGLAT2UTM,SUPPRESS_UTM_PROJECTION)

  Z_DEPTH_BLOCK = - dabs(DEPTH_BLOCK_KM) * 1000.d0

  if(dabs(DEPTH_BLOCK_KM) <= DEPTH_MOHO_SOCAL .and. MODEL /= 'Lacq_gas_field_France' .and. MODEL /= 'Copper_Carcione') &
    stop 'bottom of mesh must be deeper than deepest regional layer for Southern California'

! check that parameters computed are consistent
  if(UTM_X_MIN >= UTM_X_MAX) stop 'horizontal dimension of UTM block incorrect'
  if(UTM_Y_MIN >= UTM_Y_MAX) stop 'vertical dimension of UTM block incorrect'

! set time step and radial distribution of elements
! right distribution is determined based upon maximum value of NEX

  NEX_MAX = max(NEX_XI,NEX_ETA)
  UTM_MAX = max(UTM_Y_MAX-UTM_Y_MIN, UTM_X_MAX-UTM_X_MIN)/1000.0 ! in KM

  call read_value_string(MODEL)
  call read_value_logical(OCEANS)
  call read_value_logical(TOPOGRAPHY)
  call read_value_logical(ATTENUATION)
  call read_value_logical(USE_OLSEN_ATTENUATION)

! for Lacq (France) gas field
  if(MODEL == 'Lacq_gas_field_France') then

! time step in seconds
    DT                 = 0.003d0

! number of elements in the vertical direction
    NER_SEDIM          = 2
    NER_BASEMENT_SEDIM = 6
    NER_16_BASEMENT    = 3
    NER_MOHO_16        = 3
    NER_BOTTOM_MOHO    = 8

! for copper crystal studied with Jose Carcione
  else if(MODEL == 'Copper_Carcione') then

! time step in seconds
    DT                 = 10.d-9

! number of elements in the vertical direction
! use the same number of elements in the three directions because the copper crystal is a cube
    NER_SEDIM          = NEX_XI
    NER_BASEMENT_SEDIM = 0
    NER_16_BASEMENT    = 0
    NER_MOHO_16        = 0
    NER_BOTTOM_MOHO    = 0

! standard mesh for on Caltech cluster
  else if (UTM_MAX/NEX_MAX >= 1.5) then

! time step in seconds
    DT                 = 0.011d0

! number of elements in the vertical direction
    NER_SEDIM          = 1
    NER_BASEMENT_SEDIM = 2
    NER_16_BASEMENT    = 2
    NER_MOHO_16        = 2
    NER_BOTTOM_MOHO    = 5

  else if(UTM_MAX/NEX_MAX >= 1.0) then

! time step in seconds
    DT                 = 0.009d0

! number of elements in the vertical direction
    NER_SEDIM          = 1
    NER_BASEMENT_SEDIM = 2
    NER_16_BASEMENT    = 3
    NER_MOHO_16        = 4
    NER_BOTTOM_MOHO    = 7

  else
    stop 'this value of NEX_MAX is not in the database, edit read_parameter_file.f90 and recompile'
  endif

! multiply parameters read by mesh scaling factor
  NER_BASEMENT_SEDIM = NER_BASEMENT_SEDIM * 2
  NER_16_BASEMENT = NER_16_BASEMENT * 2
  NER_MOHO_16 = NER_MOHO_16 * 2
  NER_BOTTOM_MOHO = NER_BOTTOM_MOHO * 4

  if(MODEL == 'SoCal' .or. MODEL == 'Lacq_gas_field_France') then

    BASEMENT_MAP             = .false.
    MOHO_MAP_LUPEI           = .false.
    HAUKSSON_REGIONAL_MODEL  = .false.
    HARVARD_3D_GOCAD_MODEL   = .false.
    THICKNESS_TAPER_BLOCK_HR = 1.d0
    THICKNESS_TAPER_BLOCK_MR = 1.d0
    IMPOSE_MINIMUM_VP_GOCAD  = .false.
    VP_MIN_GOCAD             = 1.d0
    VP_VS_RATIO_GOCAD_TOP    = 2.0d0
    VP_VS_RATIO_GOCAD_BOTTOM = 1.732d0
    ANISOTROPY               = .false.
    USE_REGULAR_MESH         = .false.

  else if(MODEL == 'Copper_Carcione') then

    BASEMENT_MAP             = .false.
    MOHO_MAP_LUPEI           = .false.
    HAUKSSON_REGIONAL_MODEL  = .false.
    HARVARD_3D_GOCAD_MODEL   = .false.
    THICKNESS_TAPER_BLOCK_HR = 1.d0
    THICKNESS_TAPER_BLOCK_MR = 1.d0
    IMPOSE_MINIMUM_VP_GOCAD  = .false.
    VP_MIN_GOCAD             = 1.d0
    VP_VS_RATIO_GOCAD_TOP    = 2.0d0
    VP_VS_RATIO_GOCAD_BOTTOM = 1.732d0
! copper crystal is anisotropic, but we handle it direcly in the main routine that computes
! the forces by using constants for the c_ijkl to save memory because the crystal
! is homogeneous, therefore we do not use general anisotropy for a heterogeneous medium
    ANISOTROPY               = .false.
! copper crystal is homogeneous, therefore use a regular mesh
    USE_REGULAR_MESH         = .true.

  else if(MODEL == 'Harvard_LA') then

    BASEMENT_MAP             = .true.
    MOHO_MAP_LUPEI           = .true.
    HAUKSSON_REGIONAL_MODEL  = .true.
    HARVARD_3D_GOCAD_MODEL   = .true.
    THICKNESS_TAPER_BLOCK_HR = 3000.d0
    THICKNESS_TAPER_BLOCK_MR = 15000.d0
    IMPOSE_MINIMUM_VP_GOCAD  = .true.
    VP_MIN_GOCAD             = 750.d0
    VP_VS_RATIO_GOCAD_TOP    = 2.0d0
    VP_VS_RATIO_GOCAD_BOTTOM = 1.732d0
    ANISOTROPY               = .false.
    USE_REGULAR_MESH         = .false.

  else if(MODEL == 'Min_Chen_anisotropy') then

    BASEMENT_MAP             = .false.
    MOHO_MAP_LUPEI           = .false.
    HAUKSSON_REGIONAL_MODEL  = .false.
    HARVARD_3D_GOCAD_MODEL   = .false.
    THICKNESS_TAPER_BLOCK_HR = 1.d0
    THICKNESS_TAPER_BLOCK_MR = 1.d0
    IMPOSE_MINIMUM_VP_GOCAD  = .false.
    VP_MIN_GOCAD             = 1.d0
    VP_VS_RATIO_GOCAD_TOP    = 2.0d0
    VP_VS_RATIO_GOCAD_BOTTOM = 1.732d0
    ANISOTROPY               = .true.
    USE_REGULAR_MESH         = .false.

  else
    stop 'model not implemented, edit read_parameter_file.f90 and recompile'
  endif

! check that Poisson's ratio is positive
  if(VP_VS_RATIO_GOCAD_TOP <= sqrt(2.d0) .or. VP_VS_RATIO_GOCAD_BOTTOM <= sqrt(2.d0)) &
      stop 'wrong value of Poisson''s ratio for Gocad Vs block'

  call read_value_logical(ABSORBING_CONDITIONS)
  call read_value_double_precision(RECORD_LENGTH_IN_SECONDS)

! compute total number of time steps, rounded to next multiple of 100
  NSTEP = 100 * (int(RECORD_LENGTH_IN_SECONDS / (100.d0*DT)) + 1)

! compute the total number of sources in the CMTSOLUTION file
! there are NLINES_PER_CMTSOLUTION_SOURCE lines per source in that file
  open(unit=1,file='DATA/CMTSOLUTION',iostat=ios,status='old')
  if(ios /= 0) stop 'error opening CMTSOLUTION file'
  icounter = 0
  do while(ios == 0)
    read(1,"(a)",iostat=ios) dummystring
    if(ios == 0) icounter = icounter + 1
  enddo
  close(1)
  if(mod(icounter,NLINES_PER_CMTSOLUTION_SOURCE) /= 0) &
    stop 'total number of lines in CMTSOLUTION file should be a multiple of NLINES_PER_CMTSOLUTION_SOURCE'
  NSOURCES = icounter / NLINES_PER_CMTSOLUTION_SOURCE
  if(NSOURCES < 1) stop 'need at least one source in CMTSOLUTION file'

  call read_value_logical(MOVIE_SURFACE)
  call read_value_logical(MOVIE_VOLUME)
  call read_value_integer(NTSTEP_BETWEEN_FRAMES)
  call read_value_logical(CREATE_SHAKEMAP)
  call read_value_logical(SAVE_DISPLACEMENT)
  call read_value_logical(USE_HIGHRES_FOR_MOVIES)
  call read_value_double_precision(HDUR_MOVIE)
! computes a default hdur_movie that creates nice looking movies.
! Sets HDUR_MOVIE as the minimum period the mesh can resolve for Southern California model
  if(HDUR_MOVIE <=TINYVAL .and. (MODEL == 'Harvard_LA' .or. MODEL == 'SoCal')) &
  HDUR_MOVIE = max(384/NEX_XI*2.4,384/NEX_ETA*2.4)

! compute the minimum value of hdur in CMTSOLUTION file
  open(unit=1,file='DATA/CMTSOLUTION',status='old')
  minval_hdur = HUGEVAL
  do isource = 1,NSOURCES

! skip other information
    do idummy = 1,3
      read(1,"(a)") dummystring
    enddo

! read half duration and compute minimum
    read(1,"(a)") dummystring
    read(dummystring(15:len_trim(dummystring)),*) hdur
    minval_hdur = min(minval_hdur,hdur)

! skip other information
    do idummy = 1,9
      read(1,"(a)") dummystring
    enddo

  enddo
  close(1)

! one cannot use a Heaviside source for the movies
!  if((MOVIE_SURFACE .or. MOVIE_VOLUME) .and. sqrt(minval_hdur**2 + HDUR_MOVIE**2) < TINYVAL) &
!    stop 'hdur too small for movie creation, movies do not make sense for Heaviside source'

  call read_value_logical(SAVE_MESH_FILES)
  call read_value_string(LOCAL_PATH)
  call read_value_integer(NTSTEP_BETWEEN_OUTPUT_INFO)
  call read_value_integer(NTSTEP_BETWEEN_OUTPUT_SEISMOS)
  call read_value_logical(PRINT_SOURCE_TIME_FUNCTION)

! close parameter file
  close(IIN)

  end subroutine read_parameter_file

