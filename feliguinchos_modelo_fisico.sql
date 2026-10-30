-- =====================================================================
--  FELIGUINCHOS v2 — MODELO FÍSICO (MySQL 8.0.16+ / MariaDB 10.4+ / XAMPP)
--  Implementação do documento "Modelo Lógico Relacional"
--
--  Decisões físicas (tradução do lógico, que usa tipos genéricos):
--   * INTEGER (PK)            -> INT UNSIGNED AUTO_INCREMENT
--   * TIMESTAMP               -> DATETIME (sem limite de 2038, sem fuso
--                                e sem ON UPDATE automático do MySQL)
--   * BOOLEAN                 -> TINYINT(1) com CHECK (0,1)
--   * Coluna calculada        -> GENERATED ALWAYS AS (...) STORED
--   * "Somente dígitos" (P14) -> CHECK com REGEXP
--   * Índice único parcial R6 -> coluna gerada + UNIQUE (MySQL não tem
--                                índice parcial)
--   * Regras R7 a R12, R14 a R16 -> GATILHOS (o lógico deixou pendente)
--   * Regra R13 (mínimos 1,N)    -> consulta de verificação (auditoria)
--   * ON DELETE RESTRICT em todas as FKs, exceto Cliente_Telefone (CASCADE)
--   * Motor InnoDB, charset utf8mb4
-- =====================================================================

DROP DATABASE IF EXISTS feliguinchos_v2;
CREATE DATABASE feliguinchos_v2
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE feliguinchos_v2;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- 1. CLIENTE
-- ---------------------------------------------------------------------
CREATE TABLE cliente (
    cliente_id     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    nome           VARCHAR(100)  NOT NULL,
    cpf            CHAR(11)      NOT NULL,
    email          VARCHAR(120)  NOT NULL,
    senha          VARCHAR(255)  NOT NULL,
    data_cadastro  DATE          NOT NULL DEFAULT (CURRENT_DATE),
    status         VARCHAR(10)   NOT NULL,
    logradouro     VARCHAR(120)  NULL,
    numero         VARCHAR(10)   NULL,
    complemento    VARCHAR(60)   NULL,
    bairro         VARCHAR(60)   NULL,
    cidade         VARCHAR(60)   NULL,
    uf             CHAR(2)       NULL,
    cep            CHAR(8)       NULL,
    CONSTRAINT pk_cliente        PRIMARY KEY (cliente_id),
    CONSTRAINT uq_cliente_cpf    UNIQUE (cpf),
    CONSTRAINT uq_cliente_email  UNIQUE (email),
    CONSTRAINT ck_cliente_cpf    CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT ck_cliente_cep    CHECK (cep IS NULL OR cep REGEXP '^[0-9]{8}$'),
    CONSTRAINT ck_cliente_status CHECK (status IN ('ATIVO','PENDENTE','BLOQUEADO'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. CLIENTE_TELEFONE (atributo multivalorado)
-- ---------------------------------------------------------------------
CREATE TABLE cliente_telefone (
    cliente_id  INT UNSIGNED NOT NULL,
    telefone    VARCHAR(15)  NOT NULL,
    CONSTRAINT pk_cliente_telefone PRIMARY KEY (cliente_id, telefone),
    CONSTRAINT ck_cliente_telefone CHECK (telefone REGEXP '^[0-9]+$'),
    CONSTRAINT fk_cliente_telefone_cliente FOREIGN KEY (cliente_id)
        REFERENCES cliente (cliente_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. EMPRESA
-- ---------------------------------------------------------------------
CREATE TABLE empresa (
    empresa_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    razao_social  VARCHAR(150) NOT NULL,
    cnpj          CHAR(14)     NOT NULL,
    telefone      VARCHAR(15)  NULL,
    email         VARCHAR(120) NULL,
    CONSTRAINT pk_empresa      PRIMARY KEY (empresa_id),
    CONSTRAINT uq_empresa_cnpj UNIQUE (cnpj),
    CONSTRAINT ck_empresa_cnpj CHECK (cnpj REGEXP '^[0-9]{14}$')
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. TIPO_VEICULO
-- ---------------------------------------------------------------------
CREATE TABLE tipo_veiculo (
    tipo_veiculo_id INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    descricao       VARCHAR(50)   NOT NULL,
    categoria       VARCHAR(50)   NULL,
    peso_max_kg     DECIMAL(8,2)  NULL,
    CONSTRAINT pk_tipo_veiculo      PRIMARY KEY (tipo_veiculo_id),
    CONSTRAINT uq_tipo_veiculo_desc UNIQUE (descricao)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. VEICULO
-- ---------------------------------------------------------------------
CREATE TABLE veiculo (
    veiculo_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cliente_id      INT UNSIGNED NOT NULL,
    tipo_veiculo_id INT UNSIGNED NOT NULL,
    placa           VARCHAR(8)   NOT NULL,
    marca           VARCHAR(50)  NOT NULL,
    modelo          VARCHAR(60)  NOT NULL,
    ano             SMALLINT     NOT NULL,
    cor             VARCHAR(30)  NULL,
    blindado        BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_veiculo          PRIMARY KEY (veiculo_id),
    CONSTRAINT uq_veiculo_placa    UNIQUE (placa),
    CONSTRAINT ck_veiculo_ano      CHECK (ano >= 1900),
    CONSTRAINT ck_veiculo_blindado CHECK (blindado IN (0,1)),
    CONSTRAINT fk_veiculo_cliente FOREIGN KEY (cliente_id)
        REFERENCES cliente (cliente_id) ON DELETE RESTRICT,
    CONSTRAINT fk_veiculo_tipo_veiculo FOREIGN KEY (tipo_veiculo_id)
        REFERENCES tipo_veiculo (tipo_veiculo_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. TIPO_GUINCHO
-- ---------------------------------------------------------------------
CREATE TABLE tipo_guincho (
    tipo_guincho_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    descricao         VARCHAR(50)  NOT NULL,
    capacidade_max_kg DECIMAL(8,2) NULL,
    CONSTRAINT pk_tipo_guincho            PRIMARY KEY (tipo_guincho_id),
    CONSTRAINT uq_tipo_guincho_desc       UNIQUE (descricao),
    CONSTRAINT ck_tipo_guincho_capacidade CHECK (capacidade_max_kg IS NULL OR capacidade_max_kg > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. VEICULO_REBOQUE
-- ---------------------------------------------------------------------
CREATE TABLE veiculo_reboque (
    veiculo_reboque_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    tipo_guincho_id    INT UNSIGNED NOT NULL,
    placa              VARCHAR(8)   NOT NULL,
    marca              VARCHAR(50)  NULL,
    modelo             VARCHAR(60)  NOT NULL,
    ano                SMALLINT     NOT NULL,
    capacidade_kg      DECIMAL(8,2) NULL,
    status             VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_veiculo_reboque       PRIMARY KEY (veiculo_reboque_id),
    CONSTRAINT uq_veiculo_reboque_placa UNIQUE (placa),
    CONSTRAINT ck_veiculo_reboque_ano   CHECK (ano >= 1900),
    CONSTRAINT fk_veiculo_reboque_tipo_guincho FOREIGN KEY (tipo_guincho_id)
        REFERENCES tipo_guincho (tipo_guincho_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. PRESTADOR_SERVICO
-- ---------------------------------------------------------------------
CREATE TABLE prestador_servico (
    prestador_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    empresa_id    INT UNSIGNED NULL,
    nome          VARCHAR(100) NOT NULL,
    cpf           CHAR(11)     NOT NULL,
    telefone      VARCHAR(15)  NOT NULL,
    email         VARCHAR(120) NOT NULL,
    cnh           VARCHAR(11)  NULL,
    status        VARCHAR(10)  NOT NULL DEFAULT 'EM_ANALISE',
    data_cadastro DATE         NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT pk_prestador_servico         PRIMARY KEY (prestador_id),
    CONSTRAINT uq_prestador_servico_cpf     UNIQUE (cpf),
    CONSTRAINT uq_prestador_servico_cnh     UNIQUE (cnh),
    CONSTRAINT ck_prestador_servico_cpf     CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT ck_prestador_servico_status  CHECK (status IN ('EM_ANALISE','ATIVO','RECUSADO','BLOQUEADO')),
    CONSTRAINT ck_prestador_servico_cnh_r5  CHECK (status <> 'ATIVO' OR cnh IS NOT NULL),
    CONSTRAINT fk_prestador_servico_empresa FOREIGN KEY (empresa_id)
        REFERENCES empresa (empresa_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. SERVICO_REBOQUE
-- ---------------------------------------------------------------------
CREATE TABLE servico_reboque (
    servico_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    descricao    VARCHAR(80)  NOT NULL,
    tipo_servico VARCHAR(50)  NOT NULL,
    status       VARCHAR(10)  NOT NULL,
    CONSTRAINT pk_servico_reboque        PRIMARY KEY (servico_id),
    CONSTRAINT uq_servico_reboque_desc   UNIQUE (descricao),
    CONSTRAINT ck_servico_reboque_status CHECK (status IN ('ATIVO','INATIVO'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 10. TARIFA
-- ---------------------------------------------------------------------
CREATE TABLE tarifa (
    tarifa_id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    tipo_veiculo_id     INT UNSIGNED  NOT NULL,
    servico_id          INT UNSIGNED  NOT NULL,
    valor_base          DECIMAL(10,2) NOT NULL,
    valor_por_km        DECIMAL(10,2) NOT NULL,
    adicional_madrugada DECIMAL(10,2) NOT NULL DEFAULT 0,
    adicional_domingo   DECIMAL(10,2) NOT NULL DEFAULT 0,
    adicional_feriado   DECIMAL(10,2) NOT NULL DEFAULT 0,
    adicional_rodovia   DECIMAL(10,2) NOT NULL DEFAULT 0,
    vigencia_inicio     DATE          NOT NULL,
    vigencia_fim        DATE          NULL,
    status              VARCHAR(10)   NOT NULL,
    CONSTRAINT pk_tarifa          PRIMARY KEY (tarifa_id),
    CONSTRAINT uq_tarifa_vigencia UNIQUE (tipo_veiculo_id, servico_id, vigencia_inicio),
    CONSTRAINT ck_tarifa_valores  CHECK (valor_base >= 0 AND valor_por_km >= 0
                                         AND adicional_madrugada >= 0 AND adicional_domingo >= 0
                                         AND adicional_feriado >= 0 AND adicional_rodovia >= 0),
    CONSTRAINT ck_tarifa_vigencia CHECK (vigencia_fim IS NULL OR vigencia_fim >= vigencia_inicio),
    CONSTRAINT fk_tarifa_tipo_veiculo FOREIGN KEY (tipo_veiculo_id)
        REFERENCES tipo_veiculo (tipo_veiculo_id) ON DELETE RESTRICT,
    CONSTRAINT fk_tarifa_servico FOREIGN KEY (servico_id)
        REFERENCES servico_reboque (servico_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 11. FUNCIONARIO
-- ---------------------------------------------------------------------
CREATE TABLE funcionario (
    funcionario_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome           VARCHAR(100) NOT NULL,
    cpf            CHAR(11)     NOT NULL,
    email          VARCHAR(120) NOT NULL,
    cargo          VARCHAR(50)  NOT NULL,
    perfil_acesso  VARCHAR(10)  NOT NULL,
    senha          VARCHAR(255) NOT NULL,
    status         VARCHAR(10)  NOT NULL,
    CONSTRAINT pk_funcionario        PRIMARY KEY (funcionario_id),
    CONSTRAINT uq_funcionario_cpf    UNIQUE (cpf),
    CONSTRAINT uq_funcionario_email  UNIQUE (email),
    CONSTRAINT ck_funcionario_cpf    CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT ck_funcionario_perfil CHECK (perfil_acesso IN ('ATENDENTE','FINANCEIRO','GERENTE')),
    CONSTRAINT ck_funcionario_status CHECK (status IN ('ATIVO','INATIVO'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 12. SOLICITACAO
-- ---------------------------------------------------------------------
CREATE TABLE solicitacao (
    solicitacao_id        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    veiculo_id            INT UNSIGNED  NOT NULL,
    servico_id            INT UNSIGNED  NOT NULL,
    funcionario_id        INT UNSIGNED  NULL,
    data_hora_solicitacao DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    endereco_origem       VARCHAR(255)  NOT NULL,
    endereco_destino      VARCHAR(255)  NOT NULL,
    distancia_km          DECIMAL(8,2)  NOT NULL,
    observacao            VARCHAR(500)  NULL,
    valor_estimado        DECIMAL(10,2) NOT NULL,
    status                VARCHAR(15)   NOT NULL DEFAULT 'SOLICITADA',
    CONSTRAINT pk_solicitacao           PRIMARY KEY (solicitacao_id),
    CONSTRAINT ck_solicitacao_distancia CHECK (distancia_km >= 0),
    CONSTRAINT ck_solicitacao_valor     CHECK (valor_estimado >= 0),
    CONSTRAINT ck_solicitacao_status    CHECK (status IN ('SOLICITADA','EM_ANALISE','ACEITA','SEM_PRESTADOR','CANCELADA')),
    CONSTRAINT fk_solicitacao_veiculo FOREIGN KEY (veiculo_id)
        REFERENCES veiculo (veiculo_id) ON DELETE RESTRICT,
    CONSTRAINT fk_solicitacao_servico FOREIGN KEY (servico_id)
        REFERENCES servico_reboque (servico_id) ON DELETE RESTRICT,
    CONSTRAINT fk_solicitacao_funcionario FOREIGN KEY (funcionario_id)
        REFERENCES funcionario (funcionario_id) ON DELETE RESTRICT,
    INDEX idx_solicitacao_data   (data_hora_solicitacao),
    INDEX idx_solicitacao_status (status)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 13. ORDEM_SERVICO
-- ---------------------------------------------------------------------
CREATE TABLE ordem_servico (
    ordem_id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    solicitacao_id     INT UNSIGNED  NOT NULL,
    tarifa_id          INT UNSIGNED  NOT NULL,
    prestador_id       INT UNSIGNED  NOT NULL,
    veiculo_reboque_id INT UNSIGNED  NOT NULL,
    data_hora_inicio   DATETIME      NULL,
    data_previsao      DATETIME      NULL,
    data_hora_fim      DATETIME      NULL,
    status_atual       VARCHAR(15)   NOT NULL DEFAULT 'ACEITA',
    observacao         VARCHAR(500)  NULL,
    valor_base         DECIMAL(10,2) NOT NULL,
    valor_adicionais   DECIMAL(10,2) NOT NULL DEFAULT 0,
    desconto           DECIMAL(10,2) NOT NULL DEFAULT 0,
    valor_total        DECIMAL(10,2) GENERATED ALWAYS AS (valor_base + valor_adicionais - desconto) STORED,
    CONSTRAINT pk_ordem_servico             PRIMARY KEY (ordem_id),
    CONSTRAINT uq_ordem_servico_solicitacao UNIQUE (solicitacao_id),
    CONSTRAINT ck_ordem_servico_fim         CHECK (data_hora_fim IS NULL OR data_hora_fim >= data_hora_inicio),
    CONSTRAINT ck_ordem_servico_status      CHECK (status_atual IN ('ACEITA','A_CAMINHO','NO_LOCAL','EM_ATENDIMENTO','FINALIZADA','CANCELADA')),
    CONSTRAINT ck_ordem_servico_valores     CHECK (valor_base >= 0 AND valor_adicionais >= 0 AND desconto >= 0),
    CONSTRAINT ck_ordem_servico_desconto    CHECK (desconto <= valor_base + valor_adicionais),
    CONSTRAINT fk_ordem_servico_solicitacao FOREIGN KEY (solicitacao_id)
        REFERENCES solicitacao (solicitacao_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ordem_servico_tarifa FOREIGN KEY (tarifa_id)
        REFERENCES tarifa (tarifa_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ordem_servico_prestador FOREIGN KEY (prestador_id)
        REFERENCES prestador_servico (prestador_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ordem_servico_veiculo_reboque FOREIGN KEY (veiculo_reboque_id)
        REFERENCES veiculo_reboque (veiculo_reboque_id) ON DELETE RESTRICT,
    INDEX idx_ordem_servico_status (status_atual)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 14. HISTORICO_STATUS
-- ---------------------------------------------------------------------
CREATE TABLE historico_status (
    historico_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ordem_id            INT UNSIGNED NOT NULL,
    funcionario_id      INT UNSIGNED NULL,
    status              VARCHAR(15)  NOT NULL,
    data_hora_alteracao DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacao          VARCHAR(500) NULL,
    CONSTRAINT pk_historico_status PRIMARY KEY (historico_id),
    CONSTRAINT ck_historico_status CHECK (status IN ('ACEITA','A_CAMINHO','NO_LOCAL','EM_ATENDIMENTO','FINALIZADA','CANCELADA')),
    CONSTRAINT fk_historico_status_ordem FOREIGN KEY (ordem_id)
        REFERENCES ordem_servico (ordem_id) ON DELETE RESTRICT,
    CONSTRAINT fk_historico_status_funcionario FOREIGN KEY (funcionario_id)
        REFERENCES funcionario (funcionario_id) ON DELETE RESTRICT,
    INDEX idx_historico_ordem_data (ordem_id, data_hora_alteracao)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 15. FORMA_PAGAMENTO
-- ---------------------------------------------------------------------
CREATE TABLE forma_pagamento (
    forma_pagamento_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    descricao          VARCHAR(50)  NOT NULL,
    tipo               VARCHAR(30)  NULL,
    CONSTRAINT pk_forma_pagamento      PRIMARY KEY (forma_pagamento_id),
    CONSTRAINT uq_forma_pagamento_desc UNIQUE (descricao)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 16. PAGAMENTO
-- ---------------------------------------------------------------------
CREATE TABLE pagamento (
    pagamento_id        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    ordem_id            INT UNSIGNED  NOT NULL,
    forma_pagamento_id  INT UNSIGNED  NOT NULL,
    valor_pago          DECIMAL(10,2) NOT NULL,
    data_hora_pagamento DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status              VARCHAR(10)   NOT NULL DEFAULT 'PENDENTE',
    comprovante         VARCHAR(255)  NULL,
    CONSTRAINT pk_pagamento        PRIMARY KEY (pagamento_id),
    CONSTRAINT ck_pagamento_valor  CHECK (valor_pago > 0),
    CONSTRAINT ck_pagamento_status CHECK (status IN ('PENDENTE','APROVADO','RECUSADO')),
    CONSTRAINT fk_pagamento_ordem FOREIGN KEY (ordem_id)
        REFERENCES ordem_servico (ordem_id) ON DELETE RESTRICT,
    CONSTRAINT fk_pagamento_forma FOREIGN KEY (forma_pagamento_id)
        REFERENCES forma_pagamento (forma_pagamento_id) ON DELETE RESTRICT,
    INDEX idx_pagamento_status (status)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 17. AVALIACAO
-- ---------------------------------------------------------------------
CREATE TABLE avaliacao (
    avaliacao_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ordem_id       INT UNSIGNED NOT NULL,
    nota           SMALLINT     NOT NULL,
    comentario     VARCHAR(500) NULL,
    data_avaliacao DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_avaliacao       PRIMARY KEY (avaliacao_id),
    CONSTRAINT uq_avaliacao_ordem UNIQUE (ordem_id),
    CONSTRAINT ck_avaliacao_nota  CHECK (nota BETWEEN 1 AND 5),
    CONSTRAINT fk_avaliacao_ordem FOREIGN KEY (ordem_id)
        REFERENCES ordem_servico (ordem_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 18. CANCELAMENTO
-- ---------------------------------------------------------------------
CREATE TABLE cancelamento (
    cancelamento_id INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    ordem_id        INT UNSIGNED  NOT NULL,
    funcionario_id  INT UNSIGNED  NULL,
    responsavel     VARCHAR(10)   NOT NULL,
    motivo          VARCHAR(255)  NOT NULL,
    data_hora       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor_multa     DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT pk_cancelamento             PRIMARY KEY (cancelamento_id),
    CONSTRAINT uq_cancelamento_ordem       UNIQUE (ordem_id),
    CONSTRAINT ck_cancelamento_responsavel CHECK (responsavel IN ('CLIENTE','PRESTADOR','CENTRAL')),
    CONSTRAINT ck_cancelamento_multa       CHECK (valor_multa >= 0),
    CONSTRAINT fk_cancelamento_ordem FOREIGN KEY (ordem_id)
        REFERENCES ordem_servico (ordem_id) ON DELETE RESTRICT,
    CONSTRAINT fk_cancelamento_funcionario FOREIGN KEY (funcionario_id)
        REFERENCES funcionario (funcionario_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 19. PRESTADOR_VEICULO_REBOQUE (associativa: Opera)
-- ---------------------------------------------------------------------
CREATE TABLE prestador_veiculo_reboque (
    prestador_id       INT UNSIGNED NOT NULL,
    veiculo_reboque_id INT UNSIGNED NOT NULL,
    data_inicio        DATE         NOT NULL,
    data_fim           DATE         NULL,
    status             VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_prestador_veiculo_reboque PRIMARY KEY (prestador_id, veiculo_reboque_id, data_inicio),
    CONSTRAINT ck_prestador_veiculo_reboque_datas CHECK (data_fim IS NULL OR data_fim >= data_inicio),
    CONSTRAINT fk_pvr_prestador FOREIGN KEY (prestador_id)
        REFERENCES prestador_servico (prestador_id) ON DELETE RESTRICT,
    CONSTRAINT fk_pvr_veiculo_reboque FOREIGN KEY (veiculo_reboque_id)
        REFERENCES veiculo_reboque (veiculo_reboque_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 20. GUINCHO_TIPO_VEICULO (associativa: Compatível)
-- ---------------------------------------------------------------------
CREATE TABLE guincho_tipo_veiculo (
    tipo_guincho_id INT UNSIGNED NOT NULL,
    tipo_veiculo_id INT UNSIGNED NOT NULL,
    observacao      VARCHAR(255) NULL,
    CONSTRAINT pk_guincho_tipo_veiculo PRIMARY KEY (tipo_guincho_id, tipo_veiculo_id),
    CONSTRAINT fk_gtv_tipo_guincho FOREIGN KEY (tipo_guincho_id)
        REFERENCES tipo_guincho (tipo_guincho_id) ON DELETE RESTRICT,
    CONSTRAINT fk_gtv_tipo_veiculo FOREIGN KEY (tipo_veiculo_id)
        REFERENCES tipo_veiculo (tipo_veiculo_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 21. NOTIFICACAO_PRESTADOR (associativa: Notifica)
--     aceite_unico implementa R6 (índice único parcial):
--     só recebe valor quando resposta = 'ACEITA'; NULL pode repetir.
-- ---------------------------------------------------------------------
CREATE TABLE notificacao_prestador (
    solicitacao_id     INT UNSIGNED NOT NULL,
    prestador_id       INT UNSIGNED NOT NULL,
    data_hora_envio    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_hora_resposta DATETIME     NULL,
    resposta           VARCHAR(10)  NULL,
    aceite_unico       INT UNSIGNED GENERATED ALWAYS AS
                       (CASE WHEN resposta = 'ACEITA' THEN solicitacao_id END) STORED,
    CONSTRAINT pk_notificacao_prestador PRIMARY KEY (solicitacao_id, prestador_id),
    CONSTRAINT uq_notificacao_um_aceite UNIQUE (aceite_unico),
    CONSTRAINT ck_notificacao_datas     CHECK (data_hora_resposta IS NULL OR data_hora_resposta >= data_hora_envio),
    CONSTRAINT ck_notificacao_resposta  CHECK (resposta IS NULL OR resposta IN ('ACEITA','RECUSADA','EXPIRADA')),
    CONSTRAINT fk_notificacao_solicitacao FOREIGN KEY (solicitacao_id)
        REFERENCES solicitacao (solicitacao_id) ON DELETE RESTRICT,
    CONSTRAINT fk_notificacao_prestador FOREIGN KEY (prestador_id)
        REFERENCES prestador_servico (prestador_id) ON DELETE RESTRICT
) ENGINE=InnoDB;


-- =====================================================================
-- GATILHOS — regras que o Modelo Lógico deixou para gatilho (R7–R16)
-- =====================================================================
DELIMITER $$

-- Validação comum da O.S. (R7, R8, R9, R10), usada no INSERT e no UPDATE.
-- Se algum registro referenciado não existir, deixa a FK recusar.
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
        LEAVE proc;   -- a FK correspondente vai recusar o registro
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

-- R16 (parte 3) + serviço inativo: solicitação só para cliente ATIVO e serviço ATIVO
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
END$$

-- R8: só prestador ATIVO recebe notificação
CREATE TRIGGER trg_notificacao_prestador_bi BEFORE INSERT ON notificacao_prestador
FOR EACH ROW
BEGIN
    IF (SELECT status FROM prestador_servico WHERE prestador_id = NEW.prestador_id) <> 'ATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R8: somente prestador com status ATIVO recebe notificacao';
    END IF;
END$$

-- R7–R10 + R15 (toda O.S. nasce como ACEITA)
CREATE TRIGGER trg_ordem_servico_bi BEFORE INSERT ON ordem_servico
FOR EACH ROW
BEGIN
    IF NEW.status_atual <> 'ACEITA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R15: toda O.S. deve ser criada com status ACEITA';
    END IF;
    CALL sp_valida_ordem_servico(NEW.solicitacao_id, NEW.tarifa_id, NEW.prestador_id, NEW.veiculo_reboque_id);
END$$

-- R14: toda O.S. nasce com o registro de aceite no histórico (mesma transação)
CREATE TRIGGER trg_ordem_servico_ai AFTER INSERT ON ordem_servico
FOR EACH ROW
BEGIN
    INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao)
    VALUES (NEW.ordem_id, NULL, 'ACEITA',
            COALESCE((SELECT MAX(data_hora_resposta) FROM notificacao_prestador
                      WHERE solicitacao_id = NEW.solicitacao_id AND resposta = 'ACEITA'), NOW()),
            'Aceite registrado automaticamente (R14)');
END$$

-- R15: O.S. encerrada não muda; status_atual = último histórico; R7–R10 se mudar FK
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

-- R15: sequência ACEITA > A_CAMINHO > NO_LOCAL > EM_ATENDIMENTO > FINALIZADA;
--      CANCELADA a partir de qualquer status não encerrado; sem voltar no tempo
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

-- R16: avaliação só para O.S. FINALIZADA
CREATE TRIGGER trg_avaliacao_bi BEFORE INSERT ON avaliacao
FOR EACH ROW
BEGIN
    IF (SELECT status_atual FROM ordem_servico WHERE ordem_id = NEW.ordem_id) <> 'FINALIZADA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R16: avaliacao permitida somente para O.S. FINALIZADA';
    END IF;
END$$

-- R16: cancelamento só para O.S. CANCELADA
CREATE TRIGGER trg_cancelamento_bi BEFORE INSERT ON cancelamento
FOR EACH ROW
BEGIN
    IF (SELECT status_atual FROM ordem_servico WHERE ordem_id = NEW.ordem_id) <> 'CANCELADA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R16: cancelamento permitido somente para O.S. CANCELADA';
    END IF;
END$$

-- R11: vigências de tarifa não se sobrepõem (mesmo tipo de veículo e serviço)
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

-- R12: capacidade do guincho não passa da capacidade máxima do tipo
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


-- =====================================================================
-- VIEW DE APOIO — O.S. consolidada
-- =====================================================================
CREATE VIEW vw_ordem_servico_detalhada AS
SELECT  os.ordem_id,
        os.status_atual,
        s.solicitacao_id,
        s.data_hora_solicitacao,
        c.cliente_id,
        c.nome                                AS cliente,
        v.placa                               AS placa_veiculo,
        CONCAT(v.marca, ' ', v.modelo)        AS veiculo,
        tv.descricao                          AS tipo_veiculo,
        sr.descricao                          AS servico,
        p.prestador_id,
        p.nome                                AS prestador,
        COALESCE(e.razao_social, 'Autônomo')  AS empresa,
        vr.placa                              AS placa_guincho,
        tg.descricao                          AS tipo_guincho,
        s.distancia_km,
        os.data_hora_inicio,
        os.data_previsao,
        os.data_hora_fim,
        os.valor_base,
        os.valor_adicionais,
        os.desconto,
        os.valor_total
FROM ordem_servico os
JOIN solicitacao       s  ON s.solicitacao_id      = os.solicitacao_id
JOIN veiculo           v  ON v.veiculo_id          = s.veiculo_id
JOIN cliente           c  ON c.cliente_id          = v.cliente_id
JOIN tipo_veiculo      tv ON tv.tipo_veiculo_id    = v.tipo_veiculo_id
JOIN servico_reboque   sr ON sr.servico_id         = s.servico_id
JOIN prestador_servico p  ON p.prestador_id        = os.prestador_id
LEFT JOIN empresa      e  ON e.empresa_id          = p.empresa_id
JOIN veiculo_reboque   vr ON vr.veiculo_reboque_id = os.veiculo_reboque_id
JOIN tipo_guincho      tg ON tg.tipo_guincho_id    = vr.tipo_guincho_id;
