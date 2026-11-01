# Evidências do teste dos scripts SQL

Esta pasta guarda a prova de que os scripts da pasta `sql/` rodam do começo ao fim em um banco vazio, como pede a Etapa 15 do manual:

banco vazio → script → tabelas → restrições → dados → consultas → resultados

O teste foi feito em 31/10/2026, depois das correções do grupo.

## O que foi testado

- Os 11 scripts originais da pasta `sql/`, sem mudar nada, na ordem do `sql/README.md`.
- O banco foi criado do zero, em uma instância vazia do MariaDB 10.4.28 do XAMPP.
- O `sql_mode` foi o padrão do XAMPP (`NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION`), sem modo estrito no servidor.
- Para cada script guardamos a saída, os erros e o código de saída.
- Também conferimos com consultas se as correções feitas no banco estão mesmo lá.

## Como reproduzir

1. Abra o Shell do XAMPP e entre na pasta `sql/` do projeto.
2. Rode os comandos da seção "Pelo Shell do XAMPP" do `sql/README.md`, na ordem.
3. No final, rode `SELECT * FROM feliguinchos_testes.resultado_teste;` para ver os testes.

Atenção: o `ddl/01_tabelas.sql` apaga o banco `feliguinchos` se ele já existir.

No nosso teste usamos uma instância separada, na porta 3307, para não mexer no banco do XAMPP. Os detalhes estão em `00_ambiente.txt`.

## Resumo dos resultados

### Scripts

Os 11 scripts rodaram sem erro. Todos terminaram com código de saída 0 e nenhuma mensagem de erro.

### Testes de integridade

152 de 152 testes aprovados, com o `sql_mode` padrão do XAMPP.

Os testes 94 e 95 (gravar à mão nas colunas calculadas `valor_total` e `aceite_unico`) agora passam, porque o script de testes liga o `STRICT_TRANS_TABLES` só na sessão dele.

### Consultas de auditoria

O `mysql -t` não mostra nada quando uma consulta não acha linhas. Por isso, conferimos a quantidade de linhas de cada auditoria rodando o arquivo de novo com `-vvv`.

| Auditoria | Esperado | Obtido | Confere? |
|---|---|---|---|
| D1 Trilha de status | lista completa | 97 linhas | sim |
| D2 status_atual diferente do histórico | nenhuma linha | nenhuma linha | sim |
| D3 O.S. sem histórico | nenhuma linha | nenhuma linha | sim |
| D4 Finalizada sem pagamento aprovado | O.S. 11 | O.S. 11 | sim |
| D5 Valor devido diferente do pago | O.S. 11 e O.S. 13 | O.S. 11 (0,00 de 185,00) e O.S. 13 (900,00 de 980,00) | sim |
| D6 Pagamentos recusados | pagamento 9 | pagamento 9 | sim |
| D7 Cancelamento sem funcionário | cancelamento 3 | cancelamento 3 | sim |
| D8 Prestador, guincho ou tarifa errados | nenhuma linha | nenhuma linha | sim |
| D9 Finalizadas depois da previsão | O.S. 2, 5 e 13 | O.S. 2, 5 e 13 | sim |
| D10 Data de fim x status | nenhuma linha | nenhuma linha | sim |
| D11 Status da solicitação x O.S. | nenhuma linha | nenhuma linha | sim |
| D12 Valor base x valor estimado | nenhuma linha | nenhuma linha | sim |
| D13 Descontos concedidos | lista | O.S. 4, 9 e 14 | sim |
| D14 a D19 | nenhuma linha | nenhuma linha | sim |

### Registros

- Logo depois da carga: 436 registros, igual ao README do projeto.
- Depois do UPDATE e do DELETE: 437 registros.

### Correções conferidas

Todas as correções foram encontradas no banco ou nos scripts:

- testes 94 e 95;
- adicional de madrugada da O.S. 20;
- motivo do cancelamento 3 e histórico da O.S. 16;
- data de cadastro dos prestadores 1 e 2;
- observação da O.S. 4;
- C1 com ticket por O.S.;
- C9 só com O.S. finalizadas;
- comentários "Pergunta" e "Decisão";
- fim do DELETE de notificações.

As consultas e os resultados estão em `verificacao_correcoes.txt`.

## Arquivos

| Arquivo | O que tem |
|---|---|
| `00_ambiente.txt` | Data, versão do MariaDB, sql_mode, como a instância vazia foi criada e a ordem dos scripts |
| `01_ddl_01_tabelas.txt` | Saída de `sql/ddl/01_tabelas.sql` |
| `02_ddl_02_gatilhos.txt` | Saída de `sql/ddl/02_gatilhos.sql` |
| `03_ddl_03_views.txt` | Saída de `sql/ddl/03_views.sql` |
| `04_dados_01_carga.txt` | Saída de `sql/dados/01_carga.sql` |
| `05_consultas_01_select.txt` | Saída de `sql/consultas/01_select.sql` |
| `06_consultas_02_join.txt` | Saída de `sql/consultas/02_join.sql` |
| `07_consultas_03_gerenciais.txt` | Saída de `sql/consultas/03_gerenciais.sql` |
| `08_consultas_04_update.txt` | Saída de `sql/consultas/04_update.sql` |
| `09_consultas_05_delete.txt` | Saída de `sql/consultas/05_delete.sql` |
| `10_auditoria_01_consultas_auditoria.txt` | Saída de `sql/auditoria/01_consultas_auditoria.sql` |
| `11_auditoria_02_testes_integridade.txt` | Saída de `sql/auditoria/02_testes_integridade.sql` |
| `testes_integridade_resultado.txt` | Tabela `resultado_teste` inteira e o resumo |
| `contagem_registros.txt` | Registros por tabela depois da carga e no final |
| `verificacao_correcoes.txt` | Uma consulta para cada correção, com o resultado |

Os scripts de DDL, carga, UPDATE e DELETE não mostram nada na tela. Por isso, os arquivos deles só têm o cabeçalho, "(nenhum)" em erros e o código de saída.
