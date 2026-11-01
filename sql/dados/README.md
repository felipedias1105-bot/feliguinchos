# Massa de dados (carga)

Arquivo: [01_carga.sql](01_carga.sql). Rode depois dos três scripts de `sql/ddl/`.

A carga simula os meses de setembro e outubro de 2026, com os feriados de 07/09 e 12/10. Ela passa pelos gatilhos do banco, então só entra no banco se respeitar as regras R7 a R16.

| Tabela | Registros | Tabela | Registros |
|---|---:|---|---:|
| pessoa | 28 | tarifa | 13 |
| pessoa_telefone | 33 | solicitacao | 23 |
| cliente | 12 | notificacao_prestador | 32 |
| funcionario | 7 | ordem_servico | 20 |
| empresa | 3 | historico_status | 93 |
| prestador_servico | 10 | cancelamento | 3 |
| cidade | 10 | forma_pagamento | 5 |
| cep | 29 | pagamento | 18 |
| modelo_veiculo | 22 | avaliacao | 13 |
| tipo_veiculo | 6 | prestador_veiculo_reboque | 11 |
| veiculo | 16 | guincho_tipo_veiculo | 11 |
| tipo_guincho | 5 | servico_reboque | 6 |
| veiculo_reboque | 7 | Total | 436 |

O histórico de status tem 6 linhas escritas à mão. As outras 87 são geradas por `INSERT ... SELECT` e pelo gatilho que grava o aceite de cada O.S.

---

## Uso de IA na geração da massa de dados

A carga foi gerada com ajuda do **Claude** (aplicativo Claude Desktop).

Seguimos o ciclo do manual: **gerar → testar → validar → corrigir**.

### 1. Gerar

Os prompts abaixo foram reescritos pelo grupo a partir da conversa original no Claude Desktop.

**Prompt 1: carga principal**

```
Tenho o banco feliguinchos em MariaDB 10.4 (XAMPP). Ele é de um aplicativo
de guincho que liga o cliente ao prestador (guincheiro). Vou colar os
scripts 01_tabelas.sql e 02_gatilhos.sql.

Gere um script de INSERT com a massa de dados de teste, seguindo estas regras:
- Período de setembro e outubro de 2026. Considere os feriados 07/09 e 12/10.
- Use IDs explícitos em todas as tabelas, para facilitar a auditoria.
- Nomes, CPFs, CNPJs, placas e e-mails fictícios. CPF, CNPJ, CEP e telefone
  só com dígitos. Senha gravada com SHA2(...,256), nunca em texto.
- Respeite todas as PKs, FKs, UNIQUEs, CHECKs e os gatilhos R7 a R16.
  A ordem dos INSERTs tem que funcionar com os gatilhos.
- valor_estimado = tarifa.valor_base + tarifa.valor_por_km * distancia_km,
  usando a tarifa vigente na data do pedido.
- Os adicionais da O.S. seguem a tarifa: madrugada (22h às 6h), domingo,
  feriado e rodovia.

Quantidades e situações que precisam aparecer:
- 10 cidades de SP. Duas delas (Juquitiba e Pirapora do Bom Jesus) com CEP
  genérico, com logradouro e bairro informados na pessoa ou na solicitação.
- Clientes, 7 funcionários (gerente, atendentes e financeiro, um INATIVO)
  e 10 prestadores com todos os status (ATIVO, EM_ANALISE, BLOQUEADO, RECUSADO).
- Uma mesma pessoa que é prestador e também cliente.
- Dois clientes que atuam como pessoa jurídica (cnpj preenchido).
- Um cliente sem veículo, um PENDENTE e um BLOQUEADO.
- 3 empresas parceiras, uma sem telefone e e-mail.
- Um modelo de veículo usado por um carro de cliente e por um guincho.
- Veículos blindados atendidos só por guincho plataforma.
- Um guincho em manutenção e o mesmo par prestador-guincho em dois períodos.
- Uma tarifa antiga já encerrada (2025) e um serviço INATIVO.
- Solicitações em todos os status: SOLICITADA, EM_ANALISE, ACEITA,
  SEM_PRESTADOR e CANCELADA. Serviços no local (bateria, pneu) com destino
  igual à origem.
- Notificações aceitas, recusadas, expiradas e ainda sem resposta.
- O.S. finalizadas, em andamento e canceladas pelo cliente, pelo prestador
  e pela central.
- Pagamentos por Pix, crédito, débito, dinheiro e boleto para PJ. Um pagamento
  recusado e depois aprovado, e uma O.S. paga em duas formas.
- Avaliações de 1 a 5, e algumas O.S. finalizadas sem avaliação.
```

**Prompt 2: casos para a auditoria**

```
Agora inclua de propósito algumas situações que as consultas de auditoria
precisam encontrar, sem quebrar nenhuma restrição do banco:
- uma O.S. finalizada sem pagamento aprovado (pagamento PENDENTE);
- uma O.S. paga a menos do que o valor total;
- um cancelamento sem funcionário autorizador;
- algumas O.S. finalizadas depois do horário previsto;
- um pagamento recusado.
Comente no script onde está cada caso.
```

**Prompt 3: histórico de status**

```
O gatilho R15 exige que o histórico de status seja gravado em ordem
cronológica e que status_atual da O.S. seja igual ao último histórico.
Ajuste a carga: as O.S. nascem ACEITA (o gatilho grava esse histórico),
depois insira A_CAMINHO, NO_LOCAL, EM_ATENDIMENTO, FINALIZADA ou CANCELADA
na ordem certa e, no final, atualize status_atual a partir do histórico.
```

### 2. Testar

O grupo rodou o script num banco vazio, na ordem do [sql/README.md](../README.md), junto com as auditorias e os 152 testes automáticos.

### 3. Validar

Conferimos o resultado da IA nos pontos que o manual pede:

| O que conferimos | Como | Resultado |
|---|---|---|
| PKs, FKs e constraints | Execução sem erro em banco vazio e testes de integridade | 152 de 152 aprovados |
| Regras entre tabelas (R7 a R16) | A própria carga passa pelos gatilhos | Nenhum INSERT recusado |
| Valor estimado | Comparação com a tarifa e a distância em cada solicitação | Bate nas 23 solicitações |
| Valor base e adicionais da O.S. | Comparação com a tarifa vigente e com a data e hora do pedido | Corrigido na O.S. 20 (ver abaixo) |
| Guincho ou prestador em duas O.S. ao mesmo tempo | Consulta de sobreposição de horários | Nenhum caso |
| Casos plantados para a auditoria | Consultas D4 a D9 | Todas retornam o esperado |
| Sentido para o negócio | Leitura dos motivos, observações e datas | Três correções (ver abaixo) |

As provas da execução estão em [evidencias/sql/](../../evidencias/sql/).

### 4. Corrigir

Na revisão de 31/10/2026, feita com o Claude Code, achamos dados que passavam pelas restrições mas não faziam sentido. Os prompts usados foram estes:

```
encontre inconsistencias entre modelo fisico/der/sql/informações como se fosse
um professor de modelagem de dados, revise 2x antes de me passar
```

```
refaça os scripts que nao precisa mexer em regras ou decisões e me informe os
que faltam
```

```
faça os testes dos scripts com o professor e traga evidencias e coloque na
pasta evidencias/sql/
```

O que foi corrigido na carga:

| Problema encontrado | Correção |
|---|---|
| A O.S. 20 foi pedida às 22:15 e estava sem o adicional de madrugada | Lançado o adicional de R$ 50,00 da tarifa 1 |
| O cancelamento 3 dizia "sem guincho compatível", mas um guincho compatível já estava a caminho | Motivo trocado para "Endereço de origem informado errado" |
| Os prestadores 1 e 2 tinham vínculo com guincho antes da data de cadastro | Data de cadastro ajustada para 20/02/2025 |
| A O.S. 4 dizia "cliente PJ recorrente" no primeiro serviço do cliente | Observação trocada para "Desconto para cliente PJ (frota)" |

Ficaram para decisão do grupo, e não foram mudados pela IA, os pontos que dependem de regra de negócio: percentual da multa, limite de desconto, quem pode isentar, dono do guincho e quando vale o adicional de madrugada para uma O.S. que passa da meia-noite.
