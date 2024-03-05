      subroutine irrigate(jj,volmm)
      
!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    this subroutine applies irrigation water to HRU

!!    ~ ~ ~ INCOMING VARIABLES ~ ~ ~
!!    name        |units         |definition
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
!!    aairr(:)    |mm H2O        |average annual amount of irrigation water
!!                               |applied to HRU
!!    curyr       |none          |current year of simulation
!!    irn(:)      |none          |average annual number of irrigation 
!!                               |applications in HRU
!!    nyskip      |none          |number of years to skip output summarization
!!                               |and printing
!!    sol_fc(:,:) |mm H2O        |amount of water available to plants in soil
!!                               |layer at field capacity (fc - wp)
!!    sol_nly(:)  |none          |number of soil layers
!!    sol_st(:,:) |mm H2O        |amount of water stored in the soil layer
!!                               |on any given day (less wp water)
!!    hrumono(22,:)|mm H2O        |amount of irrigation water applied to HRU
!!                               |during month
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

!!    ~ ~ ~ OUTGOING VARIABLES ~ ~ ~
!!    name        |units         |definition
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
!!    aairr(:)    |mm H2O        |average annual amount of irrigation water
!!                               |applied to HRU
!!    aird(:)     |mm H2O        |amount of water applied to HRU on current
!!                               |day
!!    irn(:)      |none          |average annual number of irrigation 
!!                               |applications in HRU
!!    sol_st(:,:) |mm H2O        |amount of water stored in the soil layer
!!                               |on any given day (less wp water)
!!    sol_sw(:)   |mm H2O        |amount of water stored in the soil profile
!!                               |on any given day
!!    hrumono(22,:)|mm H2O        |amount of irrigation water applied to HRU
!!                               |during month
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

!!    ~ ~ ~ LOCAL DEFINITIONS ~ ~ ~
!!    name        |units         |definition
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
!!    fcx         |mm H2O        |amount of water stored in soil layer when
!!                               |moisture content is at field capacity
!!    jj          |none          |HRU number
!!    k           |none          |counter (soil layers)
!!    stx         |mm H2O        |amount of water stored in soil layer on 
!!                               |current day
!!    volmm       |mm H2O        |depth irrigation water applied to HRU
!!    yy          |mm H2O        |amount of water added to soil layer
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

!!    ~ ~ ~ ~ ~ ~ END SPECIFICATIONS ~ ~ ~ ~ ~ ~

      use parm
      use smrt_parm !rtb modflow

      integer, intent (in) :: jj
      real, intent (in out) :: volmm
      integer :: k,dum
      real :: fcx, stx, yy

      integer n,cell_row,cell_col,cell_lay !rtb modflow
      real    gw_vol,hru_area,irrig_vol !rtb modflow

!! initialize variable for HRU
!! (because irrigation can be applied in different command loops
!! the variable is initialized here)


      !SWAT-MODFLOW: check available groundwater, and re-calculate irrigation depth if necessary
      if(mf_active.eq.1 .and. mf_irrigation_swat.eq.1) then
        if(volmm.gt.0) then
          dum = 10
        endif

        !check available groundwater; decrease irrigation depth if not enough groundwater to meet irrigation requirement
        do n=1,ncell_irrigate
          if(jj.eq.mf_sub_irrigate(n,4)) then !found HRU
            
            !row and column of the WELL cell
            cell_row = mf_sub_irrigate(n,2)
            cell_col = mf_sub_irrigate(n,3)
            cell_lay = mf_sub_irrigate(n,5)

            !check available groundwater in the WELL cell
            gw_vol = gw_available(cell_col,cell_row,cell_lay)

            !compute irrigation volume
            hru_area = hru_km(jj) * 1000000. !m2
            irrig_vol = (volmm/1000.) * hru_area

            !compare and make necessary change
            if(irrig_vol.gt.gw_vol) then
              irrig_vol = gw_vol !take what is left
              volmm = (irrig_vol/hru_area) * 1000. !re-calculate mm of irrigation water
              gw_available(cell_col,cell_row,cell_lay) = 0. !no more groundwater in the cell
            endif

            irrig_depth(jj) = irrig_depth(jj) + volmm !mm

          endif
        enddo
      endif

      !regular SWAT calculations
      aird(jj) = volmm * (1. - sq_rto)
      qird(jj) = volmm * sq_rto

      !summary calculations
      if (curyr > nyskip) then 
        irn(jj) = irn(jj) + 1
        aairr(jj) = aairr(jj) + aird(jj)
        hrumono(22,jj) = hrumono(22,jj) + aird(jj)
      end if


      return
      end