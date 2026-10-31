-- =====================================================================
--  FELIGUINCHOS — TESTES DE INTEGRIDADE AUTOMATIZADOS
--  Executar DEPOIS do script feliguinchos.sql
--
--  Cada teste roda dentro de uma transação que é desfeita (ROLLBACK),
--  então NENHUM dado do banco é alterado.
--
--  Parte A: comandos INVÁLIDOS -> o banco deve BLOQUEAR
--  Parte B: comandos VÁLIDOS com campos opcionais -> o banco deve ACEITAR
--  Parte C: ações referenciais (CASCADE / SET NULL / RESTRICT)
--  Parte D: cardinalidades (1,n) e coluna derivada (não garantidas por FK)
--  Resultado: tabela final com APROVADO / REPROVADO por teste
-- =====================================================================
USE feliguinchos;

DROP TEMPORARY TABLE IF EXISTS resultado_teste;
CREATE TEMPORARY TABLE resultado_teste (
    n          INT AUTO_INCREMENT PRIMARY KEY,
    categoria  VARCHAR(30),
    teste      VARCHAR(150),
    esperado   VARCHAR(10),
    obtido     VARCHAR(10),
    resultado  VARCHAR(10),
    mensagem   VARCHAR(300)
);

DROP PROCEDURE IF EXISTS sp_teste;
DELIMITER $$
CREATE PROCEDURE sp_teste(IN p_categoria VARCHAR(30), IN p_teste VARCHAR(150),
                          IN p_esperado VARCHAR(10), IN p_sql TEXT)
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
    SET @sql_teste = p_sql;
    PREPARE stmt FROM @sql_teste;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    ROLLBACK;
    INSERT INTO resultado_teste (categoria, teste, esperado, obtido, resultado, mensagem)
    VALUES (p_categoria, p_teste, p_esperado, 'ACEITOU',
            IF(p_esperado = 'ACEITA', 'APROVADO', 'REPROVADO'), NULL);
END$$

DROP PROCEDURE IF EXISTS sp_verifica$$
CREATE PROCEDURE sp_verifica(IN p_categoria VARCHAR(30), IN p_teste VARCHAR(150), IN p_ok BOOLEAN, IN p_info VARCHAR(300))
BEGIN
    INSERT INTO resultado_teste (categoria, teste, esperado, obtido, resultado, mensagem)
    VALUES (p_categoria, p_teste, 'OK', IF(p_ok, 'OK', 'ERRO'), IF(p_ok, 'APROVADO', 'REPROVADO'), p_info);
END$$
DELIMITER ;


-- =====================================================================
-- PARTE A — DEVE BLOQUEAR
-- =====================================================================

-- PK simples
CALL sp_teste('PK', 'Cliente com id_cliente já existente', 'BLOQUEIA',
 'INSERT INTO cliente (id_cliente,nome,cpf,email,senha,logradouro,numero,bairro,cidade,uf,cep) VALUES (1,''X'',''99999999999'',''x@x.com'',''h'',''R'',''1'',''B'',''C'',''SP'',''01000000'')');
CALL sp_teste('PK', 'OS com id_os já existente', 'BLOQUEIA',
 'INSERT INTO ordem_servico (id_os,id_solicitacao,id_tarifa,id_prestador,id_veiculo_reboque,data_inicio,valor_base) VALUES (1,22,9,2,2,''2026-10-28 09:00'',96)');

-- PK composta
CALL sp_teste('PK COMPOSTA', 'Compatibilidade tipo veículo x guincho duplicada', 'BLOQUEIA',
 'INSERT INTO compativel (id_tipo_veiculo,id_tipo_guincho) VALUES (1,1)');
CALL sp_teste('PK COMPOSTA', 'Mesmo prestador notificado 2x na mesma solicitação', 'BLOQUEIA',
 'INSERT INTO notificacao (id_solicitacao,id_prestador,data_envio,status) VALUES (1,1,NOW(),''ENVIADA'')');
CALL sp_teste('PK COMPOSTA', 'Telefone repetido para o mesmo cliente', 'BLOQUEIA',
 'INSERT INTO cliente_telefone (id_cliente,telefone) VALUES (1,''11987654321'')');

-- UNIQUE
CALL sp_teste('UNIQUE', 'CPF de cliente duplicado', 'BLOQUEIA',
 'INSERT INTO cliente (nome,cpf,email,senha,logradouro,numero,bairro,cidade,uf,cep) VALUES (''X'',''32165498701'',''novo@x.com'',''h'',''R'',''1'',''B'',''C'',''SP'',''01000000'')');
CALL sp_teste('UNIQUE', 'E-mail de cliente duplicado', 'BLOQUEIA',
 'INSERT INTO cliente (nome,cpf,email,senha,logradouro,numero,bairro,cidade,uf,cep) VALUES (''X'',''99999999999'',''mariana.almeida@email.com'',''h'',''R'',''1'',''B'',''C'',''SP'',''01000000'')');
CALL sp_teste('UNIQUE', 'Placa de veículo duplicada', 'BLOQUEIA',
 'INSERT INTO veiculo (id_cliente,id_tipo_veiculo,placa,marca,modelo,ano,cor) VALUES (2,2,''BRA2E19'',''Fiat'',''Uno'',2010,''Branco'')');
CALL sp_teste('UNIQUE', 'CNPJ de empresa duplicado', 'BLOQUEIA',
 'INSERT INTO empresa (razao_social,cnpj,telefone,email) VALUES (''X'',''12345678000101'',''1130000000'',''x@x.com'')');
CALL sp_teste('UNIQUE', 'CNH de prestador duplicada', 'BLOQUEIA',
 'INSERT INTO prestador (nome,cpf,cnh,telefone,email) VALUES (''X'',''99999999999'',''01234567801'',''11999999999'',''x@x.com'')');

-- UNIQUE que implementa relacionamento 1:(0,1)
CALL sp_teste('1:1 (UNIQUE FK)', 'Segunda OS para a mesma solicitação (Gera 0,1)', 'BLOQUEIA',
 'INSERT INTO ordem_servico (id_solicitacao,id_tarifa,id_prestador,id_veiculo_reboque,data_inicio,valor_base) VALUES (1,1,1,1,''2026-09-02 10:00'',100)');
CALL sp_teste('1:1 (UNIQUE FK)', 'Segunda avaliação para a mesma OS (Avaliada 0,1)', 'BLOQUEIA',
 'INSERT INTO avaliacao (id_os,nota) VALUES (1,4)');
CALL sp_teste('1:1 (UNIQUE FK)', 'Segundo cancelamento para a mesma OS (Cancelada 0,1)', 'BLOQUEIA',
 'INSERT INTO cancelamento (id_os,tipo_responsavel,motivo) VALUES (8,''CLIENTE'',''teste'')');

-- FK — registro pai inexistente
CALL sp_teste('FK', 'Veículo de cliente inexistente', 'BLOQUEIA',
 'INSERT INTO veiculo (id_cliente,id_tipo_veiculo,placa,marca,modelo,ano,cor) VALUES (999,2,''TST1A11'',''Fiat'',''Uno'',2010,''Branco'')');
CALL sp_teste('FK', 'Veículo com tipo inexistente', 'BLOQUEIA',
 'INSERT INTO veiculo (id_cliente,id_tipo_veiculo,placa,marca,modelo,ano,cor) VALUES (1,999,''TST1A11'',''Fiat'',''Uno'',2010,''Branco'')');
CALL sp_teste('FK', 'Solicitação de veículo inexistente', 'BLOQUEIA',
 'INSERT INTO solicitacao (id_veiculo,id_servico_reboque,endereco_origem) VALUES (999,1,''Rua X'')');
CALL sp_teste('FK', 'OS com tarifa inexistente', 'BLOQUEIA',
 'INSERT INTO ordem_servico (id_solicitacao,id_tarifa,id_prestador,id_veiculo_reboque,data_inicio,valor_base) VALUES (22,999,2,2,''2026-10-28 09:00'',96)');
CALL sp_teste('FK', 'OS com prestador inexistente', 'BLOQUEIA',
 'INSERT INTO ordem_servico (id_solicitacao,id_tarifa,id_prestador,id_veiculo_reboque,data_inicio,valor_base) VALUES (22,9,999,2,''2026-10-28 09:00'',96)');
CALL sp_teste('FK', 'Pagamento com forma de pagamento inexistente', 'BLOQUEIA',
 'INSERT INTO pagamento (id_os,id_forma_pagamento,valor,status) VALUES (1,999,10,''PENDENTE'')');
CALL sp_teste('FK', 'Histórico de OS inexistente', 'BLOQUEIA',
 'INSERT INTO historico_status (id_os,status) VALUES (999,''ABERTA'')');

-- FK — ON DELETE RESTRICT
CALL sp_teste('FK RESTRICT', 'Excluir cliente que possui veículos', 'BLOQUEIA',
 'DELETE FROM cliente WHERE id_cliente = 1');
CALL sp_teste('FK RESTRICT', 'Excluir prestador que executou OS', 'BLOQUEIA',
 'DELETE FROM prestador WHERE id_prestador = 1');
CALL sp_teste('FK RESTRICT', 'Excluir tipo de veículo em uso', 'BLOQUEIA',
 'DELETE FROM tipo_veiculo WHERE id_tipo_veiculo = 2');
CALL sp_teste('FK RESTRICT', 'Excluir forma de pagamento usada', 'BLOQUEIA',
 'DELETE FROM forma_pagamento WHERE id_forma_pagamento = 1');
CALL sp_teste('FK RESTRICT', 'Excluir OS que possui pagamentos', 'BLOQUEIA',
 'DELETE FROM ordem_servico WHERE id_os = 1');
CALL sp_teste('FK RESTRICT', 'Excluir tarifa aplicada em OS', 'BLOQUEIA',
 'DELETE FROM tarifa WHERE id_tarifa = 1');

-- NOT NULL
CALL sp_teste('NOT NULL', 'Cliente sem nome', 'BLOQUEIA',
 'INSERT INTO cliente (nome,cpf,email,senha,logradouro,numero,bairro,cidade,uf,cep) VALUES (NULL,''99999999999'',''x@x.com'',''h'',''R'',''1'',''B'',''C'',''SP'',''01000000'')');
CALL sp_teste('NOT NULL', 'Solicitação sem endereço de origem', 'BLOQUEIA',
 'INSERT INTO solicitacao (id_veiculo,id_servico_reboque,endereco_origem) VALUES (1,1,NULL)');
CALL sp_teste('NOT NULL', 'Cancelamento sem motivo', 'BLOQUEIA',
 'INSERT INTO cancelamento (id_os,tipo_responsavel,motivo) VALUES (20,''CLIENTE'',NULL)');

-- CHECK — formato
CALL sp_teste('CHECK FORMATO', 'CPF com letras', 'BLOQUEIA',
 'INSERT INTO cliente (nome,cpf,email,senha,logradouro,numero,bairro,cidade,uf,cep) VALUES (''X'',''123ABC78901'',''x@x.com'',''h'',''R'',''1'',''B'',''C'',''SP'',''01000000'')');
CALL sp_teste('CHECK FORMATO', 'CEP com 7 dígitos', 'BLOQUEIA',
 'INSERT INTO cliente (nome,cpf,email,senha,logradouro,numero,bairro,cidade,uf,cep) VALUES (''X'',''99999999999'',''x@x.com'',''h'',''R'',''1'',''B'',''C'',''SP'',''0100000'')');
CALL sp_teste('CHECK FORMATO', 'UF inválida', 'BLOQUEIA',
 'INSERT INTO cliente (nome,cpf,email,senha,logradouro,numero,bairro,cidade,uf,cep) VALUES (''X'',''99999999999'',''x@x.com'',''h'',''R'',''1'',''B'',''C'',''S1'',''01000000'')');
CALL sp_teste('CHECK FORMATO', 'E-mail sem @', 'BLOQUEIA',
 'INSERT INTO cliente (nome,cpf,email,senha,logradouro,numero,bairro,cidade,uf,cep) VALUES (''X'',''99999999999'',''email_invalido'',''h'',''R'',''1'',''B'',''C'',''SP'',''01000000'')');
CALL sp_teste('CHECK FORMATO', 'Placa fora do padrão', 'BLOQUEIA',
 'INSERT INTO veiculo (id_cliente,id_tipo_veiculo,placa,marca,modelo,ano,cor) VALUES (1,2,''123ABCD'',''Fiat'',''Uno'',2010,''Branco'')');
CALL sp_teste('CHECK FORMATO', 'CNPJ com 13 dígitos', 'BLOQUEIA',
 'INSERT INTO empresa (razao_social,cnpj,telefone,email) VALUES (''X'',''1234567800010'',''1130000000'',''x@x.com'')');
CALL sp_teste('CHECK FORMATO', 'Telefone com letras', 'BLOQUEIA',
 'INSERT INTO cliente_telefone (id_cliente,telefone) VALUES (1,''11ABCD12345'')');

-- CHECK — domínio (listas de valores)
CALL sp_teste('CHECK DOMINIO', 'Status de solicitação inexistente', 'BLOQUEIA',
 'INSERT INTO solicitacao (id_veiculo,id_servico_reboque,endereco_origem,status) VALUES (1,1,''Rua X'',''PERDIDA'')');
CALL sp_teste('CHECK DOMINIO', 'Status de OS inexistente', 'BLOQUEIA',
 'UPDATE ordem_servico SET status_os = ''PAUSADA'' WHERE id_os = 20');
CALL sp_teste('CHECK DOMINIO', 'Tipo de responsável inválido no cancelamento', 'BLOQUEIA',
 'INSERT INTO cancelamento (id_os,tipo_responsavel,motivo) VALUES (20,''GOVERNO'',''teste'')');
CALL sp_teste('CHECK DOMINIO', 'Perfil de acesso inexistente', 'BLOQUEIA',
 'INSERT INTO funcionario (nome,cpf,email,cargo,perfil_acesso,senha) VALUES (''X'',''99999999999'',''x@x.com'',''C'',''SUPERUSER'',''h'')');
CALL sp_teste('CHECK DOMINIO', 'Categoria de tipo de veículo inválida', 'BLOQUEIA',
 'INSERT INTO tipo_veiculo (descricao,categoria) VALUES (''Bicicleta'',''MINI'')');

-- CHECK — faixas de valores
CALL sp_teste('CHECK FAIXA', 'Nota de avaliação 6', 'BLOQUEIA',
 'INSERT INTO avaliacao (id_os,nota) VALUES (11,6)');
CALL sp_teste('CHECK FAIXA', 'Nota de avaliação 0', 'BLOQUEIA',
 'INSERT INTO avaliacao (id_os,nota) VALUES (11,0)');
CALL sp_teste('CHECK FAIXA', 'Ano do veículo 1900', 'BLOQUEIA',
 'INSERT INTO veiculo (id_cliente,id_tipo_veiculo,placa,marca,modelo,ano,cor) VALUES (1,2,''TST1A11'',''Ford'',''T'',1900,''Preto'')');
CALL sp_teste('CHECK FAIXA', 'Distância negativa', 'BLOQUEIA',
 'INSERT INTO solicitacao (id_veiculo,id_servico_reboque,endereco_origem,distancia_km) VALUES (1,1,''Rua X'',-5)');
CALL sp_teste('CHECK FAIXA', 'Valor base de OS negativo', 'BLOQUEIA',
 'INSERT INTO ordem_servico (id_solicitacao,id_tarifa,id_prestador,id_veiculo_reboque,data_inicio,valor_base) VALUES (22,9,2,2,''2026-10-28 09:00'',-10)');
CALL sp_teste('CHECK FAIXA', 'Pagamento com valor zero', 'BLOQUEIA',
 'INSERT INTO pagamento (id_os,id_forma_pagamento,valor,data_pagamento,status) VALUES (1,1,0,NOW(),''APROVADO'')');
CALL sp_teste('CHECK FAIXA', 'Multa de cancelamento negativa', 'BLOQUEIA',
 'UPDATE cancelamento SET valor_multa = -1 WHERE id_cancelamento = 1');
CALL sp_teste('CHECK FAIXA', 'Capacidade de guincho zero', 'BLOQUEIA',
 'INSERT INTO tipo_guincho (descricao,capacidade_max_kg) VALUES (''Teste'',0)');
CALL sp_teste('CHECK FAIXA', 'Tarifa com valor por km negativo', 'BLOQUEIA',
 'INSERT INTO tarifa (id_tipo_veiculo,id_servico_reboque,valor_base,valor_km,vigencia_inicio) VALUES (2,3,50,-1,''2027-01-01'')');

-- CHECK — regras de negócio entre colunas
CALL sp_teste('CHECK NEGOCIO', 'Desconto maior que o valor do serviço', 'BLOQUEIA',
 'UPDATE ordem_servico SET desconto = 9999 WHERE id_os = 1');
CALL sp_teste('CHECK NEGOCIO', 'OS FINALIZADA sem data de finalização', 'BLOQUEIA',
 'UPDATE ordem_servico SET status_os = ''FINALIZADA'' WHERE id_os = 20');
CALL sp_teste('CHECK NEGOCIO', 'OS em andamento com data de finalização', 'BLOQUEIA',
 'UPDATE ordem_servico SET data_finalizacao = ''2026-10-28 00:00'' WHERE id_os = 20');
CALL sp_teste('CHECK NEGOCIO', 'Previsão anterior ao início da OS', 'BLOQUEIA',
 'INSERT INTO ordem_servico (id_solicitacao,id_tarifa,id_prestador,id_veiculo_reboque,data_inicio,data_previsao,valor_base) VALUES (22,9,2,2,''2026-10-28 09:00'',''2026-10-28 08:00'',96)');
CALL sp_teste('CHECK NEGOCIO', 'Finalização anterior ao início da OS', 'BLOQUEIA',
 'UPDATE ordem_servico SET data_finalizacao = ''2026-01-01 00:00'' WHERE id_os = 1');
CALL sp_teste('CHECK NEGOCIO', 'Vigência final anterior à inicial', 'BLOQUEIA',
 'INSERT INTO tarifa (id_tipo_veiculo,id_servico_reboque,valor_base,valor_km,vigencia_inicio,vigencia_fim) VALUES (2,3,50,1,''2026-12-01'',''2026-11-01'')');
CALL sp_teste('CHECK NEGOCIO', 'Vínculo ENCERRADO sem data_fim', 'BLOQUEIA',
 'INSERT INTO opera (id_prestador,id_veiculo_reboque,data_inicio,status) VALUES (6,1,''2026-10-01'',''ENCERRADO'')');
CALL sp_teste('CHECK NEGOCIO', 'Vínculo ATIVO com data_fim', 'BLOQUEIA',
 'INSERT INTO opera (id_prestador,id_veiculo_reboque,data_inicio,data_fim,status) VALUES (6,1,''2026-10-01'',''2026-10-10'',''ATIVO'')');
CALL sp_teste('CHECK NEGOCIO', 'Notificação ACEITA sem data de resposta', 'BLOQUEIA',
 'INSERT INTO notificacao (id_solicitacao,id_prestador,data_envio,status) VALUES (22,1,NOW(),''ACEITA'')');
CALL sp_teste('CHECK NEGOCIO', 'Resposta antes do envio da notificação', 'BLOQUEIA',
 'INSERT INTO notificacao (id_solicitacao,id_prestador,data_envio,data_resposta,status) VALUES (22,1,''2026-10-28 10:00'',''2026-10-28 09:00'',''RECUSADA'')');
CALL sp_teste('CHECK NEGOCIO', 'Pagamento PENDENTE com data de pagamento', 'BLOQUEIA',
 'INSERT INTO pagamento (id_os,id_forma_pagamento,valor,data_pagamento,status) VALUES (1,1,10,NOW(),''PENDENTE'')');
CALL sp_teste('CHECK NEGOCIO', 'Pagamento APROVADO sem data de pagamento', 'BLOQUEIA',
 'INSERT INTO pagamento (id_os,id_forma_pagamento,valor,status) VALUES (1,1,10,''APROVADO'')');

-- Coluna derivada
CALL sp_teste('DERIVADO', 'Gravar valor_final manualmente', 'BLOQUEIA',
 'UPDATE ordem_servico SET valor_final = 1.00 WHERE id_os = 1');


-- =====================================================================
-- PARTE B — DEVE ACEITAR (campos opcionais / cardinalidade mínima 0)
-- =====================================================================
CALL sp_teste('OPCIONAL (0,1)', 'Prestador autônomo (id_empresa NULL)', 'ACEITA',
 'INSERT INTO prestador (id_empresa,nome,cpf,cnh,telefone,email) VALUES (NULL,''Novo Autonomo'',''99999999999'',''99999999999'',''11999999999'',''autonomo@x.com'')');
CALL sp_teste('OPCIONAL (0,1)', 'Solicitação aberta pelo app (id_funcionario NULL)', 'ACEITA',
 'INSERT INTO solicitacao (id_veiculo,id_servico_reboque,id_funcionario,endereco_origem,distancia_km,valor_estimado) VALUES (1,1,NULL,''Rua X, 10'',5,167.50)');
CALL sp_teste('OPCIONAL (0,1)', 'Histórico registrado pelo sistema (id_funcionario NULL)', 'ACEITA',
 'INSERT INTO historico_status (id_os,id_funcionario,status,observacao) VALUES (20,NULL,''EM_ATENDIMENTO'',''teste'')');
CALL sp_teste('OPCIONAL', 'Socorro no local (endereco_destino NULL)', 'ACEITA',
 'INSERT INTO solicitacao (id_veiculo,id_servico_reboque,endereco_origem,endereco_destino) VALUES (1,4,''Rua X, 10'',NULL)');
CALL sp_teste('OPCIONAL', 'Tarifa sem data de fim (vigência indeterminada)', 'ACEITA',
 'INSERT INTO tarifa (id_tipo_veiculo,id_servico_reboque,valor_base,valor_km,vigencia_inicio,vigencia_fim) VALUES (4,2,300,6,''2027-01-01'',NULL)');
CALL sp_teste('OPCIONAL', 'Pagamento PENDENTE sem data', 'ACEITA',
 'INSERT INTO pagamento (id_os,id_forma_pagamento,valor,status) VALUES (20,1,181.50,''PENDENTE'')');
CALL sp_teste('VALIDO', 'Cadastro completo de cliente válido', 'ACEITA',
 'INSERT INTO cliente (nome,cpf,email,senha,logradouro,numero,bairro,cidade,uf,cep) VALUES (''Cliente Teste'',''99999999999'',''teste.valido@email.com'',SHA2(''x'',256),''Rua A'',''1'',''Centro'',''São Paulo'',''SP'',''01000000'')');
CALL sp_teste('VALIDO', 'Nova OS válida para solicitação sem OS', 'ACEITA',
 'INSERT INTO ordem_servico (id_solicitacao,id_tarifa,id_prestador,id_veiculo_reboque,data_inicio,data_previsao,valor_base) VALUES (22,9,1,1,''2026-10-28 09:00'',''2026-10-28 10:00'',96)');


-- =====================================================================
-- PARTE C — AÇÕES REFERENCIAIS (executa, confere e desfaz)
-- =====================================================================

-- C1. ON DELETE CASCADE: excluir solicitação apaga suas notificações
START TRANSACTION;
SET @antes = (SELECT COUNT(*) FROM notificacao WHERE id_solicitacao = 22);
DELETE FROM solicitacao WHERE id_solicitacao = 22;
SET @depois = (SELECT COUNT(*) FROM notificacao WHERE id_solicitacao = 22);
ROLLBACK;
CALL sp_verifica('CASCADE', 'Excluir solicitação apaga notificações (ON DELETE CASCADE)',
                 @antes > 0 AND @depois = 0, CONCAT('notificações antes=', @antes, ' depois=', @depois));

-- C2. ON DELETE CASCADE: excluir cliente apaga telefones (cliente sem veículo)
START TRANSACTION;
INSERT INTO cliente (id_cliente,nome,cpf,email,senha,logradouro,numero,bairro,cidade,uf,cep)
VALUES (500,'Temp','88888888888','temp@x.com','h','R','1','B','C','SP','01000000');
INSERT INTO cliente_telefone VALUES (500,'11900000000');
DELETE FROM cliente WHERE id_cliente = 500;
SET @depois = (SELECT COUNT(*) FROM cliente_telefone WHERE id_cliente = 500);
ROLLBACK;
CALL sp_verifica('CASCADE', 'Excluir cliente apaga telefones (ON DELETE CASCADE)',
                 @depois = 0, CONCAT('telefones restantes=', @depois));

-- C3. ON DELETE SET NULL: excluir funcionário mantém solicitações, sem autor
START TRANSACTION;
SET @qtd = (SELECT COUNT(*) FROM solicitacao WHERE id_funcionario = 3);
SET @total_antes = (SELECT COUNT(*) FROM solicitacao);
DELETE FROM funcionario WHERE id_funcionario = 3;
SET @restantes = (SELECT COUNT(*) FROM solicitacao WHERE id_funcionario = 3);
SET @total_depois = (SELECT COUNT(*) FROM solicitacao);
ROLLBACK;
CALL sp_verifica('SET NULL', 'Excluir funcionário: solicitações ficam com id_funcionario NULL',
                 @qtd > 0 AND @restantes = 0 AND @total_antes = @total_depois,
                 CONCAT('solicitações do funcionário=', @qtd, ' total antes=', @total_antes, ' depois=', @total_depois));

-- C4. ON DELETE SET NULL: excluir empresa torna prestadores autônomos
START TRANSACTION;
SET @qtd = (SELECT COUNT(*) FROM prestador WHERE id_empresa = 1);
DELETE FROM empresa WHERE id_empresa = 1;
SET @autonomos = (SELECT COUNT(*) FROM prestador WHERE id_prestador IN (1,2) AND id_empresa IS NULL);
ROLLBACK;
CALL sp_verifica('SET NULL', 'Excluir empresa: prestadores viram autônomos',
                 @autonomos = @qtd AND @qtd > 0, CONCAT('prestadores da empresa=', @qtd, ' viraram autônomos=', @autonomos));

-- C5. ON UPDATE CASCADE: alterar PK da empresa propaga para prestador
START TRANSACTION;
UPDATE empresa SET id_empresa = 100 WHERE id_empresa = 2;
SET @propagou = (SELECT COUNT(*) FROM prestador WHERE id_empresa = 100);
ROLLBACK;
CALL sp_verifica('UPDATE CASCADE', 'Alterar PK da empresa propaga para prestador',
                 @propagou = 2, CONCAT('prestadores atualizados=', @propagou));

-- C6. Banco continua intacto após todos os testes
CALL sp_verifica('ROLLBACK', 'Nenhum dado alterado pelos testes',
                 (SELECT COUNT(*) FROM solicitacao) = 22 AND (SELECT COUNT(*) FROM ordem_servico) = 20
                 AND (SELECT COUNT(*) FROM cliente) = 9,
                 'Contagens de solicitacao, ordem_servico e cliente conferidas');


-- =====================================================================
-- PARTE D — CARDINALIDADES (1,n) E DERIVADO
--   FK não garante o "pelo menos 1"; por isso é verificado por consulta.
-- =====================================================================
CALL sp_verifica('CARDINALIDADE', 'Todo cliente tem ao menos 1 telefone (1,n)',
  NOT EXISTS (SELECT 1 FROM cliente c WHERE NOT EXISTS (SELECT 1 FROM cliente_telefone t WHERE t.id_cliente = c.id_cliente)), NULL);
CALL sp_verifica('CARDINALIDADE', 'Toda OS tem ao menos 1 histórico (Registra 1,n)',
  NOT EXISTS (SELECT 1 FROM ordem_servico os WHERE NOT EXISTS (SELECT 1 FROM historico_status h WHERE h.id_os = os.id_os)), NULL);
CALL sp_verifica('CARDINALIDADE', 'Todo tipo de guincho é compatível com ao menos 1 tipo de veículo (1,n)',
  NOT EXISTS (SELECT 1 FROM tipo_guincho g WHERE NOT EXISTS (SELECT 1 FROM compativel c WHERE c.id_tipo_guincho = g.id_tipo_guincho)), NULL);
CALL sp_verifica('CARDINALIDADE', 'Todo tipo de veículo tem ao menos 1 guincho compatível',
  NOT EXISTS (SELECT 1 FROM tipo_veiculo v WHERE NOT EXISTS (SELECT 1 FROM compativel c WHERE c.id_tipo_veiculo = v.id_tipo_veiculo)), NULL);
CALL sp_verifica('DERIVADO', 'valor_final = valor_base + adicionais - desconto em todas as OS',
  NOT EXISTS (SELECT 1 FROM ordem_servico WHERE valor_final <> valor_base + valor_adicionais - desconto), NULL);
CALL sp_verifica('CONSISTENCIA', 'Toda OS usa guincho compatível e prestador vinculado',
  NOT EXISTS (SELECT 1 FROM ordem_servico os
              JOIN solicitacao s ON s.id_solicitacao = os.id_solicitacao
              JOIN veiculo v ON v.id_veiculo = s.id_veiculo
              JOIN veiculo_reboque vr ON vr.id_veiculo_reboque = os.id_veiculo_reboque
              WHERE NOT EXISTS (SELECT 1 FROM compativel c WHERE c.id_tipo_veiculo = v.id_tipo_veiculo AND c.id_tipo_guincho = vr.id_tipo_guincho)
                 OR NOT EXISTS (SELECT 1 FROM opera o WHERE o.id_prestador = os.id_prestador AND o.id_veiculo_reboque = os.id_veiculo_reboque)), NULL);


-- =====================================================================
-- RESULTADO
-- =====================================================================
SELECT n, categoria, teste, esperado, obtido, resultado, mensagem
FROM resultado_teste
ORDER BY n;

SELECT COUNT(*)                          AS total_testes,
       SUM(resultado = 'APROVADO')       AS aprovados,
       SUM(resultado = 'REPROVADO')      AS reprovados
FROM resultado_teste;

SELECT categoria, COUNT(*) AS testes, SUM(resultado = 'APROVADO') AS aprovados
FROM resultado_teste
GROUP BY categoria
ORDER BY MIN(n);

-- Limpeza (as procedures são só para o teste)
DROP PROCEDURE IF EXISTS sp_teste;
DROP PROCEDURE IF EXISTS sp_verifica;
