*----------------------------------------------------------------------*
***INCLUDE ZXM06O01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  pbo  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo OUTPUT.
  PERFORM modify_screen USING sy-dynnr.   " Modify screen
ENDMODULE.                 " pbo  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0101  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0101 OUTPUT.
  perform modify_screen_0101 using sy-dynnr.                "UD1K922802
ENDMODULE.                 " STATUS_0101  OUTPUT
