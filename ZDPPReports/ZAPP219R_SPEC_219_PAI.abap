*----------------------------------------------------------------------*
***INCLUDE ZAPP219R_SPEC_219_PAI .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  exit_300  INPUT
*&---------------------------------------------------------------------*
*       Exit Command
*----------------------------------------------------------------------*
MODULE exit_300 INPUT.
  IF sy-ucomm = 'BACK' OR sy-ucomm = 'EXIT'.
    leave to screen 0.
  ENDIF.

ENDMODULE.                 " exit_300  INPUT
