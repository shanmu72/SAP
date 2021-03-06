FUNCTION zmmf_if_change_vendor.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_VENDOR) LIKE  ZSMM_IF007 STRUCTURE  ZSMM_IF007
*"  TABLES
*"      E_RETURN STRUCTURE  BAPIRETURN
*& Date      Developer   Request     Description
*& 06/28/06  Manju       UD1K921212  Ignore Taxcode 2 and Email address
*&                                   passed from VAATZ.
*& 08/15/06  Manju       UD1K921759  Add search term, state, fax
*&                                   to Vaatz structure & change BDC to
*&                                   update the same
*"----------------------------------------------------------------------
  DATA: lv_seqno LIKE ztmm_if017-seqno.

  CLEAR: v_vendor.
  CLEAR: it_return, e_return.

  REFRESH: it_return, e_return.

  MOVE: i_vendor TO v_vendor.
  MOVE: 'R'      TO v_flag. " change vendor flag.

*---// interface data type conversion.
  PERFORM apply_conversion_rule.

*---// insert entry to table.
  PERFORM save_if_table.

  IF e_return-type = 'E'.
    EXIT.
  ENDIF.
*---// importing value existence check with further processing.
  PERFORM check_change_parameters.

  READ TABLE it_return WITH KEY type = 'E'.
  IF sy-subrc = 0.
    LOOP AT it_return.
      lv_seqno = sy-tabix. " Assign Message sequence number

      MOVE-CORRESPONDING it_return TO ztmm_if017.
      MOVE: v_serno  TO ztmm_if017-serno,
            lv_seqno TO ztmm_if017-seqno.
      INSERT ztmm_if017.
      MOVE-CORRESPONDING it_return TO e_return.
      APPEND e_return.
    ENDLOOP.

*** Modification for Re-processing - Inserted by YWYANG
    UPDATE ztmm_if007 SET   type = 'E'
                      WHERE serno = v_serno.
    COMMIT WORK AND WAIT.
*** 2006/02/22 - End of insert
    EXIT.
  ENDIF.

*---// changing vendor.
  PERFORM change_vendor.

  LOOP AT it_return.
    lv_seqno = sy-tabix. " Assign Message sequence number

    MOVE-CORRESPONDING it_return TO ztmm_if017.
    MOVE: v_serno  TO ztmm_if017-serno,
          lv_seqno TO ztmm_if017-seqno.
    INSERT ztmm_if017.
    MOVE-CORRESPONDING it_return TO e_return.
    APPEND e_return.
  ENDLOOP.
ENDFUNCTION.
