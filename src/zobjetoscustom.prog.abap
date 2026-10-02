REPORT zobjetoscustom.
" Tabelas
TABLES: tadir.
" Tela de seleção
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS: s_object FOR tadir-object NO INTERVALS,
                s_author FOR tadir-author NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b1.

CLASS lcl_relatorio DEFINITION FINAL.
  PUBLIC SECTION.
    " Tipos para a tabela interna de saída
    TYPES:
      BEGIN OF ty_saida,
        pgmid     TYPE pgmid,
        object    TYPE trobjtype,
        obj_name  TYPE sobj_name,
        author    TYPE responsibl,
        srcsystem TYPE srcsystem,
      END OF ty_saida,
      tt_saida TYPE STANDARD TABLE OF ty_saida WITH DEFAULT KEY.

    " Tipos para receber dados de entrada do select-options
    TYPES:
      tr_object TYPE RANGE OF tadir-object,
      tr_author TYPE RANGE OF tadir-author.

    " Métodos que podem ser acessados fora da classe
    METHODS constructor
      IMPORTING
        it_object TYPE tr_object
        it_author TYPE tr_author.
    METHODS executar.

  PRIVATE SECTION.
    " Dados privados
    DATA: mt_object TYPE tr_object,
          mt_author TYPE tr_author,
          mt_saida  TYPE tt_saida.

    " Métodos internos (substitutos dos antigos FORM)
    METHODS selecionar_dados
      RETURNING
        VALUE(rv_tem_dados) TYPE abap_bool.
    METHODS exibir_alv.
ENDCLASS.

" Implementação da classe lcl_relatorio
CLASS lcl_relatorio IMPLEMENTATION.
  " O Construtor: salva o que veio da tela de seleção nos atributos privados
  METHOD constructor.
    me->mt_object = it_object.
    me->mt_author = it_author.
  ENDMETHOD.
  " Implementação do método "executar" que comanda a ordem de execução

  " Método faz uma verificação usando a estrutura condicional IF
  " Se a verificação pro selecionar_dados retornar o valor BOOLEANO "ABAP_TRUE"
  " Ele prossegue para o método de exibição do ALV

  METHOD executar.
    IF me->selecionar_dados(  ) = abap_true.
      me->exibir_alv(  ).
    ENDIF.
  ENDMETHOD.

  " Implementação do metódo selecionar_dados substituindo antigo FORM zf_seleciona_dados
  METHOD selecionar_dados.
    CLEAR me->mt_saida.
    " Seleciona os registros dos campos respectivos da tabela transparente TADIR
    " Joga os dados pra tabela interna definida no método lcl_relatorio
    " Cláusula WHERE Filtra ID do programa pra retornar as LINHAS que correspondem AO DADO 'R3TR'
    " Os demais filtros são para buscar DADOS que o nome do objeto começe com Z ou Y
    " o IN é para buscar os dados de entrada do usuário no select-options
    SELECT pgmid object obj_name author srcsystem
        FROM tadir
        INTO TABLE me->mt_saida
        WHERE pgmid = 'R3TR'
         AND ( obj_name LIKE 'Z%' OR obj_name LIKE 'Y%' )
         AND object IN me->mt_object
         AND author IN me->mt_author.
    " Tratamento de erros
    " erificar se algum dado foi encontrado na tabela de saída
    IF me->mt_saida IS INITIAL.
      MESSAGE 'Nenhum registro encontrado' TYPE 'S' DISPLAY LIKE 'W'.
      rv_tem_dados = abap_false.
    ELSE.
      rv_tem_dados = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD exibir_alv.

    DATA: lo_alv TYPE REF TO cl_salv_table.

    TRY.
        " SALV monta as colunas automaticamente baseado na mt_saida
        " A fábrica do SALV monta as colunas automaticamente baseado na mt_saida
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_alv
          CHANGING
            t_table      = me->mt_saida
        ).

        " Ativa barra de ferramentas padrão (Excel, ordenação, filtro)
        lo_alv->get_functions( )->set_all( abap_true ).

        " Otimiza o tamanho das colunas
        lo_alv->get_columns( )->set_optimize( abap_true ).

        " Exibe a tabela na tela
        lo_alv->display( ).

      CATCH cx_salv_msg.
        MESSAGE 'Erro ao renderizar o relatório ALV.' TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.


ENDCLASS.

START-OF-SELECTION.

  DATA: lo_app TYPE REF TO lcl_relatorio.

  CREATE OBJECT lo_app
    EXPORTING
      it_object = s_object[]
      it_author = s_author[].

  lo_app->executar( ).
