-- =====================================================================
--  FELIGUINCHOS — DDL 01: BANCO E TABELAS (MODELO FÍSICO NORMALIZADO)
--  Base: "Modelo de tabelas normalizado: 1FN, 2FN e 3FN"
--  25 tabelas: 4 novas (Pessoa, Cidade, CEP, Modelo_Veiculo),
--              8 alteradas, 13 sem mudança em relação ao modelo lógico.
--  SGBD: MariaDB 10.4+ (XAMPP) / MySQL 8.0.16+
--
--  Decisões físicas:
--   * INTEGER (PK gerada)      -> INT UNSIGNED AUTO_INCREMENT
--   * PK natural (cpf, cep)    -> CHAR com CHECK de dígitos
--   * TIMESTAMP                -> DATETIME
--   * BOOLEAN                  -> TINYINT(1) com CHECK (0,1)
--   * Coluna calculada         -> GENERATED ALWAYS AS (...) STORED
--   * Índice único parcial R6  -> coluna gerada + UNIQUE
--   * Regras entre tabelas     -> gatilhos (ddl/02_gatilhos.sql)
--   * ON DELETE RESTRICT em todas as FKs, exceto Pessoa_Telefone (CASCADE)
-- =====================================================================

DROP DATABASE IF EXISTS feliguinchos;
CREATE DATABASE feliguinchos
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE feliguinchos;
SET NAMES utf8mb4;


-- =====================================================================
-- 2. ENDEREÇOS
-- =====================================================================

-- CIDADE (nova)
CREATE TABLE cidade (
    cidade_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome      VARCHAR(60)  NOT NULL,
    uf        CHAR(2)      NOT NULL,
    CONSTRAINT pk_cidade         PRIMARY KEY (cidade_id),
    CONSTRAINT uq_cidade_nome_uf UNIQUE (nome, uf),
    CONSTRAINT ck_cidade_uf      CHECK (uf REGEXP '^[A-Z]{2}$')
) ENGINE=InnoDB;

-- CEP (nova). CEP genérico = CEP único da cidade, sem logradouro próprio
CREATE TABLE cep (
    cep          CHAR(8)      NOT NULL,
    cidade_id    INT UNSIGNED NOT NULL,
    logradouro   VARCHAR(120) NULL,
    bairro       VARCHAR(60)  NULL,
    cep_generico BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_cep          PRIMARY KEY (cep),
    CONSTRAINT ck_cep_digitos  CHECK (cep REGEXP '^[0-9]{8}$'),
    CONSTRAINT ck_cep_booleano CHECK (cep_generico IN (0,1)),
    CONSTRAINT ck_cep_generico CHECK ((cep_generico = 1 AND logradouro IS NULL AND bairro IS NULL)
                                   OR (cep_generico = 0 AND logradouro IS NOT NULL)),
    CONSTRAINT fk_cep_cidade FOREIGN KEY (cidade_id)
        REFERENCES cidade (cidade_id) ON DELETE RESTRICT
) ENGINE=InnoDB;


-- =====================================================================
-- 1. PESSOAS, CLIENTES, FUNCIONÁRIOS E PRESTADORES
-- =====================================================================

-- PESSOA (nova): dados comuns de quem é cliente, funcionário ou prestador
CREATE TABLE pessoa (
    cpf                  CHAR(11)     NOT NULL,
    nome                 VARCHAR(100) NOT NULL,
    email                VARCHAR(120) NOT NULL,
    senha                VARCHAR(255) NOT NULL,          -- hash (RN01, RNF01)
    cnpj                 CHAR(14)     NULL,              -- só quando atua como PJ
    data_cadastro        DATE         NOT NULL DEFAULT (CURRENT_DATE),
    cep                  CHAR(8)      NULL,              -- opcional (P14)
    numero               VARCHAR(10)  NULL,
    complemento          VARCHAR(60)  NULL,
    logradouro_informado VARCHAR(120) NULL,              -- obrigatório se CEP genérico; senão nulo
    bairro_informado     VARCHAR(60)  NULL,              -- obrigatório se CEP genérico
    CONSTRAINT pk_pessoa       PRIMARY KEY (cpf),
    CONSTRAINT uq_pessoa_email UNIQUE (email),
    CONSTRAINT uq_pessoa_cnpj  UNIQUE (cnpj),
    CONSTRAINT ck_pessoa_cpf   CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT ck_pessoa_cnpj  CHECK (cnpj IS NULL OR cnpj REGEXP '^[0-9]{14}$'),
    CONSTRAINT fk_pessoa_cep FOREIGN KEY (cep)
        REFERENCES cep (cep) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- PESSOA_TELEFONE (antes Cliente_Telefone): atributo multivalorado
CREATE TABLE pessoa_telefone (
    cpf      CHAR(11)    NOT NULL,
    telefone VARCHAR(15) NOT NULL,
    CONSTRAINT pk_pessoa_telefone PRIMARY KEY (cpf, telefone),
    CONSTRAINT ck_pessoa_telefone CHECK (telefone REGEXP '^[0-9]+$'),
    CONSTRAINT fk_pessoa_telefone_pessoa FOREIGN KEY (cpf)
        REFERENCES pessoa (cpf) ON DELETE CASCADE
) ENGINE=InnoDB;

-- EMPRESA (sem mudança)
CREATE TABLE empresa (
    empresa_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    razao_social VARCHAR(150) NOT NULL,
    cnpj         CHAR(14)     NOT NULL,
    telefone     VARCHAR(15)  NULL,
    email        VARCHAR(120) NULL,
    CONSTRAINT pk_empresa      PRIMARY KEY (empresa_id),
    CONSTRAINT uq_empresa_cnpj UNIQUE (cnpj),
    CONSTRAINT ck_empresa_cnpj CHECK (cnpj REGEXP '^[0-9]{14}$')
) ENGINE=InnoDB;

-- CLIENTE (alterada)
CREATE TABLE cliente (
    cliente_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cpf        CHAR(11)     NOT NULL,
    status     VARCHAR(10)  NOT NULL,
    CONSTRAINT pk_cliente        PRIMARY KEY (cliente_id),
    CONSTRAINT uq_cliente_cpf    UNIQUE (cpf),
    CONSTRAINT ck_cliente_status CHECK (status IN ('ATIVO','PENDENTE','BLOQUEADO')),
    CONSTRAINT fk_cliente_pessoa FOREIGN KEY (cpf)
        REFERENCES pessoa (cpf) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- FUNCIONARIO (alterada)
CREATE TABLE funcionario (
    funcionario_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cpf            CHAR(11)     NOT NULL,
    cargo          VARCHAR(50)  NOT NULL,
    perfil_acesso  VARCHAR(10)  NOT NULL,
    status         VARCHAR(10)  NOT NULL,
    CONSTRAINT pk_funcionario        PRIMARY KEY (funcionario_id),
    CONSTRAINT uq_funcionario_cpf    UNIQUE (cpf),
    CONSTRAINT ck_funcionario_perfil CHECK (perfil_acesso IN ('ATENDENTE','FINANCEIRO','GERENTE')),
    CONSTRAINT ck_funcionario_status CHECK (status IN ('ATIVO','INATIVO')),
    CONSTRAINT fk_funcionario_pessoa FOREIGN KEY (cpf)
        REFERENCES pessoa (cpf) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- PRESTADOR_SERVICO (alterada)
CREATE TABLE prestador_servico (
    prestador_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cpf          CHAR(11)     NOT NULL,
    empresa_id   INT UNSIGNED NULL,
    cnh          VARCHAR(11)  NULL,
    status       VARCHAR(10)  NOT NULL DEFAULT 'EM_ANALISE',
    CONSTRAINT pk_prestador_servico        PRIMARY KEY (prestador_id),
    CONSTRAINT uq_prestador_servico_cpf    UNIQUE (cpf),
    CONSTRAINT uq_prestador_servico_cnh    UNIQUE (cnh),
    CONSTRAINT ck_prestador_servico_status CHECK (status IN ('EM_ANALISE','ATIVO','RECUSADO','BLOQUEADO')),
    CONSTRAINT ck_prestador_servico_cnh_r5 CHECK (status <> 'ATIVO' OR cnh IS NOT NULL),
    CONSTRAINT fk_prestador_servico_pessoa FOREIGN KEY (cpf)
        REFERENCES pessoa (cpf) ON DELETE RESTRICT,
    CONSTRAINT fk_prestador_servico_empresa FOREIGN KEY (empresa_id)
        REFERENCES empresa (empresa_id) ON DELETE RESTRICT
) ENGINE=InnoDB;


-- =====================================================================
-- 3. VEÍCULOS E GUINCHOS
-- =====================================================================

-- MODELO_VEICULO (nova): compartilhada por Veiculo e Veiculo_Reboque
CREATE TABLE modelo_veiculo (
    modelo_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    marca     VARCHAR(50)  NOT NULL,
    nome      VARCHAR(60)  NOT NULL,
    CONSTRAINT pk_modelo_veiculo            PRIMARY KEY (modelo_id),
    CONSTRAINT uq_modelo_veiculo_marca_nome UNIQUE (marca, nome)
) ENGINE=InnoDB;

-- TIPO_VEICULO (sem mudança)
CREATE TABLE tipo_veiculo (
    tipo_veiculo_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    descricao       VARCHAR(50)  NOT NULL,
    categoria       VARCHAR(50)  NULL,
    peso_max_kg     DECIMAL(8,2) NULL,
    CONSTRAINT pk_tipo_veiculo      PRIMARY KEY (tipo_veiculo_id),
    CONSTRAINT uq_tipo_veiculo_desc UNIQUE (descricao)
) ENGINE=InnoDB;

-- VEICULO (alterada: marca e modelo foram para Modelo_Veiculo)
CREATE TABLE veiculo (
    veiculo_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cliente_id      INT UNSIGNED NOT NULL,
    tipo_veiculo_id INT UNSIGNED NOT NULL,
    modelo_id       INT UNSIGNED NOT NULL,
    placa           VARCHAR(8)   NOT NULL,
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
        REFERENCES tipo_veiculo (tipo_veiculo_id) ON DELETE RESTRICT,
    CONSTRAINT fk_veiculo_modelo FOREIGN KEY (modelo_id)
        REFERENCES modelo_veiculo (modelo_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- TIPO_GUINCHO (sem mudança)
CREATE TABLE tipo_guincho (
    tipo_guincho_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    descricao         VARCHAR(50)  NOT NULL,
    capacidade_max_kg DECIMAL(8,2) NULL,
    CONSTRAINT pk_tipo_guincho            PRIMARY KEY (tipo_guincho_id),
    CONSTRAINT uq_tipo_guincho_desc       UNIQUE (descricao),
    CONSTRAINT ck_tipo_guincho_capacidade CHECK (capacidade_max_kg IS NULL OR capacidade_max_kg > 0)
) ENGINE=InnoDB;

-- VEICULO_REBOQUE (alterada: marca e modelo foram para Modelo_Veiculo)
CREATE TABLE veiculo_reboque (
    veiculo_reboque_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    tipo_guincho_id    INT UNSIGNED NOT NULL,
    modelo_id          INT UNSIGNED NOT NULL,
    placa              VARCHAR(8)   NOT NULL,
    ano                SMALLINT     NOT NULL,
    capacidade_kg      DECIMAL(8,2) NULL,
    status             VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_veiculo_reboque       PRIMARY KEY (veiculo_reboque_id),
    CONSTRAINT uq_veiculo_reboque_placa UNIQUE (placa),
    CONSTRAINT ck_veiculo_reboque_ano   CHECK (ano >= 1900),
    CONSTRAINT fk_veiculo_reboque_tipo_guincho FOREIGN KEY (tipo_guincho_id)
        REFERENCES tipo_guincho (tipo_guincho_id) ON DELETE RESTRICT,
    CONSTRAINT fk_veiculo_reboque_modelo FOREIGN KEY (modelo_id)
        REFERENCES modelo_veiculo (modelo_id) ON DELETE RESTRICT
) ENGINE=InnoDB;


-- =====================================================================
-- 4. SERVIÇOS E TARIFAS
-- =====================================================================

-- SERVICO_REBOQUE (sem mudança)
CREATE TABLE servico_reboque (
    servico_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    descricao    VARCHAR(80)  NOT NULL,
    tipo_servico VARCHAR(50)  NOT NULL,
    status       VARCHAR(10)  NOT NULL,
    CONSTRAINT pk_servico_reboque        PRIMARY KEY (servico_id),
    CONSTRAINT uq_servico_reboque_desc   UNIQUE (descricao),
    CONSTRAINT ck_servico_reboque_status CHECK (status IN ('ATIVO','INATIVO'))
) ENGINE=InnoDB;

-- TARIFA (alterada: status removido, pois é deduzido da vigência)
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


-- =====================================================================
-- 5. SOLICITAÇÃO, ORDEM DE SERVIÇO E PAGAMENTO
-- =====================================================================

-- SOLICITACAO (alterada: endereços de origem e destino por CEP)
CREATE TABLE solicitacao (
    solicitacao_id               INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    veiculo_id                   INT UNSIGNED  NOT NULL,
    servico_id                   INT UNSIGNED  NOT NULL,
    funcionario_id               INT UNSIGNED  NULL,
    data_hora_solicitacao        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    origem_cep                   CHAR(8)       NOT NULL,
    origem_numero                VARCHAR(10)   NOT NULL,
    origem_complemento           VARCHAR(60)   NULL,
    origem_logradouro_informado  VARCHAR(120)  NULL,
    origem_bairro_informado      VARCHAR(60)   NULL,
    destino_cep                  CHAR(8)       NOT NULL,
    destino_numero               VARCHAR(10)   NOT NULL,
    destino_complemento          VARCHAR(60)   NULL,
    destino_logradouro_informado VARCHAR(120)  NULL,
    destino_bairro_informado     VARCHAR(60)   NULL,
    distancia_km                 DECIMAL(8,2)  NOT NULL,
    observacao                   VARCHAR(500)  NULL,
    valor_estimado               DECIMAL(10,2) NOT NULL,
    status                       VARCHAR(15)   NOT NULL DEFAULT 'SOLICITADA',
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
    CONSTRAINT fk_solicitacao_origem_cep FOREIGN KEY (origem_cep)
        REFERENCES cep (cep) ON DELETE RESTRICT,
    CONSTRAINT fk_solicitacao_destino_cep FOREIGN KEY (destino_cep)
        REFERENCES cep (cep) ON DELETE RESTRICT,
    INDEX idx_solicitacao_data   (data_hora_solicitacao),
    INDEX idx_solicitacao_status (status)
) ENGINE=InnoDB;

-- ORDEM_SERVICO (sem mudança)
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

-- HISTORICO_STATUS (sem mudança)
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

-- FORMA_PAGAMENTO (sem mudança)
CREATE TABLE forma_pagamento (
    forma_pagamento_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    descricao          VARCHAR(50)  NOT NULL,
    tipo               VARCHAR(30)  NULL,
    CONSTRAINT pk_forma_pagamento      PRIMARY KEY (forma_pagamento_id),
    CONSTRAINT uq_forma_pagamento_desc UNIQUE (descricao)
) ENGINE=InnoDB;

-- PAGAMENTO (sem mudança)
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

-- AVALIACAO (sem mudança)
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

-- CANCELAMENTO (sem mudança)
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

-- PRESTADOR_VEICULO_REBOQUE (sem mudança) — N:N Prestador x Veiculo_Reboque
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

-- GUINCHO_TIPO_VEICULO (sem mudança) — N:N Tipo_Guincho x Tipo_Veiculo
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

-- NOTIFICACAO_PRESTADOR (sem mudança) — N:N Solicitacao x Prestador
-- aceite_unico implementa R6 (no máximo uma ACEITA por solicitação)
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
