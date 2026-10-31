-- =====================================================================
--  FELIGUINCHOS — AUDITORIA 01: CONSULTAS DE AUDITORIA
--  Executar depois de consultas/ (o resultado esperado está em cada consulta)
-- =====================================================================
USE feliguinchos;

-- D1. Trilha completa de alterações de status
SELECT h.historico_id, h.ordem_id, h.status, h.data_hora_alteracao,
       COALESCE(pf.nome, 'Prestador/Sistema') AS alterado_por, f.perfil_acesso, h.observacao
FROM historico_status h
LEFT JOIN funcionario f ON f.funcionario_id = h.funcionario_id
LEFT JOIN pessoa pf     ON pf.cpf           = f.cpf
ORDER BY h.ordem_id, h.data_hora_alteracao, h.historico_id;

-- D2. status_atual diferente do último histórico (R15) — esperado: nenhuma
SELECT os.ordem_id, os.status_atual,
       (SELECT h.status FROM historico_status h WHERE h.ordem_id = os.ordem_id
        ORDER BY h.data_hora_alteracao DESC, h.historico_id DESC LIMIT 1) AS ultimo_historico
FROM ordem_servico os
HAVING os.status_atual <> ultimo_historico;

-- D3. O.S. sem histórico (R14) — esperado: nenhuma
SELECT os.ordem_id FROM ordem_servico os
WHERE NOT EXISTS (SELECT 1 FROM historico_status h WHERE h.ordem_id = os.ordem_id);

-- D4. O.S. finalizada sem pagamento aprovado — esperado: O.S. 11
SELECT os.ordem_id, os.valor_total, os.data_hora_fim
FROM ordem_servico os
WHERE os.status_atual = 'FINALIZADA'
  AND NOT EXISTS (SELECT 1 FROM pagamento pg WHERE pg.ordem_id = os.ordem_id AND pg.status = 'APROVADO');

-- D5. Valor devido x valor pago (finalizada = valor_total; cancelada = multa)
--     Esperado: O.S. 11 (0 de 185,00) e O.S. 13 (900,00 de 980,00)
SELECT os.ordem_id, os.status_atual,
       CASE WHEN os.status_atual = 'CANCELADA' THEN COALESCE(c.valor_multa, 0) ELSE os.valor_total END AS valor_devido,
       COALESCE(SUM(CASE WHEN pg.status = 'APROVADO' THEN pg.valor_pago END), 0) AS valor_pago
FROM ordem_servico os
LEFT JOIN cancelamento c ON c.ordem_id  = os.ordem_id
LEFT JOIN pagamento pg   ON pg.ordem_id = os.ordem_id
WHERE os.status_atual IN ('FINALIZADA','CANCELADA')
GROUP BY os.ordem_id, os.status_atual, os.valor_total, c.valor_multa
HAVING valor_devido <> valor_pago;

-- D6. Pagamentos recusados — esperado: pagamento 9 (O.S. 9)
SELECT pg.pagamento_id, pg.ordem_id, fp.descricao, pg.valor_pago, pg.data_hora_pagamento, pg.comprovante
FROM pagamento pg
JOIN forma_pagamento fp ON fp.forma_pagamento_id = pg.forma_pagamento_id
WHERE pg.status = 'RECUSADO';

-- D7. Cancelamento sem autorização de funcionário — esperado: cancelamento 3
SELECT cancelamento_id, ordem_id, responsavel, motivo, data_hora
FROM cancelamento
WHERE funcionario_id IS NULL;

-- D8. O.S. que violam R7/R9/R10 (gatilhos impedem) — esperado: nenhuma
SELECT os.ordem_id
FROM ordem_servico os
JOIN solicitacao s      ON s.solicitacao_id      = os.solicitacao_id
JOIN veiculo v          ON v.veiculo_id          = s.veiculo_id
JOIN veiculo_reboque vr ON vr.veiculo_reboque_id = os.veiculo_reboque_id
JOIN tarifa t           ON t.tarifa_id           = os.tarifa_id
WHERE NOT EXISTS (SELECT 1 FROM notificacao_prestador n
                  WHERE n.solicitacao_id = os.solicitacao_id AND n.prestador_id = os.prestador_id AND n.resposta = 'ACEITA')
   OR NOT EXISTS (SELECT 1 FROM guincho_tipo_veiculo g
                  WHERE g.tipo_guincho_id = vr.tipo_guincho_id AND g.tipo_veiculo_id = v.tipo_veiculo_id)
   OR NOT EXISTS (SELECT 1 FROM prestador_veiculo_reboque pv
                  WHERE pv.prestador_id = os.prestador_id AND pv.veiculo_reboque_id = os.veiculo_reboque_id
                    AND DATE(s.data_hora_solicitacao) >= pv.data_inicio
                    AND (pv.data_fim IS NULL OR DATE(s.data_hora_solicitacao) <= pv.data_fim))
   OR t.tipo_veiculo_id <> v.tipo_veiculo_id
   OR t.servico_id <> s.servico_id;

-- D9. O.S. finalizadas após o horário previsto (SLA) — esperado: O.S. 2, 5 e 13
SELECT ordem_id, prestador, data_previsao, data_hora_fim,
       TIMESTAMPDIFF(MINUTE, data_previsao, data_hora_fim) AS minutos_atraso
FROM vw_ordem_servico_detalhada
WHERE status_atual = 'FINALIZADA' AND data_hora_fim > data_previsao
ORDER BY minutos_atraso DESC;

-- D10. FINALIZADA sem data de fim, ou data de fim em O.S. não finalizada — esperado: nenhuma
SELECT ordem_id, status_atual, data_hora_fim
FROM ordem_servico
WHERE (status_atual = 'FINALIZADA' AND data_hora_fim IS NULL)
   OR (status_atual <> 'FINALIZADA' AND data_hora_fim IS NOT NULL);

-- D11. Status da solicitação incoerente com a O.S. — esperado: nenhuma
SELECT s.solicitacao_id, s.status, os.ordem_id, os.status_atual
FROM solicitacao s
LEFT JOIN ordem_servico os ON os.solicitacao_id = s.solicitacao_id
WHERE (os.ordem_id IS NOT NULL AND os.status_atual <> 'CANCELADA' AND s.status <> 'ACEITA')
   OR (os.status_atual = 'CANCELADA' AND s.status <> 'CANCELADA')
   OR (os.ordem_id IS NULL AND s.status = 'ACEITA');

-- D12. Valor base da O.S. diferente do valor estimado — esperado: nenhuma
SELECT os.ordem_id, s.valor_estimado, os.valor_base
FROM ordem_servico os
JOIN solicitacao s ON s.solicitacao_id = os.solicitacao_id
WHERE os.valor_base <> s.valor_estimado;

-- D13. Descontos concedidos
SELECT ordem_id, valor_base + valor_adicionais AS valor_bruto, desconto,
       ROUND(100 * desconto / (valor_base + valor_adicionais), 2) AS desconto_pct, observacao
FROM ordem_servico
WHERE desconto > 0
ORDER BY desconto_pct DESC;

-- D14. Mínimos (1,N) do DER (R13) — esperado: nenhuma linha
SELECT 'Pessoa sem telefone' AS problema, p.cpf AS id FROM pessoa p
WHERE NOT EXISTS (SELECT 1 FROM pessoa_telefone t WHERE t.cpf = p.cpf)
UNION ALL
SELECT 'Tipo de veículo sem guincho compatível', tv.tipo_veiculo_id FROM tipo_veiculo tv
WHERE NOT EXISTS (SELECT 1 FROM guincho_tipo_veiculo g WHERE g.tipo_veiculo_id = tv.tipo_veiculo_id)
UNION ALL
SELECT 'Tipo de guincho sem tipo de veículo', tg.tipo_guincho_id FROM tipo_guincho tg
WHERE NOT EXISTS (SELECT 1 FROM guincho_tipo_veiculo g WHERE g.tipo_guincho_id = tg.tipo_guincho_id);

-- D15. Solicitações com mais de um aceite (R6) — esperado: nenhuma
SELECT solicitacao_id, COUNT(*) AS aceites
FROM notificacao_prestador
WHERE resposta = 'ACEITA'
GROUP BY solicitacao_id
HAVING COUNT(*) > 1;

-- D16. Ações registradas por funcionário hoje INATIVO — esperado: nenhuma
SELECT 'solicitacao' AS origem, s.solicitacao_id AS id, pf.nome
FROM solicitacao s
JOIN funcionario f ON f.funcionario_id = s.funcionario_id
JOIN pessoa pf     ON pf.cpf           = f.cpf
WHERE f.status = 'INATIVO'
UNION ALL
SELECT 'historico', h.historico_id, pf.nome
FROM historico_status h
JOIN funcionario f ON f.funcionario_id = h.funcionario_id
JOIN pessoa pf     ON pf.cpf           = f.cpf
WHERE f.status = 'INATIVO';

-- D17. Endereços inconsistentes com o tipo de CEP (gatilhos impedem) — esperado: nenhuma
--      CEP genérico sem logradouro/bairro informados, ou CEP comum com logradouro informado
SELECT 'Pessoa' AS origem, p.cpf AS id, p.cep
FROM pessoa p JOIN cep ce ON ce.cep = p.cep
WHERE (ce.cep_generico = 1 AND (p.logradouro_informado IS NULL OR p.bairro_informado IS NULL))
   OR (ce.cep_generico = 0 AND p.logradouro_informado IS NOT NULL)
UNION ALL
SELECT 'Solicitação (origem)', s.solicitacao_id, s.origem_cep
FROM solicitacao s JOIN cep ce ON ce.cep = s.origem_cep
WHERE (ce.cep_generico = 1 AND (s.origem_logradouro_informado IS NULL OR s.origem_bairro_informado IS NULL))
   OR (ce.cep_generico = 0 AND s.origem_logradouro_informado IS NOT NULL)
UNION ALL
SELECT 'Solicitação (destino)', s.solicitacao_id, s.destino_cep
FROM solicitacao s JOIN cep ce ON ce.cep = s.destino_cep
WHERE (ce.cep_generico = 1 AND (s.destino_logradouro_informado IS NULL OR s.destino_bairro_informado IS NULL))
   OR (ce.cep_generico = 0 AND s.destino_logradouro_informado IS NOT NULL);

-- D18. Conflito de interesse: prestador atendendo O.S. de veículo próprio
--      (possível porque a mesma pessoa pode ser cliente e prestador) — esperado: nenhuma
SELECT os.ordem_id, pp.nome AS prestador_e_cliente, v.placa
FROM ordem_servico os
JOIN prestador_servico p ON p.prestador_id = os.prestador_id
JOIN pessoa pp           ON pp.cpf         = p.cpf
JOIN solicitacao s       ON s.solicitacao_id = os.solicitacao_id
JOIN veiculo v           ON v.veiculo_id   = s.veiculo_id
JOIN cliente c           ON c.cliente_id   = v.cliente_id
WHERE c.cpf = p.cpf;

-- D19. Pessoas cadastradas sem nenhum papel (nem cliente, nem funcionário,
--      nem prestador) — esperado: nenhuma
SELECT p.cpf, p.nome
FROM pessoa p
WHERE NOT EXISTS (SELECT 1 FROM cliente           WHERE cpf = p.cpf)
  AND NOT EXISTS (SELECT 1 FROM funcionario       WHERE cpf = p.cpf)
  AND NOT EXISTS (SELECT 1 FROM prestador_servico WHERE cpf = p.cpf);


-- =====================================================================
-- CONFERÊNCIA FINAL — registros por tabela (25 tabelas)
-- =====================================================================
SELECT 'pessoa' AS tabela, COUNT(*) AS registros FROM pessoa
UNION ALL SELECT 'pessoa_telefone',           COUNT(*) FROM pessoa_telefone
UNION ALL SELECT 'cliente',                   COUNT(*) FROM cliente
UNION ALL SELECT 'funcionario',               COUNT(*) FROM funcionario
UNION ALL SELECT 'empresa',                   COUNT(*) FROM empresa
UNION ALL SELECT 'prestador_servico',         COUNT(*) FROM prestador_servico
UNION ALL SELECT 'cidade',                    COUNT(*) FROM cidade
UNION ALL SELECT 'cep',                       COUNT(*) FROM cep
UNION ALL SELECT 'modelo_veiculo',            COUNT(*) FROM modelo_veiculo
UNION ALL SELECT 'tipo_veiculo',              COUNT(*) FROM tipo_veiculo
UNION ALL SELECT 'veiculo',                   COUNT(*) FROM veiculo
UNION ALL SELECT 'tipo_guincho',              COUNT(*) FROM tipo_guincho
UNION ALL SELECT 'veiculo_reboque',           COUNT(*) FROM veiculo_reboque
UNION ALL SELECT 'servico_reboque',           COUNT(*) FROM servico_reboque
UNION ALL SELECT 'tarifa',                    COUNT(*) FROM tarifa
UNION ALL SELECT 'solicitacao',               COUNT(*) FROM solicitacao
UNION ALL SELECT 'ordem_servico',             COUNT(*) FROM ordem_servico
UNION ALL SELECT 'historico_status',          COUNT(*) FROM historico_status
UNION ALL SELECT 'notificacao_prestador',     COUNT(*) FROM notificacao_prestador
UNION ALL SELECT 'cancelamento',              COUNT(*) FROM cancelamento
UNION ALL SELECT 'avaliacao',                 COUNT(*) FROM avaliacao
UNION ALL SELECT 'forma_pagamento',           COUNT(*) FROM forma_pagamento
UNION ALL SELECT 'pagamento',                 COUNT(*) FROM pagamento
UNION ALL SELECT 'prestador_veiculo_reboque', COUNT(*) FROM prestador_veiculo_reboque
UNION ALL SELECT 'guincho_tipo_veiculo',      COUNT(*) FROM guincho_tipo_veiculo;
