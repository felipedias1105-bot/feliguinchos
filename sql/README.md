# Feliguinchos — Scripts SQL (modelo normalizado 1FN, 2FN e 3FN)

Banco: **feliguinchos** · SGBD: MariaDB 10.4+ (XAMPP) ou MySQL 8.0.16+

25 tabelas: 4 novas (pessoa, cidade, cep, modelo_veiculo), 8 alteradas e 13 sem mudança
em relação ao modelo lógico. 36 chaves estrangeiras, 36 CHECKs, 15 gatilhos, 2 procedures e 2 views.

```
sql/
├── ddl/
│   ├── 01_tabelas.sql          CREATE DATABASE, 25 tabelas, PK, FK, UNIQUE, CHECK, DEFAULT
│   ├── 02_gatilhos.sql         15 gatilhos (endereço e regras R7 a R16) + 2 procedures
│   └── 03_views.sql            vw_solicitacao_endereco e vw_ordem_servico_detalhada
├── dados/
│   └── 01_carga.sql            massa de dados (INSERT)
├── consultas/
│   ├── 01_select.sql           consultas simples
│   ├── 02_join.sql             consultas com relacionamentos
│   ├── 03_gerenciais.sql       relatórios de gestão
│   ├── 04_update.sql           processos empresariais (UPDATE)
│   └── 05_delete.sql           exclusões (DELETE)
└── auditoria/
    ├── 01_consultas_auditoria.sql   consultas de auditoria + contagem final
    └── 02_testes_integridade.sql    152 testes automáticos (APROVADO / REPROVADO)
```

## Ordem de execução

Rode na ordem das pastas e dos números:

1. `ddl/01_tabelas.sql` → `ddl/02_gatilhos.sql` → `ddl/03_views.sql`
2. `dados/01_carga.sql`
3. `consultas/01` → `02` → `03` → `04` → `05`
4. `auditoria/01_consultas_auditoria.sql`
5. `auditoria/02_testes_integridade.sql`

`ddl/01_tabelas.sql` apaga e recria o banco. Para voltar ao estado inicial, recomece do passo 1.

## Pelo phpMyAdmin

Para cada arquivo: aba **Importar** → escolher o arquivo → **Executar**.
Para ver o resultado de uma consulta, copie a consulta e cole na aba **SQL**.

O phpMyAdmin não mostra resultados ao importar. Depois de importar os testes (passo 5),
veja o resultado no banco **feliguinchos_testes**, tabela **resultado_teste**, aba **Procurar**,
ou rode na aba SQL: `SELECT * FROM feliguinchos_testes.resultado_teste;`

## Pelo Shell do XAMPP

```
cd "caminho\da\pasta\sql"
mysql -u root --default-character-set=utf8mb4 < ddl\01_tabelas.sql
mysql -u root --default-character-set=utf8mb4 < ddl\02_gatilhos.sql
mysql -u root --default-character-set=utf8mb4 < ddl\03_views.sql
mysql -u root --default-character-set=utf8mb4 < dados\01_carga.sql
mysql -u root --default-character-set=utf8mb4 < consultas\01_select.sql
mysql -u root --default-character-set=utf8mb4 < consultas\02_join.sql
mysql -u root --default-character-set=utf8mb4 < consultas\03_gerenciais.sql
mysql -u root --default-character-set=utf8mb4 < consultas\04_update.sql
mysql -u root --default-character-set=utf8mb4 < consultas\05_delete.sql
mysql -u root -t --default-character-set=utf8mb4 < auditoria\01_consultas_auditoria.sql > resultado_auditoria.txt
mysql -u root -t --default-character-set=utf8mb4 < auditoria\02_testes_integridade.sql > resultado_testes.txt
```

Se o root tiver senha, use `-u root -p`. Se `mysql` não for reconhecido, use `C:\xampp\mysql\bin\mysql.exe`.

## Resultados esperados

- **Testes de integridade:** 152 de 152 aprovados, inclusive no XAMPP padrão (o script liga `STRICT_TRANS_TABLES` só na sessão dele).
- **Auditoria** (casos plantados de propósito na carga):
  - D4: O.S. 11 finalizada sem pagamento aprovado
  - D5: O.S. 11 (0,00 de 185,00) e O.S. 13 (900,00 de 980,00) com valor divergente
  - D6: pagamento 9 recusado
  - D7: cancelamento 3 sem funcionário autorizador
  - D9: O.S. 2, 5 e 13 finalizadas após a previsão
  - Demais auditorias: nenhuma linha (integridade confirmada)

## Casos da normalização presentes na carga

- Paulo Sérgio Ramos é **prestador e cliente** ao mesmo tempo (uma única linha em `pessoa`).
- O modelo **Fiat Strada** é usado por um veículo de cliente e por um guincho.
- Juquitiba e Pirapora do Bom Jesus têm **CEP genérico**: o logradouro e o bairro são informados
  na pessoa ou na solicitação.
- Thiago e Gustavo atuam como **pessoa jurídica** (`cnpj` preenchido em `pessoa`).
