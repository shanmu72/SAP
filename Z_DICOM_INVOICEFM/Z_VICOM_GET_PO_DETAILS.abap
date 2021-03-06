FUNCTION Z_VICOM_GET_PO_DETAILS.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             VALUE(PONUMBER) TYPE  CHAR10
*"       EXPORTING
*"             VALUE(VENDOR) TYPE  CHAR10
*"             VALUE(SUPPL_VEND) TYPE  CHAR10
*"             VALUE(DOC_DATE) TYPE  CHAR8
*"             VALUE(CURRENCY) TYPE  CHAR5
*"             VALUE(STATUS) TYPE  CHAR1
*"       TABLES
*"              PO_LINEITEMS STRUCTURE  ZPO_LINEINFO OPTIONAL
*"       EXCEPTIONS
*"              PO_NOT_FOUND
*"----------------------------------------------------------------------

DATA  : TBL_ITEMS TYPE BAPIEKPO OCCURS 1 WITH HEADER LINE,
        TBL_HEADER TYPE BAPIEKKOL OCCURS 1 WITH HEADER LINE.

CALL FUNCTION 'BAPI_PO_GETDETAIL'
  EXPORTING
    PURCHASEORDER                    = PONUMBER
 IMPORTING
   PO_HEADER                        = TBL_HEADER
 TABLES
   PO_ITEMS                         = TBL_ITEMS.

  MOVE TBL_HEADER-VENDOR TO VENDOR.
  MOVE TBL_HEADER-SUPPL_VEND TO SUPPL_VEND.
  MOVE TBL_HEADER-DOC_DATE TO DOC_DATE.
  MOVE TBL_HEADER-CURRENCY TO CURRENCY.
  MOVE TBL_HEADER-STATUS TO STATUS.

  CLEAR PO_LINEITEMS.
  LOOP AT TBL_ITEMS.
    PO_LINEITEMS-PO_ITEM = TBL_ITEMS-PO_ITEM.
    PO_LINEITEMS-QUANTITY = TBL_ITEMS-QUANTITY.
    PO_LINEITEMS-MATERIAL = TBL_ITEMS-MATERIAL.
    PO_LINEITEMS-SHORT_TEXT = TBL_ITEMS-SHORT_TEXT.
    PO_LINEITEMS-NET_PRICE = TBL_ITEMS-NET_PRICE.
    APPEND PO_LINEITEMS.
  ENDLOOP.

  IF SY-SUBRC NE 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
        WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    RAISE PO_NOT_FOUND.
  ENDIF.

ENDFUNCTION.
