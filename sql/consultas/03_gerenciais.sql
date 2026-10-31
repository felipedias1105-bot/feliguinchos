-- =====================================================================
--  FELIGUINCHOS — CONSULTAS 03: GERENCIAIS
--  Relatórios para a gestão
-- =====================================================================
USE feliguinchos;

-- C1. Faturamento mensal (pagamentos aprovados)
SELECT DATE_FORMAT(data_hora_pagamento, '%Y-%m') AS mes,
       COUNT(*) AS qtd_pagamentos, SUM(valor_pago) AS total_recebido,
       ROUND(AVG(valor_pago), 2) AS ticket_medio
FROM pagamento
WHERE status = 'APROVADO'
GROUP BY DATE_FORMAT(data_hora_pagamento, '%Y-%m')
ORDER BY mes;

-- C2. Faturamento por forma de pagamento (participação %)
SELECT fp.descricao, COUNT(*) AS qtd, SUM(pg.valor_pago) AS total,
       ROUND(100 * SUM(pg.valor_pago) / (SELECT SUM(valor_pago) FROM pagamento WHERE status = 'APROVADO'), 2) AS percentual
FROM pagamento pg
JOIN forma_pagamento fp ON fp.forma_pagamento_id = pg.forma_pagamento_id
WHERE pg.status = 'APROVADO'
GROUP BY fp.forma_pagamento_id, fp.descricao
ORDER BY total DESC;

-- C3. Ranking de prestadores (O.S., faturamento, nota média)
SELECT RANK() OVER (ORDER BY r.faturamento DESC) AS posicao, r.*
FROM (
    SELECT p.prestador_id, pp.nome, COALESCE(e.razao_social, 'Autônomo') AS empresa,
           COUNT(os.ordem_id)                                         AS total_os,
           COALESCE(SUM(os.status_atual = 'FINALIZADA'), 0)           AS finalizadas,
           COALESCE(SUM(os.status_atual = 'CANCELADA'), 0)            AS canceladas,
           COALESCE(SUM(CASE WHEN os.status_atual = 'FINALIZADA' THEN os.valor_total END), 0) AS faturamento,
           ROUND(AVG(a.nota), 2)                                      AS nota_media
    FROM prestador_servico p
    JOIN pessoa pp             ON pp.cpf         = p.cpf
    LEFT JOIN empresa e        ON e.empresa_id   = p.empresa_id
    LEFT JOIN ordem_servico os ON os.prestador_id = p.prestador_id
    LEFT JOIN avaliacao a      ON a.ordem_id     = os.ordem_id
    GROUP BY p.prestador_id, pp.nome, e.razao_social
) r;

-- C4. Desempenho por empresa parceira
SELECT empresa, COUNT(*) AS total_os, SUM(status_atual = 'FINALIZADA') AS finalizadas,
       SUM(CASE WHEN status_atual = 'FINALIZADA' THEN valor_total ELSE 0 END) AS faturamento
FROM vw_ordem_servico_detalhada
GROUP BY empresa
ORDER BY faturamento DESC;

-- C5. Serviços mais solicitados e ticket médio
SELECT sr.descricao, sr.tipo_servico, COUNT(s.solicitacao_id) AS qtd_solicitacoes,
       ROUND(AVG(os.valor_total), 2) AS ticket_medio_os
FROM servico_reboque sr
LEFT JOIN solicitacao s    ON s.servico_id      = sr.servico_id
LEFT JOIN ordem_servico os ON os.solicitacao_id = s.solicitacao_id AND os.status_atual = 'FINALIZADA'
GROUP BY sr.servico_id, sr.descricao, sr.tipo_servico
ORDER BY qtd_solicitacoes DESC;

-- C6. Tempo médio (minutos) do pedido até a finalização, por serviço
SELECT servico, COUNT(*) AS os_finalizadas,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, data_hora_solicitacao, data_hora_fim)), 1) AS min_pedido_ate_fim,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, data_hora_inicio, data_hora_fim)), 1)      AS min_execucao
FROM vw_ordem_servico_detalhada
WHERE status_atual = 'FINALIZADA'
GROUP BY servico
ORDER BY min_pedido_ate_fim DESC;

-- C7. Taxa de cancelamento e cancelamentos por responsável
SELECT COUNT(*) AS total_os, SUM(status_atual = 'CANCELADA') AS canceladas,
       ROUND(100 * SUM(status_atual = 'CANCELADA') / COUNT(*), 2) AS taxa_cancelamento_pct
FROM ordem_servico;

SELECT responsavel, COUNT(*) AS qtd, SUM(valor_multa) AS multas
FROM cancelamento
GROUP BY responsavel;

-- C8. Top 5 clientes por valor pago
SELECT c.cliente_id, p.nome, COUNT(DISTINCT os.ordem_id) AS qtd_os, SUM(pg.valor_pago) AS total_pago
FROM cliente c
JOIN pessoa p         ON p.cpf             = c.cpf
JOIN veiculo v        ON v.cliente_id      = c.cliente_id
JOIN solicitacao s    ON s.veiculo_id      = v.veiculo_id
JOIN ordem_servico os ON os.solicitacao_id = s.solicitacao_id
JOIN pagamento pg     ON pg.ordem_id       = os.ordem_id AND pg.status = 'APROVADO'
GROUP BY c.cliente_id, p.nome
ORDER BY total_pago DESC
LIMIT 5;

-- C9. Utilização da frota de guinchos
SELECT vr.placa, CONCAT(mv.marca, ' ', mv.nome) AS modelo, tg.descricao AS tipo, vr.status,
       COUNT(os.ordem_id) AS qtd_os,
       COALESCE(SUM(s.distancia_km), 0) AS km_rodados,
       COALESCE(SUM(os.valor_total), 0) AS receita_gerada
FROM veiculo_reboque vr
JOIN modelo_veiculo mv     ON mv.modelo_id          = vr.modelo_id
JOIN tipo_guincho tg       ON tg.tipo_guincho_id    = vr.tipo_guincho_id
LEFT JOIN ordem_servico os ON os.veiculo_reboque_id = vr.veiculo_reboque_id AND os.status_atual <> 'CANCELADA'
LEFT JOIN solicitacao s    ON s.solicitacao_id      = os.solicitacao_id
GROUP BY vr.veiculo_reboque_id, vr.placa, mv.marca, mv.nome, tg.descricao, vr.status
ORDER BY qtd_os DESC;

-- C10. Canal de abertura: atendentes x aplicativo
SELECT COALESCE(pf.nome, 'Aplicativo') AS canal, COUNT(*) AS solicitacoes,
       SUM(s.status = 'ACEITA') AS aceitas
FROM solicitacao s
LEFT JOIN funcionario f ON f.funcionario_id = s.funcionario_id
LEFT JOIN pessoa pf     ON pf.cpf           = f.cpf
GROUP BY f.funcionario_id, pf.nome
ORDER BY solicitacoes DESC;

-- C11. Taxa de aceite e tempo de resposta por prestador
SELECT pp.nome, COUNT(*) AS notificacoes, SUM(n.resposta = 'ACEITA') AS aceitas,
       ROUND(100 * SUM(n.resposta = 'ACEITA') / COUNT(*), 1) AS taxa_aceite_pct,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, n.data_hora_envio, n.data_hora_resposta)), 1) AS min_medio_resposta
FROM notificacao_prestador n
JOIN prestador_servico p ON p.prestador_id = n.prestador_id
JOIN pessoa pp           ON pp.cpf         = p.cpf
GROUP BY p.prestador_id, pp.nome
ORDER BY taxa_aceite_pct DESC;

-- C12. Demanda por dia da semana e faixa horária
SELECT ELT(DAYOFWEEK(data_hora_solicitacao), 'Domingo','Segunda','Terça','Quarta','Quinta','Sexta','Sábado') AS dia_semana,
       CASE WHEN HOUR(data_hora_solicitacao) < 6  THEN '00h-06h'
            WHEN HOUR(data_hora_solicitacao) < 12 THEN '06h-12h'
            WHEN HOUR(data_hora_solicitacao) < 18 THEN '12h-18h'
            ELSE '18h-24h' END AS faixa_horaria,
       COUNT(*) AS qtd
FROM solicitacao
GROUP BY dia_semana, faixa_horaria
ORDER BY qtd DESC;

-- C13. Satisfação: distribuição das notas e NPS simplificado
SELECT nota, COUNT(*) AS qtd FROM avaliacao GROUP BY nota ORDER BY nota DESC;

SELECT ROUND(AVG(nota), 2) AS nota_media,
       ROUND(100 * (SUM(nota = 5) - SUM(nota <= 3)) / COUNT(*), 1) AS nps_simplificado
FROM avaliacao;

-- C14. Funil das solicitações
SELECT status, COUNT(*) AS qtd FROM solicitacao GROUP BY status ORDER BY qtd DESC;

-- C15. Demanda por cidade de origem (usa CEP -> Cidade)
SELECT ci.nome AS cidade, ci.uf, COUNT(*) AS solicitacoes,
       COALESCE(SUM(os.valor_total), 0) AS valor_das_os
FROM solicitacao s
JOIN cep ce                ON ce.cep            = s.origem_cep
JOIN cidade ci             ON ci.cidade_id      = ce.cidade_id
LEFT JOIN ordem_servico os ON os.solicitacao_id = s.solicitacao_id AND os.status_atual = 'FINALIZADA'
GROUP BY ci.cidade_id, ci.nome, ci.uf
ORDER BY solicitacoes DESC;

-- C16. Clientes por cidade de residência
SELECT COALESCE(ci.nome, 'Sem endereço') AS cidade, COUNT(*) AS clientes
FROM cliente c
JOIN pessoa p       ON p.cpf        = c.cpf
LEFT JOIN cep ce    ON ce.cep       = p.cep
LEFT JOIN cidade ci ON ci.cidade_id = ce.cidade_id
GROUP BY ci.nome
ORDER BY clientes DESC;
