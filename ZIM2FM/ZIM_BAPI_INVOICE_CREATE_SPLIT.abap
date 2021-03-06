FUNCTION ZIM_BAPI_INVOICE_CREATE_SPLIT.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             REFERENCE(P_ZFCIVRN) LIKE  ZTCIVHD-ZFCIVRN
*"             REFERENCE(P_CHG_MODE) TYPE  C DEFAULT 'X'
*"             REFERENCE(P_DOC_TYPE)
*"  LIKE  BAPI_INCINV_CREATE_HEADER-DOC_TYPE DEFAULT 'RE'
*"             REFERENCE(I_INVOICE) LIKE  RBKP-XRECH
*"             REFERENCE(I_CREDITMEMO) LIKE  RBKP-XRECH
*"             REFERENCE(P_BLDAT) LIKE  MKPF-BLDAT
*"             REFERENCE(P_BUDAT) LIKE  MKPF-BUDAT
*"             REFERENCE(P_ZFBDT) LIKE  ZTCIVHST-ZFBDT
*"       EXPORTING
*"             REFERENCE(INVOICEDOCNUMBER)
*"  LIKE  BAPI_INCINV_FLD-INV_DOC_NO
*"             REFERENCE(FISCALYEAR) LIKE  BAPI_INCINV_FLD-FISC_YEAR
*"       TABLES
*"              RETURN STRUCTURE  BAPIRET2
*"       EXCEPTIONS
*"              LIV_ERROR
*"----------------------------------------------------------------------
  DATA : L_TEXT         LIKE BKPF-AWKEY,
         L_DATE         LIKE SY-DATUM,
         W_ITEM_TEXT    LIKE BAPI_INCINV_CREATE_ITEM-ITEM_TEXT,
         L_FIELDNM(30)  TYPE C,
         W_LENGTH       TYPE I.

  FIELD-SYMBOLS: <F_BP>,
                 <F_BA>.

  CLEAR : INVOICEDOCNUMBER, FISCALYEAR,
          HEADERDATA,
          ITEMDATA,
          TAXDATA,
          RETURN,
          ZTREQHD, ZTBL.

  REFRESH : ITEMDATA,
            TAXDATA,
            RETURN.

  ">> Key Value Check.
  IF P_ZFCIVRN IS INITIAL.
     MESSAGE E213  RAISING  LIV_ERROR.
  ENDIF.

  ">> Commercial Invoice Header Get.
  SELECT SINGLE * FROM   ZTCIVHD
                  WHERE  ZFCIVRN  EQ   P_ZFCIVRN.
  IF SY-SUBRC NE 0.
    MESSAGE  E374 WITH P_ZFCIVRN   RAISING  LIV_ERROR.
  ENDIF.

  ">> Non-Monetary
  IF ZTCIVHD-ZFPOYN EQ 'N'.
    MESSAGE  E522 WITH P_ZFCIVRN   RAISING  LIV_ERROR.
  ENDIF.

  ">> Company Code
  IF ZTCIVHD-BUKRS IS INITIAL.
    MESSAGE  E167 WITH 'Company code'  RAISING  LIV_ERROR.
  ENDIF.

  ">> Import System IMG Get
  SELECT SINGLE * FROM ZTIMIMG00.
  IF SY-SUBRC NE 0.
    MESSAGE  E167 WITH 'Import IMG' RAISING LIV_ERROR.
  ENDIF.

  ">> Commercial Invoice Item Get.
  SELECT * INTO CORRESPONDING FIELDS OF TABLE IT_ZSCIVIT
           FROM  ZTCIVIT
           WHERE ZFCIVRN   EQ   P_ZFCIVRN.
  IF SY-SUBRC NE 0.
    MESSAGE E167 WITH 'Item description'   RAISING  LIV_ERROR.
  ENDIF.

  SELECT * INTO *EKPO FROM EKPO UP TO 1 ROWS
           FOR ALL ENTRIES IN  IT_ZSCIVIT
           WHERE EBELN  EQ  IT_ZSCIVIT-EBELN
           AND   EBELP  EQ  IT_ZSCIVIT-EBELP
           AND   WEBRE  EQ  'X'.
  ENDSELECT.

*---------------------------------------------------------------------
* Item Level Check
*---------------------------------------------------------------------
  W_LINE = 0.
  LOOP AT IT_ZSCIVIT.

    ">> P/O Header Check
    IF NOT IT_ZSCIVIT-EBELN IS INITIAL.
       CLEAR : EKKO.
       SELECT SINGLE * FROM  EKKO
       WHERE  EBELN EQ IT_ZSCIVIT-EBELN.
       IF EKKO-LOEKZ NE SPACE.
          MESSAGE E005 WITH IT_ZSCIVIT-EBELN  RAISING  LIV_ERROR.
       ENDIF.

       IF ZTIMIMG00-ZFEXFIX EQ 'X' AND ZTIMIMG00-ZFEXMTD NE 'G'.

          IF ZTCIVHD-ZFEXRT NE EKKO-WKURS.
             MESSAGE E529 WITH ZTCIVHD-ZFCIVRN ZTCIVHD-ZFEXRT
                               EKKO-EBELN      EKKO-WKURS.
          ENDIF.
          IF EKKO-KUFIX NE 'X'.
             MESSAGE E528 WITH EKKO-EBELN RAISING  LIV_ERROR.
          ENDIF.
       ENDIF.

       ">> P/O Item Check.
       CLEAR : EKPO.
       SELECT SINGLE * FROM  EKPO
                     WHERE EBELN EQ IT_ZSCIVIT-EBELN
                     AND   EBELP EQ IT_ZSCIVIT-EBELP.
       IF EKPO-LOEKZ NE SPACE.
          MESSAGE E069 WITH IT_ZSCIVIT-EBELN IT_ZSCIVIT-EBELP
                       RAISING  LIV_ERROR.
       ENDIF.

    ENDIF.

    WRITE IT_ZSCIVIT-ZFIVAMP TO  W_TEXT_AMOUNT
                                 CURRENCY  ZTCIVHD-ZFIVAMC.
    PERFORM    P2000_WRITE_NO_MASK     CHANGING  W_TEXT_AMOUNT.

    CLEAR : EKPO.
    SELECT SINGLE * FROM  EKPO
              WHERE EBELN EQ IT_ZSCIVIT-EBELN
              AND   EBELP EQ IT_ZSCIVIT-EBELP.

    ">> G/R Based I/V
    CLEAR : ITEMDATA.
    IF EKPO-WEBRE EQ 'X' AND ZTCIVHD-ZFSVYN NE 'X'.
       SELECT * FROM   EKBE  UP TO 1 ROWS
                WHERE  BEWTP   EQ    'E'
                AND    EBELN   EQ    IT_ZSCIVIT-EBELN
                AND    EBELP   EQ    IT_ZSCIVIT-EBELP.
          MOVE : EKBE-GJAHR     TO    ITEMDATA-REF_DOC_YEAR,
                 EKBE-BELNR     TO    ITEMDATA-REF_DOC,
                 EKBE-BUZEI     TO    ITEMDATA-REF_DOC_IT.
       ENDSELECT.
       IF SY-SUBRC NE 0.
          MESSAGE  E219(ZIM1) WITH IT_ZSCIVIT-EBELN IT_ZSCIVIT-EBELP
                              RAISING  LIV_ERROR.
       ENDIF.
    ENDIF.

    ">> Tax Code Get.
    CLEAR : ZTREQHD, EKKO.
    SELECT SINGLE * FROM ZTREQHD
                    WHERE ZFREQNO   EQ   IT_ZSCIVIT-ZFREQNO.

    SELECT SINGLE * FROM EKKO
                    WHERE EBELN     EQ   IT_ZSCIVIT-EBELN.

    IF SY-SUBRC EQ 0.
       SELECT SINGLE * FROM  ZTIMIMG01
       WHERE  ZTERM    EQ    EKKO-ZTERM
       AND    BSTYP    EQ    EKKO-BSTYP
       AND    BSART    EQ    EKKO-BSART
       AND    ZFREQTY  EQ    ZTREQHD-ZFREQTY
       AND    ZFAPLDT  EQ  ( SELECT MAX( ZFAPLDT )
                             FROM   ZTIMIMG01
                             WHERE  ZTERM    EQ   EKKO-ZTERM
                             AND    BSTYP    EQ   EKKO-BSTYP
                             AND    BSART    EQ   EKKO-BSART
                             AND    ZFREQTY  EQ   ZTREQHD-ZFREQTY
                             AND    ZFAPLDT  LE   P_BUDAT ).
       IF ZTIMIMG01-MWSKZ IS INITIAL.
          MESSAGE E921 RAISING  LIV_ERROR.
       ENDIF.
    ELSE.
       MESSAGE E921 RAISING  LIV_ERROR.
    ENDIF.

    ">> B/L Number Get
    SELECT SINGLE * FROM ZTBL
    WHERE  ZFBLNO   EQ   IT_ZSCIVIT-ZFBLNO.
    IF SY-SUBRC NE 0.
       MOVE   ZTREQHD-ZFOPNNO  TO  ZTBL-ZFHBLNO.
    ENDIF.

    W_LENGTH = STRLEN( ZTBL-ZFHBLNO ).
    W_LENGTH = 20  -  W_LENGTH.

    CONCATENATE  ZTBL-ZFHBLNO  IT_ZSCIVIT-MATNR INTO W_ITEM_TEXT
                               SEPARATED BY SPACE.

    ADD    1    TO     W_LINE.
    MOVE : W_LINE                 TO  ITEMDATA-INVOICE_DOC_ITEM,
           IT_ZSCIVIT-EBELN       TO  ITEMDATA-PO_NUMBER,
           IT_ZSCIVIT-EBELP       TO  ITEMDATA-PO_ITEM,
           SPACE                  TO  ITEMDATA-DE_CRE_IND,
           W_ITEM_TEXT            TO  ITEMDATA-ITEM_TEXT,
           ZTIMIMG01-MWSKZ        TO  ITEMDATA-TAX_CODE,
           SPACE                  TO  ITEMDATA-TAXJURCODE,
           W_TEXT_AMOUNT          TO  ITEMDATA-ITEM_AMOUNT,
           IT_ZSCIVIT-ZFPRQN      TO  ITEMDATA-QUANTITY,
           IT_ZSCIVIT-MEINS       TO  ITEMDATA-PO_UNIT,
           SPACE                  TO  ITEMDATA-PO_UNIT_ISO,
           IT_ZSCIVIT-BPRME       TO  ITEMDATA-PO_PR_UOM,
           SPACE                  TO  ITEMDATA-PO_PR_UOM_ISO,
           SPACE                  TO  ITEMDATA-COND_TYPE,
           SPACE                  TO  ITEMDATA-COND_ST_NO,
           SPACE                  TO  ITEMDATA-COND_COUNT.
*>> Convert Quantity Unit.
    IF IT_ZSBDIV-BPRME NE IT_ZSBDIV-MEINS.
      CALL FUNCTION 'CF_UT_UNIT_CONVERSION'
           EXPORTING
                UNIT_NEW_IMP  = IT_ZSBDIV-BPRME
                UNIT_OLD_IMP  = IT_ZSBDIV-MEINS
                VALUE_OLD_IMP = 1
           IMPORTING
                VALUE_NEW_EXP = NEW_LFIMG
           EXCEPTIONS
                OVERFLOW      = 1
                OTHERS        = 2.
      W_ZFPRQN = IT_ZSBDIV-MENGE * NEW_LFIMG.
    ENDIF.
    MOVE : W_ZFPRQN               TO  ITEMDATA-PO_PR_QNT.

*----------------------------------------------------------------
*> Service No ENTRY.
*----------------------------------------------------------------
    IF ZTCIVHD-ZFSVYN EQ 'X'.
      MOVE : IT_ZSCIVIT-ZFSVNO      TO  ITEMDATA-SHEET_NO.
      CLEAR : ITEMDATA-QUANTITY,   ITEMDATA-PO_UNIT,
              ITEMDATA-PO_PR_QNT,  ITEMDATA-PO_PR_UOM.
    ENDIF.
*----------------------------------------------------------------

    APPEND ITEMDATA.
  ENDLOOP.

  WRITE ZTCIVHD-ZFIVAMP TO  W_TEXT_AMOUNT
        CURRENCY  ZTCIVHD-ZFIVAMC.
  PERFORM    P2000_WRITE_NO_MASK     CHANGING  W_TEXT_AMOUNT.

  ">> Tax Data Get
  CLEAR : TAXDATA.
  MOVE : ZTIMIMG01-MWSKZ   TO   TAXDATA-TAX_CODE.
  APPEND  TAXDATA.

  ">> Import Request Get
  READ TABLE  IT_ZSCIVIT INDEX 1.
  IF SY-SUBRC EQ 0.
    SELECT SINGLE * FROM ZTREQHD
                    WHERE ZFREQNO  EQ  IT_ZSCIVIT-ZFREQNO.
  ENDIF.

  ">> B/L No Get.
  CLEAR TEMP_BKTXT.
  LOOP AT IT_ZSCIVIT WHERE ZFBLNO <> SPACE.
    SELECT SINGLE * FROM ZTBL
                    WHERE ZFBLNO  EQ  IT_ZSCIVIT-ZFBLNO.
    TEMP_BKTXT = ZTBL-ZFHBLNO.
  ENDLOOP.

  ">> Currency Code Get.
  SELECT SINGLE * FROM   TCURC
                  WHERE  WAERS   EQ   ZTCIVHD-ZFIVAMC.

  ">> Header Data
  IF NOT I_INVOICE IS INITIAL.
    MOVE : 'X'         TO  HEADERDATA-INVOICE_IND.
  ELSEIF NOT I_CREDITMEMO IS INITIAL.
    MOVE : SPACE       TO  HEADERDATA-INVOICE_IND.
  ELSE.
    MOVE : 'X'         TO  HEADERDATA-INVOICE_IND.
  ENDIF.

*  IF ZTREQHD-ZFREQTY NE 'TT'.
*     MOVE ZTCIVHD-ZFOPBN  TO  HEADERDATA-PAYEE_PAYER.
*  ENDIF.

  MOVE : P_DOC_TYPE      TO  HEADERDATA-DOC_TYPE,
         P_BLDAT         TO  HEADERDATA-DOC_DATE,
         P_BUDAT         TO  HEADERDATA-PSTNG_DATE,
         P_ZFBDT         TO  HEADERDATA-BLINE_DATE,
         ZTCIVHD-ZFCIVNO TO  HEADERDATA-REF_DOC_NO,
         ZTCIVHD-BUKRS   TO  HEADERDATA-COMP_CODE,
*         ZTCIVHD-ZFOPBN  TO  HEADERDATA-PAYEE_PAYER,
         ZTCIVHD-ZFIVAMC TO  HEADERDATA-CURRENCY,
         TCURC-ISOCD     TO  HEADERDATA-CURRENCY_ISO,
         ZTBL-ZFHBLNO    TO  HEADERDATA-PAYMT_REF,
         ZTREQHD-ZFOPNNO TO  HEADERDATA-HEADER_TXT.

  ">> Exchange Rate
  IF ZTCIVHD-ZFIVAMC NE 'USD'.
    MOVE: ZTCIVHD-ZFEXRT TO  HEADERDATA-EXCH_RATE.
  ENDIF.

  IF ZTCIVHD-ZFREQTY EQ 'PU' OR ZTCIVHD-ZFREQTY EQ 'LO'.
    MOVE ZTCIVHD-ZFMAVN  TO  HEADERDATA-DIFF_INV.
  ELSE.
    MOVE ZTCIVHD-ZFMAVN  TO  HEADERDATA-DIFF_INV.
  ENDIF.
** added by furong
  MOVE ZTCIVHD-ZFOPBN  TO  HEADERDATA-PAYEE_PAYER.
** end of addition
  MOVE : W_TEXT_AMOUNT   TO  HEADERDATA-GROSS_AMOUNT,
         ' '             TO  HEADERDATA-CALC_TAX_IND,
         ZTCIVHD-ZTERM   TO  HEADERDATA-PMNTTRMS,
         ' '             TO  HEADERDATA-PMTMTHSUPL,
         0               TO  HEADERDATA-DSCT_DAYS1,
         0               TO  HEADERDATA-DSCT_DAYS2,
         0               TO  HEADERDATA-NETTERMS,
         0               TO  HEADERDATA-DSCT_PCT1,
         0               TO  HEADERDATA-DSCT_PCT2,
         SPACE           TO  HEADERDATA-IV_CATEGORY,
         ZTREQHD-EBELN   TO  HEADERDATA-ALLOC_NMBR.

  ">> Unplanned Amount
  W_ZFIVAMT = 0.
  W_ZFIVAMT = ZTCIVHD-ZFPKCHGP + ZTCIVHD-ZFHDCHGP.

  WRITE W_ZFIVAMT TO  W_TEXT_AMOUNT  CURRENCY  ZTCIVHD-ZFIVAMC.
  PERFORM    P2000_WRITE_NO_MASK     CHANGING  W_TEXT_AMOUNT.

  MOVE : W_TEXT_AMOUNT TO  HEADERDATA-DEL_COSTS,
         SPACE         TO  HEADERDATA-DEL_COSTS_TAXC,
         SPACE         TO  HEADERDATA-DEL_COSTS_TAXJ,
         SY-UNAME      TO  HEADERDATA-PERSON_EXT.

  IF ZTIMIMG00-CSREALYN EQ 'X'.
    CALL FUNCTION 'BAPI_INCOMINGINVOICE_PARK'
         EXPORTING
              HEADERDATA       = HEADERDATA
         IMPORTING
              INVOICEDOCNUMBER = INVOICEDOCNUMBER
              FISCALYEAR       = FISCALYEAR
         TABLES
              ITEMDATA         = ITEMDATA
              TAXDATA          = TAXDATA
              RETURN           = RETURN.
  ELSE.

    CALL FUNCTION 'BAPI_INCOMINGINVOICE_CREATE'
         EXPORTING
              HEADERDATA       = HEADERDATA
         IMPORTING
              INVOICEDOCNUMBER = INVOICEDOCNUMBER
              FISCALYEAR       = FISCALYEAR
         TABLES
              ITEMDATA         = ITEMDATA
              TAXDATA          = TAXDATA
              RETURN           = RETURN.
  ENDIF.

  IF RETURN[] IS INITIAL.

    SELECT SINGLE * FROM ZTCIVHD
                    WHERE ZFCIVRN   EQ    P_ZFCIVRN.

    MOVE-CORRESPONDING  ZTCIVHD   TO    *ZTCIVHD.

    CLEAR : ZTCIVHST.

    IF NOT I_INVOICE IS INITIAL.
       MOVE : 'Y'               TO      ZTCIVHD-ZFIVST,
              SY-UNAME          TO      ZTCIVHD-UNAM,
              SY-DATUM          TO      ZTCIVHD-UDAT.
       UPDATE ZTCIVHD.
       MOVE    'S'              TO      ZTCIVHST-SHKZG.
    ELSE.
       MOVE : 'N'               TO      ZTCIVHD-ZFIVST,
              SY-UNAME          TO      ZTCIVHD-UNAM,
              SY-DATUM          TO      ZTCIVHD-UDAT.
       UPDATE ZTCIVHD.
       MOVE    'H'              TO      ZTCIVHST-SHKZG.
    ENDIF.

    ">> Change Document.
    CALL FUNCTION 'ZIM_CHANGE_DOCUMENT_CIV'
         EXPORTING
              UPD_CHNGIND = 'U'
              N_ZTCIVHD   = ZTCIVHD
              O_ZTCIVHD   = *ZTCIVHD.

  ENDIF.

  IF P_CHG_MODE EQ 'X'.
    IF RETURN[] IS INITIAL.        "> SUCCESS

      MOVE : SY-MANDT           TO     ZTCIVHST-MANDT,
             P_ZFCIVRN          TO     ZTCIVHST-ZFCIVRN,
             P_BLDAT            TO     ZTCIVHST-BLDAT,
             P_BUDAT            TO     ZTCIVHST-BUDAT,
             ZTCIVHD-BUKRS      TO     ZTCIVHST-BUKRS,
             ZTCIVHD-ZFIVAMK    TO     ZTCIVHST-ZFIVAMK,
             'KRW'              TO     ZTCIVHST-ZFKRW,
             ZTCIVHD-ZFIVAMP    TO     ZTCIVHST-ZFIVAMP,
             ZTCIVHD-ZFIVAMC    TO     ZTCIVHST-WAERS,
             ZTCIVHD-ZFEXRT     TO     ZTCIVHST-ZFEXRT,
             SY-UNAME           TO     ZTCIVHST-ERNAM,
             SY-DATUM           TO     ZTCIVHST-CDAT,
             SY-UZEIT           TO     ZTCIVHST-CTME,
             FISCALYEAR         TO     ZTCIVHST-GJAHR,
             INVOICEDOCNUMBER   TO     ZTCIVHST-BELNR.

      SELECT MAX( ZFCIVHST ) INTO ZTCIVHST-ZFCIVHST
             FROM   ZTCIVHST
             WHERE  ZFCIVRN    EQ    P_ZFCIVRN.

      ADD    1                 TO    ZTCIVHST-ZFCIVHST.

      INSERT   ZTCIVHST.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      RAISE   LIV_ERROR.
    ENDIF.
  ELSE.
    IF RETURN[] IS INITIAL.        "> SUCCESS
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      RAISE   LIV_ERROR.
    ENDIF.
  ENDIF.

ENDFUNCTION.
