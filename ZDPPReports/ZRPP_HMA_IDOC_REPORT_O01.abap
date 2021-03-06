*----------------------------------------------------------------------*
*   INCLUDE ZRPP_HMA_ZPODER_O01                                        *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0100 OUTPUT.
  DATA: UCOMM TYPE TABLE OF SY-UCOMM,
        TMP_MAKTX LIKE MAKT-MAKTX.

  DATA : LV_TITLE(40), LV_LINE TYPE I.

  LV_TITLE = S_DATUM-LOW .

  IF NOT S_DATUM-HIGH IS INITIAL.
  CONCATENATE S_DATUM-LOW S_DATUM-HIGH INTO LV_TITLE
  SEPARATED BY SPACE.
  ENDIF.
*
 DESCRIBE TABLE <INTAB> LINES LV_LINE.


  REFRESH UCOMM.
  SET PF-STATUS 'S100' EXCLUDING UCOMM.
  SET TITLEBAR  'T100' WITH LV_TITLE LV_LINE.

ENDMODULE.                 " STATUS_0100  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  CREATE_OBJECT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CREATE_OBJECT OUTPUT.
  PERFORM P1000_CREATE_OBJECT.
ENDMODULE.                 " CREATE_OBJECT  OUTPUT
