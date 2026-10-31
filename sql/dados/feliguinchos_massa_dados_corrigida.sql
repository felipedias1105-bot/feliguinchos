-- FELIGUINCHOS v2 — MASSA DE DADOS COMPATÍVEL COM O MODELO FÍSICO
-- Compatível com o DDL feliguinchos_modelo_fisico.sql enviado.
-- O DDL cria 21 tabelas (não 25).
-- Execute SOMENTE depois de criar o schema feliguinchos_v2 e selecionar esse banco.
-- Esta massa usa IDs explícitos para facilitar auditoria.
-- Execute em banco de TESTES vazio. Não contém DROP DATABASE.

USE feliguinchos;
SET NAMES utf8mb4;
START TRANSACTION;

-- 1. CLIENTE
INSERT INTO cliente
(cliente_id,nome,cpf,email,senha,data_cadastro,status,logradouro,numero,bairro,cidade,uf,cep)
VALUES
(1,'Ana Lima','52998224725','ana.teste@example.com','$2y$10$HASH_FICTICIO_NAO_USAR_EM_LOGIN','2026-10-01','ATIVO','Avenida Paulista','100','Bela Vista','Sao Paulo','SP','01310100'),
(2,'Bruno Costa','11144477735','bruno.teste@example.com','$2y$10$HASH_FICTICIO_NAO_USAR_EM_LOGIN','2026-10-02','ATIVO','Rua das Figueiras','200','Jardim','Santo Andre','SP','09010000');

-- 2. CLIENTE_TELEFONE
INSERT INTO cliente_telefone (cliente_id,telefone) VALUES
(1,'11999990001'),(2,'11999990002');

-- 3. EMPRESA
INSERT INTO empresa (empresa_id,razao_social,cnpj,telefone,email) VALUES
(1,'Feliguinchos Servicos Ltda','12345678000195','1133334444','contato@feliguinchos.example');

-- 4. TIPO_VEICULO
INSERT INTO tipo_veiculo (tipo_veiculo_id,descricao,categoria,peso_max_kg) VALUES
(1,'Carro de passeio','Leve',2500.00),
(2,'Utilitario','Medio',3500.00);

-- 5. VEICULO
INSERT INTO veiculo (veiculo_id,cliente_id,tipo_veiculo_id,placa,marca,modelo,ano,cor,blindado) VALUES
(1,1,1,'ABC1D23','Fiat','Argo',2022,'Prata',0),
(2,2,2,'DEF4G56','Volkswagen','Saveiro',2021,'Branca',0);

-- 6. TIPO_GUINCHO
INSERT INTO tipo_guincho (tipo_guincho_id,descricao,capacidade_max_kg) VALUES
(1,'Plataforma',5000.00);

-- 7. VEICULO_REBOQUE
INSERT INTO veiculo_reboque (veiculo_reboque_id,tipo_guincho_id,placa,marca,modelo,ano,capacidade_kg,status) VALUES
(1,1,'GHI7J89','Iveco','Daily Plataforma',2020,3500.00,'ATIVO'),
(2,1,'KLM1N23','Mercedes-Benz','Sprinter Plataforma',2022,4000.00,'ATIVO');

-- 8. PRESTADOR_SERVICO
INSERT INTO prestador_servico
(prestador_id,empresa_id,nome,cpf,telefone,email,cnh,status,data_cadastro) VALUES
(1,1,'Carlos Mendes','12345678909','11988880001','carlos.teste@example.com','12345678901','ATIVO','2026-09-15'),
(2,NULL,'Marcos Oliveira','98765432100','11988880002','marcos.teste@example.com','98765432109','ATIVO','2026-09-16');

-- 9. SERVICO_REBOQUE
INSERT INTO servico_reboque (servico_id,descricao,tipo_servico,status) VALUES
(1,'Reboque simples','REBOQUE','ATIVO');

-- 10. TARIFA
INSERT INTO tarifa
(tarifa_id,tipo_veiculo_id,servico_id,valor_base,valor_por_km,adicional_madrugada,adicional_domingo,adicional_feriado,adicional_rodovia,vigencia_inicio,vigencia_fim,status) VALUES
(1,1,1,150.00,5.00,30.00,25.00,40.00,20.00,'2026-01-01',NULL,'ATIVO'),
(2,2,1,180.00,6.00,35.00,30.00,45.00,25.00,'2026-01-01',NULL,'ATIVO');

-- 11. FUNCIONARIO
INSERT INTO funcionario
(funcionario_id,nome,cpf,email,cargo,perfil_acesso,senha,status) VALUES
(1,'Fernanda Alves','22233344455','fernanda.teste@example.com','Atendente','ATENDENTE','$2y$10$HASH_FICTICIO_NAO_USAR_EM_LOGIN','ATIVO');

-- 12. SOLICITACAO
INSERT INTO solicitacao
(solicitacao_id,veiculo_id,servico_id,funcionario_id,data_hora_solicitacao,endereco_origem,endereco_destino,distancia_km,observacao,valor_estimado,status) VALUES
(1,1,1,1,'2026-10-20 10:00:00','Avenida Paulista, 100, Sao Paulo - SP','Praca da Se, 200, Sao Paulo - SP',10.00,'Veiculo com pane mecanica',200.00,'ACEITA'),
(2,2,1,1,'2026-10-20 11:00:00','Rua das Figueiras, 200, Santo Andre - SP','Avenida Portugal, 500, Santo Andre - SP',8.50,'Pneu danificado',231.00,'ACEITA');

-- 19. PRESTADOR_VEICULO_REBOQUE (vínculos vigentes necessários à O.S.)
INSERT INTO prestador_veiculo_reboque
(prestador_id,veiculo_reboque_id,data_inicio,data_fim,status) VALUES
(1,1,'2026-01-01',NULL,'ATIVO'),
(2,2,'2026-01-01',NULL,'ATIVO');

-- 20. GUINCHO_TIPO_VEICULO (compatibilidade dos equipamentos)
INSERT INTO guincho_tipo_veiculo (tipo_guincho_id,tipo_veiculo_id,observacao) VALUES
(1,1,'Compatível com carros de passeio'),
(1,2,'Compatível com utilitários dentro da capacidade');

-- 21. NOTIFICACAO_PRESTADOR
-- O trigger exige prestador ATIVO; a regra R6 permite apenas um ACEITA por solicitação.
INSERT INTO notificacao_prestador
(solicitacao_id,prestador_id,data_hora_envio,data_hora_resposta,resposta) VALUES
(1,1,'2026-10-20 10:01:00','2026-10-20 10:04:00','ACEITA'),
(1,2,'2026-10-20 10:01:30','2026-10-20 10:03:00','RECUSADA'),
(2,2,'2026-10-20 11:01:00','2026-10-20 11:05:00','ACEITA');

-- 13. ORDEM_SERVICO
-- O trigger AFTER INSERT cria automaticamente o primeiro HISTORICO_STATUS = ACEITA.
INSERT INTO ordem_servico
(ordem_id,solicitacao_id,tarifa_id,prestador_id,veiculo_reboque_id,status_atual,valor_base,valor_adicionais,desconto) VALUES
(1,1,1,1,1,'ACEITA',200.00,0.00,0.00),
(2,2,2,2,2,'ACEITA',231.00,0.00,0.00);

-- 14. HISTORICO_STATUS
-- O histórico inicial ACEITA já foi criado pelo trigger. Inserimos somente as próximas etapas.
-- A sequência é intencional: inserir cada evento no histórico e, em seguida,
-- atualizar a O.S. para esse mesmo status. O trigger R15 exige essa ordem.
INSERT INTO historico_status (ordem_id,funcionario_id,status,data_hora_alteracao,observacao)
VALUES (1,1,'A_CAMINHO','2026-10-20 10:10:00','Prestador a caminho');
UPDATE ordem_servico SET status_atual='A_CAMINHO' WHERE ordem_id=1;

INSERT INTO historico_status (ordem_id,funcionario_id,status,data_hora_alteracao,observacao)
VALUES (1,1,'NO_LOCAL','2026-10-20 10:30:00','Prestador chegou ao local');
UPDATE ordem_servico SET status_atual='NO_LOCAL' WHERE ordem_id=1;

INSERT INTO historico_status (ordem_id,funcionario_id,status,data_hora_alteracao,observacao)
VALUES (1,1,'EM_ATENDIMENTO','2026-10-20 10:35:00','Veiculo em processo de reboque');
UPDATE ordem_servico SET status_atual='EM_ATENDIMENTO' WHERE ordem_id=1;

INSERT INTO historico_status (ordem_id,funcionario_id,status,data_hora_alteracao,observacao)
VALUES (1,1,'FINALIZADA','2026-10-20 11:00:00','Servico concluido');
UPDATE ordem_servico
SET status_atual='FINALIZADA', data_hora_fim='2026-10-20 11:00:00'
WHERE ordem_id=1;

INSERT INTO historico_status (ordem_id,funcionario_id,status,data_hora_alteracao,observacao)
VALUES (2,1,'CANCELADA','2026-10-20 11:15:00','Cliente solicitou cancelamento');
UPDATE ordem_servico SET status_atual='CANCELADA' WHERE ordem_id=2;

-- 15. FORMA_PAGAMENTO
INSERT INTO forma_pagamento (forma_pagamento_id,descricao,tipo) VALUES
(1,'PIX','Instantaneo'),
(2,'Cartao de credito','Cartao');

-- 16. PAGAMENTO
INSERT INTO pagamento (pagamento_id,ordem_id,forma_pagamento_id,valor_pago,data_hora_pagamento,status,comprovante) VALUES
(1,1,1,200.00,'2026-10-20 11:05:00','APROVADO','PIX-TESTE-0001');

-- 17. AVALIACAO
-- Trigger exige que a ordem esteja FINALIZADA.
INSERT INTO avaliacao (avaliacao_id,ordem_id,nota,comentario,data_avaliacao) VALUES
(1,1,5,'Atendimento rapido e profissional','2026-10-20 11:10:00');

-- 18. CANCELAMENTO
-- Trigger exige que a ordem esteja CANCELADA.
INSERT INTO cancelamento (cancelamento_id,ordem_id,funcionario_id,responsavel,motivo,data_hora,valor_multa) VALUES
(1,2,1,'CLIENTE','Cliente desistiu do atendimento','2026-10-20 11:16:00',0.00);

COMMIT;

-- Conferência rápida: cada uma das 21 tabelas deve conter registros.
SELECT 'cliente' tabela, COUNT(*) registros FROM cliente
UNION ALL SELECT 'cliente_telefone', COUNT(*) FROM cliente_telefone
UNION ALL SELECT 'empresa', COUNT(*) FROM empresa
UNION ALL SELECT 'tipo_veiculo', COUNT(*) FROM tipo_veiculo
UNION ALL SELECT 'veiculo', COUNT(*) FROM veiculo
UNION ALL SELECT 'tipo_guincho', COUNT(*) FROM tipo_guincho
UNION ALL SELECT 'veiculo_reboque', COUNT(*) FROM veiculo_reboque
UNION ALL SELECT 'prestador_servico', COUNT(*) FROM prestador_servico
UNION ALL SELECT 'servico_reboque', COUNT(*) FROM servico_reboque
UNION ALL SELECT 'tarifa', COUNT(*) FROM tarifa
UNION ALL SELECT 'funcionario', COUNT(*) FROM funcionario
UNION ALL SELECT 'solicitacao', COUNT(*) FROM solicitacao
UNION ALL SELECT 'ordem_servico', COUNT(*) FROM ordem_servico
UNION ALL SELECT 'historico_status', COUNT(*) FROM historico_status
UNION ALL SELECT 'forma_pagamento', COUNT(*) FROM forma_pagamento
UNION ALL SELECT 'pagamento', COUNT(*) FROM pagamento
UNION ALL SELECT 'avaliacao', COUNT(*) FROM avaliacao
UNION ALL SELECT 'cancelamento', COUNT(*) FROM cancelamento
UNION ALL SELECT 'prestador_veiculo_reboque', COUNT(*) FROM prestador_veiculo_reboque
UNION ALL SELECT 'guincho_tipo_veiculo', COUNT(*) FROM guincho_tipo_veiculo
UNION ALL SELECT 'notificacao_prestador', COUNT(*) FROM notificacao_prestador;
