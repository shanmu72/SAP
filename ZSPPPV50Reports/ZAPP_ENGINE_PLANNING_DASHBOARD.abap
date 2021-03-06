************************************************************************
* Program Name      : ZAPP_ENGINE_PLANNING_DASHBOARD
* Author            : Furong Wang
* Creation Date     : 10/15/2009
* Specifications By :
* Development Request No :
* Addl Documentation:
* Description       :
* Modification Logs
* Date       Developer    RequestNo    Description
*
*********************************************************************

REPORT ZAPP_ENGINE_PLANNING_DASHBOARD NO STANDARD PAGE HEADING
                     LINE-SIZE 132
                     LINE-COUNT 64(1)
                     MESSAGE-ID ZMPP.

DATA: IT_DATA LIKE TABLE OF ZTPP_ENG_DB WITH HEADER LINE.

SELECTION-SCREEN BEGIN OF BLOCK B1 WITH FRAME TITLE TEXT-001.
PARAMETERS: P_VBELN LIKE JITMA-VBELN OBLIGATORY.
*            P_DATUM LIKE SY-DATUM DEFAULT SY-DATUM.
SELECTION-SCREEN END OF BLOCK B1.

SELECT MATNR ETENR  EDATU ABART PRGRS WMENG
   INTO CORRESPONDING FIELDS OF TABLE IT_DATA
   FROM VBAP AS A
   INNER JOIN VBEP AS B
   ON A~VBELN = B~VBELN
   AND A~POSNR = B~POSNR
   WHERE A~VBELN = P_VBELN
*    AND EDATU >= P_DATUM
    AND ( ABART = '1' OR ABART = '2' ).

LOOP AT IT_DATA.
  IT_DATA-CRDATE = SY-DATUM.
  IT_DATA-SA_VBELN = P_VBELN.
  MODIFY IT_DATA.
ENDLOOP.
DELETE FROM ZTPP_ENG_DB WHERE SA_VBELN = P_VBELN AND CRDATE = SY-DATUM.
*MODIFY ZTPP_ENG_DB FROM TABLE IT_DATA.
INSERT ZTPP_ENG_DB FROM TABLE IT_DATA.
IF SY-SUBRC = 0.
  COMMIT WORK.
  MESSAGE S000 WITH 'Table Updated Sucessfully'.
ELSE.
  ROLLBACK WORK.
  MESSAGE E000 WITH 'DATABASE TABLE UPDATE ERROR'.
ENDIF.
