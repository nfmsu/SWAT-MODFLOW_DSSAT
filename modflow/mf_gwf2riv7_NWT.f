      MODULE GWFRIVMODULE
        INTEGER,SAVE,POINTER  ::NRIVER,MXRIVR,NRIVVL,IRIVCB,IPRRIV
        INTEGER,SAVE,POINTER  ::NPRIV,IRIVPB,NNPRIV
        CHARACTER(LEN=16),SAVE, DIMENSION(:),   POINTER     ::RIVAUX
        REAL,             SAVE, DIMENSION(:,:), POINTER     ::RIVR
      TYPE GWFRIVTYPE
        INTEGER,POINTER  ::NRIVER,MXRIVR,NRIVVL,IRIVCB,IPRRIV
        INTEGER,POINTER  ::NPRIV,IRIVPB,NNPRIV
        CHARACTER(LEN=16), DIMENSION(:),   POINTER     ::RIVAUX
        REAL,              DIMENSION(:,:), POINTER     ::RIVR
      END TYPE
      TYPE(GWFRIVTYPE), SAVE:: GWFRIVDAT(10)
      END MODULE GWFRIVMODULE


      SUBROUTINE GWF2RIV7AR(IN,IGRID)
C     ******************************************************************
C     ALLOCATE ARRAY STORAGE FOR RIVERS AND READ PARAMETER DEFINITIONS.
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IOUT,NCOL,NROW,NLAY,IFREFM
      USE GWFRIVMODULE, ONLY:NRIVER,MXRIVR,NRIVVL,IRIVCB,IPRRIV,NPRIV,
     1                       IRIVPB,NNPRIV,RIVAUX,RIVR
      use mf_rt_link !rtb
C
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
C
C1------Allocate scalar variables, which makes it possible for multiple
C1------grids to be defined.
      ALLOCATE(NRIVER,MXRIVR,NRIVVL,IRIVCB,IPRRIV,NPRIV,IRIVPB,NNPRIV)
C
C2------IDENTIFY PACKAGE AND INITIALIZE NRIVER AND NNPRIV.
      WRITE(IOUT,1)IN
    1 FORMAT(1X,/1X,'RIV -- RIVER PACKAGE, VERSION 7, 5/2/2005',
     1' INPUT READ FROM UNIT ',I4)
      NRIVER=0
      NNPRIV=0
C
C3------READ MAXIMUM NUMBER OF RIVER REACHES AND UNIT OR FLAG FOR
C3------CELL-BY-CELL FLOW TERMS.
      CALL URDCOM(IN,IOUT,LINE)
      CALL UPARLSTAL(IN,IOUT,LINE,NPRIV,MXPR)
      IF(IFREFM.EQ.0) THEN
         READ(LINE,'(2I10)') MXACTR,IRIVCB
         LLOC=21
      ELSE
         LLOC=1
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,MXACTR,R,IOUT,IN)
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IRIVCB,R,IOUT,IN)
      END IF
      WRITE(IOUT,3) MXACTR
    3 FORMAT(1X,'MAXIMUM OF ',I6,' ACTIVE RIVER REACHES AT ONE TIME')
      IF(IRIVCB.LT.0) WRITE(IOUT,7)
    7 FORMAT(1X,'CELL-BY-CELL FLOWS WILL BE PRINTED WHEN ICBCFL NOT 0')
      IF(IRIVCB.GT.0) WRITE(IOUT,8) IRIVCB
    8 FORMAT(1X,'CELL-BY-CELL FLOWS WILL BE SAVED ON UNIT ',I4)
C
C4------READ AUXILIARY VARIABLES AND PRINT OPTION.
      ALLOCATE (RIVAUX(20))
      NAUX=0
      IPRRIV=1
   10 CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,IN)
      IF(LINE(ISTART:ISTOP).EQ.'AUXILIARY' .OR.
     1        LINE(ISTART:ISTOP).EQ.'AUX') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,IN)
         IF(NAUX.LT.20) THEN
            NAUX=NAUX+1
            RIVAUX(NAUX)=LINE(ISTART:ISTOP)
            WRITE(IOUT,12) RIVAUX(NAUX)
   12       FORMAT(1X,'AUXILIARY RIVER VARIABLE: ',A)
         END IF
         GO TO 10
      ELSE IF(LINE(ISTART:ISTOP).EQ.'NOPRINT') THEN
         WRITE(IOUT,13)
   13    FORMAT(1X,'LISTS OF RIVER CELLS WILL NOT BE PRINTED')
         IPRRIV = 0
         GO TO 10
      END IF
C
C5------ALLOCATE SPACE FOR RIVER ARRAYS.
C5------FOR EACH REACH, THERE ARE SIX INPUT DATA VALUES PLUS ONE
C5------LOCATION FOR CELL-BY-CELL FLOW.
      NRIVVL=7+NAUX
      IRIVPB=MXACTR+1
      MXRIVR=MXACTR+MXPR
      maxriv = MXRIVR !rtb - for use in RT3D
      ALLOCATE (RIVR(NRIVVL,MXRIVR))
C
C6------READ NAMED PARAMETERS.
      WRITE(IOUT,99) NPRIV
   99 FORMAT(1X,//1X,I5,' River parameters')
      IF(NPRIV.GT.0) THEN
        LSTSUM=IRIVPB
        DO 120 K=1,NPRIV
          LSTBEG=LSTSUM
          CALL UPARLSTRP(LSTSUM,MXRIVR,IN,IOUT,IP,'RIV','RIV',1,
     &                   NUMINST)
          NLST=LSTSUM-LSTBEG
          IF (NUMINST.EQ.0) THEN
C6A-----READ PARAMETER WITHOUT INSTANCES
            CALL ULSTRD(NLST,RIVR,LSTBEG,NRIVVL,MXRIVR,1,IN,
     &            IOUT,'REACH NO.  LAYER   ROW   COL'//
     &            '     STAGE    STRESS FACTOR     BOTTOM EL.',
     &            RIVAUX,5,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRRIV)
          ELSE
C6B-----READ INSTANCES
            NINLST = NLST/NUMINST
            DO 110 I=1,NUMINST
            CALL UINSRP(I,IN,IOUT,IP,IPRRIV)
            CALL ULSTRD(NINLST,RIVR,LSTBEG,NRIVVL,MXRIVR,1,IN,
     &            IOUT,'REACH NO.  LAYER   ROW   COL'//
     &            '     STAGE    STRESS FACTOR     BOTTOM EL.',
     &            RIVAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRRIV)
            LSTBEG=LSTBEG+NINLST
  110       CONTINUE
          END IF
  120   CONTINUE
      END IF
C
C7------SAVE POINTERS TO DATA AND RETURN.
      CALL SGWF2RIV7PSV(IGRID)
      RETURN
      END
      SUBROUTINE GWF2RIV7RP(IN,IGRID)
C     ******************************************************************
C     READ RIVER HEAD, CONDUCTANCE AND BOTTOM ELEVATION
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IOUT,NCOL,NROW,NLAY,IFREFM,BOTM,LBOTM,
     1                       IBOUND
      USE GWFRIVMODULE, ONLY:NRIVER,MXRIVR,NRIVVL,IPRRIV,NPRIV,
     1                       IRIVPB,NNPRIV,RIVAUX,RIVR
C     ------------------------------------------------------------------
      CALL SGWF2RIV7PNT(IGRID)
C
C1------READ ITMP (NUMBER OF RIVER REACHES OR FLAG TO REUSE DATA) AND
C1------NUMBER OF PARAMETERS.
      IFREFM = 1
      IF(NPRIV.GT.0) THEN
         IF(IFREFM.EQ.0) THEN
            READ(IN,'(2I10)') ITMP,NP
         ELSE
            READ(IN,*) ITMP,NP
         END IF
      ELSE
         NP=0
         IF(IFREFM.EQ.0) THEN
            READ(IN,'(I10)') ITMP
         ELSE
            READ(IN,*) ITMP
         END IF
      END IF
C
C------CALCULATE SOME CONSTANTS
      NAUX=NRIVVL-7
      IOUTU = IOUT
      IF (IPRRIV.EQ.0) IOUTU = -IOUT
C
C2------DETERMINE THE NUMBER OF NON-PARAMETER REACHES.
      IF(ITMP.LT.0) THEN
         WRITE(IOUT,7)
    7    FORMAT(1X,/1X,
     1   'REUSING NON-PARAMETER RIVER REACHES FROM LAST STRESS PERIOD')
      ELSE
         NNPRIV=ITMP
      END IF
C
C3------IF THERE ARE NEW NON-PARAMETER REACHES, READ THEM.
      MXACTR=IRIVPB-1
      IF(ITMP.GT.0) THEN
         IF(NNPRIV.GT.MXACTR) THEN
            WRITE(IOUT,99) NNPRIV,MXACTR
   99       FORMAT(1X,/1X,'THE NUMBER OF ACTIVE REACHES (',I6,
     1                     ') IS GREATER THAN MXACTR(',I6,')')
            CALL USTOP(' ')
         END IF
         CALL ULSTRD(NNPRIV,RIVR,1,NRIVVL,MXRIVR,1,IN,IOUT,
     1          'REACH NO.  LAYER   ROW   COL'//
     2          '     STAGE      CONDUCTANCE     BOTTOM EL.',
     3          RIVAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRRIV)
      END IF
      NRIVER=NNPRIV
C
C1C-----IF THERE ARE ACTIVE RIV PARAMETERS, READ THEM AND SUBSTITUTE
      CALL PRESET('RIV')
      IF(NP.GT.0) THEN
         NREAD=NRIVVL-1
         DO 30 N=1,NP
         CALL UPARLSTSUB(IN,'RIV',IOUTU,'RIV',RIVR,NRIVVL,MXRIVR,NREAD,
     1                MXACTR,NRIVER,5,5,
     2   'REACH NO.  LAYER   ROW   COL'//
     3   '     STAGE      CONDUCTANCE     BOTTOM EL.',RIVAUX,20,NAUX)
   30    CONTINUE
      END IF
C4------CHECK RIVER HEAD AND MAKE SURE IT IS ABOVE BELL BOTTOM.
      DO 100 L=1,NRIVER
C
C5------GET COLUMN, ROW, AND LAYER OF CELL CONTAINING REACH.
      IL=RIVR(1,L)
      IR=RIVR(2,L)
      IC=RIVR(3,L)
C
C6------IF THE CELL IS EXTERNAL SKIP IT.
      IF(IBOUND(IC,IR,IL).LE.0)GO TO 100
C
C7------SINCE THE CELL IS INTERNAL GET THE RIVER DATA.
      HRIV=RIVR(4,L)
      CRIV=RIVR(5,L)
      RBOT=RIVR(6,L)
      BOT=BOTM(IC,IR,LBOTM(IL))
      DIF=HRIV-RBOT
      IF ( HRIV.LT.BOT ) THEN
        WRITE(IOUT,103)IC,IR,IL
        CALL USTOP(' ')
      END IF
  103 FORMAT('RIVER HEAD SET TO BELOW CELL BOTTOM. MODEL STOPPING. ',
     +                'CELL WITH ERROR (IC,IR,IL): ',3I5) 

  100 CONTINUE
C
C3------PRINT NUMBER OF REACHES IN CURRENT STRESS PERIOD.
      WRITE (IOUT,101) NRIVER
  101 FORMAT(1X,/1X,I6,' RIVER REACHES')
C
C8------RETURN.
  260 RETURN
      END
      SUBROUTINE GWF2RIV7FM(IGRID)
C     ******************************************************************
C     ADD RIVER TERMS TO RHS AND HCOF
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,HNEW,RHS,HCOF
      USE GWFRIVMODULE, ONLY:NRIVER,RIVR
C     ------------------------------------------------------------------
      CALL SGWF2RIV7PNT(IGRID)
C
C1------IF NRIVER<=0 THERE ARE NO RIVERS. RETURN.
      IF(NRIVER.LE.0)RETURN
C
C2------PROCESS EACH CELL IN THE RIVER LIST.
      DO 100 L=1,NRIVER
C
C3------GET COLUMN, ROW, AND LAYER OF CELL CONTAINING REACH.
      IL=RIVR(1,L)
      IR=RIVR(2,L)
      IC=RIVR(3,L)
C
C4------IF THE CELL IS EXTERNAL SKIP IT.
      IF(IBOUND(IC,IR,IL).LE.0)GO TO 100
C
C5------SINCE THE CELL IS INTERNAL GET THE RIVER DATA.
      HRIV=RIVR(4,L)
      CRIV=RIVR(5,L)
      RBOT=RIVR(6,L)
      RRBOT=RBOT
C
C6------COMPARE AQUIFER HEAD TO BOTTOM OF STREAM BED.
      IF(HNEW(IC,IR,IL).LE.RRBOT)GO TO 96
C
C7------SINCE HEAD>BOTTOM ADD TERMS TO RHS AND HCOF.
      RHS(IC,IR,IL)=RHS(IC,IR,IL)-CRIV*HRIV
      HCOF(IC,IR,IL)=HCOF(IC,IR,IL)-CRIV
      GO TO 100
C
C8------SINCE HEAD<BOTTOM ADD TERM ONLY TO RHS.
   96 RHS(IC,IR,IL)=RHS(IC,IR,IL)-CRIV*(HRIV-RBOT)
  100 CONTINUE
C
C9------RETURN
      RETURN
      END
      SUBROUTINE GWF2RIV7BD(KSTP,KPER,IGRID)
C     ******************************************************************
C     CALCULATE VOLUMETRIC BUDGET FOR RIVERS
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,HNEW,BUFF
      USE GWFBASMODULE,ONLY:MSUM,ICBCFL,IAUXSV,DELT,PERTIM,TOTIM,
     1                      VBVL,VBNM
      USE GWFRIVMODULE,ONLY:NRIVER,IRIVCB,RIVR,NRIVVL,RIVAUX
C
      DOUBLE PRECISION HHNEW,CHRIV,RRBOT,CCRIV,RATIN,RATOUT,RRATE
      CHARACTER*16 TEXT
      DATA TEXT /'   RIVER LEAKAGE'/
C     ------------------------------------------------------------------
      CALL SGWF2RIV7PNT(IGRID)
C
C1------INITIALIZE CELL-BY-CELL FLOW TERM FLAG (IBD) AND
C1------ACCUMULATORS (RATIN AND RATOUT).
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IRIVCB.LT.0 .AND. ICBCFL.NE.0) IBD=-1
      IF(IRIVCB.GT.0) IBD=ICBCFL
      IBDLBL=0
C
C2------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A LIST, WRITE HEADER.
      IF(IBD.EQ.2) THEN
         NAUX=NRIVVL-7
         IF(IAUXSV.EQ.0) NAUX=0
         CALL UBDSV4(KSTP,KPER,TEXT,NAUX,RIVAUX,IRIVCB,NCOL,NROW,NLAY,
     1          NRIVER,IOUT,DELT,PERTIM,TOTIM,IBOUND)
      END IF
C
C3------CLEAR THE BUFFER.
      DO 50 IL=1,NLAY
      DO 50 IR=1,NROW
      DO 50 IC=1,NCOL
      BUFF(IC,IR,IL)=ZERO
50    CONTINUE
C
C4------IF NO REACHES, SKIP FLOW CALCULATIONS.
      IF(NRIVER.EQ.0)GO TO 200
C
C5------LOOP THROUGH EACH RIVER REACH CALCULATING FLOW.
      DO 100 L=1,NRIVER
C
C5A-----GET LAYER, ROW & COLUMN OF CELL CONTAINING REACH.
      IL=RIVR(1,L)
      IR=RIVR(2,L)
      IC=RIVR(3,L)
      RATE=ZERO
C
C5B-----IF CELL IS NO-FLOW OR CONSTANT-HEAD MOVE ON TO NEXT REACH.
      IF(IBOUND(IC,IR,IL).LE.0)GO TO 99
C
C5C-----GET RIVER PARAMETERS FROM RIVER LIST.
      HRIV=RIVR(4,L)
      CRIV=RIVR(5,L)
      RBOT=RIVR(6,L)
      RRBOT=RBOT
      HHNEW=HNEW(IC,IR,IL)
C
C5D-----COMPARE HEAD IN AQUIFER TO BOTTOM OF RIVERBED.
      IF(HHNEW.GT.RRBOT) THEN
C
C5E-----AQUIFER HEAD > BOTTOM THEN RATE=CRIV*(HRIV-HNEW).
         CCRIV=CRIV
         CHRIV=CRIV*HRIV
         RRATE=CHRIV - CCRIV*HHNEW
         RATE=RRATE
C
C5F-----AQUIFER HEAD < BOTTOM THEN RATE=CRIV*(HRIV-RBOT).
      ELSE
         RATE=CRIV*(HRIV-RBOT)
         RRATE=RATE
      END IF
C
C5G-----PRINT THE INDIVIDUAL RATES IF REQUESTED(IRIVCB<0).
      IF(IBD.LT.0) THEN
         IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61    FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
         WRITE(IOUT,62) L,IL,IR,IC,RATE
   62    FORMAT(1X,'REACH ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',I5,
     1       '   RATE',1PG15.6)
         IBDLBL=1
      END IF
C
C5H------ADD RATE TO BUFFER.
      BUFF(IC,IR,IL)=BUFF(IC,IR,IL)+RATE
C
C5I-----SEE IF FLOW IS INTO AQUIFER OR INTO RIVER.
      IF(RATE.LT.ZERO) THEN
C
C5J-----AQUIFER IS DISCHARGING TO RIVER SUBTRACT RATE FROM RATOUT.
        RATOUT=RATOUT-RRATE
      ELSE
C
C5K-----AQUIFER IS RECHARGED FROM RIVER; ADD RATE TO RATIN.
        RATIN=RATIN+RRATE
      END IF
C
C5L-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C5L-----COPY FLOW TO RIVR.
   99 IF(IBD.EQ.2) CALL UBDSVB(IRIVCB,NCOL,NROW,IC,IR,IL,RATE,
     1                  RIVR(:,L),NRIVVL,NAUX,7,IBOUND,NLAY)
      RIVR(NRIVVL,L)=RATE
  100 CONTINUE
C
C6------IF CELL-BY-CELL FLOW WILL BE SAVED AS A 3-D ARRAY,
C6------CALL UBUDSV TO SAVE THEM.
      IF(IBD.EQ.1) CALL UBUDSV(KSTP,KPER,TEXT,IRIVCB,BUFF,NCOL,NROW,
     1                          NLAY,IOUT)
C
C7------MOVE RATES,VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVL(3,MSUM)=RIN
      VBVL(4,MSUM)=ROUT
      VBVL(1,MSUM)=VBVL(1,MSUM)+RIN*DELT
      VBVL(2,MSUM)=VBVL(2,MSUM)+ROUT*DELT
      VBNM(MSUM)=TEXT
C
C8------INCREMENT BUDGET TERM COUNTER.
      MSUM=MSUM+1
C
C9------RETURN.
      RETURN
      END
      SUBROUTINE GWF2RIV7DA(IGRID)
C  Deallocate RIV MEMORY
      USE GWFRIVMODULE
C
        CALL SGWF2RIV7PNT(IGRID)
        DEALLOCATE(NRIVER)
        DEALLOCATE(MXRIVR)
        DEALLOCATE(NRIVVL)
        DEALLOCATE(IRIVCB)
        DEALLOCATE(IPRRIV)
        DEALLOCATE(NPRIV)
        DEALLOCATE(IRIVPB)
        DEALLOCATE(NNPRIV)
        DEALLOCATE(RIVAUX)
        DEALLOCATE(RIVR)
C
      RETURN
      END
      SUBROUTINE SGWF2RIV7PNT(IGRID)
C  Change river data to a different grid.
      USE GWFRIVMODULE
C
        NRIVER=>GWFRIVDAT(IGRID)%NRIVER
        MXRIVR=>GWFRIVDAT(IGRID)%MXRIVR
        NRIVVL=>GWFRIVDAT(IGRID)%NRIVVL
        IRIVCB=>GWFRIVDAT(IGRID)%IRIVCB
        IPRRIV=>GWFRIVDAT(IGRID)%IPRRIV
        NPRIV=>GWFRIVDAT(IGRID)%NPRIV
        IRIVPB=>GWFRIVDAT(IGRID)%IRIVPB
        NNPRIV=>GWFRIVDAT(IGRID)%NNPRIV
        RIVAUX=>GWFRIVDAT(IGRID)%RIVAUX
        RIVR=>GWFRIVDAT(IGRID)%RIVR
C
      RETURN
      END
      SUBROUTINE SGWF2RIV7PSV(IGRID)
C  Save river data for a grid.
      USE GWFRIVMODULE
C
        GWFRIVDAT(IGRID)%NRIVER=>NRIVER
        GWFRIVDAT(IGRID)%MXRIVR=>MXRIVR
        GWFRIVDAT(IGRID)%NRIVVL=>NRIVVL
        GWFRIVDAT(IGRID)%IRIVCB=>IRIVCB
        GWFRIVDAT(IGRID)%IPRRIV=>IPRRIV
        GWFRIVDAT(IGRID)%NPRIV=>NPRIV
        GWFRIVDAT(IGRID)%IRIVPB=>IRIVPB
        GWFRIVDAT(IGRID)%NNPRIV=>NNPRIV
        GWFRIVDAT(IGRID)%RIVAUX=>RIVAUX
        GWFRIVDAT(IGRID)%RIVR=>RIVR
C
      RETURN
      END
