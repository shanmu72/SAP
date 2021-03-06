*----------------------------------------------------------------------*
*   INCLUDE ZMMR10000C_I01                                             *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE EXIT_COMMAND INPUT.
  PERFORM free_all_object.
  LEAVE TO SCREEN 0.
ENDMODULE.                 " EXIT_COMMAND  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND INPUT.
  sv_code  = ok_code.
  CLEAR ok_code.
  PERFORM user_command USING sv_code .
ENDMODULE.                 " USER_COMMAND  INPUT
