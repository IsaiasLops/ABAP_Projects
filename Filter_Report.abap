*&---------------------------------------------------------------------*
*& Nome: ZPR_I_EX_A8III
*& Tipo: Report
*& Objetivo: Filtrar o detalhamento de cada material
*& Data/Hora: Monday, April 17, 2023 (GMT-3) - 02:59
*& Desenvolvedor: Isaias Lopes(Infinity)
*& Request: PD1K900537
*&---------------------------------------------------------------------*
*&                            VERSÕES
*&---------------------------------------------------------------------*
*& Request: ?
*& Motivo/Correção: ?
*& Nome: ?
*&---------------------------------------------------------------------*
REPORT zpr_i_ex_a8iii. " Filtro detalhamento de material fornecido
"Ex.: O Fornecedor A me vende 5 materiais.

* Tabela transparente de referência.
TABLES: ztb_i_fornec2.


TYPES: BEGIN OF ty_material,
         codmat     TYPE ztb_i_material-cod_mat,
         cod_fornec TYPE ztb_i_material-cod_fornec,
         coduni     TYPE ztb_i_material-cod_uni,
         nome       TYPE ztb_i_material-nome,
         descr      TYPE ztb_i_material-descr,
         qtd        TYPE ztb_i_material-qtd_estoq,
         preco      TYPE ztb_i_material-prec_uni,
       END OF  ty_material,

       BEGIN OF  ty_fornec,
         codfornec TYPE ztb_i_fornec2-cod_fornec,
         nome      TYPE ztb_i_fornec2-nome,
         unidade   TYPE ztb_i_fornec2-cidade_sede,
       END OF  ty_fornec,

       BEGIN  OF  ty_output,
         cod_fornec   TYPE ztb_i_material-cod_fornec,
         nome_fornec  TYPE ztb_i_fornec2-nome,
         nome         TYPE ztb_i_material-nome,
         preco        TYPE ztb_i_material-prec_uni,
         qtd          TYPE ztb_i_material-qtd_estoq,
         valor        TYPE kbetr,
       END OF ty_output.


* Declaração de Work Areas
DATA: wa_material TYPE ty_material,
      wa_fornec   TYPE ty_fornec,
      wa_output   TYPE ty_output,
      wa_fieldcat TYPE slis_fieldcat_alv.


* Declaração de Tabelas internas que receberão os dados
DATA: it_material TYPE TABLE OF ty_material,
      it_fornec   TYPE TABLE OF ty_fornec,
      it_output   TYPE TABLE OF ty_output,
      it_fieldcat TYPE slis_t_fieldcat_alv.



* Tela de seleção RANGE
* (para permitir que o usuário insira vários fornecedores)


*&----------------------------------------------------------------------------*
* Interligar as duas tabelas a partir do código do fornecedor indicado na tela.
*&----------------------------------------------------------------------------*

* Crie uma tela de seleção e que no começo dela tenha block (caixa de linha) chamado block
* com um quadro e um titulo que será "Tabela de seleção".
SELECTION-SCREEN  BEGIN OF BLOCK  block WITH FRAME  TITLE TEXT-001.

* Crie um input de intervalo com o nome s_cdf para pesquisa do usuário
  SELECT-OPTIONS  s_cdf FOR ztb_i_fornec2-cod_fornec.

SELECTION-SCREEN  END OF BLOCK  block.


INITIALIZATION.

PERFORM zf_limpar_dados.

START-OF-SELECTION.

PERFORM: zf_seleciona_dados.

PERFORM zf_layout.


   IF it_fornec IS NOT INITIAL.

     PERFORM: zf_processa_dados,
              zf_exibir_dados.

     ELSE.
       WRITE: 'Fornecedor não encontrado'.

   ENDIF.




* Selecionar e trazer dados para as tabelas internas

  "FROM tabela transparente ztb_i_material TO interna it_material

FORM zf_seleciona_dados.
  SELECT  cod_fornec, nome, cidade_sede "Pegue esses campos
  FROM  ztb_i_fornec2                   "Dentro da tabela ztb_i_fornec2
  INTO TABLE  @it_fornec                "Coloque detro da tabela interna @it_fornec
    WHERE cod_fornec IN @s_cdf.         "Onde codigo de fornecedor seja igual ao digitado no select-option @s_cdf

    IF SY-SUBRC = 0.
      SELECT  cod_mat,cod_fornec, cod_uni, nome, descr, qtd_estoq, prec_uni   "Pegue esses campos
        FROM    ztb_i_material                                                "Dentro da tabela ztb_i_material
        INTO  TABLE @it_material                                              "Coloque dentro da tabela interna it_material
        FOR ALL ENTRIES IN @it_fornec                                         "Em que todos os valores dentro da da tabela interna it_fornec
        WHERE cod_fornec EQ @it_fornec-codfornec.                             "TENHAM o codigo do fornecedor igual ao código de fornecedor da tabela interna it_fornec

      ENDIF.

ENDFORM.

FORM zf_processa_dados.

  SORT:  it_material BY  cod_fornec,
         it_fornec   BY  codfornec.

  LOOP AT it_material INTO  wa_material.
       wa_output-nome       = wa_material-nome.
       wa_output-preco      = wa_material-preco.
       wa_output-qtd        = wa_material-qtd.
       wa_output-valor      = wa_material-preco * wa_material-qtd.

 "Leia a tabela it_fornec na linha da WA_FORNEC quando o Cód_Fornec for igual ao Cód_Fornec da WA_MATERIAL
       READ TABLE it_fornec INTO wa_fornec WITH KEY codfornec = wa_material-cod_fornec.

       IF SY-SUBRC = 0.
         wa_output-cod_fornec   = wa_fornec-codfornec.
         wa_output-nome_fornec  = wa_fornec-nome.

       ENDIF.

       APPEND wa_output TO  it_output.

       CLEAR: wa_fornec, wa_output.


  ENDLOOP.

  ENDFORM.


FORM zf_exibir_dados.



  "Criar estrutura do ALV
  CLEAR wa_fieldcat.

  wa_fieldcat-fieldname  = 'cod_fornec'.
  wa_fieldcat-seltext_s  = text-002.
  wa_fieldcat-seltext_m  = text-003.
  wa_fieldcat-seltext_l  = text-004.
  APPEND wa_fieldcat TO it_fieldcat.

  wa_fieldcat-fieldname  = 'nome_fornec'.
  wa_fieldcat-seltext_s  = text-005.
  wa_fieldcat-seltext_m  = text-006.
  wa_fieldcat-seltext_l  = text-007.
  APPEND wa_fieldcat TO it_fieldcat.

  wa_fieldcat-fieldname  = 'nome'.
  wa_fieldcat-seltext_s  = text-008.
  wa_fieldcat-seltext_m  = text-009.
  wa_fieldcat-seltext_l  = text-010.
  APPEND wa_fieldcat TO it_fieldcat.

  wa_fieldcat-fieldname  = 'preco'.
  wa_fieldcat-seltext_s  = text-011.
  wa_fieldcat-seltext_m  = text-012.
  wa_fieldcat-seltext_l  = text-013.
  APPEND wa_fieldcat TO it_fieldcat.

  wa_fieldcat-fieldname  = 'qtd'.
  wa_fieldcat-seltext_s  = text-014.
  wa_fieldcat-seltext_m  = text-015.
  wa_fieldcat-seltext_l  = text-016.
  APPEND wa_fieldcat TO it_fieldcat.

  wa_fieldcat-fieldname  = 'valor'.
  wa_fieldcat-seltext_s  = text-017.
  wa_fieldcat-seltext_m  = text-018.
  wa_fieldcat-seltext_l  = text-019.
  APPEND wa_fieldcat TO it_fieldcat.


  " Função para exibição do ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   EXPORTING
"     IS_LAYOUT                         =
     IT_FIELDCAT                       =  it_fieldcat
  TABLES
      t_outtab                          = it_output.

  IF sy-subrc <> 0.
" Implement suitable error handling here
  ENDIF.

  ENDFORM.



*&---------------------------------------------------------------------*
*& Form zf_limpar_dados
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zf_limpar_dados .

  CLEAR:  wa_fornec, wa_material, wa_output, wa_fieldcat.
  FREE:   it_fornec, it_material, it_output, it_fieldcat.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zf_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zf_layout .



ENDFORM.
