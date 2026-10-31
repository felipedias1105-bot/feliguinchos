-- =====================================================================
--  FELIGUINCHOS — CONSULTAS 02: JOIN
--  Consultas com relacionamentos (recompõem os dados normalizados)
-- =====================================================================
USE feliguinchos;

-- B1. Clientes com telefones, endereço completo e quantidade de veículos
--     (endereço: logradouro e bairro vêm do CEP; se o CEP for genérico,
--      vêm dos campos informados)
SELECT c.cliente_id,
       p.nome,
       c.status,
       GROUP_CONCAT(DISTINCT pt.telefone SEPARATOR ' / ')                     AS telefones,
       CONCAT_WS(', ', COALESCE(ce.logradouro, p.logradouro_informado), p.numero, p.complemento,
                 COALESCE(ce.bairro, p.bairro_informado))                    AS endereco,
       CONCAT(ci.nome, '/', ci.uf)                                            AS cidade,
       COUNT(DISTINCT v.veiculo_id)                                           AS qtd_veiculos
FROM cliente c
JOIN pessoa p                ON p.cpf        = c.cpf
LEFT JOIN pessoa_telefone pt ON pt.cpf       = p.cpf
LEFT JOIN cep ce             ON ce.cep       = p.cep
LEFT JOIN cidade ci          ON ci.cidade_id = ce.cidade_id
LEFT JOIN veiculo v          ON v.cliente_id = c.cliente_id
GROUP BY c.cliente_id, p.nome, c.status, ce.logradouro, p.logradouro_informado, p.numero,
         p.complemento, ce.bairro, p.bairro_informado, ci.nome, ci.uf
ORDER BY p.nome;

-- B2. Veículos com proprietário, marca/modelo e tipo
SELECT v.placa, mv.marca, mv.nome AS modelo, v.ano, tv.descricao AS tipo, p.nome AS proprietario
FROM veiculo v
JOIN modelo_veiculo mv ON mv.modelo_id       = v.modelo_id
JOIN tipo_veiculo tv   ON tv.tipo_veiculo_id = v.tipo_veiculo_id
JOIN cliente c         ON c.cliente_id       = v.cliente_id
JOIN pessoa p          ON p.cpf              = c.cpf
ORDER BY p.nome, v.placa;

-- B3. Solicitações completas: cliente, serviço, endereços e quem abriu
SELECT s.solicitacao_id, s.data_hora_solicitacao, pc.nome AS cliente, v.placa,
       sr.descricao AS servico,
       e.origem_endereco, e.origem_cidade, e.destino_endereco, e.destino_cidade,
       COALESCE(pf.nome, 'Aplicativo') AS aberta_por,
       s.distancia_km, s.valor_estimado, s.status
FROM solicitacao s
JOIN vw_solicitacao_endereco e ON e.solicitacao_id = s.solicitacao_id
JOIN veiculo v                 ON v.veiculo_id     = s.veiculo_id
JOIN cliente c                 ON c.cliente_id     = v.cliente_id
JOIN pessoa pc                 ON pc.cpf           = c.cpf
JOIN servico_reboque sr        ON sr.servico_id    = s.servico_id
LEFT JOIN funcionario f        ON f.funcionario_id = s.funcionario_id
LEFT JOIN pessoa pf            ON pf.cpf           = f.cpf
ORDER BY s.data_hora_solicitacao;

-- B4. Ordens de serviço detalhadas (JOIN em 12 tabelas)
SELECT os.ordem_id, os.status_atual, pc.nome AS cliente, v.placa AS placa_cliente,
       CONCAT(mv.marca, ' ', mv.nome) AS veiculo, tv.descricao AS tipo_veiculo,
       sr.descricao AS servico, pp.nome AS prestador,
       COALESCE(emp.razao_social, 'Autônomo') AS empresa,
       vr.placa AS placa_guincho, CONCAT(mg.marca, ' ', mg.nome) AS modelo_guincho,
       tg.descricao AS tipo_guincho, os.valor_total
FROM ordem_servico os
JOIN solicitacao s       ON s.solicitacao_id      = os.solicitacao_id
JOIN veiculo v           ON v.veiculo_id          = s.veiculo_id
JOIN modelo_veiculo mv   ON mv.modelo_id          = v.modelo_id
JOIN cliente c           ON c.cliente_id          = v.cliente_id
JOIN pessoa pc           ON pc.cpf                = c.cpf
JOIN tipo_veiculo tv     ON tv.tipo_veiculo_id    = v.tipo_veiculo_id
JOIN servico_reboque sr  ON sr.servico_id         = s.servico_id
JOIN prestador_servico p ON p.prestador_id        = os.prestador_id
JOIN pessoa pp           ON pp.cpf                = p.cpf
LEFT JOIN empresa emp    ON emp.empresa_id        = p.empresa_id
JOIN veiculo_reboque vr  ON vr.veiculo_reboque_id = os.veiculo_reboque_id
JOIN modelo_veiculo mg   ON mg.modelo_id          = vr.modelo_id
JOIN tipo_guincho tg     ON tg.tipo_guincho_id    = vr.tipo_guincho_id
ORDER BY os.ordem_id;

-- B5. Compatibilidade tipo de guincho x tipo de veículo
SELECT tg.descricao AS tipo_guincho, tg.capacidade_max_kg, tv.descricao AS tipo_veiculo, gtv.observacao
FROM guincho_tipo_veiculo gtv
JOIN tipo_guincho tg ON tg.tipo_guincho_id = gtv.tipo_guincho_id
JOIN tipo_veiculo tv ON tv.tipo_veiculo_id = gtv.tipo_veiculo_id
ORDER BY tv.tipo_veiculo_id, tg.tipo_guincho_id;

-- B6. Prestadores e os guinchos que operam (histórico de vínculos)
SELECT pp.nome AS prestador, COALESCE(e.razao_social, 'Autônomo') AS empresa,
       vr.placa, CONCAT(mv.marca, ' ', mv.nome) AS modelo, tg.descricao AS tipo_guincho,
       pvr.data_inicio, pvr.data_fim, pvr.status
FROM prestador_veiculo_reboque pvr
JOIN prestador_servico p ON p.prestador_id        = pvr.prestador_id
JOIN pessoa pp           ON pp.cpf                = p.cpf
LEFT JOIN empresa e      ON e.empresa_id          = p.empresa_id
JOIN veiculo_reboque vr  ON vr.veiculo_reboque_id = pvr.veiculo_reboque_id
JOIN modelo_veiculo mv   ON mv.modelo_id          = vr.modelo_id
JOIN tipo_guincho tg     ON tg.tipo_guincho_id    = vr.tipo_guincho_id
ORDER BY pp.nome, pvr.data_inicio;

-- B7. Linha do tempo de uma O.S. (O.S. 5)
SELECT h.data_hora_alteracao, h.status, COALESCE(pf.nome, 'Prestador/Sistema') AS responsavel, h.observacao
FROM historico_status h
LEFT JOIN funcionario f ON f.funcionario_id = h.funcionario_id
LEFT JOIN pessoa pf     ON pf.cpf           = f.cpf
WHERE h.ordem_id = 5
ORDER BY h.data_hora_alteracao, h.historico_id;

-- B8. Notificações e tempo de resposta
SELECT n.solicitacao_id, pp.nome AS prestador, n.data_hora_envio, n.data_hora_resposta,
       COALESCE(n.resposta, 'SEM RESPOSTA') AS resposta,
       TIMESTAMPDIFF(MINUTE, n.data_hora_envio, n.data_hora_resposta) AS minutos_resposta
FROM notificacao_prestador n
JOIN prestador_servico p ON p.prestador_id = n.prestador_id
JOIN pessoa pp           ON pp.cpf         = p.cpf
ORDER BY n.solicitacao_id, n.prestador_id;

-- B9. Pagamentos com forma e cliente
SELECT pg.pagamento_id, pg.ordem_id, pc.nome AS cliente, fp.descricao AS forma,
       pg.valor_pago, pg.data_hora_pagamento, pg.status
FROM pagamento pg
JOIN forma_pagamento fp ON fp.forma_pagamento_id = pg.forma_pagamento_id
JOIN ordem_servico os   ON os.ordem_id           = pg.ordem_id
JOIN solicitacao s      ON s.solicitacao_id      = os.solicitacao_id
JOIN veiculo v          ON v.veiculo_id          = s.veiculo_id
JOIN cliente c          ON c.cliente_id          = v.cliente_id
JOIN pessoa pc          ON pc.cpf                = c.cpf
ORDER BY pg.data_hora_pagamento;

-- B10. PROCESSO: quem pode atender a solicitação 23?
--      Prestador ATIVO, vínculo vigente, guincho compatível e disponível.
SELECT s.solicitacao_id, p.prestador_id, pp.nome AS prestador, vr.placa AS guincho, tg.descricao AS tipo_guincho
FROM solicitacao s
JOIN veiculo v                    ON v.veiculo_id          = s.veiculo_id
JOIN guincho_tipo_veiculo gtv     ON gtv.tipo_veiculo_id   = v.tipo_veiculo_id
JOIN veiculo_reboque vr           ON vr.tipo_guincho_id    = gtv.tipo_guincho_id
JOIN tipo_guincho tg              ON tg.tipo_guincho_id    = vr.tipo_guincho_id
JOIN prestador_veiculo_reboque pv ON pv.veiculo_reboque_id = vr.veiculo_reboque_id AND pv.data_fim IS NULL
JOIN prestador_servico p          ON p.prestador_id        = pv.prestador_id
JOIN pessoa pp                    ON pp.cpf                = p.cpf
WHERE s.solicitacao_id = 23
  AND vr.status = 'DISPONIVEL'
  AND p.status  = 'ATIVO';

-- B11. Pessoas com mais de um papel (só possível com a tabela Pessoa)
SELECT p.cpf, p.nome,
       CONCAT_WS(', ', IF(c.cliente_id     IS NOT NULL, 'Cliente',     NULL),
                       IF(f.funcionario_id IS NOT NULL, 'Funcionário', NULL),
                       IF(pr.prestador_id  IS NOT NULL, 'Prestador',   NULL)) AS papeis
FROM pessoa p
LEFT JOIN cliente c            ON c.cpf  = p.cpf
LEFT JOIN funcionario f        ON f.cpf  = p.cpf
LEFT JOIN prestador_servico pr ON pr.cpf = p.cpf
WHERE (c.cliente_id IS NOT NULL) + (f.funcionario_id IS NOT NULL) + (pr.prestador_id IS NOT NULL) > 1;

-- B12. Modelos usados por veículos de clientes e por guinchos
SELECT mv.marca, mv.nome AS modelo,
       COUNT(DISTINCT v.veiculo_id)          AS veiculos_clientes,
       COUNT(DISTINCT vr.veiculo_reboque_id) AS guinchos
FROM modelo_veiculo mv
LEFT JOIN veiculo v          ON v.modelo_id  = mv.modelo_id
LEFT JOIN veiculo_reboque vr ON vr.modelo_id = mv.modelo_id
GROUP BY mv.modelo_id, mv.marca, mv.nome
ORDER BY guinchos DESC, veiculos_clientes DESC, mv.marca;
