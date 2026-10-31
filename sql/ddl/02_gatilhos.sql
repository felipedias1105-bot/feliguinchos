-- =====================================================================
--  FELIGUINCHOS — DDL 02: GATILHOS E PROCEDURES DE VALIDAÇÃO
--  Regras que envolvem mais de uma tabela:
--   * Endereço (normalização): CEP genérico exige logradouro e bairro
--     informados; CEP com logradouro próprio não aceita logradouro_informado
--   * R7 a R12 e R14 a R16 do Modelo Lógico
--  Executar depois de 01_tabelas.sql
-- =====================================================================
USE feliguinchos;

DELIMITER $$

-- ---------------------------------------------------------------------
-- Validação de endereço (Pessoa e Solicitação)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_valida_endereco(IN p_cep CHAR(8), IN p_logradouro VARCHAR(120),
                                    IN p_bairro VARCHAR(60), IN p_rotulo VARCHAR(30))
proc: BEGIN
    DECLARE v_generico TINYINT;
    DECLARE v_msg      VARCHAR(128);

    IF p_cep IS NULL THEN
        IF p_logradouro IS NOT NULL THEN
            SET v_msg = CONCAT(p_rotulo, ': logradouro_informado so pode ser usado com CEP generico');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
        END IF;
        LEAVE proc;
    END IF;

    SET v_generico = (SELECT cep_generico FROM cep WHERE cep = p_cep);
    IF v_generico IS NULL THEN
        LEAVE proc;   -- CEP inexistente: a FK recusa
    END IF;

    IF v_generico = 1 AND (p_logradouro IS NULL OR p_bairro IS NULL) THEN
        SET v_msg = CONCAT(p_rotulo, ': CEP generico exige logradouro e bairro informados');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    IF v_generico = 0 AND p_logradouro IS NOT NULL THEN
        SET v_msg = CONCAT(p_rotulo, ': CEP com logradouro proprio nao aceita logradouro_informado');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
END$$

-- ---------------------------------------------------------------------
-- Validação da O.S. (R7, R8, R9, R10), usada no INSERT e no UPDATE.
-- Se algum registro referenciado não existir, deixa a FK recusar.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_valida_ordem_servico(IN p_solicitacao INT UNSIGNED, IN p_tarifa INT UNSIGNED,
                                         IN p_prestador INT UNSIGNED, IN p_reboque INT UNSIGNED)
proc: BEGIN
    DECLARE v_data         DATE;
    DECLARE v_tipo_veiculo INT UNSIGNED;
    DECLARE v_servico      INT UNSIGNED;
    DECLARE v_tipo_guincho INT UNSIGNED;
    DECLARE v_status_prest VARCHAR(10);

    SET v_data         = (SELECT DATE(s.data_hora_solicitacao) FROM solicitacao s WHERE s.solicitacao_id = p_solicitacao);
    SET v_tipo_veiculo = (SELECT v.tipo_veiculo_id FROM solicitacao s JOIN veiculo v ON v.veiculo_id = s.veiculo_id
                          WHERE s.solicitacao_id = p_solicitacao);
    SET v_servico      = (SELECT s.servico_id FROM solicitacao s WHERE s.solicitacao_id = p_solicitacao);
    SET v_status_prest = (SELECT status FROM prestador_servico WHERE prestador_id = p_prestador);
    SET v_tipo_guincho = (SELECT tipo_guincho_id FROM veiculo_reboque WHERE veiculo_reboque_id = p_reboque);

    IF v_data IS NULL OR v_status_prest IS NULL OR v_tipo_guincho IS NULL
       OR NOT EXISTS (SELECT 1 FROM tarifa WHERE tarifa_id = p_tarifa) THEN
        LEAVE proc;
    END IF;

    -- R8: só prestador ATIVO recebe O.S.
    IF v_status_prest <> 'ATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R8: somente prestador com status ATIVO pode receber O.S.';
    END IF;

    -- R7: o prestador da O.S. é quem aceitou a solicitação
    IF NOT EXISTS (SELECT 1 FROM notificacao_prestador
                   WHERE solicitacao_id = p_solicitacao AND prestador_id = p_prestador AND resposta = 'ACEITA') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R7: o prestador da O.S. deve ser o que aceitou a solicitacao';
    END IF;

    -- R9a: vínculo vigente entre prestador e guincho na data da solicitação
    IF NOT EXISTS (SELECT 1 FROM prestador_veiculo_reboque
                   WHERE prestador_id = p_prestador AND veiculo_reboque_id = p_reboque
                     AND v_data >= data_inicio AND (data_fim IS NULL OR v_data <= data_fim)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R9: o guincho nao tem vinculo vigente com o prestador';
    END IF;

    -- R9b: tipo de guincho compatível com o tipo do veículo atendido
    IF NOT EXISTS (SELECT 1 FROM guincho_tipo_veiculo
                   WHERE tipo_guincho_id = v_tipo_guincho AND tipo_veiculo_id = v_tipo_veiculo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R9: tipo de guincho incompativel com o tipo do veiculo';
    END IF;

    -- R10: tarifa do mesmo tipo de veículo, mesmo serviço e vigente na data
    IF NOT EXISTS (SELECT 1 FROM tarifa
                   WHERE tarifa_id = p_tarifa AND tipo_veiculo_id = v_tipo_veiculo AND servico_id = v_servico
                     AND v_data >= vigencia_inicio AND (vigencia_fim IS NULL OR v_data <= vigencia_fim)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R10: tarifa nao corresponde ao veiculo/servico ou fora da vigencia';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- PESSOA: regra de endereço
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_pessoa_bi BEFORE INSERT ON pessoa
FOR EACH ROW
BEGIN
    CALL sp_valida_endereco(NEW.cep, NEW.logradouro_informado, NEW.bairro_informado, 'Pessoa');
END$$

CREATE TRIGGER trg_pessoa_bu BEFORE UPDATE ON pessoa
FOR EACH ROW
BEGIN
    CALL sp_valida_endereco(NEW.cep, NEW.logradouro_informado, NEW.bairro_informado, 'Pessoa');
END$$

-- ---------------------------------------------------------------------
-- SOLICITACAO: R16 (cliente ATIVO), serviço ATIVO e endereços
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_solicitacao_bi BEFORE INSERT ON solicitacao
FOR EACH ROW
BEGIN
    IF (SELECT c.status FROM veiculo v JOIN cliente c ON c.cliente_id = v.cliente_id
        WHERE v.veiculo_id = NEW.veiculo_id) <> 'ATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R16: solicitacao permitida somente para cliente ATIVO';
    END IF;
    IF (SELECT status FROM servico_reboque WHERE servico_id = NEW.servico_id) <> 'ATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Servico INATIVO nao aceita novos pedidos';
    END IF;
    CALL sp_valida_endereco(NEW.origem_cep,  NEW.origem_logradouro_informado,  NEW.origem_bairro_informado,  'Origem');
    CALL sp_valida_endereco(NEW.destino_cep, NEW.destino_logradouro_informado, NEW.destino_bairro_informado, 'Destino');
END$$

CREATE TRIGGER trg_solicitacao_bu BEFORE UPDATE ON solicitacao
FOR EACH ROW
BEGIN
    CALL sp_valida_endereco(NEW.origem_cep,  NEW.origem_logradouro_informado,  NEW.origem_bairro_informado,  'Origem');
    CALL sp_valida_endereco(NEW.destino_cep, NEW.destino_logradouro_informado, NEW.destino_bairro_informado, 'Destino');
END$$

-- ---------------------------------------------------------------------
-- NOTIFICACAO: R8 (só prestador ATIVO recebe notificação)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_notificacao_prestador_bi BEFORE INSERT ON notificacao_prestador
FOR EACH ROW
BEGIN
    IF (SELECT status FROM prestador_servico WHERE prestador_id = NEW.prestador_id) <> 'ATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R8: somente prestador com status ATIVO recebe notificacao';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- ORDEM_SERVICO: R7–R10, R14, R15
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_ordem_servico_bi BEFORE INSERT ON ordem_servico
FOR EACH ROW
BEGIN
    IF NEW.status_atual <> 'ACEITA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R15: toda O.S. deve ser criada com status ACEITA';
    END IF;
    CALL sp_valida_ordem_servico(NEW.solicitacao_id, NEW.tarifa_id, NEW.prestador_id, NEW.veiculo_reboque_id);
END$$

-- R14: toda O.S. nasce com o registro de aceite no histórico
CREATE TRIGGER trg_ordem_servico_ai AFTER INSERT ON ordem_servico
FOR EACH ROW
BEGIN
    INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao)
    VALUES (NEW.ordem_id, NULL, 'ACEITA',
            COALESCE((SELECT MAX(data_hora_resposta) FROM notificacao_prestador
                      WHERE solicitacao_id = NEW.solicitacao_id AND resposta = 'ACEITA'), NOW()),
            'Aceite registrado automaticamente (R14)');
END$$

-- R15: O.S. encerrada não muda; status_atual = último histórico
CREATE TRIGGER trg_ordem_servico_bu BEFORE UPDATE ON ordem_servico
FOR EACH ROW
BEGIN
    IF OLD.status_atual IN ('FINALIZADA','CANCELADA') AND NEW.status_atual <> OLD.status_atual THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R15: O.S. FINALIZADA ou CANCELADA nao pode mudar de status';
    END IF;
    IF NEW.status_atual <> OLD.status_atual
       AND NEW.status_atual <> COALESCE((SELECT h.status FROM historico_status h
                                         WHERE h.ordem_id = NEW.ordem_id
                                         ORDER BY h.data_hora_alteracao DESC, h.historico_id DESC LIMIT 1), '') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R15: registre o novo status em historico_status antes de alterar a O.S.';
    END IF;
    IF NEW.solicitacao_id <> OLD.solicitacao_id OR NEW.tarifa_id <> OLD.tarifa_id
       OR NEW.prestador_id <> OLD.prestador_id OR NEW.veiculo_reboque_id <> OLD.veiculo_reboque_id THEN
        CALL sp_valida_ordem_servico(NEW.solicitacao_id, NEW.tarifa_id, NEW.prestador_id, NEW.veiculo_reboque_id);
    END IF;
END$$

-- ---------------------------------------------------------------------
-- HISTORICO_STATUS: R14/R15 (sequência de status)
-- ACEITA > A_CAMINHO > NO_LOCAL > EM_ATENDIMENTO > FINALIZADA;
-- CANCELADA a partir de qualquer status não encerrado
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_historico_status_bi BEFORE INSERT ON historico_status
FOR EACH ROW
BEGIN
    DECLARE v_ultimo      VARCHAR(15);
    DECLARE v_ultima_data DATETIME;

    SET v_ultimo = (SELECT status FROM historico_status WHERE ordem_id = NEW.ordem_id
                    ORDER BY data_hora_alteracao DESC, historico_id DESC LIMIT 1);
    SET v_ultima_data = (SELECT MAX(data_hora_alteracao) FROM historico_status WHERE ordem_id = NEW.ordem_id);

    IF v_ultimo IS NULL THEN
        IF NEW.status <> 'ACEITA' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R14/R15: o primeiro status da O.S. deve ser ACEITA';
        END IF;
    ELSEIF v_ultimo IN ('FINALIZADA','CANCELADA') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R15: O.S. encerrada nao aceita novo status';
    ELSEIF NEW.status <> 'CANCELADA'
       AND FIELD(NEW.status, 'ACEITA','A_CAMINHO','NO_LOCAL','EM_ATENDIMENTO','FINALIZADA')
         < FIELD(v_ultimo,   'ACEITA','A_CAMINHO','NO_LOCAL','EM_ATENDIMENTO','FINALIZADA') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R15: o status da O.S. nao pode voltar para uma etapa anterior';
    ELSEIF NEW.data_hora_alteracao < v_ultima_data THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R15: data do status anterior ao ultimo registro do historico';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- AVALIACAO e CANCELAMENTO: R16
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_avaliacao_bi BEFORE INSERT ON avaliacao
FOR EACH ROW
BEGIN
    IF (SELECT status_atual FROM ordem_servico WHERE ordem_id = NEW.ordem_id) <> 'FINALIZADA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R16: avaliacao permitida somente para O.S. FINALIZADA';
    END IF;
END$$

CREATE TRIGGER trg_cancelamento_bi BEFORE INSERT ON cancelamento
FOR EACH ROW
BEGIN
    IF (SELECT status_atual FROM ordem_servico WHERE ordem_id = NEW.ordem_id) <> 'CANCELADA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R16: cancelamento permitido somente para O.S. CANCELADA';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- TARIFA: R11 (vigências sem sobreposição)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_tarifa_bi BEFORE INSERT ON tarifa
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM tarifa t
               WHERE t.tipo_veiculo_id = NEW.tipo_veiculo_id AND t.servico_id = NEW.servico_id
                 AND t.vigencia_inicio <= COALESCE(NEW.vigencia_fim, '9999-12-31')
                 AND COALESCE(t.vigencia_fim, '9999-12-31') >= NEW.vigencia_inicio) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R11: vigencia sobreposta a outra tarifa do mesmo veiculo e servico';
    END IF;
END$$

CREATE TRIGGER trg_tarifa_bu BEFORE UPDATE ON tarifa
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM tarifa t
               WHERE t.tarifa_id <> NEW.tarifa_id
                 AND t.tipo_veiculo_id = NEW.tipo_veiculo_id AND t.servico_id = NEW.servico_id
                 AND t.vigencia_inicio <= COALESCE(NEW.vigencia_fim, '9999-12-31')
                 AND COALESCE(t.vigencia_fim, '9999-12-31') >= NEW.vigencia_inicio) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R11: vigencia sobreposta a outra tarifa do mesmo veiculo e servico';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- VEICULO_REBOQUE: R12 (capacidade <= capacidade máxima do tipo)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_veiculo_reboque_bi BEFORE INSERT ON veiculo_reboque
FOR EACH ROW
BEGIN
    IF NEW.capacidade_kg > (SELECT capacidade_max_kg FROM tipo_guincho WHERE tipo_guincho_id = NEW.tipo_guincho_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R12: capacidade do guincho acima da capacidade maxima do tipo';
    END IF;
END$$

CREATE TRIGGER trg_veiculo_reboque_bu BEFORE UPDATE ON veiculo_reboque
FOR EACH ROW
BEGIN
    IF NEW.capacidade_kg > (SELECT capacidade_max_kg FROM tipo_guincho WHERE tipo_guincho_id = NEW.tipo_guincho_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R12: capacidade do guincho acima da capacidade maxima do tipo';
    END IF;
END$$

DELIMITER ;
