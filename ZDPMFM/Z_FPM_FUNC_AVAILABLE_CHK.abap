FUNCTION Z_FPM_FUNC_AVAILABLE_CHK.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_TPLNR) LIKE  IFLOT-TPLNR
*"  EXPORTING
*"     VALUE(E_STATUS) TYPE  C
*"  TABLES
*"      T_STATUS STRUCTURE  JSTAT OPTIONAL
*"  EXCEPTIONS
*"      NOT_FOUND_FUNC_LOCATION
*"----------------------------------------------------------------------
  DATA: LV_TPLNR LIKE IFLOT-TPLNR,
        LV_OBJNR LIKE IFLOT-OBJNR.

  DATA: LIT_STATUS TYPE TABLE OF JSTAT WITH HEADER LINE.
  DATA: LRG_STAT TYPE RANGE OF JSTAT-STAT WITH HEADER LINE.

  CLEAR IFLOT.
  SELECT SINGLE OBJNR INTO LV_OBJNR
                      FROM IFLOT
                     WHERE TPLNR = I_TPLNR.

  IF SY-SUBRC NE 0.
    RAISE NOT_FOUND_FUNC_LOCATION.
  ENDIF.

  CLEAR LIT_STATUS.    REFRESH LIT_STATUS.

  CALL FUNCTION 'STATUS_READ'
       EXPORTING
            OBJNR            = LV_OBJNR
            ONLY_ACTIVE      = 'X'
       TABLES
            STATUS           = LIT_STATUS
       EXCEPTIONS
            OBJECT_NOT_FOUND = 1
            OTHERS           = 2.

  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
             WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  T_STATUS[] = LIT_STATUS[].

  CLEAR LRG_STAT.    REFRESH LRG_STAT.
  LRG_STAT-SIGN   = 'I'.
  LRG_STAT-OPTION = 'EQ'.
  LRG_STAT-LOW    = 'I0076'.    APPEND LRG_STAT.
  LRG_STAT-LOW    = 'I0320'.    APPEND LRG_STAT.
  CLEAR LRG_STAT.

  E_STATUS = 'X'.

  LOOP AT LIT_STATUS.
    CHECK LIT_STATUS-STAT IN LRG_STAT.
    CLEAR E_STATUS.
  ENDLOOP.
ENDFUNCTION.
