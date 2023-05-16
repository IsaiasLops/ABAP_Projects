*&---------------------------------------------------------------------*
*& Nome: ZPR_I_ALVI
*& Tipo: Report
*& Objetivo:  Relatório de Movimentação de Material
*& Data/Hora: Thursday, July 8, 2021 (GMT-3) - 02:59
*& Desenvolvedor: Isaias Lopes(Burger King)
*& Request: PD1K900537
*&---------------------------------------------------------------------*
*&                            VERSÕES
*&---------------------------------------------------------------------*
*& Request: ?
*& Motivo/Correção: ?
*& Nome: ?
*&---------------------------------------------------------------------*
REPORT zpr_i_alvi.

TABLES: mkpf,
        mseg.

* Herdar tipos dos campos
TYPES: BEGIN OF ty_mkpf,
         mblnr TYPE  mkpf-mblnr,
         mjahr TYPE  mkpf-mjahr,
         bldat TYPE  mkpf-bldat,
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
         mk_mblnr          TYPE mkpf-mblnr,
         mk_mjahr          TYPE mkpf-mjahr,
         mk_bldat          TYPE mkpf-bldat,
         ms_zeile          TYPE mseg-zeile,
         ms_bwart          TYPE mseg-bwart,
         ms_matnr          TYPE mseg-matnr,
         ms_makt           TYPE makt-maktx,
         ms_werks          TYPE mseg-werks,
         lw_name1          TYPE t001w-name1,
         ms_lgort          TYPE mseg-lgort,
         l1_lgobe          TYPE t001l-lgobe,
         ms_menge          TYPE mseg-menge,
         ms_meins          TYPE mseg-meins,
         ms_valor_unitario TYPE mseg-dmbtr,
         ms_dumbtr         TYPE mseg-dmbtr,
         matnr_maktx(40)   TYPE c,
       END OF ty_output.




* Declaração de Work Areas
DATA: wa_mkpf   TYPE ty_mkpf,
      wa_mseg   TYPE ty_mseg,
      wa_makt   TYPE ty_makt,
      wa_t001w  TYPE ty_t001w,
      wa_t001l  TYPE ty_t001l,
      wa_output TYPE ty_output.


* Declaração das Tabelas internas
DATA: it_mkpf   TYPE TABLE OF ty_mkpf,
      it_mseg   TYPE TABLE OF ty_mseg,
      it_makt   TYPE TABLE OF ty_makt,
      it_t001w  TYPE TABLE OF ty_t001w,
      it_t001l  TYPE TABLE OF ty_t001l,
      it_output TYPE TABLE OF ty_output.




* Tela de seleção
SELECTION-SCREEN  BEGIN OF BLOCK  block WITH FRAME  TITLE TEXT-001.

  SELECT-OPTIONS: s_mblnr FOR mkpf-mblnr,
                  s_bwart FOR mseg-bwart.


  " Declaração do PARAMETER P_MJAHR
  PARAMETERS  p_mjahr TYPE  mkpf-mjahr.

SELECTION-SCREEN  END OF BLOCK  block.


INITIALIZATION.

*  PERFORM zf_data_clear.

START-OF-SELECTION.

  PERFORM zf_data_select.

  PERFORM zf_data_process.

*  PERFORM zf_data_print.



* Selecionar e trazer dados para as tabelas internas

FORM zf_data_select.

  SELECT mblnr, mjahr, bldat
    FROM mkpf
    INTO TABLE @it_mkpf
    WHERE mblnr IN @s_mblnr
      AND mjahr EQ @p_mjahr
      AND blart EQ 'WL'.

  IF sy-subrc  IS INITIAL.

    SELECT mblnr, mjahr, zeile, bwart, matnr, werks, lgort, dmbtr, menge, meins
      FROM mseg
      INTO TABLE @it_mseg
      FOR ALL ENTRIES IN  @it_mkpf
      WHERE bwart IN @s_bwart
        AND mblnr EQ @it_mkpf-mblnr
        AND mjahr EQ @it_mkpf-mjahr.

    IF sy-subrc  IS INITIAL.

      SELECT  matnr, maktx
         FROM  makt
         INTO TABLE  @it_makt
         FOR ALL ENTRIES IN  @it_mseg
         WHERE matnr EQ @it_mseg-matnr
         AND spras EQ @sy-langu.

      IF sy-subrc  IS NOT INITIAL.
        FREE it_makt.
      ENDIF.


      SELECT werks, name1
        FROM t001w
        INTO TABLE @it_t001w
        FOR ALL ENTRIES IN  @it_mseg
        WHERE werks EQ @it_mseg-werks.

      IF sy-subrc  IS NOT INITIAL.
        FREE it_t001w.
      ENDIF.

      SELECT werks, lgort, lgobe
        FROM t001l
        INTO TABLE @it_t001l
        FOR ALL ENTRIES IN @it_mseg
        WHERE werks EQ @it_mseg-werks
         AND  lgort EQ @it_mseg-lgort.

      IF sy-subrc  IS NOT INITIAL.
        FREE it_t001l.

      ENDIF.

    ENDIF.

  ENDIF.

ENDFORM.

FORM zf_data_process.

* SORT nos campos chaves da tabela.
  SORT: it_mkpf  BY mblnr mjahr,
        it_makt  BY matnr,
        it_t001w BY werks,
        it_t001l BY werks lgort.


* Leia toda a minha tabela it_mseg
  LOOP AT it_mseg INTO wa_mseg.

    READ TABLE it_mkpf INTO wa_mkpf
      WITH KEY mblnr = wa_mseg-mblnr "Único lugar que o sinal de igual é uma comparação.
               mjahr = wa_mseg-mjahr
      BINARY SEARCH.

IF SY-SUBRC IS NOT INITIAL.
  CONTINUE.
ENDIF.

    READ TABLE it_makt INTO wa_makt
      WITH KEY matnr = wa_mseg-matnr
      BINARY SEARCH.

    IF SY-SUBRC IS NOT INITIAL.
      CONTINUE.
    ENDIF.


    READ TABLE it_t001w INTO wa_t001w
      WITH KEY werks = wa_mseg-werks
      BINARY SEARCH.

     IF SY-SUBRC IS NOT INITIAL.
       CLEAR wa_t001w.
     ENDIF.

    READ TABLE it_t001l INTO wa_t001l
      WITH KEY werks = wa_mseg-werks
               lgort = wa_mseg-lgort
               BINARY SEARCH.


  wa_output-mk_mblnr = wa_mkpf-mblnr.
  wa_output-ms_bwart = wa_mseg-bwart.

  APPEND wa_output  TO  it_output.

*    wa_output-zeile  =  wa_mseg-zeile.
*    wa_output-bwart  =  wa_mseg-bwart.
*    wa_output-matnr  =  wa_mseg-matnr.
*    wa_output-werks  =  wa_mseg-werks.
*    wa_output-lgort  =  wa_mseg-lgort.
*    wa_output-menge  =  wa_mseg-menge.
*    wa_output-meins  =  wa_mseg-meins.
*    wa_output-dumbtr =  wa_mseg-dmbtr.
*    wa_output-valor_unitario = wa_output-dumbtr / wa_output-menge.


*    CONCATENATE wa_mseg-matnr wa_makt-maktx INTO wa_output-matnr_maktx
*    SEPARATED BY '-'.
*
*
*
*    wa_output-werks = wa_t001w-werks.
*    wa_output-werks = wa_t001l-werks.
*    wa_output-lgort = wa_t001l-lgort.


ENDLOOP.

ENDFORM.


*
*FORM zf_data_print.
*
*  WRITE wa_output-bwart.
*  WRITE wa_output-bldat.
*
*ENDFORM.
*



*FORM zf_data_clear.
*
*  CLEAR:  wa_mkpf.
*  FREE:   it_mkpf.
*
*ENDFORM.
