C Basis file for running Tsyganenko experiment. 
C The goal of this file is to paste this into a folder containing your Tsyganenko model
C and change the name of the function that is supposed to be called. 
C Make sure the geopack is also in this folder.

      PROGRAM BASELINE_TSYGANENKO
      IMPLICIT NONE
      REAL ::           AA(10),SPS,CPS,BB(3),PSI,CC(18)
      COMMON /GEOPACK1/ AA,SPS,CPS,BB,PSI,CC
      
      EXTERNAL DIP_08, IGRF_GSW_08
C Placeholder name, give name of TS model here
      
      
C Define boundary
      INTEGER, PARAMETER :: DIMX=600
      INTEGER, PARAMETER :: DIMY=1
      INTEGER, PARAMETER :: DIMZ=600
      
      REAL XGSW(DIMX),YGSW(DIMY),ZGSW(DIMZ),dx,dy,dz
      REAL PARMOD(10),PS,EBX,EBY,EBZ
      ! Define input parameters
      INTEGER :: ID, IYEAR, IDOY, IHOUR, IMINUTE
      REAL :: By,Bz,VX,VY,VZ,PDYN,DST,N,B

      REAL, DIMENSION(3) :: init=(/ -40, 0, -35 /)
      REAL, DIMENSION(3) :: fin=(/ 20, 0, 35 /)

      INTEGER, PARAMETER :: LIMR=1.5
      REAL*8 :: D2 = 0.D0
      REAL*8 :: R2 = 0.D0
      REAL*8 :: Z = 0.D0

C Define output parameters
      REAL :: DXGSW,DYGSW,DZGSW ! Correct type normally
      REAL :: IXGSW,IYGSW,IZGSW ! Same for this one
      
C Read file with parameters
      INTEGER :: i, j, k
      INTEGER, PARAMETER :: ounit=20
      INTEGER, PARAMETER :: iunit=21
      INTEGER :: status 
      CHARACTER(100) :: inputfile
      CHARACTER(len=6) :: outfolder
      CHARACTER(len=9) :: createfilename
      outfolder = 'output'


      dx = (fin(1) - init(1)) / DIMX
      dy = (fin(2) - init(2)) / DIMY
      dz = (fin(3) - init(3)) / DIMZ
            
      DO k = 1, DIMZ
        DO j = 1, DIMY
          DO i = 1, DIMX  
            XGSW(i) = init(1) + (i-1)*dx
            YGSW(j) = init(2) + (j-1)*dy
            ZGSW(k) = init(3) + (k-1)*dz
          ENDDO
        ENDDO
      ENDDO


      print *, '  enter filename of input'
      read*, inputfile
      OPEN(unit=iunit,file=TRIM(ADJUSTL(inputfile)),status="old",
     * action='read')
C Skip first line      
      read(iunit,*) 

      loop_file: DO
        read(iunit,*,IOSTAT=status) ID,IYEAR,IDOY,IHOUR,IMINUTE,By,Bz,
     *   VX,VY,VZ,PDYN,DST,N,B
      
        write(*, *) 'Generating file ', ID

        CALL RECALC_08 (IYEAR,IDOY,IHOUR,IMINUTE,0,VX,VY,VZ)

        IF (status < 0) THEN
            EXIT
        END IF

        OPEN (UNIT=ounit,FILE=outfolder//"/"//createfilename(ID),
     *   ACTION="write", STATUS="replace")

        loop_z: DO k = 1, DIMZ
          loop_y: DO j = 1, DIMY
            loop_x: DO i = 1, DIMX
C              CALL T96_01 (IOPT,PARMOD,PSI,
C     *                   REAL(XGSW(i)),REAL(YGSW(j)),REAL(ZGSW(k)),
C     *                   EBX,EBY,EBZ)
C -- Routines to include internal B field:
              CALL DIP_08 (XGSW(i),YGSW(j),
     *               ZGSW(k),DXGSW,DYGSW,DZGSW)
              CALL IGRF_GSW_08 (XGSW(i),YGSW(j),
     *               ZGSW(k),IXGSW,IYGSW,IZGSW)
C -- Save output to file
              WRITE(ounit,*) XGSW(i),YGSW(j),ZGSW(k),
     *                       DXGSW+IXGSW,! + EBX,
     *                       DYGSW+IYGSW,! + EBY,
     *                       DZGSW+IZGSW! + EBZ
            ENDDO loop_x
          ENDDO loop_y
        ENDDO loop_z
      
      END DO loop_file

      END PROGRAM BASELINE_TSYGANENKO


      function createfilename(ID) result(name)
            ! Create savefile name based on ID of the line of the inputfile
            implicit none
            integer, intent(in) :: ID ! input
            CHARACTER(len=9) :: name
            IF (ID < 10) THEN
                  write (name, "(A3,I1,I1,A4)") "OUT",0,ID,".DAT"
            ELSE
                  write (name, "(A3,I2,A4)") "OUT",ID,".DAT"
            ENDIF
            print*,name
      end function createfilename

