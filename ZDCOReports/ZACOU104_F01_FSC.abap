*----------------------------------------------------------------------*
*  INCLUDE ZACOU104_F01                                                *
*----------------------------------------------------------------------*
*  Subroutines
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       Find data of entered period
*----------------------------------------------------------------------*
FORM get_data.
  DATA locked.
  g_kokrs = p_kokrs.
  g_year = p_year.
  g_kalka = p_kalka.

  PERFORM get_plant.

  REFRESH: gt_ztcou104, gt_out.
  CLEAR  : gt_ztcou104, gt_out.

* Controling area description
  SELECT SINGLE bezei INTO bezei
    FROM tka01
   WHERE kokrs = p_kokrs.

* Get data from table ZTCOU104
  SELECT  a~kokrs
          a~bdatj
          a~kalka
          a~id
          a~zcomat
          a~idtext
          a~zabp_fsc
          a~zbase_fsc
          a~base_year
          a~base_poper
          a~fsc01
          a~fsc02
          a~fsc03
          a~fsc04
          a~fsc05
          a~fsc06
          a~fsc07
          a~fsc08
          a~fsc09
          a~fsc10
          a~fsc11
          a~fsc12
          b~maktg AS idtext
   INTO CORRESPONDING FIELDS OF TABLE gt_ztcou104
    FROM ztcou104 AS a
    INNER JOIN makt AS b
    ON b~matnr EQ a~id
   WHERE a~kokrs = p_kokrs
     AND a~bdatj = p_year
     AND a~kalka = p_kalka
     AND a~id IN s_id.

  DESCRIBE TABLE gt_ztcou104 LINES gv_cnt.
  IF gv_cnt = 0.
    MESSAGE s000 WITH 'No Data found.'.
  ENDIF.

  DATA: BEGIN OF $matnr OCCURS 0,
          matnr  LIKE mvke-matnr,
        END OF $matnr.

  LOOP AT gt_ztcou104.
    MOVE-CORRESPONDING gt_ztcou104 TO gt_out.
    APPEND gt_out.
    CLEAR gt_out.

    $matnr-matnr = gt_ztcou104-id.
    APPEND $matnr.
    $matnr-matnr = gt_ztcou104-zabp_fsc.
    APPEND $matnr.

  ENDLOOP.

  SORT $matnr.
  DELETE ADJACENT DUPLICATES FROM $matnr .

  READ TABLE $matnr INDEX 1.
  IF sy-subrc EQ 0.

    __cls : lt_mvke, lt_a005.

    SELECT a~matnr a~prodh a~mvgr3 a~mvgr4 a~mvgr5 b~werks b~fevor
    c~mtart c~matkl
    INTO TABLE lt_mvke
    FROM mvke AS a
    INNER JOIN marc AS b
    ON b~matnr EQ a~matnr
    INNER JOIN mara AS c
    ON c~matnr EQ b~matnr
    FOR ALL ENTRIES IN $matnr
    WHERE a~matnr EQ $matnr-matnr.

    SELECT matnr kunnr INTO TABLE lt_a005
    FROM a005
    FOR ALL ENTRIES IN $matnr
    WHERE matnr EQ $matnr-matnr.

    DATA $ix LIKE sy-tabix.

    LOOP AT gt_out.

      $ix = sy-tabix.
      READ TABLE lt_mvke WITH KEY matnr = gt_out-id BINARY SEARCH.
      IF sy-subrc EQ 0.
        gt_out-prodh = lt_mvke-prodh.
        gt_out-mvgr3 = lt_mvke-mvgr3.
        gt_out-mvgr4 = lt_mvke-mvgr4.
        gt_out-mvgr5 = lt_mvke-mvgr5.
        gt_out-werks = lt_mvke-werks.
        gt_out-fevor = lt_mvke-fevor.
        gt_out-mtart = lt_mvke-mtart.
        gt_out-matkl = lt_mvke-matkl.
      ENDIF.

      READ TABLE lt_mvke WITH KEY matnr = gt_out-zabp_fsc
      BINARY SEARCH.

      IF sy-subrc EQ 0.
        gt_out-mvgr5abp = lt_mvke-mvgr5.
      ENDIF.

      IF gt_out-fevor NE 'SEA'.
        PERFORM get_code USING gt_out-id
                      CHANGING gt_out-model
                               gt_out-kunnr .
      ENDIF.

      IF gt_out-mtart EQ 'HALB'.
        gt_out-model = gt_out-werks.
      ENDIF.

      IF gt_out-matkl EQ 'A/S'.
        gt_out-kunnr = 'MOBIS'.
      ELSE.

        READ TABLE lt_a005 WITH KEY matnr = gt_out-id
        BINARY SEARCH.
        IF sy-subrc EQ 0.
          gt_out-kunnr = lt_a005-kunnr.
        ENDIF.

      ENDIF.

      CALL FUNCTION 'Z_CHK_LOCK_STATUS_FSC_OVERAL'
           EXPORTING
                kokrs  = gt_out-kokrs
                bdatj  = gt_out-bdatj
                kalka  = gt_out-kalka
                id     = gt_out-id
           IMPORTING
                locked = locked.

*// 2011.09.06    Change by YN.KIM   for (ECC6)
      IF locked EQ true.
        gt_out-lock = true.
*        gt_out-lock_ico = icon_locked.
        gt_out-lock_ico = gc_yellow_icon.
*      else.
*        gt_out-lock_ico = gc_red_icon.
      ENDIF.

      MODIFY gt_out INDEX $ix.

    ENDLOOP.

  ENDIF.


ENDFORM.                    " GET_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_GT_OUT
*&---------------------------------------------------------------------*
*&      Form  EXCLUDE_FUNCTIONS
*&---------------------------------------------------------------------*
*       Exclude function code
*----------------------------------------------------------------------*
FORM exclude_functions USING p_tabname.
  PERFORM append_exclude_functions
          TABLES gt_exclude[]
           USING: cl_gui_alv_grid=>mc_fc_loc_undo,
                  cl_gui_alv_grid=>mc_fc_average,
                  cl_gui_alv_grid=>mc_fc_graph,
                  cl_gui_alv_grid=>mc_fc_info,
                  cl_gui_alv_grid=>mc_fc_refresh.

ENDFORM.                    " EXCLUDE_FUNCTIONS
*&---------------------------------------------------------------------*
*&      Form  CREATE_FIELD_CATEGORY
*&---------------------------------------------------------------------*
*       Create ALV control: Field catalog
*----------------------------------------------------------------------*
FORM create_field_category.


  DATA: l_pos       TYPE i.
  DEFINE __catalog.
    l_pos = l_pos + 1.
    clear gs_fcat.
    gs_fcat-col_pos       = l_pos.
    gs_fcat-key           = &1.
    gs_fcat-fieldname     = &2.
    gs_fcat-coltext       = &3.     " Column heading
    gs_fcat-outputlen     = &4.     " Column width
    gs_fcat-datatype      = &5.     " Data type
    gs_fcat-emphasize     = &6.
    append gs_fcat to gt_fcat.
  END-OF-DEFINITION.

  __catalog :
          'X'  'LOCK_ICO'    'lk'          '4'   'CHAR' '', "ICON' '',
          'X'  'ID'          'ID'          '18'  'CHAR' '',
          ' '  'IDTEXT'      'Description' '25'  'CHAR' '',
          ' '  'ZABP_FSC'    'BP FSC'      '18'  'CHAR' '',
          ' '  'ZBASE_FSC'    'BaseFSC'     '18'  'CHAR' '',
          ' '  'BASE_YEAR'   'BA YR'       '04'  'CHAR' '',
          ' '  'BASE_POPER'  'BA MN'       '03'  'CHAR' ''.

  DATA : $ix(2) TYPE n,
         $text1(10),
         $text2(10).

  DO 12 TIMES.
    $ix = sy-index.
    CONCATENATE 'FSC' $ix INTO $text1.
    IF $ix EQ p_poper.
      CONCATENATE $text1 '*' INTO $text2.
    ELSE.
      $text2 = $text1.
    ENDIF.
    __catalog ' '  $text1        $text2        '18'  'CHAR' ''.

  ENDDO.

  __catalog :
          ' '  'BDATJ'       'BDATJ'       '4'   'CHAR' '',  "NUMC' '',
          ' '  'KALKA'       'KALKA'       '2'   'CHAR' ''.

  LOOP AT gt_fcat INTO gs_fcat.
    CASE gs_fcat-fieldname.
      WHEN 'ID' OR
           'IDTEXT' OR
           'ZABP_FSC'  OR
           'ZBASE_FSC'  OR
           'BASE_YEAR'  OR
           'BASE_POPER' OR
           'BDATJ' OR
           'KALKA'.
        gs_fcat-ref_field = gs_fcat-fieldname.
        gs_fcat-ref_table = 'ZTCOU104'.
        MODIFY gt_fcat FROM gs_fcat.
    ENDCASE.
    IF gs_fcat-fieldname CP 'FSC*'.
      gs_fcat-ref_field = gs_fcat-fieldname.
      gs_fcat-ref_table = 'ZTCOU104'.
      MODIFY gt_fcat FROM gs_fcat.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " CREATE_FIELD_CATEGORY
*&---------------------------------------------------------------------*
*&      Form  SET_EVENT
*&---------------------------------------------------------------------*
*       Setting for event
*----------------------------------------------------------------------*
FORM set_event.
  CREATE OBJECT g_event_receiver.
  SET HANDLER g_event_receiver->handle_data_changed FOR g_grid.
  SET HANDLER g_event_receiver->handle_double_click FOR g_grid.

ENDFORM.                    " SET_EVENT
*&---------------------------------------------------------------------*
*&      Form  BUILD_CELL_ATTR
*&---------------------------------------------------------------------*
*       Create attributes of cell
*----------------------------------------------------------------------*
FORM build_cell_attr.
  DATA: lt_celltab TYPE lvc_t_styl,
        ls_celltab TYPE lvc_s_styl.
  DATA $idx(2) TYPE n.
  DATA locked.
  DATA $ix TYPE i.

  LOOP AT gt_out.
    $ix = sy-tabix.
    __cls lt_celltab.

    ls_celltab-fieldname = 'ID'.
    ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
    INSERT ls_celltab INTO TABLE lt_celltab.

    ls_celltab-fieldname = 'IDTEXT'.
    ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
    INSERT ls_celltab INTO TABLE lt_celltab.

    ls_celltab-fieldname = 'BDATJ'.
    ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
    INSERT ls_celltab INTO TABLE lt_celltab.

    ls_celltab-fieldname = 'KALKA'.
    ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
    INSERT ls_celltab INTO TABLE lt_celltab.

    ls_celltab-fieldname = 'LOCK_ICO'.
    ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
    INSERT ls_celltab INTO TABLE lt_celltab.

    CLEAR *ztcou104.
    SELECT SINGLE * INTO *ztcou104
          FROM ztcou104
    WHERE kokrs EQ gt_out-kokrs
      AND bdatj EQ gt_out-bdatj
      AND kalka EQ gt_out-kalka
      AND id    EQ gt_out-id.

    IF sy-subrc EQ 0.
      CLEAR *ztcou104lock.
      SELECT SINGLE * INTO *ztcou104lock
            FROM ztcou104lock
      WHERE kokrs EQ gt_out-kokrs
        AND bdatj EQ gt_out-bdatj
        AND kalka EQ gt_out-kalka
        AND id    EQ gt_out-id.

      IF sy-subrc EQ 0.

        IF *ztcou104lock-lock00 EQ true AND gt_out-zbase_fsc NE space.
          ls_celltab-fieldname = 'ZBASE_FSC'.
          ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
          INSERT ls_celltab INTO TABLE lt_celltab.
        ENDIF.

        DO 12 TIMES.
          $idx = sy-index.
          CONCATENATE '*ZTCOU104LOCK-LOCK' $idx INTO fname.
          CONCATENATE '*ZTCOU104-FSC' $idx INTO fname2.
          CONCATENATE 'FSC' $idx INTO fname3.
          ASSIGN (fname) TO <from>.
          ASSIGN (fname2) TO <to>.

          IF <from> EQ true AND <to> NE space.
            ls_celltab-fieldname = fname3.
            ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
            INSERT ls_celltab INTO TABLE lt_celltab.
          ENDIF.
        ENDDO.

      ENDIF.
    ENDIF.

    INSERT LINES OF lt_celltab INTO TABLE gt_out-celltab.
    MODIFY gt_out INDEX $ix TRANSPORTING celltab.

  ENDLOOP.
* }

*  CLEAR gs_fcat.
*  LOOP AT gt_fcat INTO gs_fcat.
*    ls_celltab-fieldname = gs_fcat-fieldname.
*
*    IF   ls_celltab-fieldname = 'IDTEXT' OR
*         ls_celltab-fieldname = 'BDATJ' OR
*         ls_celltab-fieldname = 'KALKA' OR
*         ls_celltab-fieldname = 'LOCK_ICO'.
*      ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
*    ELSE.
*      ls_celltab-style = cl_gui_alv_grid=>mc_style_enabled.
*    ENDIF.
*
*    INSERT ls_celltab INTO TABLE lt_celltab.
*  ENDLOOP.
*
*  CLEAR gt_out-celltab.
*  INSERT LINES OF lt_celltab INTO TABLE gt_out-celltab.
*  MODIFY gt_out TRANSPORTING celltab WHERE celltab IS initial
*                                      AND  lock EQ space.
*
*  perform build_cell_attr1_lock.


ENDFORM.                    " BUILD_CELL_ATTR
*&---------------------------------------------------------------------*
*&      Form  CREATE_F4_FIELDS
*&---------------------------------------------------------------------*
*&      Form  SAVE_DATA
*&---------------------------------------------------------------------*
*       Save data to table ZTCOU100
*----------------------------------------------------------------------*
FORM save_data.
  DATA: lt_ztcou104 TYPE TABLE OF ztcou104 WITH HEADER LINE,
        lt_row      TYPE lvc_t_row,
        ls_row      TYPE lvc_s_row,
        lt_roid     TYPE lvc_t_roid,
        lv_cnt(5),
        lv_dcnt(5),
        lv_msg(200).                 " Message

  DATA locked.
* Save seleted data to table ZTCOU104
  CLEAR: lv_cnt, lt_ztcou104, lt_row[], lt_roid[].
  REFRESH lt_ztcou104.

  CALL METHOD g_grid->get_selected_rows
              IMPORTING et_index_rows = lt_row
                        et_row_no = lt_roid.

* LOOP AT lt_row INTO ls_row.
*   READ TABLE gt_out INDEX ls_row-index.
  loop at gt_out.

    IF sy-subrc = 0.
      MOVE-CORRESPONDING gt_out TO lt_ztcou104.
      lt_ztcou104-kokrs = p_kokrs.
      lt_ztcou104-bdatj = p_year.
      lt_ztcou104-kalka = p_kalka.
      lt_ztcou104-aedat = sy-datum.
      lt_ztcou104-aenam = sy-uname.

      SELECT COUNT( * ) INTO sy-dbcnt FROM ztcou103
          WHERE kokrs = p_kokrs
            AND bdatj = p_year
            AND kalka = p_kalka
            AND artnr = lt_ztcou104-id.
      IF sy-subrc <> 0.
        lt_ztcou104-zcomat = 'X'.
      ENDIF.

      APPEND lt_ztcou104.
      CLEAR lt_ztcou104.

      lv_cnt = lv_cnt + 1.
    ENDIF.
  ENDLOOP.

* {
  DATA  : i_ztcou104 LIKE ztcou104 OCCURS 0 WITH HEADER LINE,
          ls_ztcou104 LIKE ztcou104,
          lt_del_rows TYPE TABLE OF ztcou104.

  CALL METHOD g_event_receiver->get_deleted_rows
            IMPORTING deleted_rows = lt_del_rows.


  CLEAR lv_dcnt.
  LOOP AT lt_del_rows INTO ls_ztcou104.
    CALL FUNCTION 'Z_CHK_LOCK_STATUS_FSC_OVERAL'
         EXPORTING
              kokrs  = ls_ztcou104-kokrs
              bdatj  = ls_ztcou104-bdatj
              kalka  = ls_ztcou104-kalka
              id     = ls_ztcou104-id
         IMPORTING
              locked = locked.

    IF sy-subrc EQ 0 AND locked EQ true.
    ELSE.
      DELETE ztcou104 FROM ls_ztcou104.
      IF sy-subrc = 0.
        lv_dcnt = lv_dcnt + 1.
      ENDIF.
    ENDIF.

  ENDLOOP.
* }

*  CLEAR lv_dcnt.
*  LOOP AT gt_ztcou104.
*    READ TABLE gt_out WITH KEY id = gt_ztcou104-id.
*    IF sy-subrc <> 0.
*
*      CALL FUNCTION 'Z_CHK_LOCK_STATUS_FSC_OVERAL'
*           EXPORTING
*                kokrs  = gt_ztcou104-kokrs
*                bdatj  = gt_ztcou104-bdatj
*                kalka  = gt_ztcou104-kalka
*                id     = gt_ztcou104-id
*           IMPORTING
*                locked = locked.
*
*      IF sy-subrc EQ 0 AND locked EQ true.
*      ELSE.
*        DELETE ztcou104 FROM gt_ztcou104.
*        IF sy-subrc = 0.
*          lv_dcnt = lv_dcnt + 1.
*        ENDIF.
*      ENDIF.
*    ENDIF.
*  ENDLOOP.

  DATA $idx(2) TYPE n.
  DATA $ix TYPE i.
  DATA idx TYPE i.

  LOOP AT lt_ztcou104.
    $ix = sy-tabix.

    CLEAR *ztcou104.
    SELECT SINGLE * INTO *ztcou104
          FROM ztcou104
    WHERE kokrs EQ lt_ztcou104-kokrs
      AND bdatj EQ lt_ztcou104-bdatj
      AND kalka EQ lt_ztcou104-kalka
      AND id    EQ lt_ztcou104-id.

    IF sy-subrc EQ 0.

      CLEAR *ztcou104lock.

      SELECT SINGLE * INTO *ztcou104lock
            FROM ztcou104lock
      WHERE kokrs EQ lt_ztcou104-kokrs
        AND bdatj EQ lt_ztcou104-bdatj
        AND kalka EQ lt_ztcou104-kalka
        AND id    EQ lt_ztcou104-id.

      IF sy-subrc EQ 0.
        DO 12 TIMES.
          $idx = sy-index.
          CONCATENATE '*ZTCOU104LOCK-LOCK' $idx INTO fname.
          CONCATENATE '*ZTCOU104-FSC' $idx INTO fname2.
          CONCATENATE 'FSC' $idx INTO fname3.
          ASSIGN (fname) TO <from>.
          ASSIGN (fname2) TO <to>.
          IF <from> EQ true AND <to> NE space. " locked
            CONCATENATE 'LT_ZTCOU104-FSC' $idx INTO fname.
            ASSIGN (fname) TO <from>.
            IF <from> NE <to>.
              <from> = <to>.
              MODIFY lt_ztcou104 INDEX $ix TRANSPORTING (fname3).
            ENDIF.
          ENDIF.
        ENDDO.
      ENDIF.
    ELSE.
    ENDIF.
  ENDLOOP.

  MODIFY ztcou104 FROM TABLE lt_ztcou104.

  IF sy-subrc = 0.
    IF lv_dcnt > 0.
      CONCATENATE 'have deleted' lv_dcnt  'records,'
                  'saved' lv_cnt 'records.'
             INTO lv_msg SEPARATED BY space.
    ELSE.
      CONCATENATE 'You have saved data completely;'
                   lv_cnt  'records.'
             INTO lv_msg SEPARATED BY space.
    ENDIF.
  ELSE.
    IF lv_dcnt > 0.
     CONCATENATE 'You have deleted data completely' lv_dcnt  'records.'
                                         INTO lv_msg SEPARATED BY space.
    ENDIF.
  ENDIF.

  MESSAGE s000 WITH lv_msg.

ENDFORM.                    " SAVE_DATA
*&---------------------------------------------------------------------*
*&      Form  DELETE_DATA
*&---------------------------------------------------------------------*
*       Delete Data
*----------------------------------------------------------------------*
FORM delete_data.
  DATA: lv_cnt(5),
        lv_index TYPE sytabix,
        lt_row   TYPE lvc_t_row,
        ls_row   TYPE lvc_s_row,
        lt_roid  TYPE lvc_t_roid.

  CLEAR: lv_cnt, lv_index, lt_row[], lt_roid[].

* Delete selected data of table ZTCOU100
  CALL METHOD g_grid->get_selected_rows
              IMPORTING et_index_rows = lt_row
                        et_row_no = lt_roid.

  LOOP AT lt_row INTO ls_row.
    READ TABLE gt_out INDEX ls_row-index.

    IF sy-subrc = 0.
      DELETE FROM ztcou104
       WHERE kokrs = gt_out-kokrs
         AND bdatj = gt_out-bdatj
         AND id = gt_out-id.

      IF sy-subrc = 0.
        gt_out-chk = 'X'.
        MODIFY gt_out INDEX ls_row-index TRANSPORTING chk.

        lv_cnt = lv_cnt + 1.
      ENDIF.
    ENDIF.
  ENDLOOP.

  DELETE gt_out WHERE chk = 'X'.

  IF lv_cnt > 0.
    MESSAGE s000 WITH 'You have deleted' lv_cnt 'records.'.
    PERFORM refresh_field.
  ENDIF.

ENDFORM.                    " DELETE_DATA
*&---------------------------------------------------------------------*
*&      Form  SET_LVC_LAYOUT
*&---------------------------------------------------------------------*
*       Setting for layout
*----------------------------------------------------------------------*
FORM set_lvc_layout.

  CLEAR gs_layo.
  gs_layo-edit       = 'X'.
  gs_layo-zebra      = 'X'.
  gs_layo-sel_mode   = 'A'.       " Column and row selection
  gs_layo-cwidth_opt = 'X'.
  gs_layo-ctab_fname = 'TABCOLOR'.
  gs_layo-stylefname = 'CELLTAB'.

ENDFORM.                    " SET_LVC_LAYOUT
*&---------------------------------------------------------------------*
*&      Form  DOUBLE_CLICK
*&---------------------------------------------------------------------*
*       move the detail screen when double click
*----------------------------------------------------------------------*
FORM double_click USING  e_row  TYPE  lvc_s_row
                         e_column TYPE  lvc_s_col
                         es_row_no  TYPE  lvc_s_roid.

  CLEAR gv_index.
  gv_index = e_row-index.

  READ TABLE gt_out INDEX gv_index.
  IF sy-subrc = 0.

* UD1K941666 - by IG.MOON 9/24/2007 {
    CLEAR *ztcou104.
    MOVE-CORRESPONDING gt_out TO *ztcou104.
* }
    CALL SCREEN 200 STARTING AT 20 5 ENDING AT 76 25.
  ENDIF.

ENDFORM.                    " DOUBLE_CLICK
*&---------------------------------------------------------------------*
*&      Form  CREATE_ALV_CONTROL
*&---------------------------------------------------------------------*
FORM create_alv_control.
  IF g_custom_container IS INITIAL.
*   Create object
    PERFORM create_object.

*   Exclude toolbar
    PERFORM exclude_functions USING 'GT_EXCLUDE'.

*   Create field category
    PERFORM create_field_category.

*   Setting for layout
    PERFORM set_lvc_layout.

*   Set colors
    PERFORM set_color.

*   Define editable field
    CALL METHOD g_grid->set_ready_for_input
      EXPORTING
        i_ready_for_input = 1.

    CALL METHOD g_grid->register_edit_event
         EXPORTING i_event_id = cl_gui_alv_grid=>mc_evt_modified.

*   Setting for event
    PERFORM set_event.

*   Define cell attribute
    PERFORM build_cell_attr.

*   Define variant
    gs_variant-report = sy-repid.

*   Display alv grid
    CALL METHOD g_grid->set_table_for_first_display
         EXPORTING is_layout            = gs_layo
                   it_toolbar_excluding = gt_exclude
                   i_save               = gc_var_save
                   is_variant           = gs_variant
         CHANGING  it_outtab            = gt_out[]
                   it_fieldcatalog      = gt_fcat[].

  ENDIF.

ENDFORM.                    " CREATE_ALV_CONTROL
