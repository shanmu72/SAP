* Create Word Document

REPORT YTEST_WORD .

DATA: BEGIN OF ITAB OCCURS 0,
        LINE(255) TYPE C,
      END OF ITAB.

DATA: FILEPATH LIKE RLGRAP-FILENAME VALUE '/usr/sap/trans/tmp/'.
DATA: FILENAME LIKE RLGRAP-FILENAME.

CALL FUNCTION 'WS_UPLOAD'
     EXPORTING
          FILENAME = 'c:\mhpark.rtf'
     TABLES
          DATA_TAB = ITAB.

BREAK-POINT.
LOOP AT ITAB.
  SEARCH ITAB-LINE FOR 'park'.
  IF SY-SUBRC EQ 0.
    BREAK-POINT.
    REPLACE 'park' WITH 'kim' INTO ITAB-LINE.
    MODIFY ITAB.
  ENDIF.
ENDLOOP.

CONCATENATE FILEPATH 'mhpark.doc' INTO FILENAME.


CALL FUNCTION 'Z_UPLOAD_FILE'
     EXPORTING
          FILENAME = FILENAME
     TABLES
          DATA_TAB = ITAB.