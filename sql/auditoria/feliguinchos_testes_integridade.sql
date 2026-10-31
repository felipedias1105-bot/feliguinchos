-- FELIGUINCHOS v2 — TESTES DE INTEGRIDADE E REGRAS DE NEGÓCIO
-- Compatível com o DDL feliguinchos_modelo_fisico.sql enviado.
-- Execute depois da massa de dados corrigida, em banco de TESTES.
-- As consultas de auditoria devem retornar zero linhas, salvo consultas de conferência.

USE feliguinchos;

-- A. Estrutura: quantidade de tabelas físicas
SELECT COUNT(*) AS total_tabelas
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE';

-- B. Auditorias positivas: esperado = zero linhas em cada consulta
SELECT cpf, COUNT(*) qtd FROM cliente GROUP BY cpf HAVING COUNT(*) > 1;
SELECT email, COUNT(*) qtd FROM cliente GROUP BY email HAVING COUNT(*) > 1;
SELECT v.veiculo_id FROM veiculo v LEFT JOIN cliente c ON c.cliente_id=v.cliente_id WHERE c.cliente_id IS NULL;
SELECT v.veiculo_id FROM veiculo v LEFT JOIN tipo_veiculo t ON t.tipo_veiculo_id=v.tipo_veiculo_id WHERE t.tipo_veiculo_id IS NULL;
SELECT os.ordem_id FROM ordem_servico os LEFT JOIN solicitacao s ON s.solicitacao_id=os.solicitacao_id WHERE s.solicitacao_id IS NULL;
SELECT solicitacao_id, COUNT(*) qtd FROM ordem_servico GROUP BY solicitacao_id HAVING COUNT(*) > 1;
SELECT ordem_id, COUNT(*) qtd FROM avaliacao GROUP BY ordem_id HAVING COUNT(*) > 1;
SELECT solicitacao_id, COUNT(*) qtd FROM notificacao_prestador WHERE resposta='ACEITA' GROUP BY solicitacao_id HAVING COUNT(*) > 1;
SELECT vr.veiculo_reboque_id
FROM veiculo_reboque vr JOIN tipo_guincho tg ON tg.tipo_guincho_id=vr.tipo_guincho_id
WHERE tg.capacidade_max_kg IS NOT NULL AND vr.capacidade_kg > tg.capacidade_max_kg;
SELECT avaliacao_id FROM avaliacao WHERE nota NOT BETWEEN 1 AND 5;
SELECT ordem_id FROM ordem_servico
WHERE ABS(valor_total - (valor_base + valor_adicionais - desconto)) > 0.001;
SELECT os.ordem_id
FROM ordem_servico os
LEFT JOIN historico_status hs ON hs.ordem_id=os.ordem_id
GROUP BY os.ordem_id, os.status_atual
HAVING MAX(hs.data_hora_alteracao) IS NULL;
SELECT os.ordem_id, os.status_atual, h.status AS ultimo_status
FROM ordem_servico os
JOIN historico_status h ON h.historico_id = (
    SELECT h2.historico_id FROM historico_status h2
    WHERE h2.ordem_id=os.ordem_id
    ORDER BY h2.data_hora_alteracao DESC, h2.historico_id DESC LIMIT 1
)
WHERE os.status_atual <> h.status;

-- C. Conferência de triggers, procedures e view
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_schema=DATABASE()
ORDER BY event_object_table, trigger_name;

SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema=DATABASE();

SELECT table_name AS view_name
FROM information_schema.views
WHERE table_schema=DATABASE();

SELECT * FROM vw_ordem_servico_detalhada ORDER BY ordem_id;

-- D. Testes negativos: descomente e execute UM POR VEZ.
-- Cada comando deve falhar. Se inserir normalmente, a restrição/regra correspondente
-- não está ativa ou o cenário não está sendo testado corretamente.

-- D1. CPF duplicado (UNIQUE):
-- INSERT INTO cliente (nome,cpf,email,senha,status)
-- VALUES ('CPF duplicado','52998224725','cpf.duplicado@example.com','hash','ATIVO');

-- D2. FK inexistente:
-- INSERT INTO veiculo (cliente_id,tipo_veiculo_id,placa,marca,modelo,ano)
-- VALUES (99999,1,'ZZZ9Z99','Marca','Modelo',2024);

-- D3. Placa duplicada (UNIQUE):
-- INSERT INTO veiculo (cliente_id,tipo_veiculo_id,placa,marca,modelo,ano)
-- VALUES (1,1,'ABC1D23','Marca','Modelo',2024);

-- D4. Pagamento negativo (CHECK):
-- INSERT INTO pagamento (ordem_id,forma_pagamento_id,valor_pago,status)
-- VALUES (1,1,-10.00,'APROVADO');

-- D5. Nota fora do intervalo (CHECK):
-- INSERT INTO avaliacao (ordem_id,nota) VALUES (1,6);

-- D6. Segundo aceite para a mesma solicitação (índice UNIQUE sobre coluna gerada):
-- INSERT INTO notificacao_prestador
-- (solicitacao_id,prestador_id,data_hora_envio,data_hora_resposta,resposta)
-- VALUES (1,2,'2026-10-20 10:02:00','2026-10-20 10:06:00','ACEITA');
-- Observação: no conjunto demonstrativo, a combinação (1,2) já existe como RECUSADA.
-- Este teste deve falhar tanto pela PK composta quanto pela regra de aceite se usar
-- outro prestador ativo ainda não notificado. Para testar especificamente R6,
-- cadastre um terceiro prestador ativo e notifique-o para a solicitação 1 com ACEITA.

-- D7. O.S. para prestador que não aceitou a solicitação (trigger R7):
-- Para testar isoladamente, use uma nova solicitação, prestador ativo com vínculo vigente,
-- guincho compatível e tarifa vigente, mas sem notificação ACEITA desse prestador.

-- D8. Avaliação em ordem não finalizada (trigger R16):
-- Para testar isoladamente, crie uma nova ordem válida que permaneça ACEITA e tente avaliá-la.

-- D9. Cancelamento em ordem não cancelada (trigger R16):
-- Para testar isoladamente, crie uma nova ordem válida que permaneça ACEITA e tente cancelá-la.

-- E. Metadados das colunas e restrições
SELECT TABLE_NAME,COLUMN_NAME,COLUMN_TYPE,IS_NULLABLE,COLUMN_DEFAULT,EXTRA
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA=DATABASE()
ORDER BY TABLE_NAME,ORDINAL_POSITION;

SELECT TABLE_NAME,CONSTRAINT_NAME,CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA=DATABASE()
ORDER BY TABLE_NAME,CONSTRAINT_TYPE;

SELECT tc.TABLE_NAME, cc.CONSTRAINT_NAME, cc.CHECK_CLAUSE
FROM information_schema.CHECK_CONSTRAINTS cc
JOIN information_schema.TABLE_CONSTRAINTS tc
  ON tc.CONSTRAINT_SCHEMA=cc.CONSTRAINT_SCHEMA
 AND tc.CONSTRAINT_NAME=cc.CONSTRAINT_NAME
WHERE tc.TABLE_SCHEMA=DATABASE()
ORDER BY tc.TABLE_NAME, cc.CONSTRAINT_NAME;
