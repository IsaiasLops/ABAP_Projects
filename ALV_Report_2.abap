*&---------------------------------------------------------------------*
*& Nome: ZBKO_P_JOB_STATUS_XML_PLK
*& Tipo: Report
*& Objetivo: Relatório de Movimentação de Material
*& Data/Hora: Thursday, July 8, 2021 (GMT-3) - 02:59
*& Desenvolvedor: Isaias Lopes(Infinit)
*& Request: PD1K900537
*&---------------------------------------------------------------------*
*&                            VERSÕES
*&---------------------------------------------------------------------*
*& Request: ?
*& Motivo/Correção: ?
*& Nome: ?
*&---------------------------------------------------------------------*
REPORT zpr_i_alvii.

TABLES: mkpf,
        mseg.

* Montar a estrutura do tipo
TYPES: BEGIN OF ty_mkpf,
         mblnr TYPE mkpf-mblnr,
         mjahr TYPE mkpf-mjahr,
         bldat TYPE mkpf-bldat,
       END OF ty_mkpf,

       BEGIN OF ty_mseg,
         mblnr TYPE mseg-mblnr,
         mjahr TYPE mseg-mjahr,
         zeile TYPE mseg-zeile,
         bwart TYPE mseg-bwart,
         matnr TYPE mseg-matnr,
         werks TYPE mseg-werks,
         lgort TYPE mseg-lgort,
         dmbtr TYPE mseg-dmbtr,
         menge TYPE mseg-menge,
         meins TYPE mseg-meins,
       END OF ty_mseg,

       BEGIN OF ty_makt,
         matnr TYPE makt-matnr,
         maktx TYPE makt-maktx,
       END OF ty_makt,

       BEGIN OF ty_t001w,
         werks TYPE t001w-werks,
         name1 TYPE t001w-name1,
       END OF ty_t001w,

       BEGIN OF ty_t001l,
         werks TYPE t001l-werks,
         lgort TYPE t001l-lgort,
         lgobe TYPE t001l-lgobe,
       END OF ty_t001l,

       BEGIN OF ty_output,
         mk_mblnr TYPE mkpf-mblnr,
         mk_mjahr TYPE mkpf-mjahr,
         mk_bldat TYPE mkpf-bldat,
         ms_zeile TYPE mseg-zeile,
         ms_bwart TYPE mseg-bwart,
         ms_dmbtr TYPE mseg-dmbtr,
         ms_menge TYPE mseg-menge,
         ms_meins TYPE mseg-meins,
         matnr_maktx(80) TYPE c,
         werks_name1(34) TYPE c,
         lgort_lgobe(20) TYPE c,
         valor_unit  TYPE mseg-dmbtr,
        END OF ty_output.



* Criar tabela interna
DATA: it_mkpf   TYPE TABLE OF ty_mkpf,
      it_mseg   TYPE TABLE OF ty_mseg,
      it_makt   TYPE TABLE OF ty_makt,
      it_t001w  TYPE TABLE OF ty_t001w,
      it_t001l  TYPE TABLE OF ty_t001l,
      it_output TYPE TABLE OF ty_output.

* Criar Work Area
DATA: wa_mkpf   TYPE ty_mkpf,
      wa_mseg   TYPE ty_mseg,
      wa_makt   TYPE ty_makt,
      wa_t001w  TYPE ty_t001w,
      wa_t001l  TYPE ty_t001l,
      wa_output TYPE ty_output.


* Criar CONSTANTE do tipo mkpf-blart com valor de 'WL'
CONSTANTS c_blart TYPE mkpf-blart VALUE 'WL'.




SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  SELECT-OPTIONS: s_mblnr FOR mkpf-mblnr,
                  s_bwart FOR mseg-bwart.

  PARAMETERS  p_mjahr TYPE mkpf-mjahr DEFAULT '2023'.


SELECTION-SCREEN END OF BLOCK b1.




PERFORM zf_data_select.

PERFORM zf_data_process.



* Selecionar dados

FORM zf_data_select.

  SELECT mblnr, mjahr, bldat
    FROM mkpf
    WHERE mblnr IN @s_mblnr
      AND mjahr EQ @p_mjahr
      AND blart EQ @c_blart
      INTO TABLE @it_mkpf.

  IF sy-subrc IS INITIAL.
    SELECT mblnr, mjahr, zeile, bwart, matnr, werks, lgort, dmbtr, menge, meins
      FROM mseg
      FOR ALL ENTRIES IN @it_mkpf
      WHERE mblnr EQ @it_mkpf-mblnr
        AND mjahr EQ @it_mkpf-mjahr
        AND bwart IN @s_bwart
      INTO TABLE @it_mseg.

    IF sy-subrc IS INITIAL.
      SELECT matnr, maktx
        FROM makt
        FOR ALL ENTRIES IN @it_mseg
        WHERE matnr EQ @it_mseg-matnr
          AND spras EQ @sy-langu
        INTO TABLE @it_makt.

      IF sy-subrc  IS NOT INITIAL.
        FREE it_makt.
      ENDIF.

      SELECT werks, name1
        FROM t001w
        FOR ALL ENTRIES IN @it_mseg
        WHERE werks EQ @it_mseg-werks
        INTO TABLE @it_t001w.

      IF sy-subrc  IS NOT INITIAL.
        FREE it_t001w.
      ENDIF.

      SELECT werks, lgort, lgobe
        FROM t001l
        FOR ALL ENTRIES IN @it_mseg
        WHERE werks EQ @it_mseg-werks
          AND lgort EQ @it_mseg-lgort
        INTO TABLE @it_t001l.

      IF sy-subrc  IS NOT INITIAL.
        FREE it_t001l.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.


FORM zf_data_process.

  SORT: it_mkpf  BY mblnr mjahr,
        it_mseg  BY mblnr mjahr werks lgort,
        it_t001w BY werks,
        it_t001l BY lgort.

  LOOP AT it_mseg INTO wa_mseg.

    READ TABLE it_mkpf INTO wa_mkpf
      WITH KEY mblnr = wa_mseg-mblnr
               mjahr = wa_mseg-mjahr
      BINARY SEARCH.

    IF sy-subrc NE 0.
      CONTINUE.
    ENDIF.

    READ TABLE it_makt INTO wa_makt
      WITH KEY matnr = wa_mseg-matnr
      BINARY SEARCH.

    IF sy-subrc NE 0.
      CONTINUE.
    ENDIF.

    READ TABLE it_t001w INTO wa_t001w
      WITH KEY werks = wa_mseg-werks
      BINARY SEARCH.

    READ TABLE it_t001l INTO wa_t001l
      WITH KEY werks = wa_mseg-werks
               lgort = wa_mseg-lgort
      BINARY SEARCH.


wa_output-mk_mblnr = wa_mkpf-mblnr.
wa_output-mk_mjahr = wa_mkpf-mjahr.
wa_output-mk_bldat = wa_mkpf-bldat.
wa_output-ms_zeile = wa_mseg-zeile.
wa_output-ms_bwart = wa_mseg-bwart.
wa_output-ms_menge = wa_mseg-menge.
wa_output-ms_meins = wa_mseg-meins.
wa_output-ms_dmbtr = wa_mseg-dmbtr.
wa_output-valor_unit = wa_output-ms_dmbtr / wa_output-ms_menge.


CONCATENATE wa_mseg-matnr wa_makt-maktx
  INTO wa_output-matnr_maktx
  SEPARATED BY '-'.

CONCATENATE wa_mseg-werks wa_t001w-name1
  INTO wa_output-werks_name1
  SEPARATED BY '-'.

CONCATENATE wa_mseg-lgort wa_t001l-lgobe
  INTO wa_output-lgort_lgobe
  SEPARATED BY '-'.

APPEND: wa_output TO it_output.


  ENDLOOP.

ENDFORM.
