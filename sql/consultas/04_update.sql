-- =====================================================================
--  FELIGUINCHOS — CONSULTAS 04: UPDATE
--  Processos empresariais (cada processo em transação)
-- =====================================================================
USE feliguinchos;

-- E1. PROCESSO: aceite da solicitação 22 e abertura da O.S.
START TRANSACTION;
UPDATE notificacao_prestador
   SET resposta = 'ACEITA', data_hora_resposta = '2026-10-28 08:44:00'
 WHERE solicitacao_id = 22 AND prestador_id = 1;

UPDATE solicitacao SET status = 'ACEITA' WHERE solicitacao_id = 22;

-- o gatilho valida R7–R10 e grava o histórico de aceite (R14)
INSERT INTO ordem_servico (solicitacao_id, tarifa_id, prestador_id, veiculo_reboque_id, data_previsao, valor_base)
VALUES (22, 9, 1, 1, '2026-10-28 09:40:00', 96.00);

UPDATE veiculo_reboque SET status = 'EM_SERVICO' WHERE veiculo_reboque_id = 1;
COMMIT;

-- E2. PROCESSO: finalizar a O.S. 19 (histórico primeiro, depois a O.S. — R15)
START TRANSACTION;
INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao)
VALUES (19, NULL, 'FINALIZADA', '2026-10-26 11:50:00', 'Serviço concluído (app)');

UPDATE ordem_servico
   SET status_atual = 'FINALIZADA', data_hora_fim = '2026-10-26 11:50:00'
 WHERE ordem_id = 19;

UPDATE veiculo_reboque SET status = 'DISPONIVEL' WHERE veiculo_reboque_id = 3;

INSERT INTO pagamento (ordem_id, forma_pagamento_id, valor_pago, data_hora_pagamento, status, comprovante)
SELECT ordem_id, 1, valor_total, '2026-10-26 11:55:00', 'APROVADO', 'PIX-20261026-0019'
FROM ordem_servico WHERE ordem_id = 19;
COMMIT;

-- E3. PROCESSO: O.S. 20 — prestador chegou e iniciou o atendimento
START TRANSACTION;
INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao) VALUES
(20, NULL, 'NO_LOCAL',       '2026-10-27 22:45:00', 'Prestador chegou ao local (app)'),
(20, NULL, 'EM_ATENDIMENTO', '2026-10-27 22:50:00', 'Atendimento iniciado (app)');
UPDATE ordem_servico SET status_atual = 'EM_ATENDIMENTO' WHERE ordem_id = 20;
COMMIT;

-- E4. Completar cadastro da empresa 3 (telefone e e-mail opcionais — P5)
--     (o pagamento PENDENTE da O.S. 11 fica em aberto de propósito: caso de auditoria)
UPDATE empresa
   SET telefone = '1150003000', email = 'atendimento@autosocorrosp.com.br'
 WHERE empresa_id = 3;

-- E5. Reajuste de tarifa com versionamento (R11: sem sobreposição)
START TRANSACTION;
UPDATE tarifa SET vigencia_fim = '2026-10-31' WHERE tarifa_id = 2;

INSERT INTO tarifa (tipo_veiculo_id, servico_id, valor_base, valor_por_km,
                    adicional_madrugada, adicional_domingo, adicional_feriado, adicional_rodovia,
                    vigencia_inicio, vigencia_fim)
SELECT tipo_veiculo_id, servico_id, ROUND(valor_base * 1.05, 2), ROUND(valor_por_km * 1.05, 2),
       adicional_madrugada, adicional_domingo, adicional_feriado, adicional_rodovia,
       '2026-11-01', NULL
FROM tarifa WHERE tarifa_id = 2;
COMMIT;

-- E6. PROCESSO: aprovação do prestador 9 (R5: ATIVO exige CNH)
UPDATE prestador_servico SET cnh = '01234567809', status = 'ATIVO' WHERE prestador_id = 9;

-- E7. Guincho 7 volta da manutenção
UPDATE veiculo_reboque SET status = 'DISPONIVEL', capacidade_kg = 3500.00
 WHERE veiculo_reboque_id = 7;

-- E8. Atualização de e-mail: com a tabela Pessoa, o dado muda em um só lugar,
--     valendo para todos os papéis da pessoa
UPDATE pessoa p
JOIN cliente c ON c.cpf = p.cpf
   SET p.email = 'juliana.r.fernandes@email.com'
 WHERE c.cliente_id = 3;

-- E9. UPDATE com JOIN: expira notificações sem resposta há mais de 30 minutos
--     em solicitações que já foram aceitas por outro prestador
UPDATE notificacao_prestador n
JOIN solicitacao s ON s.solicitacao_id = n.solicitacao_id
   SET n.resposta = 'EXPIRADA'
 WHERE n.resposta IS NULL
   AND s.status = 'ACEITA'
   AND n.data_hora_envio < NOW() - INTERVAL 30 MINUTE;

-- E10. Mudança de endereço: a cliente 7 se mudou. Só CEP, número e
--      complemento mudam; logradouro, bairro e cidade vêm do CEP
UPDATE pessoa p
JOIN cliente c ON c.cpf = p.cpf
   SET p.cep = '03310000', p.numero = '455', p.complemento = 'Casa'
 WHERE c.cliente_id = 7;
