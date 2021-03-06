*&---------------------------------------------------------------------*
*&  Include           ZRFIT14N_T01
*&---------------------------------------------------------------------*

**********************************************************************
* Data Declaration
**********************************************************************
tables : t052, konp, knb1.

**********************************************************************
* TYPES
**********************************************************************
TYPES : BEGIN OF t_data,
          gubun(1),
          kunnr TYPE kunnr,
          matnr TYPE matnr,
          sqdt  TYPE zsqdt,
          plnmg TYPE plnmg,
        END OF t_data.

TYPES : BEGIN OF t_list,
          gubun(1),
          sqdt  TYPE zsqdt,
          paydt TYPE datum,
          matnr TYPE matnr,
          kunnr TYPE kunnr,
          fdgrv TYPE FDGRV,
          zterm TYPE dzterm,
          plnmg TYPE plnmg,
          dmshb TYPE DMSHW,
        END OF t_list.

data: it_dele like fdes        occurs 0 with header line.
data: wk_dele like fdes        occurs 0 with header line,
      wk_fdes like fdes_import occurs 0 with header line.

data: v_vrkme like vbep-vrkme,  "unit
      v_last_date like sy-datum.

DATA : gt_data TYPE TABLE OF t_data.
DATA : gt_list TYPE TABLE OF t_list.

constants : c_sptype(2) value 'SP'. "memo record planning type

* USING ALV REPORTING..
type-pools : slis.

include rvreuse_global_data.
include rvreuse_local_data.
include rvreuse_forms.

data : gs_layout    type slis_layout_alv,
       gt_fieldcat  type slis_t_fieldcat_alv,
       gs_fieldcat  type slis_fieldcat_alv,  " ?? ??? ??.
       gt_events    type slis_t_event,
       it_sort      type slis_t_sortinfo_alv,
       g_save(1)    type c,
       g_exit(1)    type c,
       gx_variant   like disvariant,
       g_variant    like disvariant,
       g_repid      like sy-repid,
       g_cnt(2)     type n.

constants : c_status_set   type slis_formname
                           value 'PF_STATUS_SET',
            c_user_command type slis_formname
                           value 'USER_COMMAND',
            c_top_of_page  type slis_formname value 'TOP_OF_PAGE',
            c_top_of_list  type slis_formname value 'TOP_OF_LIST',
            c_end_of_list  type slis_formname value 'END_OF_LIST'.

constants : gc_x   type c   value 'X'.

**********************************************************************
*  SELECTION-SCREEN
**********************************************************************
selection-screen begin of block b1 with frame title text-001.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) text-h01.
PARAMETERS: p_bukrs  LIKE t001-bukrs   OBLIGATORY  MEMORY ID buk
                                       default 'H201'.
SELECTION-SCREEN COMMENT 52(40) p_butxt.
SELECTION-SCREEN END OF LINE.

parameters : p_edatu TYPE datum obligatory default sy-datum.

selection-screen skip 1.
parameters : p_test  as checkbox default 'X'.
selection-screen end of block b1.

*selection-screen begin of block b2 with frame title text-002.
*select-options: s_vbeln   for vbap-vbeln.
*selection-screen end of block b2.
*
*selection-screen begin of block b3 with frame title text-003.
*selection-screen begin of line.
*parameters : p_start radiobutton group rd.
*selection-screen comment 05(33) text-004.
*parameters : p_end   radiobutton group rd default 'X'.
*selection-screen comment 45(30) text-005.
*selection-screen end of line.
*selection-screen end of block b3.

**********************************************************************
