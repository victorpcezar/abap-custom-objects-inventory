
********************************************************************************
* Empresa         : xxxxxxxxxxxxxxxxxxxxxxxxxxx                                *
* Cliente         : xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                           *
* Modulo          : xxxxxxxxxxxx                                               *
* Titulo          : Relatório de desenvolvimentos                              *
* Programa        : ZOBJETOSCUSTOM                                             *
* Transação       : XXXXXXXXX                                                  *
* Tipo Programa   : Report ALV                                                 *
* Funcional       : XXXXXXXXXXXXXXX                                            *
* Desenvolvedor   : Victor                                                     *
* Data Criação    : 14/09/2026                                                 *
*------------------------------------------------------------------------------*
* Ult Modif       Autor                  Chamado          Descrição            *
* ===========     ==============         ===========      =========            *
* xxxxxxxxxx      xxxxxxxxxxxxxx         XXXXXXXXXX       Codificação inicial  *
********************************************************************************
REPORT zobjetoscustom.
*------------------------------------------------------------------------------*
* Tabelas                                                                      *
*------------------------------------------------------------------------------*
TABLES: tadir.
*------------------------------------------------------------------------------*
* Types                                                                        *
*------------------------------------------------------------------------------*
TYPES:
  BEGIN OF y_saida,
    pgmid     TYPE tadir-pgmid,
    object    TYPE tadir-object,
    obj_name  TYPE tadir-obj_name,
    author    TYPE tadir-author,
    srcsystem TYPE tadir-srcsystem,
  END OF y_saida.
*------------------------------------------------------------------------------*
* Tabelas Internas                                                             *
*------------------------------------------------------------------------------*
DATA: lt_saida TYPE TABLE OF y_saida.
*------------------------------------------------------------------------------*
* Type-Pools                                                                   *
*------------------------------------------------------------------------------*
TYPE-POOLS: slis.
*------------------------------------------------------------------------------*
* DATA - Variáveis                                                             *
*------------------------------------------------------------------------------*
DATA: t_fieldcat TYPE TABLE OF slis_fieldcat_alv,           " Colunas exibidas na ALV
      s_fieldcat TYPE slis_fieldcat_alv,                    " Colunas exibidas na ALV
      s_layout   TYPE slis_layout_alv.                      " Configura layout do ALV
*------------------------------------------------------------------------------*
* Selection Screen                                                             *
*------------------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS: s_object FOR tadir-object NO INTERVALS,
                s_author FOR tadir-author NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.
*------------------------------------------------------------------------------*
* Execução dos Formulários                                                     *
*------------------------------------------------------------------------------*
  PERFORM zf_seleciona_dados.
  PERFORM zf_monta_fieldcat.
  PERFORM zf_exibe_alv.

FORM zf_seleciona_dados .
  SELECT pgmid object obj_name author srcsystem
  FROM tadir
  INTO TABLE lt_saida
  WHERE pgmid = 'R3TR' AND ( obj_name LIKE 'Z%' OR obj_name LIKE 'Y%' )
    AND object IN s_object
  AND author IN s_author.
  IF lt_saida IS INITIAL.
    MESSAGE 'Nenhum registro encontrado' TYPE 'S' DISPLAY LIKE 'W'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.

FORM zf_monta_fieldcat .

  REFRESH t_fieldcat.
  PERFORM zf_adiciona_coluna USING 'PGMID'     'Programa ID'.
  PERFORM zf_adiciona_coluna USING 'OBJECT'    'Tipo do objeto'.
  PERFORM zf_adiciona_coluna USING 'OBJ_NAME'  'Nome do objeto'.
  PERFORM zf_adiciona_coluna USING 'AUTHOR'    'Autor'.
  PERFORM zf_adiciona_coluna USING 'SRCSYSTEM' 'Sistema de origem'.

ENDFORM.
FORM zf_adiciona_coluna USING p_campo
                              p_texto.

  CLEAR s_fieldcat.
  s_fieldcat-fieldname =  p_campo.
  s_fieldcat-seltext_m =  p_texto.

  APPEND s_fieldcat TO t_fieldcat.
ENDFORM.

FORM zf_exibe_alv .

  CLEAR s_layout.
  s_layout-zebra = 'X'.             " Ativa efeito zebrado
  s_layout-colwidth_optimize = 'X'. " Ajusta a largura das colunas automaticamente
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      is_layout     = s_layout
      it_fieldcat   = t_fieldcat
    TABLES
      t_outtab      = lt_saida
    EXCEPTIONS
      program_error = 1
      OTHERS        = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Erro ao renderizar o relatório ALV.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
