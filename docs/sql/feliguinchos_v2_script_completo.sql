-- =====================================================================
--  FELIGUINCHOS v2 — SCRIPT SQL COMPLETO
--  Parte 1: modelo físico (CREATE DATABASE, CREATE TABLE, PK, FK, constraints, gatilhos)
--  Parte 2: carga (INSERT)
--  Parte 3: SELECT, JOIN, gerenciais, auditoria, UPDATE, DELETE
--  Depois rode feliguinchos_v2_testes_integridade.sql
-- =====================================================================

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

-- =====================================================================
--  FELIGUINCHOS v2 — CARGA DE DADOS (MASSA DE TESTE)
--  Executar depois de 01_estrutura.sql
--  Período simulado: set/2026 a out/2026 (feriados: 07/09 e 12/10)
--
--  A carga passa pelos gatilhos, então ela própria comprova as regras:
--  notificação aceita antes da O.S. (R7), guincho vinculado e compatível
--  (R9), tarifa correta (R10), histórico em ordem (R14/R15), avaliação
--  só de O.S. finalizada e cancelamento só de O.S. cancelada (R16).
-- =====================================================================
USE feliguinchos_v2;

-- Domínios ------------------------------------------------------------
INSERT INTO forma_pagamento (forma_pagamento_id, descricao, tipo) VALUES
(1, 'PIX',                  'ELETRONICO'),
(2, 'Cartão de Crédito',    'CARTAO'),
(3, 'Cartão de Débito',     'CARTAO'),
(4, 'Dinheiro',             'DINHEIRO'),
(5, 'Faturado (Boleto PJ)', 'FATURADO');

INSERT INTO tipo_veiculo (tipo_veiculo_id, descricao, categoria, peso_max_kg) VALUES
(1, 'Motocicleta',              'LEVE',     300.00),
(2, 'Automóvel de passeio',     'LEVE',    2000.00),
(3, 'SUV / Picape',             'MEDIO',   3000.00),
(4, 'Utilitário / Van',         'MEDIO',   3500.00),
(5, 'Caminhão leve (3/4)',      'PESADO',  8000.00),
(6, 'Caminhão pesado / Ônibus', 'PESADO', 25000.00);

INSERT INTO tipo_guincho (tipo_guincho_id, descricao, capacidade_max_kg) VALUES
(1, 'Carretinha para motos',   400.00),
(2, 'Plataforma (prancha)',   3500.00),
(3, 'Plataforma pesada',      8000.00),
(4, 'Asa delta',              4000.00),
(5, 'Lança pesada',          25000.00);

INSERT INTO guincho_tipo_veiculo (tipo_guincho_id, tipo_veiculo_id, observacao) VALUES
(1, 1, 'Uso preferencial para motos'),
(2, 1, 'Necessita cintas e calço de roda'),
(2, 2, NULL),
(4, 2, 'Evitar em veículos rebaixados'),
(2, 3, 'Conferir peso: limite de 3.500 kg'),
(3, 3, NULL),
(3, 4, NULL),
(4, 4, 'Somente vans até 4.000 kg'),
(3, 5, NULL),
(5, 5, NULL),
(5, 6, 'Único tipo apto para veículos pesados');

INSERT INTO servico_reboque (servico_id, descricao, tipo_servico, status) VALUES
(1, 'Reboque urbano',             'REBOQUE', 'ATIVO'),
(2, 'Reboque rodoviário',         'REBOQUE', 'ATIVO'),
(3, 'Troca de pneu',              'SOCORRO', 'ATIVO'),
(4, 'Carga de bateria',           'SOCORRO', 'ATIVO'),
(5, 'Resgate em vala/ribanceira', 'RESGATE', 'ATIVO'),
(6, 'Pane seca',                  'SOCORRO', 'INATIVO');

-- Tarifas: valor estimado = valor_base + valor_por_km * distância
INSERT INTO tarifa (tarifa_id, tipo_veiculo_id, servico_id, valor_base, valor_por_km,
                    adicional_madrugada, adicional_domingo, adicional_feriado, adicional_rodovia,
                    vigencia_inicio, vigencia_fim, status) VALUES
( 1, 2, 1, 150.00,  3.50,  50.00,  40.00,  60.00,   0.00, '2026-01-01', NULL,         'ATIVA'),
( 2, 2, 2, 200.00,  4.00,  60.00,  50.00,  70.00,  80.00, '2026-01-01', NULL,         'ATIVA'),
( 3, 1, 1, 100.00,  2.50,  40.00,  30.00,  40.00,   0.00, '2026-01-01', NULL,         'ATIVA'),
( 4, 3, 1, 200.00,  4.50,  60.00,  50.00,  70.00,   0.00, '2026-01-01', NULL,         'ATIVA'),
( 5, 3, 2, 260.00,  5.00,  70.00,  60.00,  80.00, 100.00, '2026-01-01', NULL,         'ATIVA'),
( 6, 4, 1, 230.00,  5.00,  70.00,  50.00,  70.00,   0.00, '2026-01-01', NULL,         'ATIVA'),
( 7, 5, 2, 450.00,  8.00, 100.00,  80.00, 120.00, 150.00, '2026-01-01', NULL,         'ATIVA'),
( 8, 6, 2, 800.00, 12.00, 150.00, 120.00, 180.00, 250.00, '2026-01-01', NULL,         'ATIVA'),
( 9, 2, 3,  90.00,  1.50,  30.00,  20.00,  30.00,   0.00, '2026-01-01', NULL,         'ATIVA'),
(10, 2, 4,  80.00,  1.50,  30.00,  20.00,  30.00,   0.00, '2026-01-01', NULL,         'ATIVA'),
(11, 3, 5, 600.00,  6.00, 120.00, 100.00, 150.00, 200.00, '2026-01-01', NULL,         'ATIVA'),
(12, 2, 1, 130.00,  3.00,  45.00,  35.00,  50.00,   0.00, '2025-01-01', '2025-12-31', 'INATIVA'),
(13, 1, 2, 140.00,  3.00,  50.00,  40.00,  50.00,  60.00, '2026-01-01', NULL,         'ATIVA');

-- Empresas e prestadores -----------------------------------------------
INSERT INTO empresa (empresa_id, razao_social, cnpj, telefone, email) VALUES
(1, 'Guinchos Rápido Sul Ltda',     '12345678000101', '1130001000', 'contato@rapidosul.com.br'),
(2, 'Reboque Forte Transportes ME', '23456789000102', '1140002000', 'contato@reboqueforte.com.br'),
(3, 'Auto Socorro Paulista Ltda',   '34567890000103', NULL,         NULL);

INSERT INTO prestador_servico (prestador_id, empresa_id, nome, cpf, telefone, email, cnh, status, data_cadastro) VALUES
(1, 1,    'Carlos Henrique Souza',   '11223344501', '11981110001', 'carlos.souza@rapidosul.com.br',         '01234567801', 'ATIVO',      '2026-01-08'),
(2, 1,    'Marcos Vinícius Lima',    '11223344502', '11981110002', 'marcos.lima@rapidosul.com.br',          '01234567802', 'ATIVO',      '2026-01-08'),
(3, 2,    'José Roberto Alves',      '11223344503', '11981110003', 'jose.alves@reboqueforte.com.br',        '01234567803', 'ATIVO',      '2026-01-20'),
(4, 2,    'Anderson Pereira Costa',  '11223344504', '11981110004', 'anderson.costa@reboqueforte.com.br',    '01234567804', 'ATIVO',      '2026-01-20'),
(5, 3,    'Ricardo Mendes Oliveira', '11223344505', '11981110005', 'ricardo.oliveira@autosocorrosp.com.br', '01234567805', 'ATIVO',      '2026-02-15'),
(6, NULL, 'Paulo Sérgio Ramos',      '11223344506', '11981110006', 'paulo.ramos.guincho@email.com',         '01234567806', 'ATIVO',      '2026-03-10'),
(7, NULL, 'Fábio Augusto Nunes',     '11223344507', '11981110007', 'fabio.nunes.reboque@email.com',         '01234567807', 'ATIVO',      '2026-03-28'),
(8, 3,    'Luiz Fernando Teixeira',  '11223344508', '11981110008', 'luiz.teixeira@autosocorrosp.com.br',    '01234567808', 'BLOQUEADO',  '2026-01-02'),
(9, NULL, 'Rodrigo Alves Pacheco',   '11223344509', '11981110009', 'rodrigo.pacheco@email.com',             NULL,          'EM_ANALISE', '2026-10-25'),
(10,NULL, 'Wagner Dias Moreira',     '11223344510', '11981110010', 'wagner.moreira@email.com',              NULL,          'RECUSADO',   '2026-08-14');

INSERT INTO veiculo_reboque (veiculo_reboque_id, tipo_guincho_id, placa, marca, modelo, ano, capacidade_kg, status) VALUES
(1, 2, 'GUI1A23', 'Volkswagen',    'Delivery 9.170',    2021,  3500.00, 'DISPONIVEL'),
(2, 2, 'GUI2B34', 'Ford',          'Cargo 816',         2020,  3500.00, 'EM_SERVICO'),
(3, 3, 'GUI3C45', 'Mercedes-Benz', 'Accelo 1016',       2022,  8000.00, 'EM_SERVICO'),
(4, 4, 'GUI4D56', 'Iveco',         'Daily 70C17',       2019,  4000.00, 'DISPONIVEL'),
(5, 5, 'GUI5E67', 'Volvo',         'VM 270',            2018, 25000.00, 'DISPONIVEL'),
(6, 1, 'GUI6F78', 'Fiat',          'Strada Carretinha', 2023,   400.00, 'DISPONIVEL'),
(7, 2, 'GUI7G89', NULL,            'HR Plataforma',     2017,  NULL,    'MANUTENCAO');

INSERT INTO prestador_veiculo_reboque (prestador_id, veiculo_reboque_id, data_inicio, data_fim, status) VALUES
(1, 1, '2026-01-10', NULL,         'ATIVO'),
(2, 2, '2026-01-10', NULL,         'ATIVO'),
(2, 7, '2025-06-01', '2025-12-31', 'ENCERRADO'),
(3, 3, '2026-02-01', NULL,         'ATIVO'),
(4, 4, '2026-02-01', NULL,         'ATIVO'),
(5, 5, '2026-03-01', NULL,         'ATIVO'),
(6, 6, '2026-03-15', NULL,         'ATIVO'),
(7, 2, '2026-04-01', NULL,         'ATIVO'),
(5, 3, '2026-05-01', NULL,         'ATIVO'),
(8, 7, '2026-01-05', '2026-08-31', 'ENCERRADO'),
(1, 1, '2025-03-01', '2025-11-30', 'ENCERRADO');   -- mesmo par em outro período (PK com data_inicio)

-- Funcionários ----------------------------------------------------------
INSERT INTO funcionario (funcionario_id, nome, cpf, email, cargo, perfil_acesso, senha, status) VALUES
(1, 'Ana Paula Ferreira',    '10120230301', 'ana.ferreira@feliguinchos.com.br',   'Gerente de Operações',      'GERENTE',    SHA2('Ana@2026', 256),     'ATIVO'),
(2, 'Bruno Carvalho Dias',   '10120230302', 'bruno.dias@feliguinchos.com.br',     'Supervisor de Atendimento', 'GERENTE',    SHA2('Bruno@2026', 256),   'ATIVO'),
(3, 'Camila Rocha Santos',   '10120230303', 'camila.santos@feliguinchos.com.br',  'Atendente',                 'ATENDENTE',  SHA2('Camila@2026', 256),  'ATIVO'),
(4, 'Diego Martins Silva',   '10120230304', 'diego.silva@feliguinchos.com.br',    'Atendente',                 'ATENDENTE',  SHA2('Diego@2026', 256),   'ATIVO'),
(5, 'Eduarda Lopes Gomes',   '10120230305', 'eduarda.gomes@feliguinchos.com.br',  'Analista Financeiro',       'FINANCEIRO', SHA2('Eduarda@2026', 256), 'ATIVO'),
(6, 'Felipe Andrade Barros', '10120230306', 'felipe.barros@feliguinchos.com.br',  'Administrador de Sistemas', 'GERENTE',    SHA2('Felipe@2026', 256),  'ATIVO'),
(7, 'Gabriela Moura Pinto',  '10120230307', 'gabriela.pinto@feliguinchos.com.br', 'Atendente',                 'ATENDENTE',  SHA2('Gabi@2026', 256),    'INATIVO');

-- Clientes ---------------------------------------------------------------
INSERT INTO cliente (cliente_id, nome, cpf, email, senha, data_cadastro, status, logradouro, numero, complemento, bairro, cidade, uf, cep) VALUES
( 1, 'Mariana Costa Almeida',     '32165498701', 'mariana.almeida@email.com',   SHA2('cli001',256), '2026-01-15', 'ATIVO',     'Rua Augusta',                  '1500', 'Apto 82',  'Consolação',     'São Paulo',             'SP', '01304001'),
( 2, 'Rafael Souza Barbosa',      '45678912302', 'rafael.barbosa@email.com',    SHA2('cli002',256), '2026-02-03', 'ATIVO',     'Avenida Paulista',             '2000', NULL,       'Bela Vista',     'São Paulo',             'SP', '01310200'),
( 3, 'Juliana Ribeiro Fernandes', '78912345603', 'juliana.fernandes@email.com', SHA2('cli003',256), '2026-02-20', 'ATIVO',     'Rua Vergueiro',                '3185', 'Casa 2',   'Vila Mariana',   'São Paulo',             'SP', '04101300'),
( 4, 'Thiago Henrique Moreira',   '15975345604', 'thiago.moreira@email.com',    SHA2('cli004',256), '2026-03-01', 'ATIVO',     'Avenida Industrial',           '600',  'Galpão 3', 'Jardim',         'Santo André',           'SP', '09080510'),
( 5, 'Patrícia Gomes Cardoso',    '35715945605', 'patricia.cardoso@email.com',  SHA2('cli005',256), '2026-03-12', 'ATIVO',     'Rua das Flores',               '45',   NULL,       'Centro',         'Guarulhos',             'SP', '07010010'),
( 6, 'Lucas Batista Freitas',     '25836914706', 'lucas.freitas@email.com',     SHA2('cli006',256), '2026-04-02', 'ATIVO',     'Avenida Brigadeiro Faria Lima','3477', 'Conj. 101','Itaim Bibi',     'São Paulo',             'SP', '04538133'),
( 7, 'Fernanda Araújo Monteiro',  '14725836907', 'fernanda.monteiro@email.com', SHA2('cli007',256), '2026-04-18', 'ATIVO',     'Rua Tuiuti',                   '1200', 'Apto 34',  'Tatuapé',        'São Paulo',             'SP', '03081000'),
( 8, 'Gustavo Correia Vieira',    '96385274108', 'gustavo.vieira@email.com',    SHA2('cli008',256), '2026-05-05', 'ATIVO',     'Rodovia Anhanguera, km 25',    'S/N',  NULL,       'Jardim Jaraguá', 'São Paulo',             'SP', '05275000'),
( 9, 'Beatriz Nogueira Castro',   '74185296309', 'beatriz.castro@email.com',    SHA2('cli009',256), '2026-06-10', 'ATIVO',     'Avenida Kennedy',              '880',  NULL,       'Jardim do Mar',  'São Bernardo do Campo', 'SP', '09726253'),
(10, 'Roberto Carlos Duarte',     '85296374110', 'roberto.duarte@email.com',    SHA2('cli010',256), '2026-07-01', 'PENDENTE',  NULL,                           NULL,   NULL,       NULL,             NULL,                    NULL, NULL),
(11, 'Sérgio Lima Prado',         '63985214711', 'sergio.prado@email.com',      SHA2('cli011',256), '2026-05-20', 'BLOQUEADO', 'Rua Domingos de Morais',       '2200', NULL,       'Vila Mariana',   'São Paulo',             'SP', '04036000');

INSERT INTO cliente_telefone (cliente_id, telefone) VALUES
( 1, '11987654321'), ( 1, '1133224455'),
( 2, '11991234567'), ( 2, '11976543210'),
( 3, '11988887777'),
( 4, '11999990001'), ( 4, '1144556677'),
( 5, '11955554444'),
( 6, '11966667777'),
( 7, '11977778888'),
( 8, '11930001000'), ( 8, '1139990000'),
( 9, '11912345678'),
(10, '11900001111'),
(11, '11944443333');

-- Veículos (cliente 10 sem veículo: cardinalidade 0,N) --------------------
INSERT INTO veiculo (veiculo_id, cliente_id, tipo_veiculo_id, placa, marca, modelo, ano, cor, blindado) VALUES
( 1,  1, 2, 'BRA2E19', 'Chevrolet',     'Onix',             2022, 'Branco',   FALSE),
( 2,  1, 1, 'MOT1A11', 'Honda',         'CG 160',           2021, 'Vermelho', FALSE),
( 3,  2, 3, 'SUV3B22', 'Toyota',        'Hilux',            2023, 'Prata',    TRUE),
( 4,  3, 2, 'CAR4C33', 'Hyundai',       'HB20',             2020, 'Preto',    FALSE),
( 5,  4, 4, 'VAN5D44', 'Fiat',          'Ducato',           2019, 'Branco',   FALSE),
( 6,  4, 5, 'CAM6E55', 'Volkswagen',    'Delivery Express', 2021, 'Branco',   FALSE),
( 7,  5, 2, 'CAR7F66', 'Volkswagen',    'Polo',             2023, 'Cinza',    FALSE),
( 8,  6, 3, 'SUV8G77', 'Jeep',          'Compass',          2022, 'Preto',    TRUE),
( 9,  7, 2, 'CAR9H88', 'Renault',       'Kwid',             2019, 'Laranja',  FALSE),
(10,  8, 6, 'ONI1J99', 'Mercedes-Benz', 'Axor 2544',        2017, 'Azul',     FALSE),
(11,  9, 2, 'CAR2K10', 'Fiat',          'Argo',             2021, 'Vermelho', FALSE),
(12,  9, 1, 'MOT3L21', 'Yamaha',        'Fazer 250',        2022, NULL,       FALSE),
(13,  5, 3, 'SUV4M32', 'Honda',         'HR-V',             2024, 'Branco',   FALSE),
(14,  2, 2, 'CAR5N43', 'Toyota',        'Corolla',          2024, 'Preto',    TRUE),
(15, 11, 2, 'CAR6P54', 'Chevrolet',     'Prisma',           2015, 'Prata',    FALSE);

-- Solicitações --------------------------------------------------------------
-- endereco_destino é obrigatório (RN04 / pendência P13): no socorro no local,
-- o destino registra o próprio local do atendimento.
INSERT INTO solicitacao (solicitacao_id, veiculo_id, servico_id, funcionario_id, data_hora_solicitacao,
                         endereco_origem, endereco_destino, distancia_km, observacao, valor_estimado, status) VALUES
( 1,  1, 1, 3,    '2026-09-02 08:15:00', 'Av. Rebouças, 1200 - Pinheiros, São Paulo/SP',          'Oficina Pinheiros - R. dos Pinheiros, 870, São Paulo/SP',            12.00, 'Carro não liga, câmbio travado',             192.00, 'ACEITA'),
( 2,  3, 2, NULL, '2026-09-06 02:30:00', 'Rod. dos Bandeirantes, km 72 - Jundiaí/SP',             'Toyota Concessionária - Av. Rebouças, 3000, São Paulo/SP',           85.00, 'Pane elétrica na rodovia, veículo blindado', 685.00, 'ACEITA'),
( 3,  4, 4, 4,    '2026-09-07 10:00:00', 'R. Vergueiro, 3185 - Vila Mariana, São Paulo/SP',       'No local (mesmo endereço da origem)',                                 5.00, 'Bateria descarregada na garagem',             87.50, 'ACEITA'),
( 4,  5, 1, 3,    '2026-09-10 14:20:00', 'Av. dos Estados, 4500 - Santo André/SP',                'Oficina Diesel ABC - R. das Figueiras, 300, Santo André/SP',         18.00, 'Van de entregas com motor fundido',          320.00, 'ACEITA'),
( 5, 10, 2, 2,    '2026-09-12 16:00:00', 'Rod. Anhanguera, km 98 - Valinhos/SP',                  'Pátio Transportadora - Rod. Anhanguera, km 25, São Paulo/SP',       140.00, 'Caminhão carregado, quebra de eixo',        2480.00, 'ACEITA'),
( 6,  2, 1, NULL, '2026-09-15 19:30:00', 'R. Augusta, 900 - Consolação, São Paulo/SP',            'Moto Center - R. Augusta, 2200, São Paulo/SP',                        8.00, 'Corrente da moto arrebentou',                120.00, 'ACEITA'),
( 7,  7, 3, 4,    '2026-09-18 11:00:00', 'Av. Monteiro Lobato, 1500 - Guarulhos/SP',              'No local (mesmo endereço da origem)',                                 6.00, 'Pneu furado, sem estepe utilizável',          99.00, 'ACEITA'),
( 8,  8, 1, 3,    '2026-09-20 09:00:00', 'Av. Faria Lima, 3477 - Itaim Bibi, São Paulo/SP',       'Jeep Concessionária - Av. Europa, 500, São Paulo/SP',                22.00, 'Luz de injeção acesa',                       299.00, 'CANCELADA'),
( 9,  6, 2, 2,    '2026-09-24 07:30:00', 'Rod. Presidente Dutra, km 210 - Guarulhos/SP',          'Oficina Diesel ABC - R. das Figueiras, 300, Santo André/SP',         60.00, 'Superaquecimento do motor',                  930.00, 'ACEITA'),
(10,  9, 1, NULL, '2026-09-28 03:10:00', 'R. Tuiuti, 300 - Tatuapé, São Paulo/SP',                'Auto Center Tatuapé - R. Itapura, 1000, São Paulo/SP',               15.00, 'Colisão leve, roda danificada',              202.50, 'ACEITA'),
(11, 11, 1, 4,    '2026-10-02 13:00:00', 'Av. Kennedy, 1500 - São Bernardo do Campo/SP',          'Fiat Concessionária - Av. Senador Vergueiro, 2000, São Bernardo do Campo/SP', 10.00, 'Embreagem quebrada',          185.00, 'ACEITA'),
(12, 12, 2, 3,    '2026-10-04 10:30:00', 'Rod. dos Imigrantes, km 40 - São Bernardo do Campo/SP', 'Yamaha Motos - Av. Kennedy, 500, São Bernardo do Campo/SP',          45.00, 'Moto parou na serra',                        275.00, 'ACEITA'),
(13, 13, 5, 2,    '2026-10-06 18:00:00', 'Estrada da Roselândia, 2000 - Cotia/SP',                'Honda Concessionária - Av. Brasil, 1000, São Paulo/SP',              30.00, 'Veículo caiu em vala lateral',               780.00, 'ACEITA'),
(14,  8, 2, NULL, '2026-10-09 05:20:00', 'Rod. Castello Branco, km 70 - Itu/SP',                  'Jeep Concessionária - Av. Europa, 500, São Paulo/SP',                70.00, 'Problema na transmissão',                    610.00, 'ACEITA'),
(15, 14, 1, NULL, '2026-10-12 15:00:00', 'Av. Paulista, 2000 - Bela Vista, São Paulo/SP',         'Toyota Concessionária - Av. Rebouças, 3000, São Paulo/SP',           20.00, 'Veículo blindado, não dá partida',           220.00, 'CANCELADA'),
(16,  5, 1, 3,    '2026-10-14 16:00:00', 'Av. Industrial, 600 - Santo André/SP',                  'Oficina Diesel ABC - R. das Figueiras, 300, Santo André/SP',         25.00, 'Van com freio travado',                      355.00, 'CANCELADA'),
(17,  1, 4, 3,    '2026-10-15 07:50:00', 'R. Augusta, 1500 - Consolação, São Paulo/SP',           'No local (mesmo endereço da origem)',                                 3.00, 'Bateria arriada',                             84.50, 'ACEITA'),
(18,  4, 2, 4,    '2026-10-20 21:00:00', 'Rod. Régis Bittencourt, km 350 - Juquitiba/SP',         'Hyundai Concessionária - R. Vergueiro, 4000, São Paulo/SP',         120.00, 'Correia dentada rompida',                    680.00, 'ACEITA'),
(19, 11, 1, 4,    '2026-10-22 12:00:00', 'Av. Kennedy, 880 - São Bernardo do Campo/SP',           'Fiat Concessionária - Av. Senador Vergueiro, 2000, São Bernardo do Campo/SP', 11.00, 'Nenhum prestador respondeu', 188.50, 'SEM_PRESTADOR'),
(20,  3, 1, 2,    '2026-10-26 10:00:00', 'Av. Paulista, 1000 - Bela Vista, São Paulo/SP',         'Toyota Concessionária - Av. Rebouças, 3000, São Paulo/SP',           14.00, 'Barulho forte na suspensão',                 263.00, 'ACEITA'),
(21,  7, 1, NULL, '2026-10-27 22:15:00', 'Av. Monteiro Lobato, 800 - Guarulhos/SP',               'VW Concessionária - Av. Tiradentes, 1200, Guarulhos/SP',              9.00, 'Motor apagou e não volta',                   181.50, 'ACEITA'),
(22,  9, 3, 3,    '2026-10-28 08:40:00', 'R. Tuiuti, 1200 - Tatuapé, São Paulo/SP',               'No local (mesmo endereço da origem)',                                 4.00, 'Dois pneus furados',                          96.00, 'EM_ANALISE'),
(23, 13, 1, 3,    '2026-10-29 18:00:00', 'Rua das Flores, 45 - Centro, Guarulhos/SP',             'Honda Concessionária - Av. Brasil, 1000, São Paulo/SP',              28.00, 'Ruído no motor, cliente prefere rebocar',    326.00, 'SOLICITADA');

-- Notificações (resposta NULL = ainda sem resposta) -------------------------
INSERT INTO notificacao_prestador (solicitacao_id, prestador_id, data_hora_envio, data_hora_resposta, resposta) VALUES
( 1, 1, '2026-09-02 08:16:00', '2026-09-02 08:18:00', 'ACEITA'),
( 1, 2, '2026-09-02 08:16:00', '2026-09-02 08:17:00', 'RECUSADA'),
( 2, 3, '2026-09-06 02:31:00', '2026-09-06 02:33:00', 'ACEITA'),
( 2, 5, '2026-09-06 02:31:00', NULL,                  'EXPIRADA'),
( 3, 4, '2026-09-07 10:01:00', '2026-09-07 10:03:00', 'ACEITA'),
( 4, 4, '2026-09-10 14:21:00', '2026-09-10 14:24:00', 'ACEITA'),
( 4, 3, '2026-09-10 14:21:00', '2026-09-10 14:22:00', 'RECUSADA'),
( 5, 5, '2026-09-12 16:01:00', '2026-09-12 16:05:00', 'ACEITA'),
( 6, 6, '2026-09-15 19:31:00', '2026-09-15 19:33:00', 'ACEITA'),
( 7, 2, '2026-09-18 11:01:00', '2026-09-18 11:04:00', 'ACEITA'),
( 7, 1, '2026-09-18 11:01:00', '2026-09-18 11:02:00', 'RECUSADA'),
( 8, 1, '2026-09-20 09:01:00', '2026-09-20 09:03:00', 'ACEITA'),
( 9, 3, '2026-09-24 07:31:00', '2026-09-24 07:36:00', 'ACEITA'),
( 9, 5, '2026-09-24 07:31:00', '2026-09-24 07:33:00', 'RECUSADA'),
(10, 7, '2026-09-28 03:11:00', '2026-09-28 03:15:00', 'ACEITA'),
(10, 2, '2026-09-28 03:11:00', NULL,                  'EXPIRADA'),
(11, 1, '2026-10-02 13:01:00', '2026-10-02 13:04:00', 'ACEITA'),
(12, 6, '2026-10-04 10:31:00', '2026-10-04 10:35:00', 'ACEITA'),
(13, 5, '2026-10-06 18:01:00', '2026-10-06 18:06:00', 'ACEITA'),
(14, 5, '2026-10-09 05:21:00', '2026-10-09 05:26:00', 'ACEITA'),
(14, 3, '2026-10-09 05:21:00', '2026-10-09 05:23:00', 'RECUSADA'),
(15, 2, '2026-10-12 15:01:00', '2026-10-12 15:04:00', 'ACEITA'),
(16, 4, '2026-10-14 16:01:00', '2026-10-14 16:05:00', 'ACEITA'),
(17, 7, '2026-10-15 07:51:00', '2026-10-15 07:54:00', 'ACEITA'),
(18, 1, '2026-10-20 21:01:00', '2026-10-20 21:08:00', 'ACEITA'),
(18, 2, '2026-10-20 21:01:00', '2026-10-20 21:03:00', 'RECUSADA'),
(19, 1, '2026-10-22 12:01:00', NULL,                  'EXPIRADA'),
(19, 7, '2026-10-22 12:01:00', NULL,                  'EXPIRADA'),
(20, 3, '2026-10-26 10:01:00', '2026-10-26 10:05:00', 'ACEITA'),
(21, 2, '2026-10-27 22:16:00', '2026-10-27 22:19:00', 'ACEITA'),
(22, 1, '2026-10-28 08:41:00', NULL,                  NULL),
(22, 2, '2026-10-28 08:41:00', NULL,                  NULL);

-- Ordens de serviço ----------------------------------------------------------
-- Todas nascem como ACEITA (R15). O gatilho cria o histórico de aceite (R14).
-- valor_total é calculado pelo banco.
INSERT INTO ordem_servico (ordem_id, solicitacao_id, tarifa_id, prestador_id, veiculo_reboque_id,
                           data_hora_inicio, data_previsao, data_hora_fim, observacao,
                           valor_base, valor_adicionais, desconto) VALUES
( 1,  1,  1, 1, 1, '2026-09-02 08:25:00', '2026-09-02 09:30:00', '2026-09-02 09:20:00', NULL,                                         192.00,   0.00,  0.00),
( 2,  2,  5, 3, 3, '2026-09-06 02:45:00', '2026-09-06 05:00:00', '2026-09-06 05:10:00', 'Adicionais: madrugada + domingo + rodovia',  685.00, 230.00,  0.00),
( 3,  3, 10, 4, 4, '2026-09-07 10:10:00', '2026-09-07 11:00:00', '2026-09-07 10:50:00', 'Adicional de feriado (07/09)',                87.50,  30.00,  0.00),
( 4,  4,  6, 4, 4, '2026-09-10 14:35:00', '2026-09-10 16:00:00', '2026-09-10 15:40:00', 'Desconto cliente PJ recorrente',             320.00,   0.00, 20.00),
( 5,  5,  8, 5, 5, '2026-09-12 16:20:00', '2026-09-12 21:00:00', '2026-09-12 21:45:00', 'Adicional de rodovia',                      2480.00, 250.00,  0.00),
( 6,  6,  3, 6, 6, '2026-09-15 19:45:00', '2026-09-15 20:30:00', '2026-09-15 20:25:00', NULL,                                         120.00,   0.00,  0.00),
( 7,  7,  9, 2, 2, '2026-09-18 11:15:00', '2026-09-18 12:00:00', '2026-09-18 11:55:00', NULL,                                          99.00,   0.00,  0.00),
( 8,  8,  4, 1, 1, '2026-09-20 09:10:00', '2026-09-20 10:30:00', NULL,                  'Cancelada pelo cliente',                     299.00,  50.00,  0.00),
( 9,  9,  7, 3, 3, '2026-09-24 07:50:00', '2026-09-24 11:00:00', '2026-09-24 10:40:00', 'Desconto negociado pelo supervisor',         930.00, 150.00, 50.00),
(10, 10,  1, 7, 2, '2026-09-28 03:25:00', '2026-09-28 04:30:00', '2026-09-28 04:20:00', 'Adicional de madrugada',                     202.50,  50.00,  0.00),
(11, 11,  1, 1, 1, '2026-10-02 13:15:00', '2026-10-02 14:15:00', '2026-10-02 14:05:00', NULL,                                         185.00,   0.00,  0.00),
(12, 12, 13, 6, 6, '2026-10-04 10:50:00', '2026-10-04 13:00:00', '2026-10-04 12:40:00', 'Adicionais: domingo + rodovia',              275.00, 100.00,  0.00),
(13, 13, 11, 5, 3, '2026-10-06 18:20:00', '2026-10-06 21:00:00', '2026-10-06 21:30:00', 'Adicional de rodovia/área rural',            780.00, 200.00,  0.00),
(14, 14,  5, 5, 3, '2026-10-09 05:40:00', '2026-10-09 08:00:00', '2026-10-09 07:50:00', 'Adicionais: madrugada + rodovia',            610.00, 170.00, 30.00),
(15, 15,  1, 2, 2, '2026-10-12 15:10:00', '2026-10-12 16:30:00', NULL,                  'Cancelada por falha do guincho',             220.00,  60.00,  0.00),
(16, 16,  6, 4, 4, '2026-10-14 16:15:00', '2026-10-14 17:45:00', NULL,                  'Cancelada pela central',                     355.00,   0.00,  0.00),
(17, 17, 10, 7, 2, '2026-10-15 08:05:00', '2026-10-15 09:00:00', '2026-10-15 08:40:00', NULL,                                          84.50,   0.00,  0.00),
(18, 18,  2, 1, 1, '2026-10-20 21:20:00', '2026-10-21 00:30:00', '2026-10-21 00:15:00', 'Adicional de rodovia; pagamento dividido',   680.00,  80.00,  0.00),
(19, 20,  4, 3, 3, '2026-10-26 10:15:00', '2026-10-26 12:00:00', NULL,                  NULL,                                         263.00,   0.00,  0.00),
(20, 21,  1, 2, 2, '2026-10-27 22:25:00', '2026-10-27 23:30:00', NULL,                  NULL,                                         181.50,   0.00,  0.00);

-- Histórico de status (em ordem cronológica, como o gatilho R15 exige) -------
-- A_CAMINHO: todas as O.S. (prestador saiu no data_hora_inicio)
INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao)
SELECT ordem_id, NULL, 'A_CAMINHO', data_hora_inicio, 'Prestador iniciou o deslocamento (app)'
FROM ordem_servico ORDER BY ordem_id;

-- NO_LOCAL e EM_ATENDIMENTO: O.S. finalizadas e a O.S. 19 (em atendimento)
INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao)
SELECT ordem_id, NULL, 'NO_LOCAL', data_hora_inicio + INTERVAL 20 MINUTE, 'Prestador chegou ao local (app)'
FROM ordem_servico WHERE data_hora_fim IS NOT NULL OR ordem_id = 19 ORDER BY ordem_id;

INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao)
SELECT ordem_id, NULL, 'EM_ATENDIMENTO', data_hora_inicio + INTERVAL 25 MINUTE, 'Atendimento iniciado (app)'
FROM ordem_servico WHERE data_hora_fim IS NOT NULL OR ordem_id = 19 ORDER BY ordem_id;

-- Intervenções de funcionários (mesmo status, com observação)
INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao) VALUES
( 9, 2, 'EM_ATENDIMENTO', '2026-09-24 09:00:00', 'Desconto de R$ 50,00 aprovado pelo supervisor'),
( 5, 2, 'EM_ATENDIMENTO', '2026-09-12 20:30:00', 'Cliente avisado do atraso: congestionamento na Rod. Anhanguera'),
(13, 2, 'EM_ATENDIMENTO', '2026-10-06 21:10:00', 'Resgate exigiu equipamento adicional (cintas e cabo de aço)');

-- FINALIZADA
INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao)
SELECT ordem_id, NULL, 'FINALIZADA', data_hora_fim, 'Serviço concluído (app)'
FROM ordem_servico WHERE data_hora_fim IS NOT NULL ORDER BY ordem_id;

-- CANCELADA
INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao) VALUES
( 8, 2,    'CANCELADA', '2026-09-20 09:35:00', 'Cliente desistiu após o deslocamento'),
(15, 1,    'CANCELADA', '2026-10-12 15:40:00', 'Guincho apresentou pane no trajeto'),
(16, NULL, 'CANCELADA', '2026-10-14 16:30:00', 'Sem guincho compatível disponível na região');

-- status_atual = último registro do histórico (R15)
UPDATE ordem_servico os
   SET os.status_atual = (SELECT h.status FROM historico_status h
                          WHERE h.ordem_id = os.ordem_id
                          ORDER BY h.data_hora_alteracao DESC, h.historico_id DESC LIMIT 1);

-- Cancelamentos (o nº 3 sem funcionário autorizador -> auditoria) -----------
INSERT INTO cancelamento (cancelamento_id, ordem_id, funcionario_id, responsavel, motivo, data_hora, valor_multa) VALUES
(1,  8, 2,    'CLIENTE',   'Cliente desistiu após o deslocamento do guincho (veículo voltou a funcionar)', '2026-09-20 09:35:00', 50.00),
(2, 15, 1,    'PRESTADOR', 'Guincho apresentou pane mecânica no trajeto',                                 '2026-10-12 15:40:00',  0.00),
(3, 16, NULL, 'CENTRAL',   'Sem guincho compatível disponível na região no horário',                      '2026-10-14 16:30:00',  0.00);

-- Pagamentos ----------------------------------------------------------------
--  O.S. 9  -> 1ª tentativa recusada, 2ª aprovada
--  O.S. 11 -> PENDENTE (auditoria)
--  O.S. 13 -> pago a menor (auditoria)
--  O.S. 18 -> pagamento dividido
--  O.S. 8  -> multa do cancelamento
INSERT INTO pagamento (pagamento_id, ordem_id, forma_pagamento_id, valor_pago, data_hora_pagamento, status, comprovante) VALUES
( 1,  1, 1,  192.00, '2026-09-02 09:25:00', 'APROVADO', 'PIX-20260902-0001'),
( 2,  2, 2,  915.00, '2026-09-06 05:20:00', 'APROVADO', 'CC-AUT-778812'),
( 3,  3, 3,  117.50, '2026-09-07 10:55:00', 'APROVADO', 'CD-AUT-110233'),
( 4,  4, 5,  300.00, '2026-09-25 10:00:00', 'APROVADO', 'BOL-000451'),
( 5,  5, 5, 2730.00, '2026-10-10 09:00:00', 'APROVADO', 'BOL-000467'),
( 6,  6, 4,  120.00, '2026-09-15 20:30:00', 'APROVADO', NULL),
( 7,  7, 1,   99.00, '2026-09-18 12:00:00', 'APROVADO', 'PIX-20260918-0007'),
( 8,  8, 1,   50.00, '2026-09-20 09:50:00', 'APROVADO', 'PIX-20260920-0008'),
( 9,  9, 2, 1030.00, '2026-09-24 10:50:00', 'RECUSADO', 'CC-NEG-990011'),
(10,  9, 1, 1030.00, '2026-09-24 11:05:00', 'APROVADO', 'PIX-20260924-0010'),
(11, 10, 1,  252.50, '2026-09-28 04:25:00', 'APROVADO', 'PIX-20260928-0011'),
(12, 11, 1,  185.00, '2026-10-02 14:10:00', 'PENDENTE', NULL),
(13, 12, 2,  375.00, '2026-10-04 12:45:00', 'APROVADO', 'CC-AUT-781200'),
(14, 13, 2,  900.00, '2026-10-06 21:40:00', 'APROVADO', 'CC-AUT-781355'),
(15, 14, 1,  750.00, '2026-10-09 08:00:00', 'APROVADO', 'PIX-20261009-0015'),
(16, 17, 3,   84.50, '2026-10-15 08:45:00', 'APROVADO', 'CD-AUT-120044'),
(17, 18, 1,  400.00, '2026-10-21 00:20:00', 'APROVADO', 'PIX-20261021-0017'),
(18, 18, 2,  360.00, '2026-10-21 00:22:00', 'APROVADO', 'CC-AUT-781990');

-- Avaliações (O.S. 11 e 17 finalizadas sem avaliação: cardinalidade 0,1) ----
INSERT INTO avaliacao (avaliacao_id, ordem_id, nota, comentario, data_avaliacao) VALUES
( 1,  1, 5, 'Atendimento rápido e prestador muito educado.',       '2026-09-02 10:00:00'),
( 2,  2, 4, 'Bom atendimento de madrugada, preço um pouco alto.',  '2026-09-06 09:00:00'),
( 3,  3, 5, 'Resolveram em poucos minutos, mesmo no feriado.',     '2026-09-07 12:00:00'),
( 4,  4, 4, NULL,                                                   '2026-09-11 08:00:00'),
( 5,  5, 3, 'Chegou depois do horário previsto.',                  '2026-09-13 10:00:00'),
( 6,  6, 5, 'Cuidado excelente com a moto.',                       '2026-09-15 21:00:00'),
( 7,  7, 5, 'Troca de pneu impecável.',                            '2026-09-18 13:00:00'),
( 8,  9, 4, 'Serviço bom, só tive problema com o cartão.',         '2026-09-25 09:00:00'),
( 9, 10, 5, 'Salvou minha madrugada!',                             '2026-09-28 08:00:00'),
(10, 12, 4, 'Moto transportada com segurança.',                    '2026-10-04 14:00:00'),
(11, 13, 2, 'Resgate demorou muito e o valor foi alto.',           '2026-10-07 09:00:00'),
(12, 14, 5, 'Excelente, mesmo de madrugada na rodovia.',           '2026-10-09 09:30:00'),
(13, 18, 5, 'Prestador muito atencioso na estrada.',               '2026-10-21 08:00:00');

-- =====================================================================
--  FELIGUINCHOS v2 — SELECT, JOIN, GERENCIAIS, AUDITORIA, UPDATE, DELETE
--  Executar depois de 01_estrutura.sql e 02_carga.sql
-- =====================================================================
USE feliguinchos_v2;


-- =====================================================================
-- A. SELECT — CONSULTAS SIMPLES
-- =====================================================================

-- A1. Clientes ativos
SELECT cliente_id, nome, email, cidade, uf, data_cadastro
FROM cliente
WHERE status = 'ATIVO'
ORDER BY nome;

-- A2. Veículos blindados
SELECT veiculo_id, placa, marca, modelo, ano
FROM veiculo
WHERE blindado = TRUE;

-- A3. Prestadores autônomos (sem empresa)
SELECT prestador_id, nome, telefone, status
FROM prestador_servico
WHERE empresa_id IS NULL;

-- A4. Prestadores aguardando análise de cadastro
SELECT prestador_id, nome, cnh, data_cadastro
FROM prestador_servico
WHERE status = 'EM_ANALISE';

-- A5. Solicitações sem O.S. ainda (solicitadas ou em análise)
SELECT solicitacao_id, data_hora_solicitacao, endereco_origem, status
FROM solicitacao
WHERE status IN ('SOLICITADA','EM_ANALISE')
ORDER BY data_hora_solicitacao;

-- A6. Tarifas vigentes hoje
SELECT tarifa_id, tipo_veiculo_id, servico_id, valor_base, valor_por_km, vigencia_inicio, vigencia_fim
FROM tarifa
WHERE CURDATE() BETWEEN vigencia_inicio AND COALESCE(vigencia_fim, '9999-12-31');

-- A7. Simulação de orçamento: automóvel, reboque urbano, 15 km, num domingo
SET @tipo_veiculo = 2, @servico = 1, @km = 15;
SELECT tarifa_id,
       valor_base,
       valor_por_km * @km                                    AS valor_distancia,
       adicional_domingo                                     AS adicional,
       valor_base + valor_por_km * @km + adicional_domingo   AS orcamento_total
FROM tarifa
WHERE tipo_veiculo_id = @tipo_veiculo
  AND servico_id      = @servico
  AND CURDATE() BETWEEN vigencia_inicio AND COALESCE(vigencia_fim, '9999-12-31');


-- =====================================================================
-- B. JOIN
-- =====================================================================

-- B1. Clientes com telefones e quantidade de veículos (LEFT JOIN)
SELECT c.cliente_id, c.nome, c.status,
       GROUP_CONCAT(DISTINCT ct.telefone SEPARATOR ' / ') AS telefones,
       COUNT(DISTINCT v.veiculo_id)                       AS qtd_veiculos
FROM cliente c
LEFT JOIN cliente_telefone ct ON ct.cliente_id = c.cliente_id
LEFT JOIN veiculo v           ON v.cliente_id  = c.cliente_id
GROUP BY c.cliente_id, c.nome, c.status
ORDER BY c.nome;

-- B2. Veículos com proprietário e tipo
SELECT v.placa, v.marca, v.modelo, tv.descricao AS tipo, tv.categoria, c.nome AS proprietario
FROM veiculo v
JOIN cliente c       ON c.cliente_id       = v.cliente_id
JOIN tipo_veiculo tv ON tv.tipo_veiculo_id = v.tipo_veiculo_id
ORDER BY c.nome, v.placa;

-- B3. Solicitações completas (quem abriu: funcionário ou aplicativo)
SELECT s.solicitacao_id, s.data_hora_solicitacao, c.nome AS cliente, v.placa,
       sr.descricao AS servico, COALESCE(f.nome, 'Aplicativo') AS aberta_por,
       s.distancia_km, s.valor_estimado, s.status
FROM solicitacao s
JOIN veiculo v          ON v.veiculo_id     = s.veiculo_id
JOIN cliente c          ON c.cliente_id     = v.cliente_id
JOIN servico_reboque sr ON sr.servico_id    = s.servico_id
LEFT JOIN funcionario f ON f.funcionario_id = s.funcionario_id
ORDER BY s.data_hora_solicitacao;

-- B4. Ordens de serviço detalhadas (JOIN em 9 tabelas)
SELECT os.ordem_id, os.status_atual, c.nome AS cliente, v.placa AS placa_cliente,
       tv.descricao AS tipo_veiculo, sr.descricao AS servico, p.nome AS prestador,
       COALESCE(e.razao_social, 'Autônomo') AS empresa, vr.placa AS placa_guincho,
       tg.descricao AS tipo_guincho, os.valor_total
FROM ordem_servico os
JOIN solicitacao s       ON s.solicitacao_id      = os.solicitacao_id
JOIN veiculo v           ON v.veiculo_id          = s.veiculo_id
JOIN cliente c           ON c.cliente_id          = v.cliente_id
JOIN tipo_veiculo tv     ON tv.tipo_veiculo_id    = v.tipo_veiculo_id
JOIN servico_reboque sr  ON sr.servico_id         = s.servico_id
JOIN prestador_servico p ON p.prestador_id        = os.prestador_id
LEFT JOIN empresa e      ON e.empresa_id          = p.empresa_id
JOIN veiculo_reboque vr  ON vr.veiculo_reboque_id = os.veiculo_reboque_id
JOIN tipo_guincho tg     ON tg.tipo_guincho_id    = vr.tipo_guincho_id
ORDER BY os.ordem_id;

-- B5. Compatibilidade tipo de guincho x tipo de veículo
SELECT tg.descricao AS tipo_guincho, tg.capacidade_max_kg, tv.descricao AS tipo_veiculo, gtv.observacao
FROM guincho_tipo_veiculo gtv
JOIN tipo_guincho tg ON tg.tipo_guincho_id = gtv.tipo_guincho_id
JOIN tipo_veiculo tv ON tv.tipo_veiculo_id = gtv.tipo_veiculo_id
ORDER BY tv.tipo_veiculo_id, tg.tipo_guincho_id;

-- B6. Prestadores e guinchos que operam (histórico de vínculos)
SELECT p.nome AS prestador, COALESCE(e.razao_social, 'Autônomo') AS empresa,
       vr.placa, vr.modelo, tg.descricao AS tipo_guincho,
       pvr.data_inicio, pvr.data_fim, pvr.status
FROM prestador_veiculo_reboque pvr
JOIN prestador_servico p ON p.prestador_id        = pvr.prestador_id
LEFT JOIN empresa e      ON e.empresa_id          = p.empresa_id
JOIN veiculo_reboque vr  ON vr.veiculo_reboque_id = pvr.veiculo_reboque_id
JOIN tipo_guincho tg     ON tg.tipo_guincho_id    = vr.tipo_guincho_id
ORDER BY p.nome, pvr.data_inicio;

-- B7. Linha do tempo de uma O.S. (O.S. 5)
SELECT h.data_hora_alteracao, h.status, COALESCE(f.nome, 'Prestador/Sistema') AS responsavel, h.observacao
FROM historico_status h
LEFT JOIN funcionario f ON f.funcionario_id = h.funcionario_id
WHERE h.ordem_id = 5
ORDER BY h.data_hora_alteracao, h.historico_id;

-- B8. Notificações e tempo de resposta
SELECT n.solicitacao_id, p.nome AS prestador, n.data_hora_envio, n.data_hora_resposta,
       COALESCE(n.resposta, 'SEM RESPOSTA') AS resposta,
       TIMESTAMPDIFF(MINUTE, n.data_hora_envio, n.data_hora_resposta) AS minutos_resposta
FROM notificacao_prestador n
JOIN prestador_servico p ON p.prestador_id = n.prestador_id
ORDER BY n.solicitacao_id, n.prestador_id;

-- B9. Pagamentos com forma e cliente
SELECT pg.pagamento_id, pg.ordem_id, c.nome AS cliente, fp.descricao AS forma,
       pg.valor_pago, pg.data_hora_pagamento, pg.status
FROM pagamento pg
JOIN forma_pagamento fp ON fp.forma_pagamento_id = pg.forma_pagamento_id
JOIN ordem_servico os   ON os.ordem_id           = pg.ordem_id
JOIN solicitacao s      ON s.solicitacao_id      = os.solicitacao_id
JOIN veiculo v          ON v.veiculo_id          = s.veiculo_id
JOIN cliente c          ON c.cliente_id          = v.cliente_id
ORDER BY pg.data_hora_pagamento;

-- B10. PROCESSO: quem pode atender a solicitação 23?
--      Prestador ATIVO, vínculo vigente, guincho compatível e disponível.
SELECT s.solicitacao_id, p.prestador_id, p.nome AS prestador, vr.placa AS guincho, tg.descricao AS tipo_guincho
FROM solicitacao s
JOIN veiculo v                    ON v.veiculo_id          = s.veiculo_id
JOIN guincho_tipo_veiculo gtv     ON gtv.tipo_veiculo_id   = v.tipo_veiculo_id
JOIN veiculo_reboque vr           ON vr.tipo_guincho_id    = gtv.tipo_guincho_id
JOIN tipo_guincho tg              ON tg.tipo_guincho_id    = vr.tipo_guincho_id
JOIN prestador_veiculo_reboque pv ON pv.veiculo_reboque_id = vr.veiculo_reboque_id
                                 AND pv.data_fim IS NULL
JOIN prestador_servico p          ON p.prestador_id        = pv.prestador_id
WHERE s.solicitacao_id = 23
  AND vr.status = 'DISPONIVEL'
  AND p.status  = 'ATIVO';


-- =====================================================================
-- C. CONSULTAS GERENCIAIS
-- =====================================================================

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
    SELECT p.prestador_id, p.nome, COALESCE(e.razao_social, 'Autônomo') AS empresa,
           COUNT(os.ordem_id)                                         AS total_os,
           COALESCE(SUM(os.status_atual = 'FINALIZADA'), 0)           AS finalizadas,
           COALESCE(SUM(os.status_atual = 'CANCELADA'), 0)            AS canceladas,
           COALESCE(SUM(CASE WHEN os.status_atual = 'FINALIZADA' THEN os.valor_total END), 0) AS faturamento,
           ROUND(AVG(a.nota), 2)                                      AS nota_media
    FROM prestador_servico p
    LEFT JOIN empresa e        ON e.empresa_id   = p.empresa_id
    LEFT JOIN ordem_servico os ON os.prestador_id = p.prestador_id
    LEFT JOIN avaliacao a      ON a.ordem_id     = os.ordem_id
    GROUP BY p.prestador_id, p.nome, e.razao_social
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
SELECT c.cliente_id, c.nome, COUNT(DISTINCT os.ordem_id) AS qtd_os, SUM(pg.valor_pago) AS total_pago
FROM cliente c
JOIN veiculo v        ON v.cliente_id      = c.cliente_id
JOIN solicitacao s    ON s.veiculo_id      = v.veiculo_id
JOIN ordem_servico os ON os.solicitacao_id = s.solicitacao_id
JOIN pagamento pg     ON pg.ordem_id       = os.ordem_id AND pg.status = 'APROVADO'
GROUP BY c.cliente_id, c.nome
ORDER BY total_pago DESC
LIMIT 5;

-- C9. Utilização da frota de guinchos
SELECT vr.placa, vr.modelo, tg.descricao AS tipo, vr.status,
       COUNT(os.ordem_id) AS qtd_os,
       COALESCE(SUM(s.distancia_km), 0) AS km_rodados,
       COALESCE(SUM(os.valor_total), 0) AS receita_gerada
FROM veiculo_reboque vr
JOIN tipo_guincho tg       ON tg.tipo_guincho_id    = vr.tipo_guincho_id
LEFT JOIN ordem_servico os ON os.veiculo_reboque_id = vr.veiculo_reboque_id AND os.status_atual <> 'CANCELADA'
LEFT JOIN solicitacao s    ON s.solicitacao_id      = os.solicitacao_id
GROUP BY vr.veiculo_reboque_id, vr.placa, vr.modelo, tg.descricao, vr.status
ORDER BY qtd_os DESC;

-- C10. Canal de abertura: atendentes x aplicativo
SELECT COALESCE(f.nome, 'Aplicativo') AS canal, COUNT(*) AS solicitacoes,
       SUM(s.status = 'ACEITA') AS aceitas
FROM solicitacao s
LEFT JOIN funcionario f ON f.funcionario_id = s.funcionario_id
GROUP BY f.funcionario_id, f.nome
ORDER BY solicitacoes DESC;

-- C11. Taxa de aceite e tempo de resposta por prestador
SELECT p.nome, COUNT(*) AS notificacoes, SUM(n.resposta = 'ACEITA') AS aceitas,
       ROUND(100 * SUM(n.resposta = 'ACEITA') / COUNT(*), 1) AS taxa_aceite_pct,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, n.data_hora_envio, n.data_hora_resposta)), 1) AS min_medio_resposta
FROM notificacao_prestador n
JOIN prestador_servico p ON p.prestador_id = n.prestador_id
GROUP BY p.prestador_id, p.nome
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


-- =====================================================================
-- D. CONSULTAS DE AUDITORIA (resultado esperado indicado em cada uma)
-- =====================================================================

-- D1. Trilha completa de alterações de status
SELECT h.historico_id, h.ordem_id, h.status, h.data_hora_alteracao,
       COALESCE(f.nome, 'Prestador/Sistema') AS alterado_por, f.perfil_acesso, h.observacao
FROM historico_status h
LEFT JOIN funcionario f ON f.funcionario_id = h.funcionario_id
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
SELECT 'Cliente sem telefone' AS problema, c.cliente_id AS id FROM cliente c
WHERE NOT EXISTS (SELECT 1 FROM cliente_telefone t WHERE t.cliente_id = c.cliente_id)
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
SELECT 'solicitacao' AS origem, s.solicitacao_id AS id, f.nome
FROM solicitacao s JOIN funcionario f ON f.funcionario_id = s.funcionario_id WHERE f.status = 'INATIVO'
UNION ALL
SELECT 'historico', h.historico_id, f.nome
FROM historico_status h JOIN funcionario f ON f.funcionario_id = h.funcionario_id WHERE f.status = 'INATIVO';


-- =====================================================================
-- E. UPDATE — PROCESSOS EMPRESARIAIS (cada processo em transação)
-- =====================================================================

-- E1. PROCESSO: aceite da solicitação 22 e abertura da O.S.
START TRANSACTION;
UPDATE notificacao_prestador
   SET resposta = 'ACEITA', data_hora_resposta = '2026-10-28 08:44:00'
 WHERE solicitacao_id = 22 AND prestador_id = 1;

UPDATE solicitacao SET status = 'ACEITA' WHERE solicitacao_id = 22;

-- o gatilho valida R7–R10 e grava o histórico de aceite (R14)
INSERT INTO ordem_servico (solicitacao_id, tarifa_id, prestador_id, veiculo_reboque_id,
                           data_previsao, valor_base)
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

-- E4. Baixa do pagamento pendente da O.S. 11 (financeiro)
UPDATE pagamento
   SET status = 'APROVADO', data_hora_pagamento = '2026-10-28 09:00:00', comprovante = 'PIX-20261028-0012'
 WHERE pagamento_id = 12;

-- E5. Reajuste de tarifa com versionamento (R11: sem sobreposição)
START TRANSACTION;
UPDATE tarifa SET vigencia_fim = '2026-10-31' WHERE tarifa_id = 2;

INSERT INTO tarifa (tipo_veiculo_id, servico_id, valor_base, valor_por_km,
                    adicional_madrugada, adicional_domingo, adicional_feriado, adicional_rodovia,
                    vigencia_inicio, vigencia_fim, status)
SELECT tipo_veiculo_id, servico_id, ROUND(valor_base * 1.05, 2), ROUND(valor_por_km * 1.05, 2),
       adicional_madrugada, adicional_domingo, adicional_feriado, adicional_rodovia,
       '2026-11-01', NULL, 'ATIVA'
FROM tarifa WHERE tarifa_id = 2;
COMMIT;

-- E6. PROCESSO: aprovação do prestador 9 (R5: ATIVO exige CNH)
UPDATE prestador_servico SET cnh = '01234567809', status = 'ATIVO' WHERE prestador_id = 9;

-- E7. Guincho 7 volta da manutenção
UPDATE veiculo_reboque SET status = 'DISPONIVEL', marca = 'Hyundai', capacidade_kg = 3500.00
 WHERE veiculo_reboque_id = 7;

-- E8. Atualização cadastral de cliente
UPDATE cliente SET email = 'juliana.r.fernandes@email.com' WHERE cliente_id = 3;

-- E9. UPDATE com JOIN: expira notificações sem resposta há mais de 30 minutos
--     em solicitações que já foram aceitas por outro prestador
UPDATE notificacao_prestador n
JOIN solicitacao s ON s.solicitacao_id = n.solicitacao_id
   SET n.resposta = 'EXPIRADA'
 WHERE n.resposta IS NULL
   AND s.status = 'ACEITA'
   AND n.data_hora_envio < NOW() - INTERVAL 30 MINUTE;


-- =====================================================================
-- F. DELETE
--    Pela regra do modelo (RN12/RNF09), cadastros saem de uso por status;
--    exclusão física só onde não há histórico a preservar.
-- =====================================================================
START TRANSACTION;

-- F1. Remover telefone desativado de um cliente
DELETE FROM cliente_telefone WHERE cliente_id = 2 AND telefone = '11976543210';

-- F2. Limpeza de notificações expiradas anteriores a outubro/2026
DELETE FROM notificacao_prestador
 WHERE resposta = 'EXPIRADA' AND data_hora_envio < '2026-10-01';

-- F3. Excluir tarifa antiga que nunca foi aplicada
DELETE FROM tarifa
 WHERE tarifa_id = 12
   AND NOT EXISTS (SELECT 1 FROM ordem_servico WHERE tarifa_id = 12);

-- F4. Excluir cadastro PENDENTE que nunca foi concluído (sem veículos);
--     os telefones são apagados em CASCADE
DELETE FROM cliente
 WHERE cliente_id = 10 AND status = 'PENDENTE'
   AND NOT EXISTS (SELECT 1 FROM veiculo WHERE cliente_id = 10);

COMMIT;


-- =====================================================================
-- G. CONFERÊNCIA FINAL
-- =====================================================================
SELECT 'cliente' AS tabela, COUNT(*) AS registros FROM cliente
UNION ALL SELECT 'cliente_telefone',          COUNT(*) FROM cliente_telefone
UNION ALL SELECT 'empresa',                   COUNT(*) FROM empresa
UNION ALL SELECT 'tipo_veiculo',              COUNT(*) FROM tipo_veiculo
UNION ALL SELECT 'veiculo',                   COUNT(*) FROM veiculo
UNION ALL SELECT 'tipo_guincho',              COUNT(*) FROM tipo_guincho
UNION ALL SELECT 'veiculo_reboque',           COUNT(*) FROM veiculo_reboque
UNION ALL SELECT 'prestador_servico',         COUNT(*) FROM prestador_servico
UNION ALL SELECT 'servico_reboque',           COUNT(*) FROM servico_reboque
UNION ALL SELECT 'tarifa',                    COUNT(*) FROM tarifa
UNION ALL SELECT 'funcionario',               COUNT(*) FROM funcionario
UNION ALL SELECT 'solicitacao',               COUNT(*) FROM solicitacao
UNION ALL SELECT 'ordem_servico',             COUNT(*) FROM ordem_servico
UNION ALL SELECT 'historico_status',          COUNT(*) FROM historico_status
UNION ALL SELECT 'forma_pagamento',           COUNT(*) FROM forma_pagamento
UNION ALL SELECT 'pagamento',                 COUNT(*) FROM pagamento
UNION ALL SELECT 'avaliacao',                 COUNT(*) FROM avaliacao
UNION ALL SELECT 'cancelamento',              COUNT(*) FROM cancelamento
UNION ALL SELECT 'prestador_veiculo_reboque', COUNT(*) FROM prestador_veiculo_reboque
UNION ALL SELECT 'guincho_tipo_veiculo',      COUNT(*) FROM guincho_tipo_veiculo
UNION ALL SELECT 'notificacao_prestador',     COUNT(*) FROM notificacao_prestador;
