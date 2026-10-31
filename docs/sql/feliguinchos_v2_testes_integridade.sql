-- =====================================================================
--  FELIGUINCHOS v2 — TESTES DE INTEGRIDADE AUTOMATIZADOS
--  Executar DEPOIS do script completo (estrutura + carga + consultas).
--  Cada teste roda em transação desfeita (ROLLBACK): nada é alterado.
--
--  Parte A: estrutura física x documento do Modelo Lógico
--  Parte B: comandos inválidos -> o banco deve BLOQUEAR
--  Parte C: comandos válidos   -> o banco deve ACEITAR
--  Parte D: gatilhos (R7 a R16) e ações referenciais
--  Parte E: cardinalidades (1,N) e coluna derivada
-- =====================================================================
USE feliguinchos_v2;

DROP TEMPORARY TABLE IF EXISTS resultado_teste;
CREATE TEMPORARY TABLE resultado_teste (
    n         INT AUTO_INCREMENT PRIMARY KEY,
    categoria VARCHAR(30),
    teste     VARCHAR(150),
    esperado  VARCHAR(10),
    obtido    VARCHAR(10),
    resultado VARCHAR(10),
    mensagem  VARCHAR(300)
);

DROP PROCEDURE IF EXISTS sp_teste;
DROP PROCEDURE IF EXISTS sp_verifica;
DELIMITER $$
-- p_setup: comando opcional executado antes do teste, na mesma transação
CREATE PROCEDURE sp_teste(IN p_categoria VARCHAR(30), IN p_teste VARCHAR(150),
                          IN p_esperado VARCHAR(10), IN p_setup TEXT, IN p_sql TEXT)
BEGIN
    DECLARE v_msg TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO resultado_teste (categoria, teste, esperado, obtido, resultado, mensagem)
        VALUES (p_categoria, p_teste, p_esperado, 'BLOQUEOU',
                IF(p_esperado = 'BLOQUEIA', 'APROVADO', 'REPROVADO'), LEFT(v_msg, 300));
    END;

    START TRANSACTION;
    IF p_setup IS NOT NULL THEN
        SET @sql_setup = p_setup;
        PREPARE st FROM @sql_setup; EXECUTE st; DEALLOCATE PREPARE st;
    END IF;
    SET @sql_teste = p_sql;
    PREPARE st FROM @sql_teste; EXECUTE st; DEALLOCATE PREPARE st;
    ROLLBACK;
    INSERT INTO resultado_teste (categoria, teste, esperado, obtido, resultado, mensagem)
    VALUES (p_categoria, p_teste, p_esperado, 'ACEITOU',
            IF(p_esperado = 'ACEITA', 'APROVADO', 'REPROVADO'), NULL);
END$$

CREATE PROCEDURE sp_verifica(IN p_categoria VARCHAR(30), IN p_teste VARCHAR(150),
                             IN p_ok BOOLEAN, IN p_info VARCHAR(300))
BEGIN
    INSERT INTO resultado_teste (categoria, teste, esperado, obtido, resultado, mensagem)
    VALUES (p_categoria, p_teste, 'OK', IF(p_ok, 'OK', 'ERRO'), IF(p_ok, 'APROVADO', 'REPROVADO'), p_info);
END$$
DELIMITER ;

-- Setup reutilizado: prestador 1 aceita a solicitação 23 (SUV, reboque urbano)
SET @aceite_p1 = 'INSERT INTO notificacao_prestador (solicitacao_id, prestador_id, data_hora_envio, data_hora_resposta, resposta) VALUES (23, 1, ''2026-10-29 18:01'', ''2026-10-29 18:03'', ''ACEITA'')';
SET @aceite_p2 = 'INSERT INTO notificacao_prestador (solicitacao_id, prestador_id, data_hora_envio, data_hora_resposta, resposta) VALUES (23, 2, ''2026-10-29 18:01'', ''2026-10-29 18:03'', ''ACEITA'')';
SET @aceite_p6 = 'INSERT INTO notificacao_prestador (solicitacao_id, prestador_id, data_hora_envio, data_hora_resposta, resposta) VALUES (23, 6, ''2026-10-29 18:01'', ''2026-10-29 18:03'', ''ACEITA'')';
SET @nova_os   = 'INSERT INTO ordem_servico (solicitacao_id, tarifa_id, prestador_id, veiculo_reboque_id, data_previsao, valor_base) VALUES ';


-- =====================================================================
-- PARTE A — ESTRUTURA FÍSICA x MODELO LÓGICO
-- =====================================================================
CALL sp_verifica('ESTRUTURA', '21 tabelas (17 entidades + 3 associativas + 1 multivalorado)',
  (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE') = 21, NULL);
CALL sp_verifica('ESTRUTURA', 'Todas as tabelas têm chave primária',
  (SELECT COUNT(DISTINCT TABLE_NAME) FROM information_schema.TABLE_CONSTRAINTS
   WHERE TABLE_SCHEMA = DATABASE() AND CONSTRAINT_TYPE = 'PRIMARY KEY') = 21, NULL);
CALL sp_verifica('ESTRUTURA', '27 chaves estrangeiras (F1 a F27)',
  (SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE()) = 27, NULL);
CALL sp_verifica('ESTRUTURA', 'Exatamente 4 FKs aceitam nulo (lados 0,1 do DER)',
  (SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE k
   JOIN information_schema.COLUMNS c ON c.TABLE_SCHEMA = k.TABLE_SCHEMA AND c.TABLE_NAME = k.TABLE_NAME AND c.COLUMN_NAME = k.COLUMN_NAME
   WHERE k.TABLE_SCHEMA = DATABASE() AND k.REFERENCED_TABLE_NAME IS NOT NULL AND c.IS_NULLABLE = 'YES') = 4, NULL);
CALL sp_verifica('ESTRUTURA', '4 chaves primárias compostas',
  (SELECT COUNT(*) FROM (SELECT TABLE_NAME FROM information_schema.KEY_COLUMN_USAGE
   WHERE TABLE_SCHEMA = DATABASE() AND CONSTRAINT_NAME = 'PRIMARY' GROUP BY TABLE_NAME HAVING COUNT(*) > 1) x) = 4, NULL);
CALL sp_verifica('ESTRUTURA', 'Só Cliente_Telefone tem ON DELETE CASCADE',
  (SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE() AND DELETE_RULE = 'CASCADE') = 1
  AND (SELECT TABLE_NAME FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE() AND DELETE_RULE = 'CASCADE') = 'cliente_telefone', NULL);
CALL sp_verifica('ESTRUTURA', '12 gatilhos das regras R7 a R16',
  (SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = DATABASE()) = 12, NULL);
CALL sp_verifica('ESTRUTURA', 'valor_total é coluna calculada (derivada)',
  (SELECT EXTRA FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'ordem_servico' AND COLUMN_NAME = 'valor_total') LIKE '%GENERATED%', NULL);


-- =====================================================================
-- PARTE B — DEVE BLOQUEAR
-- =====================================================================

-- PK
CALL sp_teste('PK', 'Funcionário com id já existente', 'BLOQUEIA', NULL,
 'INSERT INTO funcionario (funcionario_id,nome,cpf,email,cargo,perfil_acesso,senha,status) VALUES (1,''X'',''99999999999'',''x@x.com'',''C'',''ATENDENTE'',''h'',''ATIVO'')');
CALL sp_teste('PK', 'Forma de pagamento com id já existente', 'BLOQUEIA', NULL,
 'INSERT INTO forma_pagamento (forma_pagamento_id, descricao) VALUES (1, ''Cheque'')');

-- PK composta
CALL sp_teste('PK COMPOSTA', 'Compatibilidade guincho x veículo duplicada', 'BLOQUEIA', NULL,
 'INSERT INTO guincho_tipo_veiculo (tipo_guincho_id, tipo_veiculo_id) VALUES (1, 1)');
CALL sp_teste('PK COMPOSTA', 'Mesmo prestador notificado 2x na mesma solicitação', 'BLOQUEIA', NULL,
 'INSERT INTO notificacao_prestador (solicitacao_id, prestador_id) VALUES (1, 1)');
CALL sp_teste('PK COMPOSTA', 'Telefone repetido para o mesmo cliente', 'BLOQUEIA', NULL,
 'INSERT INTO cliente_telefone VALUES (1, ''11987654321'')');
CALL sp_teste('PK COMPOSTA', 'Vínculo prestador x guincho com mesma data de início', 'BLOQUEIA', NULL,
 'INSERT INTO prestador_veiculo_reboque VALUES (1, 1, ''2026-01-10'', NULL, ''ATIVO'')');

-- UNIQUE
CALL sp_teste('UNIQUE', 'CPF de cliente duplicado', 'BLOQUEIA', NULL,
 'INSERT INTO cliente (nome,cpf,email,senha,status) VALUES (''X'',''32165498701'',''novo@x.com'',''h'',''ATIVO'')');
CALL sp_teste('UNIQUE', 'E-mail de cliente duplicado', 'BLOQUEIA', NULL,
 'INSERT INTO cliente (nome,cpf,email,senha,status) VALUES (''X'',''99999999999'',''mariana.almeida@email.com'',''h'',''ATIVO'')');
CALL sp_teste('UNIQUE', 'Placa de veículo duplicada', 'BLOQUEIA', NULL,
 'INSERT INTO veiculo (cliente_id,tipo_veiculo_id,placa,marca,modelo,ano) VALUES (2,2,''BRA2E19'',''Fiat'',''Uno'',2010)');
CALL sp_teste('UNIQUE', 'Placa de guincho duplicada', 'BLOQUEIA', NULL,
 'INSERT INTO veiculo_reboque (tipo_guincho_id,placa,modelo,ano,status) VALUES (2,''GUI1A23'',''X'',2020,''DISPONIVEL'')');
CALL sp_teste('UNIQUE', 'CNPJ duplicado', 'BLOQUEIA', NULL,
 'INSERT INTO empresa (razao_social, cnpj) VALUES (''X'', ''12345678000101'')');
CALL sp_teste('UNIQUE', 'CNH de prestador duplicada', 'BLOQUEIA', NULL,
 'INSERT INTO prestador_servico (nome,cpf,telefone,email,cnh) VALUES (''X'',''99999999999'',''11999999999'',''x@x.com'',''01234567801'')');
CALL sp_teste('UNIQUE', 'E-mail de funcionário duplicado', 'BLOQUEIA', NULL,
 'INSERT INTO funcionario (nome,cpf,email,cargo,perfil_acesso,senha,status) VALUES (''X'',''99999999999'',''ana.ferreira@feliguinchos.com.br'',''C'',''ATENDENTE'',''h'',''ATIVO'')');
CALL sp_teste('UNIQUE', 'Descrição de tipo de veículo duplicada', 'BLOQUEIA', NULL,
 'INSERT INTO tipo_veiculo (descricao) VALUES (''Motocicleta'')');

-- 1:1 (FK + UNIQUE)
CALL sp_teste('1:1', 'Segunda O.S. para a mesma solicitação (Gera)', 'BLOQUEIA', NULL,
 CONCAT(@nova_os, '(1, 1, 1, 1, NULL, 192)'));
CALL sp_teste('1:1', 'Segunda avaliação para a mesma O.S. (Avaliada)', 'BLOQUEIA', NULL,
 'INSERT INTO avaliacao (ordem_id, nota) VALUES (1, 4)');
CALL sp_teste('1:1', 'Segundo cancelamento para a mesma O.S. (Cancelada)', 'BLOQUEIA', NULL,
 'INSERT INTO cancelamento (ordem_id, responsavel, motivo) VALUES (8, ''CLIENTE'', ''teste'')');

-- R6: índice único parcial
CALL sp_teste('R6 UNICO PARCIAL', 'Segundo aceite na mesma solicitação', 'BLOQUEIA', NULL,
 'UPDATE notificacao_prestador SET resposta = ''ACEITA'', data_hora_resposta = ''2026-09-02 08:19'' WHERE solicitacao_id = 1 AND prestador_id = 2');

-- FK: pai inexistente
CALL sp_teste('FK', 'Veículo de cliente inexistente', 'BLOQUEIA', NULL,
 'INSERT INTO veiculo (cliente_id,tipo_veiculo_id,placa,marca,modelo,ano) VALUES (999,2,''TST1A11'',''Fiat'',''Uno'',2010)');
CALL sp_teste('FK', 'Veículo com tipo inexistente', 'BLOQUEIA', NULL,
 'INSERT INTO veiculo (cliente_id,tipo_veiculo_id,placa,marca,modelo,ano) VALUES (1,999,''TST1A11'',''Fiat'',''Uno'',2010)');
CALL sp_teste('FK', 'Solicitação de veículo inexistente', 'BLOQUEIA', NULL,
 'INSERT INTO solicitacao (veiculo_id,servico_id,endereco_origem,endereco_destino,distancia_km,valor_estimado) VALUES (999,1,''A'',''B'',1,1)');
CALL sp_teste('FK', 'O.S. com tarifa inexistente', 'BLOQUEIA', @aceite_p1,
 CONCAT(@nova_os, '(23, 999, 1, 1, NULL, 326)'));
CALL sp_teste('FK', 'O.S. com prestador inexistente', 'BLOQUEIA', NULL,
 CONCAT(@nova_os, '(23, 4, 999, 1, NULL, 326)'));
CALL sp_teste('FK', 'Pagamento com forma inexistente', 'BLOQUEIA', NULL,
 'INSERT INTO pagamento (ordem_id, forma_pagamento_id, valor_pago) VALUES (1, 999, 10)');
CALL sp_teste('FK', 'Histórico de O.S. inexistente', 'BLOQUEIA', NULL,
 'INSERT INTO historico_status (ordem_id, status) VALUES (999, ''ACEITA'')');
CALL sp_teste('FK', 'Notificação para prestador inexistente', 'BLOQUEIA', NULL,
 'INSERT INTO notificacao_prestador (solicitacao_id, prestador_id) VALUES (23, 999)');

-- FK: ON DELETE RESTRICT (RN12 / RNF09: histórico preservado)
CALL sp_teste('FK RESTRICT', 'Excluir cliente com veículos', 'BLOQUEIA', NULL, 'DELETE FROM cliente WHERE cliente_id = 1');
CALL sp_teste('FK RESTRICT', 'Excluir prestador com O.S.', 'BLOQUEIA', NULL, 'DELETE FROM prestador_servico WHERE prestador_id = 1');
CALL sp_teste('FK RESTRICT', 'Excluir empresa com prestadores', 'BLOQUEIA', NULL, 'DELETE FROM empresa WHERE empresa_id = 1');
CALL sp_teste('FK RESTRICT', 'Excluir funcionário com registros', 'BLOQUEIA', NULL, 'DELETE FROM funcionario WHERE funcionario_id = 3');
CALL sp_teste('FK RESTRICT', 'Excluir solicitação com O.S.', 'BLOQUEIA', NULL, 'DELETE FROM solicitacao WHERE solicitacao_id = 1');
CALL sp_teste('FK RESTRICT', 'Excluir O.S. com histórico', 'BLOQUEIA', NULL, 'DELETE FROM ordem_servico WHERE ordem_id = 20');
CALL sp_teste('FK RESTRICT', 'Excluir tipo de veículo em uso', 'BLOQUEIA', NULL, 'DELETE FROM tipo_veiculo WHERE tipo_veiculo_id = 2');
CALL sp_teste('FK RESTRICT', 'Excluir tarifa aplicada em O.S.', 'BLOQUEIA', NULL, 'DELETE FROM tarifa WHERE tarifa_id = 1');
CALL sp_teste('FK RESTRICT', 'Excluir forma de pagamento usada', 'BLOQUEIA', NULL, 'DELETE FROM forma_pagamento WHERE forma_pagamento_id = 1');

-- NOT NULL
CALL sp_teste('NOT NULL', 'Cliente sem nome', 'BLOQUEIA', NULL,
 'INSERT INTO cliente (nome,cpf,email,senha,status) VALUES (NULL,''99999999999'',''x@x.com'',''h'',''ATIVO'')');
CALL sp_teste('NOT NULL', 'Solicitação sem destino (RN04 / P13)', 'BLOQUEIA', NULL,
 'INSERT INTO solicitacao (veiculo_id,servico_id,endereco_origem,endereco_destino,distancia_km,valor_estimado) VALUES (1,1,''A'',NULL,1,1)');
CALL sp_teste('NOT NULL', 'Guincho sem modelo', 'BLOQUEIA', NULL,
 'INSERT INTO veiculo_reboque (tipo_guincho_id,placa,modelo,ano,status) VALUES (2,''TST9Z99'',NULL,2020,''DISPONIVEL'')');

-- CHECK de formato
CALL sp_teste('CHECK FORMATO', 'CPF com letras', 'BLOQUEIA', NULL,
 'INSERT INTO cliente (nome,cpf,email,senha,status) VALUES (''X'',''123ABC78901'',''x@x.com'',''h'',''ATIVO'')');
CALL sp_teste('CHECK FORMATO', 'CEP com 7 dígitos', 'BLOQUEIA', NULL,
 'INSERT INTO cliente (nome,cpf,email,senha,status,cep) VALUES (''X'',''99999999999'',''x@x.com'',''h'',''ATIVO'',''0100000'')');
CALL sp_teste('CHECK FORMATO', 'CNPJ com 13 dígitos', 'BLOQUEIA', NULL,
 'INSERT INTO empresa (razao_social, cnpj) VALUES (''X'', ''1234567800010'')');
CALL sp_teste('CHECK FORMATO', 'Telefone com letras', 'BLOQUEIA', NULL,
 'INSERT INTO cliente_telefone VALUES (1, ''11ABCD12345'')');

-- CHECK de domínio
CALL sp_teste('CHECK DOMINIO', 'Status de cliente inexistente (INATIVO)', 'BLOQUEIA', NULL,
 'UPDATE cliente SET status = ''INATIVO'' WHERE cliente_id = 1');
CALL sp_teste('CHECK DOMINIO', 'Status de prestador inexistente (SUSPENSO)', 'BLOQUEIA', NULL,
 'UPDATE prestador_servico SET status = ''SUSPENSO'' WHERE prestador_id = 1');
CALL sp_teste('CHECK DOMINIO', 'Perfil de acesso inexistente', 'BLOQUEIA', NULL,
 'UPDATE funcionario SET perfil_acesso = ''ADMIN'' WHERE funcionario_id = 6');
CALL sp_teste('CHECK DOMINIO', 'Status de solicitação inexistente', 'BLOQUEIA', NULL,
 'UPDATE solicitacao SET status = ''CONCLUIDA'' WHERE solicitacao_id = 1');
CALL sp_teste('CHECK DOMINIO', 'Status de pagamento inexistente', 'BLOQUEIA', NULL,
 'UPDATE pagamento SET status = ''ESTORNADO'' WHERE pagamento_id = 1');
CALL sp_teste('CHECK DOMINIO', 'Resposta de notificação inexistente', 'BLOQUEIA', NULL,
 'INSERT INTO notificacao_prestador (solicitacao_id, prestador_id, resposta) VALUES (23, 1, ''TALVEZ'')');
CALL sp_teste('CHECK DOMINIO', 'Responsável de cancelamento inexistente', 'BLOQUEIA', NULL,
 'UPDATE cancelamento SET responsavel = ''EMPRESA'' WHERE cancelamento_id = 3');
CALL sp_teste('CHECK DOMINIO', 'Status de serviço inexistente', 'BLOQUEIA', NULL,
 'UPDATE servico_reboque SET status = ''PAUSADO'' WHERE servico_id = 1');

-- CHECK de faixa
CALL sp_teste('CHECK FAIXA', 'Nota de avaliação 6', 'BLOQUEIA', NULL, 'INSERT INTO avaliacao (ordem_id, nota) VALUES (11, 6)');
CALL sp_teste('CHECK FAIXA', 'Nota de avaliação 0', 'BLOQUEIA', NULL, 'INSERT INTO avaliacao (ordem_id, nota) VALUES (11, 0)');
CALL sp_teste('CHECK FAIXA', 'Ano do veículo 1899', 'BLOQUEIA', NULL,
 'INSERT INTO veiculo (cliente_id,tipo_veiculo_id,placa,marca,modelo,ano) VALUES (1,2,''TST1A11'',''Ford'',''T'',1899)');
CALL sp_teste('CHECK FAIXA', 'Distância negativa', 'BLOQUEIA', NULL,
 'INSERT INTO solicitacao (veiculo_id,servico_id,endereco_origem,endereco_destino,distancia_km,valor_estimado) VALUES (1,1,''A'',''B'',-5,1)');
CALL sp_teste('CHECK FAIXA', 'Valor base de O.S. negativo', 'BLOQUEIA', @aceite_p1,
 CONCAT(@nova_os, '(23, 4, 1, 1, NULL, -10)'));
CALL sp_teste('CHECK FAIXA', 'Pagamento com valor zero', 'BLOQUEIA', NULL,
 'INSERT INTO pagamento (ordem_id, forma_pagamento_id, valor_pago) VALUES (1, 1, 0)');
CALL sp_teste('CHECK FAIXA', 'Multa negativa', 'BLOQUEIA', NULL,
 'UPDATE cancelamento SET valor_multa = -1 WHERE cancelamento_id = 1');
CALL sp_teste('CHECK FAIXA', 'Capacidade de tipo de guincho zero', 'BLOQUEIA', NULL,
 'INSERT INTO tipo_guincho (descricao, capacidade_max_kg) VALUES (''Teste'', 0)');
CALL sp_teste('CHECK FAIXA', 'Tarifa com valor por km negativo', 'BLOQUEIA', NULL,
 'INSERT INTO tarifa (tipo_veiculo_id,servico_id,valor_base,valor_por_km,vigencia_inicio,status) VALUES (4,2,300,-1,''2027-01-01'',''ATIVA'')');

-- CHECK de regra entre colunas
CALL sp_teste('CHECK REGRA', 'Desconto maior que o valor do serviço', 'BLOQUEIA', NULL,
 'UPDATE ordem_servico SET desconto = 9999 WHERE ordem_id = 1');
CALL sp_teste('CHECK REGRA', 'Fim da O.S. antes do início', 'BLOQUEIA', NULL,
 'UPDATE ordem_servico SET data_hora_fim = ''2026-01-01'' WHERE ordem_id = 1');
CALL sp_teste('CHECK REGRA', 'Vigência final antes da inicial', 'BLOQUEIA', NULL,
 'INSERT INTO tarifa (tipo_veiculo_id,servico_id,valor_base,valor_por_km,vigencia_inicio,vigencia_fim,status) VALUES (4,3,50,1,''2026-12-01'',''2026-11-01'',''ATIVA'')');
CALL sp_teste('CHECK REGRA', 'Vínculo com data_fim antes de data_inicio', 'BLOQUEIA', NULL,
 'INSERT INTO prestador_veiculo_reboque VALUES (6, 1, ''2026-10-10'', ''2026-10-01'', ''ENCERRADO'')');
CALL sp_teste('CHECK REGRA', 'Resposta antes do envio da notificação', 'BLOQUEIA', NULL,
 'INSERT INTO notificacao_prestador VALUES (23, 1, ''2026-10-29 18:10'', ''2026-10-29 18:00'', ''RECUSADA'', DEFAULT)');
CALL sp_teste('CHECK R5', 'Prestador ATIVO sem CNH (cadastro)', 'BLOQUEIA', NULL,
 'INSERT INTO prestador_servico (nome,cpf,telefone,email,status) VALUES (''X'',''99999999999'',''11999999999'',''x@x.com'',''ATIVO'')');
CALL sp_teste('CHECK R5', 'Ativar prestador que não tem CNH', 'BLOQUEIA', NULL,
 'UPDATE prestador_servico SET status = ''ATIVO'' WHERE prestador_id = 10');

-- Colunas calculadas
CALL sp_teste('DERIVADO', 'Gravar valor_total manualmente', 'BLOQUEIA', NULL,
 'UPDATE ordem_servico SET valor_total = 1 WHERE ordem_id = 1');
CALL sp_teste('DERIVADO', 'Gravar aceite_unico manualmente', 'BLOQUEIA', NULL,
 'UPDATE notificacao_prestador SET aceite_unico = 5 WHERE solicitacao_id = 1 AND prestador_id = 2');


-- =====================================================================
-- PARTE C — DEVE ACEITAR (opcionais e cardinalidade mínima 0)
-- =====================================================================
CALL sp_teste('OPCIONAL (0,1)', 'Prestador sem empresa (empresa_id NULL)', 'ACEITA', NULL,
 'INSERT INTO prestador_servico (empresa_id,nome,cpf,telefone,email) VALUES (NULL,''Novo'',''99999999999'',''11999999999'',''novo@x.com'')');
CALL sp_teste('OPCIONAL (0,1)', 'Solicitação aberta pelo app (funcionario_id NULL)', 'ACEITA', NULL,
 'INSERT INTO solicitacao (veiculo_id,servico_id,funcionario_id,endereco_origem,endereco_destino,distancia_km,valor_estimado) VALUES (1,1,NULL,''A'',''B'',5,167.50)');
CALL sp_teste('OPCIONAL (0,1)', 'Histórico pelo prestador/sistema (funcionario_id NULL)', 'ACEITA', NULL,
 'INSERT INTO historico_status (ordem_id, funcionario_id, status, observacao) VALUES (20, NULL, ''EM_ATENDIMENTO'', ''obs'')');
CALL sp_teste('OPCIONAL', 'Prestador EM_ANALISE sem CNH (R5 permite)', 'ACEITA', NULL,
 'INSERT INTO prestador_servico (nome,cpf,telefone,email) VALUES (''Novo'',''99999999999'',''11999999999'',''novo@x.com'')');
CALL sp_teste('OPCIONAL', 'Cliente sem endereço (colunas de endereço nulas)', 'ACEITA', NULL,
 'INSERT INTO cliente (nome,cpf,email,senha,status) VALUES (''Novo'',''99999999999'',''novo@x.com'',''h'',''PENDENTE'')');
CALL sp_teste('OPCIONAL', 'Notificação ainda sem resposta (resposta NULL)', 'ACEITA', NULL,
 'INSERT INTO notificacao_prestador (solicitacao_id, prestador_id) VALUES (23, 1)');
CALL sp_teste('OPCIONAL', 'Vários prestadores RECUSANDO a mesma solicitação', 'ACEITA',
 'INSERT INTO notificacao_prestador VALUES (23, 1, ''2026-10-29 18:01'', ''2026-10-29 18:02'', ''RECUSADA'', DEFAULT)',
 'INSERT INTO notificacao_prestador VALUES (23, 2, ''2026-10-29 18:01'', ''2026-10-29 18:02'', ''RECUSADA'', DEFAULT)');
CALL sp_teste('VALIDO', 'Novo vínculo do mesmo par em outro período', 'ACEITA', NULL,
 'INSERT INTO prestador_veiculo_reboque VALUES (1, 1, ''2027-01-01'', NULL, ''ATIVO'')');


-- =====================================================================
-- PARTE D — GATILHOS (regras R7 a R16)
-- =====================================================================
-- R7
CALL sp_teste('GATILHO R7', 'O.S. para prestador que NÃO aceitou', 'BLOQUEIA', @aceite_p1,
 CONCAT(@nova_os, '(23, 4, 2, 2, NULL, 326)'));
-- R8
CALL sp_teste('GATILHO R8', 'Notificar prestador BLOQUEADO', 'BLOQUEIA', NULL,
 'INSERT INTO notificacao_prestador (solicitacao_id, prestador_id) VALUES (23, 8)');
CALL sp_teste('GATILHO R8', 'Notificar prestador RECUSADO', 'BLOQUEIA', NULL,
 'INSERT INTO notificacao_prestador (solicitacao_id, prestador_id) VALUES (23, 10)');
-- R9
CALL sp_teste('GATILHO R9', 'Guincho sem vínculo com o prestador', 'BLOQUEIA', @aceite_p1,
 CONCAT(@nova_os, '(23, 4, 1, 3, NULL, 326)'));
CALL sp_teste('GATILHO R9', 'Guincho com vínculo já ENCERRADO', 'BLOQUEIA', @aceite_p2,
 CONCAT(@nova_os, '(23, 4, 2, 7, NULL, 326)'));
CALL sp_teste('GATILHO R9', 'Guincho incompatível (carretinha de moto p/ SUV)', 'BLOQUEIA', @aceite_p6,
 CONCAT(@nova_os, '(23, 4, 6, 6, NULL, 326)'));
-- R10
CALL sp_teste('GATILHO R10', 'Tarifa de outro tipo de veículo', 'BLOQUEIA', @aceite_p1,
 CONCAT(@nova_os, '(23, 1, 1, 1, NULL, 326)'));
CALL sp_teste('GATILHO R10', 'Tarifa de outro serviço', 'BLOQUEIA', @aceite_p1,
 CONCAT(@nova_os, '(23, 5, 1, 1, NULL, 326)'));
-- O.S. correta passa por todas as regras
CALL sp_teste('GATILHO R7-R10', 'O.S. correta (aceite, vínculo, compatível, tarifa certa)', 'ACEITA', @aceite_p1,
 CONCAT(@nova_os, '(23, 4, 1, 1, ''2026-10-29 19:30'', 326)'));
-- R11
CALL sp_teste('GATILHO R11', 'Tarifa com vigência sobreposta', 'BLOQUEIA', NULL,
 'INSERT INTO tarifa (tipo_veiculo_id,servico_id,valor_base,valor_por_km,vigencia_inicio,status) VALUES (2,1,170,4,''2026-06-01'',''ATIVA'')');
CALL sp_teste('GATILHO R11', 'Alterar vigência para sobrepor outra', 'BLOQUEIA', NULL,
 'UPDATE tarifa SET vigencia_fim = NULL WHERE tarifa_id = 2');
CALL sp_teste('GATILHO R11', 'Tarifa nova sem sobreposição', 'ACEITA', NULL,
 'INSERT INTO tarifa (tipo_veiculo_id,servico_id,valor_base,valor_por_km,vigencia_inicio,status) VALUES (4,2,300,6,''2027-01-01'',''ATIVA'')');
-- R12
CALL sp_teste('GATILHO R12', 'Guincho com capacidade acima do tipo', 'BLOQUEIA', NULL,
 'INSERT INTO veiculo_reboque (tipo_guincho_id,placa,modelo,ano,capacidade_kg,status) VALUES (2,''TST9Z99'',''X'',2020,5000,''DISPONIVEL'')');
CALL sp_teste('GATILHO R12', 'Aumentar capacidade acima do tipo', 'BLOQUEIA', NULL,
 'UPDATE veiculo_reboque SET capacidade_kg = 9000 WHERE veiculo_reboque_id = 1');
-- R15
CALL sp_teste('GATILHO R15', 'Criar O.S. já FINALIZADA', 'BLOQUEIA', @aceite_p1,
 'INSERT INTO ordem_servico (solicitacao_id,tarifa_id,prestador_id,veiculo_reboque_id,status_atual,valor_base) VALUES (23,4,1,1,''FINALIZADA'',326)');
CALL sp_teste('GATILHO R15', 'Novo status em O.S. FINALIZADA', 'BLOQUEIA', NULL,
 'INSERT INTO historico_status (ordem_id, status) VALUES (1, ''EM_ATENDIMENTO'')');
CALL sp_teste('GATILHO R15', 'Status voltando etapa (EM_ATENDIMENTO -> A_CAMINHO)', 'BLOQUEIA', NULL,
 'INSERT INTO historico_status (ordem_id, status) VALUES (20, ''A_CAMINHO'')');
CALL sp_teste('GATILHO R15', 'Histórico com data anterior ao último', 'BLOQUEIA', NULL,
 'INSERT INTO historico_status (ordem_id, status, data_hora_alteracao) VALUES (20, ''FINALIZADA'', ''2026-10-01'')');
CALL sp_teste('GATILHO R15', 'Mudar status da O.S. sem registrar histórico', 'BLOQUEIA', NULL,
 'UPDATE ordem_servico SET status_atual = ''FINALIZADA'', data_hora_fim = ''2026-10-27 23:40'' WHERE ordem_id = 20');
CALL sp_teste('GATILHO R15', 'Reabrir O.S. FINALIZADA', 'BLOQUEIA', NULL,
 'UPDATE ordem_servico SET status_atual = ''EM_ATENDIMENTO'' WHERE ordem_id = 1');
CALL sp_teste('GATILHO R15', 'Avançar status corretamente', 'ACEITA', NULL,
 'INSERT INTO historico_status (ordem_id, status, data_hora_alteracao) VALUES (20, ''FINALIZADA'', ''2026-10-27 23:40'')');
CALL sp_teste('GATILHO R15', 'Cancelar O.S. a partir de ACEITA', 'ACEITA', NULL,
 'INSERT INTO historico_status (ordem_id, status) VALUES (21, ''CANCELADA'')');
-- R16
CALL sp_teste('GATILHO R16', 'Avaliar O.S. não finalizada', 'BLOQUEIA', NULL,
 'INSERT INTO avaliacao (ordem_id, nota) VALUES (20, 5)');
CALL sp_teste('GATILHO R16', 'Cancelamento de O.S. não cancelada', 'BLOQUEIA', NULL,
 'INSERT INTO cancelamento (ordem_id, responsavel, motivo) VALUES (1, ''CLIENTE'', ''teste'')');
CALL sp_teste('GATILHO R16', 'Solicitação de cliente BLOQUEADO', 'BLOQUEIA', NULL,
 'INSERT INTO solicitacao (veiculo_id,servico_id,endereco_origem,endereco_destino,distancia_km,valor_estimado) VALUES (15,1,''A'',''B'',5,167.50)');
CALL sp_teste('GATILHO SERVICO', 'Solicitação de serviço INATIVO', 'BLOQUEIA', NULL,
 'INSERT INTO solicitacao (veiculo_id,servico_id,endereco_origem,endereco_destino,distancia_km,valor_estimado) VALUES (1,6,''A'',''B'',5,50)');

-- R14: O.S. nasce com histórico de aceite (verificação manual)
START TRANSACTION;
INSERT INTO notificacao_prestador VALUES (23, 1, '2026-10-29 18:01', '2026-10-29 18:03', 'ACEITA', DEFAULT);
INSERT INTO ordem_servico (solicitacao_id, tarifa_id, prestador_id, veiculo_reboque_id, valor_base) VALUES (23, 4, 1, 1, 326);
SET @os_nova = LAST_INSERT_ID();
SET @qtd_hist = (SELECT COUNT(*) FROM historico_status WHERE ordem_id = @os_nova);
SET @st_hist  = (SELECT status FROM historico_status WHERE ordem_id = @os_nova LIMIT 1);
SET @dt_hist  = (SELECT data_hora_alteracao FROM historico_status WHERE ordem_id = @os_nova LIMIT 1);
ROLLBACK;
CALL sp_verifica('GATILHO R14', 'Nova O.S. ganha histórico ACEITA na hora do aceite',
  @qtd_hist = 1 AND @st_hist = 'ACEITA' AND @dt_hist = '2026-10-29 18:03:00',
  CONCAT('registros=', @qtd_hist, ' status=', @st_hist, ' data=', @dt_hist));

-- CASCADE: excluir cliente apaga telefones
START TRANSACTION;
INSERT INTO cliente (cliente_id, nome, cpf, email, senha, status) VALUES (500, 'Temp', '88888888888', 'temp@x.com', 'h', 'PENDENTE');
INSERT INTO cliente_telefone VALUES (500, '11900000000'), (500, '11900000001');
DELETE FROM cliente WHERE cliente_id = 500;
SET @restantes = (SELECT COUNT(*) FROM cliente_telefone WHERE cliente_id = 500);
ROLLBACK;
CALL sp_verifica('CASCADE', 'Excluir cliente apaga os telefones (F3)', @restantes = 0, CONCAT('telefones restantes=', @restantes));

-- Nenhum teste alterou o banco
CALL sp_verifica('ROLLBACK', 'Banco intacto após os testes',
  (SELECT COUNT(*) FROM solicitacao) = 23 AND (SELECT COUNT(*) FROM ordem_servico) = 21
  AND (SELECT COUNT(*) FROM historico_status) = 97 AND (SELECT COUNT(*) FROM tarifa) = 13,
  'contagens de solicitacao, ordem_servico, historico_status e tarifa conferidas');


-- =====================================================================
-- PARTE E — CARDINALIDADES (1,N) E DERIVADO
-- =====================================================================
CALL sp_verifica('CARDINALIDADE', 'Todo cliente tem ao menos 1 telefone (R13)',
  NOT EXISTS (SELECT 1 FROM cliente c WHERE NOT EXISTS (SELECT 1 FROM cliente_telefone t WHERE t.cliente_id = c.cliente_id)), NULL);
CALL sp_verifica('CARDINALIDADE', 'Todo tipo de veículo tem guincho compatível (R13)',
  NOT EXISTS (SELECT 1 FROM tipo_veiculo v WHERE NOT EXISTS (SELECT 1 FROM guincho_tipo_veiculo g WHERE g.tipo_veiculo_id = v.tipo_veiculo_id)), NULL);
CALL sp_verifica('CARDINALIDADE', 'Todo tipo de guincho atende ao menos 1 tipo de veículo',
  NOT EXISTS (SELECT 1 FROM tipo_guincho t WHERE NOT EXISTS (SELECT 1 FROM guincho_tipo_veiculo g WHERE g.tipo_guincho_id = t.tipo_guincho_id)), NULL);
CALL sp_verifica('CARDINALIDADE', 'Toda O.S. tem histórico (R14)',
  NOT EXISTS (SELECT 1 FROM ordem_servico o WHERE NOT EXISTS (SELECT 1 FROM historico_status h WHERE h.ordem_id = o.ordem_id)), NULL);
CALL sp_verifica('CONSISTENCIA', 'status_atual = último histórico em todas as O.S. (R15)',
  NOT EXISTS (SELECT 1 FROM ordem_servico o WHERE o.status_atual <> (SELECT h.status FROM historico_status h
              WHERE h.ordem_id = o.ordem_id ORDER BY h.data_hora_alteracao DESC, h.historico_id DESC LIMIT 1)), NULL);
CALL sp_verifica('DERIVADO', 'valor_total = valor_base + adicionais - desconto',
  NOT EXISTS (SELECT 1 FROM ordem_servico WHERE valor_total <> valor_base + valor_adicionais - desconto), NULL);


-- =====================================================================
-- RESULTADO
-- =====================================================================
SELECT n, categoria, teste, esperado, obtido, resultado, mensagem
FROM resultado_teste ORDER BY n;

SELECT COUNT(*) AS total_testes,
       SUM(resultado = 'APROVADO')  AS aprovados,
       SUM(resultado = 'REPROVADO') AS reprovados
FROM resultado_teste;

SELECT categoria, COUNT(*) AS testes, SUM(resultado = 'APROVADO') AS aprovados
FROM resultado_teste GROUP BY categoria ORDER BY MIN(n);

DROP PROCEDURE IF EXISTS sp_teste;
DROP PROCEDURE IF EXISTS sp_verifica;
