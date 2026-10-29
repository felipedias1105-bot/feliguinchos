-- =====================================================================
--  FELIGUINCHOS — SCRIPT SQL COMPLETO
--  Base: Modelo Conceitual (DER - Notação de Chen)
--  SGBD: MySQL 8.0.16+ / MariaDB 10.4+ (mesmo do XAMPP)
--
--  Seções:
--   1. CREATE DATABASE
--   2. CREATE TABLE (PK, FK, UNIQUE, CHECK, DEFAULT, coluna derivada)
--   3. VIEW de apoio
--   4. INSERT (massa de dados)
--   5. SELECT (consultas simples)
--   6. JOIN (consultas com relacionamentos)
--   7. Consultas gerenciais
--   8. Consultas de auditoria
--   9. UPDATE (processos empresariais)
--  10. DELETE
--  11. Testes de integridade (comentados — cada um DEVE falhar)
--  12. Conferência final
--
--  Mapeamento do DER -> modelo relacional:
--   * Atributo composto "endereco" (Cliente) -> colunas logradouro..cep
--   * Atributo multivalorado "telefone (1,n)" -> tabela cliente_telefone
--   * N:N Compativel (Tipo_Veiculo x Tipo_Guincho) -> tabela compativel
--   * N:N Opera (Prestador x Veiculo_Reboque)       -> tabela opera
--   * N:N Notifica (Solicitacao x Prestador)        -> tabela notificacao
--   * 1:1 Gera / Cancelada / Avaliada -> FK com UNIQUE no lado (0,1)
--   * valor_final (derivado) -> coluna GENERATED (calculada pelo banco)
-- =====================================================================


-- =====================================================================
-- 1. CREATE DATABASE
-- =====================================================================
DROP DATABASE IF EXISTS feliguinchos;
CREATE DATABASE feliguinchos
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE feliguinchos;

SET NAMES utf8mb4;


-- =====================================================================
-- 2. CREATE TABLE
-- =====================================================================

-- ---------------------------------------------------------------------
-- FORMA_PAGAMENTO
-- ---------------------------------------------------------------------
CREATE TABLE forma_pagamento (
    id_forma_pagamento INT UNSIGNED NOT NULL AUTO_INCREMENT,
    descricao          VARCHAR(60)  NOT NULL,
    tipo               VARCHAR(15)  NOT NULL,
    CONSTRAINT pk_forma_pagamento      PRIMARY KEY (id_forma_pagamento),
    CONSTRAINT uq_forma_pagamento_desc UNIQUE (descricao),
    CONSTRAINT ck_forma_pagamento_tipo CHECK (tipo IN ('ELETRONICO','CARTAO','DINHEIRO','FATURADO'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- TIPO_VEICULO
-- ---------------------------------------------------------------------
CREATE TABLE tipo_veiculo (
    id_tipo_veiculo INT UNSIGNED NOT NULL AUTO_INCREMENT,
    descricao       VARCHAR(60)  NOT NULL,
    categoria       VARCHAR(10)  NOT NULL,
    CONSTRAINT pk_tipo_veiculo           PRIMARY KEY (id_tipo_veiculo),
    CONSTRAINT uq_tipo_veiculo_desc      UNIQUE (descricao),
    CONSTRAINT ck_tipo_veiculo_categoria CHECK (categoria IN ('LEVE','MEDIO','PESADO'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- TIPO_GUINCHO
-- ---------------------------------------------------------------------
CREATE TABLE tipo_guincho (
    id_tipo_guincho   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    descricao         VARCHAR(60)   NOT NULL,
    capacidade_max_kg DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_tipo_guincho            PRIMARY KEY (id_tipo_guincho),
    CONSTRAINT uq_tipo_guincho_desc       UNIQUE (descricao),
    CONSTRAINT ck_tipo_guincho_capacidade CHECK (capacidade_max_kg > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- COMPATIVEL  (N:N Tipo_Veiculo x Tipo_Guincho, com atributo observacao)
-- ---------------------------------------------------------------------
CREATE TABLE compativel (
    id_tipo_veiculo INT UNSIGNED NOT NULL,
    id_tipo_guincho INT UNSIGNED NOT NULL,
    observacao      VARCHAR(255) NULL,
    CONSTRAINT pk_compativel PRIMARY KEY (id_tipo_veiculo, id_tipo_guincho),
    CONSTRAINT fk_compativel_tipo_veiculo FOREIGN KEY (id_tipo_veiculo)
        REFERENCES tipo_veiculo (id_tipo_veiculo) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_compativel_tipo_guincho FOREIGN KEY (id_tipo_guincho)
        REFERENCES tipo_guincho (id_tipo_guincho) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- SERVICO_REBOQUE
-- ---------------------------------------------------------------------
CREATE TABLE servico_reboque (
    id_servico_reboque INT UNSIGNED NOT NULL AUTO_INCREMENT,
    descricao          VARCHAR(80)  NOT NULL,
    tipo_servico       VARCHAR(15)  NOT NULL,
    status             VARCHAR(10)  NOT NULL DEFAULT 'ATIVO',
    CONSTRAINT pk_servico_reboque        PRIMARY KEY (id_servico_reboque),
    CONSTRAINT uq_servico_reboque_desc   UNIQUE (descricao),
    CONSTRAINT ck_servico_reboque_tipo   CHECK (tipo_servico IN ('REBOQUE','SOCORRO','RESGATE')),
    CONSTRAINT ck_servico_reboque_status CHECK (status IN ('ATIVO','INATIVO'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- TARIFA  (Define: Tipo_Veiculo 1,1 | Precifica: Servico_Reboque 1,1)
-- ---------------------------------------------------------------------
CREATE TABLE tarifa (
    id_tarifa            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    id_tipo_veiculo      INT UNSIGNED  NOT NULL,
    id_servico_reboque   INT UNSIGNED  NOT NULL,
    valor_base           DECIMAL(10,2) NOT NULL,
    valor_km             DECIMAL(10,2) NOT NULL,
    adicional_madrugada  DECIMAL(10,2) NOT NULL DEFAULT 0,
    adicional_domingo    DECIMAL(10,2) NOT NULL DEFAULT 0,
    adicional_feriado    DECIMAL(10,2) NOT NULL DEFAULT 0,
    adicional_rodovia    DECIMAL(10,2) NOT NULL DEFAULT 0,
    vigencia_inicio      DATE          NOT NULL,
    vigencia_fim         DATE          NULL,
    status               VARCHAR(10)   NOT NULL DEFAULT 'ATIVA',
    CONSTRAINT pk_tarifa PRIMARY KEY (id_tarifa),
    CONSTRAINT uq_tarifa_vigencia UNIQUE (id_tipo_veiculo, id_servico_reboque, vigencia_inicio),
    CONSTRAINT ck_tarifa_valores  CHECK (valor_base >= 0 AND valor_km >= 0
                                         AND adicional_madrugada >= 0 AND adicional_domingo >= 0
                                         AND adicional_feriado >= 0 AND adicional_rodovia >= 0),
    CONSTRAINT ck_tarifa_vigencia CHECK (vigencia_fim IS NULL OR vigencia_fim >= vigencia_inicio),
    CONSTRAINT ck_tarifa_status   CHECK (status IN ('ATIVA','INATIVA')),
    CONSTRAINT fk_tarifa_tipo_veiculo FOREIGN KEY (id_tipo_veiculo)
        REFERENCES tipo_veiculo (id_tipo_veiculo) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_tarifa_servico FOREIGN KEY (id_servico_reboque)
        REFERENCES servico_reboque (id_servico_reboque) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- EMPRESA
-- ---------------------------------------------------------------------
CREATE TABLE empresa (
    id_empresa   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    razao_social VARCHAR(150) NOT NULL,
    cnpj         CHAR(14)     NOT NULL,
    telefone     VARCHAR(11)  NOT NULL,
    email        VARCHAR(120) NOT NULL,
    CONSTRAINT pk_empresa          PRIMARY KEY (id_empresa),
    CONSTRAINT uq_empresa_cnpj     UNIQUE (cnpj),
    CONSTRAINT ck_empresa_cnpj     CHECK (cnpj REGEXP '^[0-9]{14}$'),
    CONSTRAINT ck_empresa_telefone CHECK (telefone REGEXP '^[0-9]{10,11}$'),
    CONSTRAINT ck_empresa_email    CHECK (email LIKE '%_@_%._%')
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- PRESTADOR  (Vincula: Empresa 0,1 -> autônomo quando NULL)
-- ---------------------------------------------------------------------
CREATE TABLE prestador (
    id_prestador  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_empresa    INT UNSIGNED NULL,
    nome          VARCHAR(120) NOT NULL,
    cpf           CHAR(11)     NOT NULL,
    cnh           CHAR(11)     NOT NULL,
    telefone      VARCHAR(11)  NOT NULL,
    email         VARCHAR(120) NOT NULL,
    data_cadastro DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status        VARCHAR(10)  NOT NULL DEFAULT 'ATIVO',
    CONSTRAINT pk_prestador          PRIMARY KEY (id_prestador),
    CONSTRAINT uq_prestador_cpf      UNIQUE (cpf),
    CONSTRAINT uq_prestador_cnh      UNIQUE (cnh),
    CONSTRAINT uq_prestador_email    UNIQUE (email),
    CONSTRAINT ck_prestador_cpf      CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT ck_prestador_cnh      CHECK (cnh REGEXP '^[0-9]{11}$'),
    CONSTRAINT ck_prestador_telefone CHECK (telefone REGEXP '^[0-9]{10,11}$'),
    CONSTRAINT ck_prestador_email    CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT ck_prestador_status   CHECK (status IN ('ATIVO','INATIVO','SUSPENSO')),
    CONSTRAINT fk_prestador_empresa FOREIGN KEY (id_empresa)
        REFERENCES empresa (id_empresa) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- VEICULO_REBOQUE  (Classifica: Tipo_Guincho 1,1)
-- ---------------------------------------------------------------------
CREATE TABLE veiculo_reboque (
    id_veiculo_reboque INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    id_tipo_guincho    INT UNSIGNED  NOT NULL,
    placa              CHAR(7)       NOT NULL,
    marca              VARCHAR(40)   NOT NULL,
    modelo             VARCHAR(60)   NOT NULL,
    ano                SMALLINT      NOT NULL,
    capacidade_kg      DECIMAL(10,2) NOT NULL,
    status             VARCHAR(12)   NOT NULL DEFAULT 'DISPONIVEL',
    CONSTRAINT pk_veiculo_reboque            PRIMARY KEY (id_veiculo_reboque),
    CONSTRAINT uq_veiculo_reboque_placa      UNIQUE (placa),
    CONSTRAINT ck_veiculo_reboque_placa      CHECK (placa REGEXP '^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$'),
    CONSTRAINT ck_veiculo_reboque_ano        CHECK (ano BETWEEN 1950 AND 2100),
    CONSTRAINT ck_veiculo_reboque_capacidade CHECK (capacidade_kg > 0),
    CONSTRAINT ck_veiculo_reboque_status     CHECK (status IN ('DISPONIVEL','EM_SERVICO','MANUTENCAO','INATIVO')),
    CONSTRAINT fk_veiculo_reboque_tipo FOREIGN KEY (id_tipo_guincho)
        REFERENCES tipo_guincho (id_tipo_guincho) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- OPERA  (N:N Prestador x Veiculo_Reboque, com data_inicio, data_fim, status)
-- ---------------------------------------------------------------------
CREATE TABLE opera (
    id_opera           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_prestador       INT UNSIGNED NOT NULL,
    id_veiculo_reboque INT UNSIGNED NOT NULL,
    data_inicio        DATE         NOT NULL,
    data_fim           DATE         NULL,
    status             VARCHAR(10)  NOT NULL DEFAULT 'ATIVO',
    CONSTRAINT pk_opera PRIMARY KEY (id_opera),
    CONSTRAINT uq_opera_periodo UNIQUE (id_prestador, id_veiculo_reboque, data_inicio),
    CONSTRAINT ck_opera_datas   CHECK (data_fim IS NULL OR data_fim >= data_inicio),
    CONSTRAINT ck_opera_status  CHECK ((status = 'ATIVO' AND data_fim IS NULL)
                                    OR (status = 'ENCERRADO' AND data_fim IS NOT NULL)),
    CONSTRAINT fk_opera_prestador FOREIGN KEY (id_prestador)
        REFERENCES prestador (id_prestador) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_opera_veiculo_reboque FOREIGN KEY (id_veiculo_reboque)
        REFERENCES veiculo_reboque (id_veiculo_reboque) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- FUNCIONARIO
-- ---------------------------------------------------------------------
CREATE TABLE funcionario (
    id_funcionario INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome           VARCHAR(120) NOT NULL,
    cpf            CHAR(11)     NOT NULL,
    email          VARCHAR(120) NOT NULL,
    cargo          VARCHAR(60)  NOT NULL,
    perfil_acesso  VARCHAR(12)  NOT NULL,
    senha          VARCHAR(255) NOT NULL,   -- armazenar sempre hash, nunca texto puro
    status         VARCHAR(10)  NOT NULL DEFAULT 'ATIVO',
    CONSTRAINT pk_funcionario        PRIMARY KEY (id_funcionario),
    CONSTRAINT uq_funcionario_cpf    UNIQUE (cpf),
    CONSTRAINT uq_funcionario_email  UNIQUE (email),
    CONSTRAINT ck_funcionario_cpf    CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT ck_funcionario_email  CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT ck_funcionario_perfil CHECK (perfil_acesso IN ('ADMIN','GERENTE','SUPERVISOR','ATENDENTE','FINANCEIRO')),
    CONSTRAINT ck_funcionario_status CHECK (status IN ('ATIVO','INATIVO'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- CLIENTE  (endereco composto desmembrado)
-- ---------------------------------------------------------------------
CREATE TABLE cliente (
    id_cliente    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome          VARCHAR(120) NOT NULL,
    cpf           CHAR(11)     NOT NULL,
    email         VARCHAR(120) NOT NULL,
    senha         VARCHAR(255) NOT NULL,
    logradouro    VARCHAR(150) NOT NULL,
    numero        VARCHAR(10)  NOT NULL,
    complemento   VARCHAR(60)  NULL,
    bairro        VARCHAR(80)  NOT NULL,
    cidade        VARCHAR(80)  NOT NULL,
    uf            CHAR(2)      NOT NULL,
    cep           CHAR(8)      NOT NULL,
    data_cadastro DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status        VARCHAR(10)  NOT NULL DEFAULT 'ATIVO',
    CONSTRAINT pk_cliente        PRIMARY KEY (id_cliente),
    CONSTRAINT uq_cliente_cpf    UNIQUE (cpf),
    CONSTRAINT uq_cliente_email  UNIQUE (email),
    CONSTRAINT ck_cliente_cpf    CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT ck_cliente_cep    CHECK (cep REGEXP '^[0-9]{8}$'),
    CONSTRAINT ck_cliente_uf     CHECK (uf REGEXP '^[A-Z]{2}$'),
    CONSTRAINT ck_cliente_email  CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT ck_cliente_status CHECK (status IN ('ATIVO','INATIVO','BLOQUEADO'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- CLIENTE_TELEFONE  (atributo multivalorado telefone (1,n))
-- ---------------------------------------------------------------------
CREATE TABLE cliente_telefone (
    id_cliente INT UNSIGNED NOT NULL,
    telefone   VARCHAR(11)  NOT NULL,
    CONSTRAINT pk_cliente_telefone PRIMARY KEY (id_cliente, telefone),
    CONSTRAINT ck_cliente_telefone CHECK (telefone REGEXP '^[0-9]{10,11}$'),
    CONSTRAINT fk_cliente_telefone_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- VEICULO  (Possui: Cliente 1,1 | Classificado: Tipo_Veiculo 1,1)
-- ---------------------------------------------------------------------
CREATE TABLE veiculo (
    id_veiculo      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_cliente      INT UNSIGNED NOT NULL,
    id_tipo_veiculo INT UNSIGNED NOT NULL,
    placa           CHAR(7)      NOT NULL,
    marca           VARCHAR(40)  NOT NULL,
    modelo          VARCHAR(60)  NOT NULL,
    ano             SMALLINT     NOT NULL,
    cor             VARCHAR(30)  NOT NULL,
    blindado        TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT pk_veiculo          PRIMARY KEY (id_veiculo),
    CONSTRAINT uq_veiculo_placa    UNIQUE (placa),
    CONSTRAINT ck_veiculo_placa    CHECK (placa REGEXP '^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$'),
    CONSTRAINT ck_veiculo_ano      CHECK (ano BETWEEN 1950 AND 2100),
    CONSTRAINT ck_veiculo_blindado CHECK (blindado IN (0,1)),
    CONSTRAINT fk_veiculo_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_veiculo_tipo FOREIGN KEY (id_tipo_veiculo)
        REFERENCES tipo_veiculo (id_tipo_veiculo) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- SOLICITACAO  (Refere-se: Veiculo 1,1 | Tipo_de: Servico 1,1 | Abre: Funcionario 0,1)
-- id_funcionario NULL = solicitação aberta pelo próprio cliente no app
-- endereco_destino NULL = atendimento no local (socorro)
-- ---------------------------------------------------------------------
CREATE TABLE solicitacao (
    id_solicitacao     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    id_veiculo         INT UNSIGNED  NOT NULL,
    id_servico_reboque INT UNSIGNED  NOT NULL,
    id_funcionario     INT UNSIGNED  NULL,
    data_solicitacao   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    endereco_origem    VARCHAR(200)  NOT NULL,
    endereco_destino   VARCHAR(200)  NULL,
    distancia_km       DECIMAL(8,2)  NOT NULL DEFAULT 0,
    observacoes        VARCHAR(255)  NULL,
    valor_estimado     DECIMAL(10,2) NOT NULL DEFAULT 0,
    status             VARCHAR(15)   NOT NULL DEFAULT 'ABERTA',
    CONSTRAINT pk_solicitacao           PRIMARY KEY (id_solicitacao),
    CONSTRAINT ck_solicitacao_distancia CHECK (distancia_km >= 0),
    CONSTRAINT ck_solicitacao_valor     CHECK (valor_estimado >= 0),
    CONSTRAINT ck_solicitacao_status    CHECK (status IN ('ABERTA','EM_ATENDIMENTO','CONCLUIDA','CANCELADA')),
    CONSTRAINT fk_solicitacao_veiculo FOREIGN KEY (id_veiculo)
        REFERENCES veiculo (id_veiculo) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_solicitacao_servico FOREIGN KEY (id_servico_reboque)
        REFERENCES servico_reboque (id_servico_reboque) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_solicitacao_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES funcionario (id_funcionario) ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_solicitacao_data (data_solicitacao),
    INDEX idx_solicitacao_status (status)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- NOTIFICACAO  (N:N Solicitacao x Prestador — relacionamento "Notifica")
-- ---------------------------------------------------------------------
CREATE TABLE notificacao (
    id_solicitacao INT UNSIGNED NOT NULL,
    id_prestador   INT UNSIGNED NOT NULL,
    data_envio     DATETIME     NOT NULL,
    data_resposta  DATETIME     NULL,
    status         VARCHAR(10)  NOT NULL DEFAULT 'ENVIADA',
    CONSTRAINT pk_notificacao PRIMARY KEY (id_solicitacao, id_prestador),
    CONSTRAINT ck_notificacao_datas  CHECK (data_resposta IS NULL OR data_resposta >= data_envio),
    CONSTRAINT ck_notificacao_status CHECK ((status IN ('ENVIADA','EXPIRADA') AND data_resposta IS NULL)
                                         OR (status IN ('ACEITA','RECUSADA') AND data_resposta IS NOT NULL)),
    CONSTRAINT fk_notificacao_solicitacao FOREIGN KEY (id_solicitacao)
        REFERENCES solicitacao (id_solicitacao) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_notificacao_prestador FOREIGN KEY (id_prestador)
        REFERENCES prestador (id_prestador) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- ORDEM_SERVICO
--   Gera: Solicitacao 1,1  -> UNIQUE (cada solicitação gera no máximo 1 OS)
--   Aplica: Tarifa 1,1 | Executa: Prestador 1,1 | Utiliza: Veiculo_Reboque 1,1
--   valor_final = atributo derivado (coluna calculada)
-- ---------------------------------------------------------------------
CREATE TABLE ordem_servico (
    id_os              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    id_solicitacao     INT UNSIGNED  NOT NULL,
    id_tarifa          INT UNSIGNED  NOT NULL,
    id_prestador       INT UNSIGNED  NOT NULL,
    id_veiculo_reboque INT UNSIGNED  NOT NULL,
    data_inicio        DATETIME      NOT NULL,
    data_previsao      DATETIME      NULL,
    data_finalizacao   DATETIME      NULL,
    status_os          VARCHAR(15)   NOT NULL DEFAULT 'ABERTA',
    observacoes        VARCHAR(255)  NULL,
    valor_base         DECIMAL(10,2) NOT NULL,
    valor_adicionais   DECIMAL(10,2) NOT NULL DEFAULT 0,
    desconto           DECIMAL(10,2) NOT NULL DEFAULT 0,
    valor_final        DECIMAL(10,2) GENERATED ALWAYS AS (valor_base + valor_adicionais - desconto) STORED,
    CONSTRAINT pk_ordem_servico             PRIMARY KEY (id_os),
    CONSTRAINT uq_ordem_servico_solicitacao UNIQUE (id_solicitacao),
    CONSTRAINT ck_os_valores    CHECK (valor_base >= 0 AND valor_adicionais >= 0 AND desconto >= 0),
    CONSTRAINT ck_os_desconto   CHECK (desconto <= valor_base + valor_adicionais),
    CONSTRAINT ck_os_previsao   CHECK (data_previsao IS NULL OR data_previsao >= data_inicio),
    CONSTRAINT ck_os_finalizacao CHECK (data_finalizacao IS NULL OR data_finalizacao >= data_inicio),
    CONSTRAINT ck_os_status     CHECK (status_os IN ('ABERTA','A_CAMINHO','EM_ATENDIMENTO','FINALIZADA','CANCELADA')),
    CONSTRAINT ck_os_status_fim CHECK ((status_os = 'FINALIZADA' AND data_finalizacao IS NOT NULL)
                                    OR (status_os <> 'FINALIZADA' AND data_finalizacao IS NULL)),
    CONSTRAINT fk_os_solicitacao FOREIGN KEY (id_solicitacao)
        REFERENCES solicitacao (id_solicitacao) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_os_tarifa FOREIGN KEY (id_tarifa)
        REFERENCES tarifa (id_tarifa) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_os_prestador FOREIGN KEY (id_prestador)
        REFERENCES prestador (id_prestador) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_os_veiculo_reboque FOREIGN KEY (id_veiculo_reboque)
        REFERENCES veiculo_reboque (id_veiculo_reboque) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_os_status (status_os),
    INDEX idx_os_data_inicio (data_inicio)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- HISTORICO_STATUS  (Registra: OS 1,1 / 1,n | Altera: Funcionario 0,1)
-- id_funcionario NULL = alteração feita pelo sistema/app do prestador
-- ---------------------------------------------------------------------
CREATE TABLE historico_status (
    id_historico   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_os          INT UNSIGNED NOT NULL,
    id_funcionario INT UNSIGNED NULL,
    status         VARCHAR(15)  NOT NULL,
    data_hora      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacao     VARCHAR(255) NULL,
    CONSTRAINT pk_historico_status PRIMARY KEY (id_historico),
    CONSTRAINT ck_historico_status CHECK (status IN ('ABERTA','A_CAMINHO','EM_ATENDIMENTO','FINALIZADA','CANCELADA')),
    CONSTRAINT fk_historico_os FOREIGN KEY (id_os)
        REFERENCES ordem_servico (id_os) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_historico_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES funcionario (id_funcionario) ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_historico_os_data (id_os, data_hora)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- CANCELAMENTO  (Cancelada: OS 1,1 / 0,1 -> UNIQUE | Autoriza: Funcionario 0,1)
-- ---------------------------------------------------------------------
CREATE TABLE cancelamento (
    id_cancelamento  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    id_os            INT UNSIGNED  NOT NULL,
    id_funcionario   INT UNSIGNED  NULL,
    tipo_responsavel VARCHAR(10)   NOT NULL,
    motivo           VARCHAR(255)  NOT NULL,
    data_hora        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor_multa      DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT pk_cancelamento             PRIMARY KEY (id_cancelamento),
    CONSTRAINT uq_cancelamento_os          UNIQUE (id_os),
    CONSTRAINT ck_cancelamento_responsavel CHECK (tipo_responsavel IN ('CLIENTE','PRESTADOR','EMPRESA')),
    CONSTRAINT ck_cancelamento_multa       CHECK (valor_multa >= 0),
    CONSTRAINT fk_cancelamento_os FOREIGN KEY (id_os)
        REFERENCES ordem_servico (id_os) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cancelamento_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES funcionario (id_funcionario) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- PAGAMENTO  (Paga: OS 1,1 / 0,n | Pago_com: Forma_Pagamento 1,1)
-- ---------------------------------------------------------------------
CREATE TABLE pagamento (
    id_pagamento       INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    id_os              INT UNSIGNED  NOT NULL,
    id_forma_pagamento INT UNSIGNED  NOT NULL,
    valor              DECIMAL(10,2) NOT NULL,
    data_pagamento     DATETIME      NULL,
    status             VARCHAR(10)   NOT NULL DEFAULT 'PENDENTE',
    comprovante        VARCHAR(100)  NULL,
    CONSTRAINT pk_pagamento        PRIMARY KEY (id_pagamento),
    CONSTRAINT ck_pagamento_valor  CHECK (valor > 0),
    CONSTRAINT ck_pagamento_status CHECK (status IN ('PENDENTE','APROVADO','RECUSADO','ESTORNADO')),
    CONSTRAINT ck_pagamento_data   CHECK ((status = 'PENDENTE' AND data_pagamento IS NULL)
                                       OR (status <> 'PENDENTE' AND data_pagamento IS NOT NULL)),
    CONSTRAINT fk_pagamento_os FOREIGN KEY (id_os)
        REFERENCES ordem_servico (id_os) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pagamento_forma FOREIGN KEY (id_forma_pagamento)
        REFERENCES forma_pagamento (id_forma_pagamento) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- AVALIACAO  (Avaliada: OS 1,1 / 0,1 -> UNIQUE)
-- ---------------------------------------------------------------------
CREATE TABLE avaliacao (
    id_avaliacao   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_os          INT UNSIGNED NOT NULL,
    nota           TINYINT      NOT NULL,
    comentario     VARCHAR(500) NULL,
    data_avaliacao DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_avaliacao      PRIMARY KEY (id_avaliacao),
    CONSTRAINT uq_avaliacao_os   UNIQUE (id_os),
    CONSTRAINT ck_avaliacao_nota CHECK (nota BETWEEN 1 AND 5),
    CONSTRAINT fk_avaliacao_os FOREIGN KEY (id_os)
        REFERENCES ordem_servico (id_os) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


-- =====================================================================
-- 3. VIEW DE APOIO (visão consolidada da OS, usada nos relatórios)
-- =====================================================================
CREATE VIEW vw_os_detalhada AS
SELECT  os.id_os,
        os.status_os,
        s.id_solicitacao,
        s.data_solicitacao,
        c.id_cliente,
        c.nome                                 AS cliente,
        v.placa                                AS placa_veiculo,
        CONCAT(v.marca, ' ', v.modelo)         AS veiculo,
        tv.descricao                           AS tipo_veiculo,
        sr.descricao                           AS servico,
        pr.id_prestador,
        pr.nome                                AS prestador,
        COALESCE(e.razao_social, 'Autônomo')   AS empresa,
        vr.placa                               AS placa_reboque,
        tg.descricao                           AS tipo_guincho,
        s.distancia_km,
        os.data_inicio,
        os.data_previsao,
        os.data_finalizacao,
        os.valor_base,
        os.valor_adicionais,
        os.desconto,
        os.valor_final
FROM ordem_servico os
JOIN solicitacao      s  ON s.id_solicitacao      = os.id_solicitacao
JOIN veiculo          v  ON v.id_veiculo          = s.id_veiculo
JOIN cliente          c  ON c.id_cliente          = v.id_cliente
JOIN tipo_veiculo     tv ON tv.id_tipo_veiculo    = v.id_tipo_veiculo
JOIN servico_reboque  sr ON sr.id_servico_reboque = s.id_servico_reboque
JOIN prestador        pr ON pr.id_prestador       = os.id_prestador
LEFT JOIN empresa     e  ON e.id_empresa          = pr.id_empresa
JOIN veiculo_reboque  vr ON vr.id_veiculo_reboque = os.id_veiculo_reboque
JOIN tipo_guincho     tg ON tg.id_tipo_guincho    = vr.id_tipo_guincho;


-- =====================================================================
-- 4. INSERT — MASSA DE DADOS
--    Período simulado: set/2026 a out/2026
--    Feriados usados: 07/09/2026 e 12/10/2026
-- =====================================================================

-- Formas de pagamento
INSERT INTO forma_pagamento (id_forma_pagamento, descricao, tipo) VALUES
(1, 'PIX',                    'ELETRONICO'),
(2, 'Cartão de Crédito',      'CARTAO'),
(3, 'Cartão de Débito',       'CARTAO'),
(4, 'Dinheiro',               'DINHEIRO'),
(5, 'Faturado (Boleto PJ)',   'FATURADO');

-- Tipos de veículo
INSERT INTO tipo_veiculo (id_tipo_veiculo, descricao, categoria) VALUES
(1, 'Motocicleta',                'LEVE'),
(2, 'Automóvel de passeio',       'LEVE'),
(3, 'SUV / Picape',               'MEDIO'),
(4, 'Utilitário / Van',           'MEDIO'),
(5, 'Caminhão leve (3/4)',        'PESADO'),
(6, 'Caminhão pesado / Ônibus',   'PESADO');

-- Tipos de guincho
INSERT INTO tipo_guincho (id_tipo_guincho, descricao, capacidade_max_kg) VALUES
(1, 'Carretinha para motos',        400.00),
(2, 'Plataforma leve',             3500.00),
(3, 'Plataforma pesada',           8000.00),
(4, 'Asa-delta (lança leve)',      4000.00),
(5, 'Guincho pesado (lança)',     25000.00);

-- Compatibilidade Tipo_Veiculo x Tipo_Guincho
INSERT INTO compativel (id_tipo_veiculo, id_tipo_guincho, observacao) VALUES
(1, 1, 'Uso preferencial para motos'),
(1, 2, 'Necessita cintas e calço de roda para moto'),
(2, 2, NULL),
(2, 4, 'Evitar em veículos rebaixados'),
(3, 2, 'Conferir peso: limite de 3.500 kg'),
(3, 3, NULL),
(4, 3, NULL),
(4, 4, 'Somente vans até 4.000 kg'),
(5, 3, NULL),
(5, 5, NULL),
(6, 5, 'Único tipo apto para veículos pesados');

-- Serviços
INSERT INTO servico_reboque (id_servico_reboque, descricao, tipo_servico, status) VALUES
(1, 'Reboque urbano',               'REBOQUE', 'ATIVO'),
(2, 'Reboque rodoviário',           'REBOQUE', 'ATIVO'),
(3, 'Troca de pneu',                'SOCORRO', 'ATIVO'),
(4, 'Carga de bateria',             'SOCORRO', 'ATIVO'),
(5, 'Resgate em vala/ribanceira',   'RESGATE', 'ATIVO'),
(6, 'Pane seca',                    'SOCORRO', 'INATIVO');

-- Tarifas (valor_base + valor_km * distância + adicionais em R$)
INSERT INTO tarifa (id_tarifa, id_tipo_veiculo, id_servico_reboque, valor_base, valor_km,
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

-- Empresas parceiras
INSERT INTO empresa (id_empresa, razao_social, cnpj, telefone, email) VALUES
(1, 'Guinchos Rápido Sul Ltda',       '12345678000101', '1130001000', 'contato@rapidosul.com.br'),
(2, 'Reboque Forte Transportes ME',   '23456789000102', '1140002000', 'contato@reboqueforte.com.br'),
(3, 'Auto Socorro Paulista Ltda',     '34567890000103', '1150003000', 'atendimento@autosocorrosp.com.br');

-- Prestadores (id_empresa NULL = autônomo)
INSERT INTO prestador (id_prestador, id_empresa, nome, cpf, cnh, telefone, email, data_cadastro, status) VALUES
(1, 1,    'Carlos Henrique Souza',   '11223344501', '01234567801', '11981110001', 'carlos.souza@rapidosul.com.br',     '2026-01-08 09:00:00', 'ATIVO'),
(2, 1,    'Marcos Vinícius Lima',    '11223344502', '01234567802', '11981110002', 'marcos.lima@rapidosul.com.br',      '2026-01-08 09:30:00', 'ATIVO'),
(3, 2,    'José Roberto Alves',      '11223344503', '01234567803', '11981110003', 'jose.alves@reboqueforte.com.br',    '2026-01-20 10:00:00', 'ATIVO'),
(4, 2,    'Anderson Pereira Costa',  '11223344504', '01234567804', '11981110004', 'anderson.costa@reboqueforte.com.br','2026-01-20 10:30:00', 'ATIVO'),
(5, 3,    'Ricardo Mendes Oliveira', '11223344505', '01234567805', '11981110005', 'ricardo.oliveira@autosocorrosp.com.br','2026-02-15 08:00:00', 'ATIVO'),
(6, NULL, 'Paulo Sérgio Ramos',      '11223344506', '01234567806', '11981110006', 'paulo.ramos.guincho@email.com',     '2026-03-10 14:00:00', 'ATIVO'),
(7, NULL, 'Fábio Augusto Nunes',     '11223344507', '01234567807', '11981110007', 'fabio.nunes.reboque@email.com',     '2026-03-28 15:00:00', 'ATIVO'),
(8, 3,    'Luiz Fernando Teixeira',  '11223344508', '01234567808', '11981110008', 'luiz.teixeira@autosocorrosp.com.br','2026-01-02 08:00:00', 'SUSPENSO');

-- Veículos de reboque (frota)
INSERT INTO veiculo_reboque (id_veiculo_reboque, id_tipo_guincho, placa, marca, modelo, ano, capacidade_kg, status) VALUES
(1, 2, 'GUI1A23', 'Volkswagen',    'Delivery 9.170',  2021,  3500.00, 'DISPONIVEL'),
(2, 2, 'GUI2B34', 'Ford',          'Cargo 816',       2020,  3500.00, 'EM_SERVICO'),
(3, 3, 'GUI3C45', 'Mercedes-Benz', 'Accelo 1016',     2022,  8000.00, 'EM_SERVICO'),
(4, 4, 'GUI4D56', 'Iveco',         'Daily 70C17',     2019,  4000.00, 'DISPONIVEL'),
(5, 5, 'GUI5E67', 'Volvo',         'VM 270',          2018, 25000.00, 'DISPONIVEL'),
(6, 1, 'GUI6F78', 'Fiat',          'Strada Carretinha', 2023, 400.00, 'DISPONIVEL'),
(7, 2, 'GUI7G89', 'Hyundai',       'HR Plataforma',   2017,  3500.00, 'MANUTENCAO');

-- Vínculo Prestador x Reboque (Opera)
INSERT INTO opera (id_opera, id_prestador, id_veiculo_reboque, data_inicio, data_fim, status) VALUES
( 1, 1, 1, '2026-01-10', NULL,         'ATIVO'),
( 2, 2, 2, '2026-01-10', NULL,         'ATIVO'),
( 3, 2, 7, '2025-06-01', '2025-12-31', 'ENCERRADO'),
( 4, 3, 3, '2026-02-01', NULL,         'ATIVO'),
( 5, 4, 4, '2026-02-01', NULL,         'ATIVO'),
( 6, 5, 5, '2026-03-01', NULL,         'ATIVO'),
( 7, 6, 6, '2026-03-15', NULL,         'ATIVO'),
( 8, 7, 2, '2026-04-01', NULL,         'ATIVO'),
( 9, 5, 3, '2026-05-01', NULL,         'ATIVO'),
(10, 8, 7, '2026-01-05', '2026-08-31', 'ENCERRADO');

-- Funcionários (senha com hash SHA-256 — em produção prefira bcrypt/argon2 na aplicação)
INSERT INTO funcionario (id_funcionario, nome, cpf, email, cargo, perfil_acesso, senha, status) VALUES
(1, 'Ana Paula Ferreira',   '10120230301', 'ana.ferreira@feliguinchos.com.br',   'Gerente de Operações',       'GERENTE',    SHA2('Ana@2026', 256),    'ATIVO'),
(2, 'Bruno Carvalho Dias',  '10120230302', 'bruno.dias@feliguinchos.com.br',     'Supervisor de Atendimento',  'SUPERVISOR', SHA2('Bruno@2026', 256),  'ATIVO'),
(3, 'Camila Rocha Santos',  '10120230303', 'camila.santos@feliguinchos.com.br',  'Atendente',                  'ATENDENTE',  SHA2('Camila@2026', 256), 'ATIVO'),
(4, 'Diego Martins Silva',  '10120230304', 'diego.silva@feliguinchos.com.br',    'Atendente',                  'ATENDENTE',  SHA2('Diego@2026', 256),  'ATIVO'),
(5, 'Eduarda Lopes Gomes',  '10120230305', 'eduarda.gomes@feliguinchos.com.br',  'Analista Financeiro',        'FINANCEIRO', SHA2('Eduarda@2026', 256),'ATIVO'),
(6, 'Felipe Andrade Barros','10120230306', 'felipe.barros@feliguinchos.com.br',  'Administrador de Sistemas',  'ADMIN',      SHA2('Felipe@2026', 256), 'ATIVO'),
(7, 'Gabriela Moura Pinto', '10120230307', 'gabriela.pinto@feliguinchos.com.br', 'Atendente',                  'ATENDENTE',  SHA2('Gabi@2026', 256),   'INATIVO');

-- Clientes
INSERT INTO cliente (id_cliente, nome, cpf, email, senha, logradouro, numero, complemento, bairro, cidade, uf, cep, data_cadastro, status) VALUES
( 1, 'Mariana Costa Almeida',    '32165498701', 'mariana.almeida@email.com',  SHA2('cli001', 256), 'Rua Augusta',               '1500', 'Apto 82',   'Consolação',      'São Paulo',              'SP', '01304001', '2026-01-15 10:20:00', 'ATIVO'),
( 2, 'Rafael Souza Barbosa',     '45678912302', 'rafael.barbosa@email.com',   SHA2('cli002', 256), 'Avenida Paulista',          '2000', NULL,        'Bela Vista',      'São Paulo',              'SP', '01310200', '2026-02-03 14:05:00', 'ATIVO'),
( 3, 'Juliana Ribeiro Fernandes','78912345603', 'juliana.fernandes@email.com',SHA2('cli003', 256), 'Rua Vergueiro',             '3185', 'Casa 2',    'Vila Mariana',    'São Paulo',              'SP', '04101300', '2026-02-20 09:40:00', 'ATIVO'),
( 4, 'Thiago Henrique Moreira',  '15975345604', 'thiago.moreira@email.com',   SHA2('cli004', 256), 'Avenida Industrial',        '600',  'Galpão 3',  'Jardim',          'Santo André',            'SP', '09080510', '2026-03-01 08:00:00', 'ATIVO'),
( 5, 'Patrícia Gomes Cardoso',   '35715945605', 'patricia.cardoso@email.com', SHA2('cli005', 256), 'Rua das Flores',            '45',   NULL,        'Centro',          'Guarulhos',              'SP', '07010010', '2026-03-12 16:30:00', 'ATIVO'),
( 6, 'Lucas Batista Freitas',    '25836914706', 'lucas.freitas@email.com',    SHA2('cli006', 256), 'Avenida Brigadeiro Faria Lima','3477','Conj. 101','Itaim Bibi',    'São Paulo',              'SP', '04538133', '2026-04-02 11:11:00', 'ATIVO'),
( 7, 'Fernanda Araújo Monteiro', '14725836907', 'fernanda.monteiro@email.com',SHA2('cli007', 256), 'Rua Tuiuti',                '1200', 'Apto 34',   'Tatuapé',         'São Paulo',              'SP', '03081000', '2026-04-18 19:00:00', 'ATIVO'),
( 8, 'Gustavo Correia Vieira',   '96385274108', 'gustavo.vieira@email.com',   SHA2('cli008', 256), 'Rodovia Anhanguera, km 25', 'S/N',  NULL,        'Jardim Jaraguá',  'São Paulo',              'SP', '05275000', '2026-05-05 07:45:00', 'ATIVO'),
( 9, 'Beatriz Nogueira Castro',  '74185296309', 'beatriz.castro@email.com',   SHA2('cli009', 256), 'Avenida Kennedy',           '880',  NULL,        'Jardim do Mar',   'São Bernardo do Campo',  'SP', '09726253', '2026-06-10 13:25:00', 'ATIVO'),
(10, 'Roberto Carlos Duarte',    '85296374110', 'roberto.duarte@email.com',   SHA2('cli010', 256), 'Rua Voluntários da Pátria', '410',  'Apto 12',   'Santana',         'São Paulo',              'SP', '02011000', '2026-07-01 10:00:00', 'INATIVO');

-- Telefones dos clientes (multivalorado)
INSERT INTO cliente_telefone (id_cliente, telefone) VALUES
( 1, '11987654321'), ( 1, '1133224455'),
( 2, '11991234567'), ( 2, '11976543210'),
( 3, '11988887777'),
( 4, '11999990001'), ( 4, '1144556677'),
( 5, '11955554444'),
( 6, '11966667777'),
( 7, '11977778888'),
( 8, '11930001000'), ( 8, '1139990000'),
( 9, '11912345678'),
(10, '11900001111');

-- Veículos dos clientes (cliente 10 propositalmente sem veículo: cardinalidade 0,n)
INSERT INTO veiculo (id_veiculo, id_cliente, id_tipo_veiculo, placa, marca, modelo, ano, cor, blindado) VALUES
( 1, 1, 2, 'BRA2E19', 'Chevrolet',     'Onix',             2022, 'Branco',  0),
( 2, 1, 1, 'MOT1A11', 'Honda',         'CG 160',           2021, 'Vermelho',0),
( 3, 2, 3, 'SUV3B22', 'Toyota',        'Hilux',            2023, 'Prata',   1),
( 4, 3, 2, 'CAR4C33', 'Hyundai',       'HB20',             2020, 'Preto',   0),
( 5, 4, 4, 'VAN5D44', 'Fiat',          'Ducato',           2019, 'Branco',  0),
( 6, 4, 5, 'CAM6E55', 'Volkswagen',    'Delivery Express', 2021, 'Branco',  0),
( 7, 5, 2, 'CAR7F66', 'Volkswagen',    'Polo',             2023, 'Cinza',   0),
( 8, 6, 3, 'SUV8G77', 'Jeep',          'Compass',          2022, 'Preto',   1),
( 9, 7, 2, 'CAR9H88', 'Renault',       'Kwid',             2019, 'Laranja', 0),
(10, 8, 6, 'ONI1J99', 'Mercedes-Benz', 'Axor 2544',        2017, 'Azul',    0),
(11, 9, 2, 'CAR2K10', 'Fiat',          'Argo',             2021, 'Vermelho',0),
(12, 9, 1, 'MOT3L21', 'Yamaha',        'Fazer 250',        2022, 'Azul',    0),
(13, 5, 3, 'SUV4M32', 'Honda',         'HR-V',             2024, 'Branco',  0),
(14, 2, 2, 'CAR5N43', 'Toyota',        'Corolla',          2024, 'Preto',   1);

-- Solicitações (id_funcionario NULL = aberta pelo app)
-- valor_estimado = tarifa.valor_base + tarifa.valor_km * distancia_km
INSERT INTO solicitacao (id_solicitacao, id_veiculo, id_servico_reboque, id_funcionario, data_solicitacao,
                         endereco_origem, endereco_destino, distancia_km, observacoes, valor_estimado, status) VALUES
( 1,  1, 1, 3,    '2026-09-02 08:15:00', 'Av. Rebouças, 1200 - Pinheiros, São Paulo/SP',          'Oficina Pinheiros - R. dos Pinheiros, 870, São Paulo/SP',          12.00, 'Carro não liga, câmbio travado',          192.00, 'CONCLUIDA'),
( 2,  3, 2, NULL, '2026-09-06 02:30:00', 'Rod. dos Bandeirantes, km 72 - Jundiaí/SP',             'Toyota Concessionária - Av. Rebouças, 3000, São Paulo/SP',         85.00, 'Pane elétrica na rodovia, veículo blindado', 685.00, 'CONCLUIDA'),
( 3,  4, 4, 4,    '2026-09-07 10:00:00', 'R. Vergueiro, 3185 - Vila Mariana, São Paulo/SP',       NULL,                                                                5.00, 'Bateria descarregada na garagem',          87.50, 'CONCLUIDA'),
( 4,  5, 1, 3,    '2026-09-10 14:20:00', 'Av. dos Estados, 4500 - Santo André/SP',                'Oficina Diesel ABC - R. das Figueiras, 300, Santo André/SP',       18.00, 'Van de entregas com motor fundido',        320.00, 'CONCLUIDA'),
( 5, 10, 2, 2,    '2026-09-12 16:00:00', 'Rod. Anhanguera, km 98 - Valinhos/SP',                  'Pátio Transportadora - Rod. Anhanguera, km 25, São Paulo/SP',     140.00, 'Caminhão carregado, quebra de eixo',      2480.00, 'CONCLUIDA'),
( 6,  2, 1, NULL, '2026-09-15 19:30:00', 'R. Augusta, 900 - Consolação, São Paulo/SP',            'Moto Center - R. Augusta, 2200, São Paulo/SP',                      8.00, 'Corrente da moto arrebentou',             120.00, 'CONCLUIDA'),
( 7,  7, 3, 4,    '2026-09-18 11:00:00', 'Av. Monteiro Lobato, 1500 - Guarulhos/SP',              NULL,                                                                6.00, 'Pneu furado, sem estepe utilizável',       99.00, 'CONCLUIDA'),
( 8,  8, 1, 3,    '2026-09-20 09:00:00', 'Av. Faria Lima, 3477 - Itaim Bibi, São Paulo/SP',       'Jeep Concessionária - Av. Europa, 500, São Paulo/SP',              22.00, 'Luz de injeção acesa',                    299.00, 'CANCELADA'),
( 9,  6, 2, 2,    '2026-09-24 07:30:00', 'Rod. Presidente Dutra, km 210 - Guarulhos/SP',          'Oficina Diesel ABC - R. das Figueiras, 300, Santo André/SP',       60.00, 'Superaquecimento do motor',               930.00, 'CONCLUIDA'),
(10,  9, 1, NULL, '2026-09-28 03:10:00', 'R. Tuiuti, 300 - Tatuapé, São Paulo/SP',                'Auto Center Tatuapé - R. Itapura, 1000, São Paulo/SP',             15.00, 'Colisão leve, roda danificada',           202.50, 'CONCLUIDA'),
(11, 11, 1, 4,    '2026-10-02 13:00:00', 'Av. Kennedy, 1500 - São Bernardo do Campo/SP',          'Fiat Concessionária - Av. Senador Vergueiro, 2000, São Bernardo do Campo/SP', 10.00, 'Embreagem quebrada',          185.00, 'CONCLUIDA'),
(12, 12, 2, 3,    '2026-10-04 10:30:00', 'Rod. dos Imigrantes, km 40 - São Bernardo do Campo/SP', 'Yamaha Motos - Av. Kennedy, 500, São Bernardo do Campo/SP',        45.00, 'Moto parou na serra',                     275.00, 'CONCLUIDA'),
(13, 13, 5, 2,    '2026-10-06 18:00:00', 'Estrada da Roselândia, 2000 - Cotia/SP',                'Honda Concessionária - Av. Brasil, 1000, São Paulo/SP',            30.00, 'Veículo caiu em vala lateral',            780.00, 'CONCLUIDA'),
(14,  8, 2, NULL, '2026-10-09 05:20:00', 'Rod. Castello Branco, km 70 - Itu/SP',                  'Jeep Concessionária - Av. Europa, 500, São Paulo/SP',              70.00, 'Problema na transmissão',                 610.00, 'CONCLUIDA'),
(15, 14, 1, NULL, '2026-10-12 15:00:00', 'Av. Paulista, 2000 - Bela Vista, São Paulo/SP',         'Toyota Concessionária - Av. Rebouças, 3000, São Paulo/SP',         20.00, 'Veículo blindado, não dá partida',        220.00, 'CANCELADA'),
(16,  5, 1, 3,    '2026-10-14 16:00:00', 'Av. Industrial, 600 - Santo André/SP',                  'Oficina Diesel ABC - R. das Figueiras, 300, Santo André/SP',       25.00, 'Van com freio travado',                   355.00, 'CANCELADA'),
(17,  1, 4, 3,    '2026-10-15 07:50:00', 'R. Augusta, 1500 - Consolação, São Paulo/SP',           NULL,                                                                3.00, 'Bateria arriada',                          84.50, 'CONCLUIDA'),
(18,  4, 2, 4,    '2026-10-20 21:00:00', 'Rod. Régis Bittencourt, km 350 - Juquitiba/SP',         'Hyundai Concessionária - R. Vergueiro, 4000, São Paulo/SP',       120.00, 'Correia dentada rompida',                 680.00, 'CONCLUIDA'),
(19, 11, 1, 4,    '2026-10-22 12:00:00', 'Av. Kennedy, 880 - São Bernardo do Campo/SP',           'Fiat Concessionária - Av. Senador Vergueiro, 2000, São Bernardo do Campo/SP', 11.00, 'Cliente desistiu antes do aceite', 188.50, 'CANCELADA'),
(20,  3, 1, 2,    '2026-10-26 10:00:00', 'Av. Paulista, 1000 - Bela Vista, São Paulo/SP',         'Toyota Concessionária - Av. Rebouças, 3000, São Paulo/SP',         14.00, 'Barulho forte na suspensão',              263.00, 'EM_ATENDIMENTO'),
(21,  7, 1, NULL, '2026-10-27 22:15:00', 'Av. Monteiro Lobato, 800 - Guarulhos/SP',               'VW Concessionária - Av. Tiradentes, 1200, Guarulhos/SP',            9.00, 'Motor apagou e não volta',                181.50, 'EM_ATENDIMENTO'),
(22,  9, 3, 3,    '2026-10-28 08:40:00', 'R. Tuiuti, 1200 - Tatuapé, São Paulo/SP',               NULL,                                                                4.00, 'Dois pneus furados',                       96.00, 'ABERTA');

-- Notificações enviadas aos prestadores
INSERT INTO notificacao (id_solicitacao, id_prestador, data_envio, data_resposta, status) VALUES
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
(22, 2, '2026-10-28 08:41:00', NULL,                  'ENVIADA'),
(22, 7, '2026-10-28 08:41:00', NULL,                  'ENVIADA');

-- Ordens de serviço (valor_final é calculado automaticamente pelo banco)
INSERT INTO ordem_servico (id_os, id_solicitacao, id_tarifa, id_prestador, id_veiculo_reboque,
                           data_inicio, data_previsao, data_finalizacao, status_os, observacoes,
                           valor_base, valor_adicionais, desconto) VALUES
( 1,  1,  1, 1, 1, '2026-09-02 08:25:00', '2026-09-02 09:30:00', '2026-09-02 09:20:00', 'FINALIZADA',     NULL,                                        192.00,   0.00,  0.00),
( 2,  2,  5, 3, 3, '2026-09-06 02:45:00', '2026-09-06 05:00:00', '2026-09-06 05:10:00', 'FINALIZADA',     'Adicionais: madrugada + domingo + rodovia', 685.00, 230.00,  0.00),
( 3,  3, 10, 4, 4, '2026-09-07 10:10:00', '2026-09-07 11:00:00', '2026-09-07 10:50:00', 'FINALIZADA',     'Adicional de feriado (07/09)',               87.50,  30.00,  0.00),
( 4,  4,  6, 4, 4, '2026-09-10 14:35:00', '2026-09-10 16:00:00', '2026-09-10 15:40:00', 'FINALIZADA',     'Desconto cliente PJ recorrente',            320.00,   0.00, 20.00),
( 5,  5,  8, 5, 5, '2026-09-12 16:20:00', '2026-09-12 21:00:00', '2026-09-12 21:45:00', 'FINALIZADA',     'Adicional de rodovia',                     2480.00, 250.00,  0.00),
( 6,  6,  3, 6, 6, '2026-09-15 19:45:00', '2026-09-15 20:30:00', '2026-09-15 20:25:00', 'FINALIZADA',     NULL,                                        120.00,   0.00,  0.00),
( 7,  7,  9, 2, 2, '2026-09-18 11:15:00', '2026-09-18 12:00:00', '2026-09-18 11:55:00', 'FINALIZADA',     NULL,                                         99.00,   0.00,  0.00),
( 8,  8,  4, 1, 1, '2026-09-20 09:10:00', '2026-09-20 10:30:00', NULL,                  'CANCELADA',      'Cancelada pelo cliente',                    299.00,  50.00,  0.00),
( 9,  9,  7, 3, 3, '2026-09-24 07:50:00', '2026-09-24 11:00:00', '2026-09-24 10:40:00', 'FINALIZADA',     'Desconto negociado pelo supervisor',        930.00, 150.00, 50.00),
(10, 10,  1, 7, 2, '2026-09-28 03:25:00', '2026-09-28 04:30:00', '2026-09-28 04:20:00', 'FINALIZADA',     'Adicional de madrugada',                    202.50,  50.00,  0.00),
(11, 11,  1, 1, 1, '2026-10-02 13:15:00', '2026-10-02 14:15:00', '2026-10-02 14:05:00', 'FINALIZADA',     NULL,                                        185.00,   0.00,  0.00),
(12, 12, 13, 6, 6, '2026-10-04 10:50:00', '2026-10-04 13:00:00', '2026-10-04 12:40:00', 'FINALIZADA',     'Adicionais: domingo + rodovia',             275.00, 100.00,  0.00),
(13, 13, 11, 5, 3, '2026-10-06 18:20:00', '2026-10-06 21:00:00', '2026-10-06 21:30:00', 'FINALIZADA',     'Adicional de rodovia/área rural',           780.00, 200.00,  0.00),
(14, 14,  5, 5, 3, '2026-10-09 05:40:00', '2026-10-09 08:00:00', '2026-10-09 07:50:00', 'FINALIZADA',     'Adicionais: madrugada + rodovia',           610.00, 170.00, 30.00),
(15, 15,  1, 2, 2, '2026-10-12 15:10:00', '2026-10-12 16:30:00', NULL,                  'CANCELADA',      'Cancelada por falha do guincho',            220.00,  60.00,  0.00),
(16, 16,  6, 4, 4, '2026-10-14 16:15:00', '2026-10-14 17:45:00', NULL,                  'CANCELADA',      'Cancelada pela empresa',                    355.00,   0.00,  0.00),
(17, 17, 10, 7, 2, '2026-10-15 08:05:00', '2026-10-15 09:00:00', '2026-10-15 08:40:00', 'FINALIZADA',     NULL,                                         84.50,   0.00,  0.00),
(18, 18,  2, 1, 1, '2026-10-20 21:20:00', '2026-10-21 00:30:00', '2026-10-21 00:15:00', 'FINALIZADA',     'Adicional de rodovia; pagamento dividido',  680.00,  80.00,  0.00),
(19, 20,  4, 3, 3, '2026-10-26 10:15:00', '2026-10-26 12:00:00', NULL,                  'EM_ATENDIMENTO', NULL,                                        263.00,   0.00,  0.00),
(20, 21,  1, 2, 2, '2026-10-27 22:25:00', '2026-10-27 23:30:00', NULL,                  'A_CAMINHO',      NULL,                                        181.50,   0.00,  0.00);

-- Cancelamentos (o nº 3 está SEM funcionário autorizador -> aparece na auditoria)
INSERT INTO cancelamento (id_cancelamento, id_os, id_funcionario, tipo_responsavel, motivo, data_hora, valor_multa) VALUES
(1,  8, 2,    'CLIENTE',   'Cliente desistiu após deslocamento do guincho (veículo voltou a funcionar)', '2026-09-20 09:35:00', 50.00),
(2, 15, 1,    'PRESTADOR', 'Guincho apresentou pane mecânica no trajeto',                                 '2026-10-12 15:40:00',  0.00),
(3, 16, NULL, 'EMPRESA',   'Sem guincho compatível disponível na região no horário',                      '2026-10-14 16:30:00',  0.00);

-- Histórico de status — gerado a partir das OS (garante a cardinalidade 1,n de "Registra")
-- (a) ABERTA: registrada por quem abriu a solicitação (NULL = app)
INSERT INTO historico_status (id_os, id_funcionario, status, data_hora, observacao)
SELECT os.id_os, s.id_funcionario, 'ABERTA', os.data_inicio, 'OS gerada a partir da solicitação'
FROM ordem_servico os
JOIN solicitacao s ON s.id_solicitacao = os.id_solicitacao;

-- (b) A_CAMINHO: todas as OS (prestador inicia deslocamento pelo app)
INSERT INTO historico_status (id_os, id_funcionario, status, data_hora, observacao)
SELECT id_os, NULL, 'A_CAMINHO', data_inicio + INTERVAL 5 MINUTE, 'Prestador iniciou deslocamento'
FROM ordem_servico;

-- (c) EM_ATENDIMENTO: OS que chegaram ao local
INSERT INTO historico_status (id_os, id_funcionario, status, data_hora, observacao)
SELECT id_os, NULL, 'EM_ATENDIMENTO', data_inicio + INTERVAL 25 MINUTE, 'Prestador chegou ao local'
FROM ordem_servico
WHERE status_os IN ('EM_ATENDIMENTO','FINALIZADA');

-- (d) FINALIZADA
INSERT INTO historico_status (id_os, id_funcionario, status, data_hora, observacao)
SELECT id_os, NULL, 'FINALIZADA', data_finalizacao, 'Serviço concluído'
FROM ordem_servico
WHERE status_os = 'FINALIZADA';

-- (e) CANCELADA: quem autorizou o cancelamento
INSERT INTO historico_status (id_os, id_funcionario, status, data_hora, observacao)
SELECT c.id_os, c.id_funcionario, 'CANCELADA', c.data_hora, c.motivo
FROM cancelamento c;

-- (f) Intervenções manuais de funcionários
INSERT INTO historico_status (id_os, id_funcionario, status, data_hora, observacao) VALUES
( 5, 2, 'EM_ATENDIMENTO', '2026-09-12 20:30:00', 'Supervisor informou atraso ao cliente: congestionamento na Rod. Anhanguera'),
(13, 2, 'EM_ATENDIMENTO', '2026-10-06 21:10:00', 'Resgate exigiu equipamento adicional (cintas e cabo de aço)'),
( 9, 2, 'EM_ATENDIMENTO', '2026-09-24 09:00:00', 'Desconto de R$ 50,00 aprovado pelo supervisor');

-- Pagamentos
--  * OS 3  -> cobrança duplicada estornada
--  * OS 9  -> 1ª tentativa recusada, 2ª aprovada
--  * OS 11 -> pagamento PENDENTE (auditoria)
--  * OS 13 -> pago a MENOR que o valor final (auditoria)
--  * OS 18 -> pagamento dividido em duas formas
--  * OS 8  -> pagamento da multa de cancelamento
INSERT INTO pagamento (id_pagamento, id_os, id_forma_pagamento, valor, data_pagamento, status, comprovante) VALUES
( 1,  1, 1,  192.00, '2026-09-02 09:25:00', 'APROVADO',  'PIX-20260902-0001'),
( 2,  2, 2,  915.00, '2026-09-06 05:20:00', 'APROVADO',  'CC-AUT-778812'),
( 3,  3, 3,  117.50, '2026-09-07 10:55:00', 'APROVADO',  'CD-AUT-110233'),
( 4,  3, 3,  117.50, '2026-09-07 10:56:00', 'ESTORNADO', 'CD-AUT-110234'),
( 5,  4, 5,  300.00, '2026-09-25 10:00:00', 'APROVADO',  'BOL-000451'),
( 6,  5, 5, 2730.00, '2026-10-10 09:00:00', 'APROVADO',  'BOL-000467'),
( 7,  6, 4,  120.00, '2026-09-15 20:30:00', 'APROVADO',  NULL),
( 8,  7, 1,   99.00, '2026-09-18 12:00:00', 'APROVADO',  'PIX-20260918-0007'),
( 9,  8, 1,   50.00, '2026-09-20 09:50:00', 'APROVADO',  'PIX-20260920-0008'),
(10,  9, 2, 1030.00, '2026-09-24 10:50:00', 'RECUSADO',  'CC-NEG-990011'),
(11,  9, 1, 1030.00, '2026-09-24 11:05:00', 'APROVADO',  'PIX-20260924-0011'),
(12, 10, 1,  252.50, '2026-09-28 04:25:00', 'APROVADO',  'PIX-20260928-0012'),
(13, 11, 1,  185.00, NULL,                  'PENDENTE',  NULL),
(14, 12, 2,  375.00, '2026-10-04 12:45:00', 'APROVADO',  'CC-AUT-781200'),
(15, 13, 2,  900.00, '2026-10-06 21:40:00', 'APROVADO',  'CC-AUT-781355'),
(16, 14, 1,  750.00, '2026-10-09 08:00:00', 'APROVADO',  'PIX-20261009-0016'),
(17, 17, 3,   84.50, '2026-10-15 08:45:00', 'APROVADO',  'CD-AUT-120044'),
(18, 18, 1,  400.00, '2026-10-21 00:20:00', 'APROVADO',  'PIX-20261021-0018'),
(19, 18, 2,  360.00, '2026-10-21 00:22:00', 'APROVADO',  'CC-AUT-781990');

-- Avaliações (OS 11 e 17 finalizadas sem avaliação: cardinalidade 0,1)
INSERT INTO avaliacao (id_avaliacao, id_os, nota, comentario, data_avaliacao) VALUES
( 1,  1, 5, 'Atendimento rápido e prestador muito educado.',          '2026-09-02 10:00:00'),
( 2,  2, 4, 'Bom atendimento de madrugada, preço um pouco alto.',     '2026-09-06 09:00:00'),
( 3,  3, 5, 'Resolveram em poucos minutos, mesmo no feriado.',        '2026-09-07 12:00:00'),
( 4,  4, 4, NULL,                                                      '2026-09-11 08:00:00'),
( 5,  5, 3, 'Chegou depois do horário previsto.',                     '2026-09-13 10:00:00'),
( 6,  6, 5, 'Cuidado excelente com a moto.',                          '2026-09-15 21:00:00'),
( 7,  7, 5, 'Troca de pneu impecável.',                               '2026-09-18 13:00:00'),
( 8,  9, 4, 'Serviço bom, só tive problema com o cartão.',            '2026-09-25 09:00:00'),
( 9, 10, 5, 'Salvou minha madrugada!',                                '2026-09-28 08:00:00'),
(10, 12, 4, 'Moto transportada com segurança.',                       '2026-10-04 14:00:00'),
(11, 13, 2, 'Resgate demorou muito e o valor foi alto.',              '2026-10-07 09:00:00'),
(12, 14, 5, 'Excelente, mesmo de madrugada na rodovia.',              '2026-10-09 09:30:00'),
(13, 18, 5, 'Prestador muito atencioso na estrada.',                  '2026-10-21 08:00:00');


-- =====================================================================
-- 5. SELECT — CONSULTAS SIMPLES
-- =====================================================================

-- 5.1 Clientes ativos em ordem alfabética
SELECT id_cliente, nome, email, cidade, uf, data_cadastro
FROM cliente
WHERE status = 'ATIVO'
ORDER BY nome;

-- 5.2 Veículos blindados (exigem atenção especial no reboque)
SELECT id_veiculo, placa, marca, modelo, ano
FROM veiculo
WHERE blindado = 1;

-- 5.3 Prestadores autônomos (sem empresa vinculada)
SELECT id_prestador, nome, telefone, status
FROM prestador
WHERE id_empresa IS NULL;

-- 5.4 Solicitações que ainda estão em aberto ou em atendimento
SELECT id_solicitacao, data_solicitacao, endereco_origem, status
FROM solicitacao
WHERE status IN ('ABERTA','EM_ATENDIMENTO')
ORDER BY data_solicitacao;

-- 5.5 Tarifas vigentes hoje
SELECT id_tarifa, id_tipo_veiculo, id_servico_reboque, valor_base, valor_km, vigencia_inicio, vigencia_fim
FROM tarifa
WHERE status = 'ATIVA'
  AND CURDATE() BETWEEN vigencia_inicio AND COALESCE(vigencia_fim, '9999-12-31');

-- 5.6 Simulação de orçamento: automóvel (tipo 2), reboque urbano (serviço 1), 15 km, num domingo
SET @tipo_veiculo = 2, @servico = 1, @km = 15;
SELECT  t.id_tarifa,
        t.valor_base,
        t.valor_km * @km                                AS valor_distancia,
        t.adicional_domingo                             AS adicional,
        t.valor_base + t.valor_km * @km + t.adicional_domingo AS orcamento_total
FROM tarifa t
WHERE t.id_tipo_veiculo    = @tipo_veiculo
  AND t.id_servico_reboque = @servico
  AND t.status = 'ATIVA';


-- =====================================================================
-- 6. JOIN — CONSULTAS COM RELACIONAMENTOS
-- =====================================================================

-- 6.1 Clientes com telefones e quantidade de veículos (LEFT JOIN: inclui cliente sem veículo)
SELECT  c.id_cliente,
        c.nome,
        GROUP_CONCAT(DISTINCT ct.telefone SEPARATOR ' / ') AS telefones,
        COUNT(DISTINCT v.id_veiculo)                       AS qtd_veiculos
FROM cliente c
LEFT JOIN cliente_telefone ct ON ct.id_cliente = c.id_cliente
LEFT JOIN veiculo v           ON v.id_cliente  = c.id_cliente
GROUP BY c.id_cliente, c.nome
ORDER BY c.nome;

-- 6.2 Veículos com proprietário e tipo
SELECT v.placa, v.marca, v.modelo, tv.descricao AS tipo, tv.categoria, c.nome AS proprietario
FROM veiculo v
JOIN cliente c       ON c.id_cliente       = v.id_cliente
JOIN tipo_veiculo tv ON tv.id_tipo_veiculo = v.id_tipo_veiculo
ORDER BY c.nome, v.placa;

-- 6.3 Solicitações completas (quem abriu: funcionário ou aplicativo)
SELECT  s.id_solicitacao,
        s.data_solicitacao,
        c.nome                                AS cliente,
        v.placa,
        sr.descricao                          AS servico,
        COALESCE(f.nome, 'Aplicativo')        AS aberta_por,
        s.distancia_km,
        s.valor_estimado,
        s.status
FROM solicitacao s
JOIN veiculo v          ON v.id_veiculo          = s.id_veiculo
JOIN cliente c          ON c.id_cliente          = v.id_cliente
JOIN servico_reboque sr ON sr.id_servico_reboque = s.id_servico_reboque
LEFT JOIN funcionario f ON f.id_funcionario      = s.id_funcionario
ORDER BY s.data_solicitacao;

-- 6.4 Ordens de serviço detalhadas (JOIN em 9 tabelas)
SELECT  os.id_os,
        os.status_os,
        c.nome                              AS cliente,
        v.placa                             AS placa_cliente,
        tv.descricao                        AS tipo_veiculo,
        sr.descricao                        AS servico,
        p.nome                              AS prestador,
        COALESCE(e.razao_social,'Autônomo') AS empresa,
        vr.placa                            AS placa_guincho,
        tg.descricao                        AS tipo_guincho,
        os.valor_final
FROM ordem_servico os
JOIN solicitacao s      ON s.id_solicitacao      = os.id_solicitacao
JOIN veiculo v          ON v.id_veiculo          = s.id_veiculo
JOIN cliente c          ON c.id_cliente          = v.id_cliente
JOIN tipo_veiculo tv    ON tv.id_tipo_veiculo    = v.id_tipo_veiculo
JOIN servico_reboque sr ON sr.id_servico_reboque = s.id_servico_reboque
JOIN prestador p        ON p.id_prestador        = os.id_prestador
LEFT JOIN empresa e     ON e.id_empresa          = p.id_empresa
JOIN veiculo_reboque vr ON vr.id_veiculo_reboque = os.id_veiculo_reboque
JOIN tipo_guincho tg    ON tg.id_tipo_guincho    = vr.id_tipo_guincho
ORDER BY os.id_os;

-- 6.5 Matriz de compatibilidade Tipo de Veículo x Tipo de Guincho
SELECT tv.descricao AS tipo_veiculo, tg.descricao AS tipo_guincho, tg.capacidade_max_kg, cp.observacao
FROM compativel cp
JOIN tipo_veiculo tv ON tv.id_tipo_veiculo = cp.id_tipo_veiculo
JOIN tipo_guincho tg ON tg.id_tipo_guincho = cp.id_tipo_guincho
ORDER BY tv.id_tipo_veiculo, tg.id_tipo_guincho;

-- 6.6 Prestadores e os guinchos que operam (período do vínculo)
SELECT  p.nome AS prestador,
        COALESCE(e.razao_social,'Autônomo') AS empresa,
        vr.placa, vr.modelo, tg.descricao AS tipo_guincho,
        o.data_inicio, o.data_fim, o.status AS vinculo
FROM opera o
JOIN prestador p        ON p.id_prestador        = o.id_prestador
LEFT JOIN empresa e     ON e.id_empresa          = p.id_empresa
JOIN veiculo_reboque vr ON vr.id_veiculo_reboque = o.id_veiculo_reboque
JOIN tipo_guincho tg    ON tg.id_tipo_guincho    = vr.id_tipo_guincho
ORDER BY p.nome, o.data_inicio;

-- 6.7 Linha do tempo de uma OS (OS 5)
SELECT h.data_hora, h.status, COALESCE(f.nome,'Sistema/App') AS responsavel, h.observacao
FROM historico_status h
LEFT JOIN funcionario f ON f.id_funcionario = h.id_funcionario
WHERE h.id_os = 5
ORDER BY h.data_hora;

-- 6.8 Notificações de cada solicitação e tempo de resposta do prestador
SELECT  n.id_solicitacao, p.nome AS prestador, n.data_envio, n.data_resposta, n.status,
        TIMESTAMPDIFF(MINUTE, n.data_envio, n.data_resposta) AS minutos_resposta
FROM notificacao n
JOIN prestador p ON p.id_prestador = n.id_prestador
ORDER BY n.id_solicitacao, n.status;

-- 6.9 Pagamentos com forma e cliente
SELECT pg.id_pagamento, pg.id_os, c.nome AS cliente, fp.descricao AS forma, pg.valor, pg.data_pagamento, pg.status
FROM pagamento pg
JOIN forma_pagamento fp ON fp.id_forma_pagamento = pg.id_forma_pagamento
JOIN ordem_servico os   ON os.id_os              = pg.id_os
JOIN solicitacao s      ON s.id_solicitacao      = os.id_solicitacao
JOIN veiculo v          ON v.id_veiculo          = s.id_veiculo
JOIN cliente c          ON c.id_cliente          = v.id_cliente
ORDER BY pg.data_pagamento;

-- 6.10 PROCESSO: quais prestador+guincho podem atender a solicitação 22 (aberta)?
--      Regras: guincho compatível, guincho DISPONÍVEL, prestador ATIVO, vínculo ATIVO.
SELECT  s.id_solicitacao, p.id_prestador, p.nome AS prestador,
        vr.placa AS guincho, tg.descricao AS tipo_guincho
FROM solicitacao s
JOIN veiculo v          ON v.id_veiculo          = s.id_veiculo
JOIN compativel cp      ON cp.id_tipo_veiculo    = v.id_tipo_veiculo
JOIN veiculo_reboque vr ON vr.id_tipo_guincho    = cp.id_tipo_guincho
JOIN tipo_guincho tg    ON tg.id_tipo_guincho    = vr.id_tipo_guincho
JOIN opera o            ON o.id_veiculo_reboque  = vr.id_veiculo_reboque AND o.status = 'ATIVO'
JOIN prestador p        ON p.id_prestador        = o.id_prestador
WHERE s.id_solicitacao = 22
  AND vr.status = 'DISPONIVEL'
  AND p.status  = 'ATIVO';


-- =====================================================================
-- 7. CONSULTAS GERENCIAIS
-- =====================================================================

-- 7.1 Faturamento mensal (pagamentos aprovados)
SELECT  DATE_FORMAT(data_pagamento, '%Y-%m') AS mes,
        COUNT(*)                             AS qtd_pagamentos,
        SUM(valor)                           AS total_recebido,
        ROUND(AVG(valor), 2)                 AS ticket_medio
FROM pagamento
WHERE status = 'APROVADO'
GROUP BY DATE_FORMAT(data_pagamento, '%Y-%m')
ORDER BY mes;

-- 7.2 Faturamento por forma de pagamento (participação %)
SELECT  fp.descricao,
        COUNT(pg.id_pagamento) AS qtd,
        SUM(pg.valor)          AS total,
        ROUND(100 * SUM(pg.valor) / (SELECT SUM(valor) FROM pagamento WHERE status = 'APROVADO'), 2) AS percentual
FROM forma_pagamento fp
JOIN pagamento pg ON pg.id_forma_pagamento = fp.id_forma_pagamento AND pg.status = 'APROVADO'
GROUP BY fp.id_forma_pagamento, fp.descricao
ORDER BY total DESC;

-- 7.3 Ranking de prestadores (OS, faturamento gerado, nota média) com RANK()
SELECT  RANK() OVER (ORDER BY r.faturamento DESC) AS posicao, r.*
FROM (
    SELECT  p.id_prestador,
            p.nome,
            COALESCE(e.razao_social,'Autônomo')                                 AS empresa,
            COUNT(os.id_os)                                                     AS total_os,
            COALESCE(SUM(os.status_os = 'FINALIZADA'), 0)                       AS finalizadas,
            COALESCE(SUM(os.status_os = 'CANCELADA'), 0)                        AS canceladas,
            COALESCE(SUM(CASE WHEN os.status_os = 'FINALIZADA' THEN os.valor_final END), 0) AS faturamento,
            ROUND(AVG(a.nota), 2)                                               AS nota_media
    FROM prestador p
    LEFT JOIN empresa e       ON e.id_empresa   = p.id_empresa
    LEFT JOIN ordem_servico os ON os.id_prestador = p.id_prestador
    LEFT JOIN avaliacao a     ON a.id_os        = os.id_os
    GROUP BY p.id_prestador, p.nome, e.razao_social
) r;

-- 7.4 Desempenho por empresa parceira
SELECT  empresa,
        COUNT(*)                                                         AS total_os,
        SUM(status_os = 'FINALIZADA')                                    AS finalizadas,
        SUM(CASE WHEN status_os = 'FINALIZADA' THEN valor_final ELSE 0 END) AS faturamento
FROM vw_os_detalhada
GROUP BY empresa
ORDER BY faturamento DESC;

-- 7.5 Serviços mais solicitados e ticket médio
SELECT  sr.descricao,
        sr.tipo_servico,
        COUNT(s.id_solicitacao)                       AS qtd_solicitacoes,
        ROUND(AVG(os.valor_final), 2)                 AS ticket_medio_os
FROM servico_reboque sr
LEFT JOIN solicitacao s    ON s.id_servico_reboque = sr.id_servico_reboque
LEFT JOIN ordem_servico os ON os.id_solicitacao    = s.id_solicitacao AND os.status_os = 'FINALIZADA'
GROUP BY sr.id_servico_reboque, sr.descricao, sr.tipo_servico
ORDER BY qtd_solicitacoes DESC;

-- 7.6 Tempo médio (min) da solicitação até a finalização, por serviço
SELECT  servico,
        COUNT(*)                                                                AS os_finalizadas,
        ROUND(AVG(TIMESTAMPDIFF(MINUTE, data_solicitacao, data_finalizacao)), 1) AS minutos_medios_total,
        ROUND(AVG(TIMESTAMPDIFF(MINUTE, data_inicio, data_finalizacao)), 1)      AS minutos_medios_execucao
FROM vw_os_detalhada
WHERE status_os = 'FINALIZADA'
GROUP BY servico
ORDER BY minutos_medios_total DESC;

-- 7.7 Taxa de cancelamento geral e por responsável
SELECT  COUNT(*)                                            AS total_os,
        SUM(status_os = 'CANCELADA')                        AS canceladas,
        ROUND(100 * SUM(status_os = 'CANCELADA') / COUNT(*), 2) AS taxa_cancelamento_pct
FROM ordem_servico;

SELECT tipo_responsavel, COUNT(*) AS qtd, SUM(valor_multa) AS multas
FROM cancelamento
GROUP BY tipo_responsavel;

-- 7.8 Top 5 clientes por valor pago
SELECT  c.id_cliente, c.nome,
        COUNT(DISTINCT os.id_os) AS qtd_os,
        SUM(pg.valor)            AS total_pago
FROM cliente c
JOIN veiculo v        ON v.id_cliente      = c.id_cliente
JOIN solicitacao s    ON s.id_veiculo      = v.id_veiculo
JOIN ordem_servico os ON os.id_solicitacao = s.id_solicitacao
JOIN pagamento pg     ON pg.id_os          = os.id_os AND pg.status = 'APROVADO'
GROUP BY c.id_cliente, c.nome
ORDER BY total_pago DESC
LIMIT 5;

-- 7.9 Utilização da frota de guinchos (inclui os que não foram usados)
SELECT  vr.placa, vr.modelo, tg.descricao AS tipo, vr.status,
        COUNT(os.id_os)                      AS qtd_os,
        COALESCE(SUM(s.distancia_km), 0)     AS km_rodados,
        COALESCE(SUM(os.valor_final), 0)     AS receita_gerada
FROM veiculo_reboque vr
JOIN tipo_guincho tg       ON tg.id_tipo_guincho   = vr.id_tipo_guincho
LEFT JOIN ordem_servico os ON os.id_veiculo_reboque = vr.id_veiculo_reboque AND os.status_os <> 'CANCELADA'
LEFT JOIN solicitacao s    ON s.id_solicitacao      = os.id_solicitacao
GROUP BY vr.id_veiculo_reboque, vr.placa, vr.modelo, tg.descricao, vr.status
ORDER BY qtd_os DESC;

-- 7.10 Produtividade dos atendentes (solicitações abertas) x canal aplicativo
SELECT  COALESCE(f.nome, 'Aplicativo') AS canal_atendente,
        COUNT(*)                       AS solicitacoes_abertas,
        SUM(s.status = 'CONCLUIDA')    AS concluidas
FROM solicitacao s
LEFT JOIN funcionario f ON f.id_funcionario = s.id_funcionario
GROUP BY f.id_funcionario, f.nome
ORDER BY solicitacoes_abertas DESC;

-- 7.11 Taxa de aceite das notificações por prestador
SELECT  p.nome,
        COUNT(*)                                                      AS notificacoes,
        SUM(n.status = 'ACEITA')                                      AS aceitas,
        ROUND(100 * SUM(n.status = 'ACEITA') / COUNT(*), 1)           AS taxa_aceite_pct,
        ROUND(AVG(TIMESTAMPDIFF(MINUTE, n.data_envio, n.data_resposta)), 1) AS min_medio_resposta
FROM notificacao n
JOIN prestador p ON p.id_prestador = n.id_prestador
GROUP BY p.id_prestador, p.nome
ORDER BY taxa_aceite_pct DESC;

-- 7.12 Demanda por dia da semana e faixa horária
SELECT  ELT(DAYOFWEEK(data_solicitacao), 'Domingo','Segunda','Terça','Quarta','Quinta','Sexta','Sábado') AS dia_semana,
        CASE
            WHEN HOUR(data_solicitacao) < 6  THEN '00h-06h (madrugada)'
            WHEN HOUR(data_solicitacao) < 12 THEN '06h-12h (manhã)'
            WHEN HOUR(data_solicitacao) < 18 THEN '12h-18h (tarde)'
            ELSE '18h-24h (noite)'
        END AS faixa_horaria,
        COUNT(*) AS qtd
FROM solicitacao
GROUP BY dia_semana, faixa_horaria
ORDER BY qtd DESC;

-- 7.13 Satisfação: distribuição das notas e NPS simplificado
SELECT nota, COUNT(*) AS qtd FROM avaliacao GROUP BY nota ORDER BY nota DESC;

SELECT  ROUND(AVG(nota), 2)                                                  AS nota_media,
        ROUND(100 * (SUM(nota = 5) - SUM(nota <= 3)) / COUNT(*), 1)          AS nps_simplificado
FROM avaliacao;


-- =====================================================================
-- 8. CONSULTAS DE AUDITORIA
--    (resultado esperado com a massa de dados indicado em cada uma)
-- =====================================================================

-- 8.1 Trilha completa de alterações de status (quem, quando, o quê)
SELECT  h.id_historico, h.id_os, h.status, h.data_hora,
        COALESCE(f.nome, 'Sistema/App') AS alterado_por,
        f.perfil_acesso, h.observacao
FROM historico_status h
LEFT JOIN funcionario f ON f.id_funcionario = h.id_funcionario
ORDER BY h.id_os, h.data_hora;

-- 8.2 OS cujo status atual difere do último status registrado no histórico
--     Esperado: nenhuma linha
SELECT os.id_os, os.status_os, h.status AS ultimo_status_historico, h.data_hora
FROM ordem_servico os
JOIN historico_status h ON h.id_os = os.id_os
WHERE h.data_hora = (SELECT MAX(h2.data_hora) FROM historico_status h2 WHERE h2.id_os = os.id_os)
  AND h.status <> os.status_os;

-- 8.3 OS sem nenhum registro de histórico (viola cardinalidade 1,n)
--     Esperado: nenhuma linha
SELECT os.id_os
FROM ordem_servico os
LEFT JOIN historico_status h ON h.id_os = os.id_os
WHERE h.id_historico IS NULL;

-- 8.4 OS finalizadas sem pagamento aprovado
--     Esperado: OS 11 (pagamento pendente)
SELECT os.id_os, os.valor_final, os.data_finalizacao
FROM ordem_servico os
WHERE os.status_os = 'FINALIZADA'
  AND NOT EXISTS (SELECT 1 FROM pagamento pg WHERE pg.id_os = os.id_os AND pg.status = 'APROVADO');

-- 8.5 Divergência entre valor devido e valor efetivamente pago
--     (FINALIZADA compara com valor_final; CANCELADA compara com a multa)
--     Esperado: OS 11 (0,00 de 185,00) e OS 13 (900,00 de 980,00)
SELECT  os.id_os,
        os.status_os,
        CASE WHEN os.status_os = 'CANCELADA' THEN COALESCE(c.valor_multa, 0) ELSE os.valor_final END AS valor_devido,
        COALESCE(SUM(CASE WHEN pg.status = 'APROVADO' THEN pg.valor END), 0)                   AS valor_pago
FROM ordem_servico os
LEFT JOIN cancelamento c ON c.id_os  = os.id_os
LEFT JOIN pagamento pg   ON pg.id_os = os.id_os
WHERE os.status_os IN ('FINALIZADA','CANCELADA')
GROUP BY os.id_os, os.status_os, os.valor_final, c.valor_multa
HAVING valor_devido <> valor_pago;

-- 8.6 Pagamentos recusados ou estornados
--     Esperado: pagamento 4 (estorno OS 3) e 10 (recusa OS 9)
SELECT pg.id_pagamento, pg.id_os, fp.descricao, pg.valor, pg.data_pagamento, pg.status, pg.comprovante
FROM pagamento pg
JOIN forma_pagamento fp ON fp.id_forma_pagamento = pg.id_forma_pagamento
WHERE pg.status IN ('RECUSADO','ESTORNADO');

-- 8.7 Cancelamentos sem funcionário autorizador
--     Esperado: cancelamento 3 (OS 16)
SELECT c.id_cancelamento, c.id_os, c.tipo_responsavel, c.motivo, c.data_hora
FROM cancelamento c
WHERE c.id_funcionario IS NULL;

-- 8.8 OS executadas por prestador SEM vínculo ativo com o guincho na data
--     Esperado: nenhuma linha
SELECT os.id_os, os.id_prestador, os.id_veiculo_reboque, os.data_inicio
FROM ordem_servico os
WHERE NOT EXISTS (
    SELECT 1 FROM opera o
    WHERE o.id_prestador       = os.id_prestador
      AND o.id_veiculo_reboque = os.id_veiculo_reboque
      AND DATE(os.data_inicio) >= o.data_inicio
      AND (o.data_fim IS NULL OR DATE(os.data_inicio) <= o.data_fim)
);

-- 8.9 OS com guincho incompatível com o tipo do veículo do cliente
--     Esperado: nenhuma linha
SELECT os.id_os, v.placa, v.id_tipo_veiculo, vr.placa AS guincho, vr.id_tipo_guincho
FROM ordem_servico os
JOIN solicitacao s      ON s.id_solicitacao      = os.id_solicitacao
JOIN veiculo v          ON v.id_veiculo          = s.id_veiculo
JOIN veiculo_reboque vr ON vr.id_veiculo_reboque = os.id_veiculo_reboque
WHERE NOT EXISTS (
    SELECT 1 FROM compativel cp
    WHERE cp.id_tipo_veiculo = v.id_tipo_veiculo
      AND cp.id_tipo_guincho = vr.id_tipo_guincho
);

-- 8.10 OS com tarifa errada (tipo de veículo/serviço diferente ou fora da vigência)
--      Esperado: nenhuma linha
SELECT os.id_os, os.id_tarifa, v.id_tipo_veiculo, s.id_servico_reboque, s.data_solicitacao
FROM ordem_servico os
JOIN solicitacao s ON s.id_solicitacao = os.id_solicitacao
JOIN veiculo v     ON v.id_veiculo     = s.id_veiculo
JOIN tarifa t      ON t.id_tarifa      = os.id_tarifa
WHERE t.id_tipo_veiculo    <> v.id_tipo_veiculo
   OR t.id_servico_reboque <> s.id_servico_reboque
   OR DATE(s.data_solicitacao) < t.vigencia_inicio
   OR (t.vigencia_fim IS NOT NULL AND DATE(s.data_solicitacao) > t.vigencia_fim);

-- 8.11 Valor base cobrado diferente do valor estimado na solicitação
--      Esperado: nenhuma linha
SELECT os.id_os, s.valor_estimado, os.valor_base
FROM ordem_servico os
JOIN solicitacao s ON s.id_solicitacao = os.id_solicitacao
WHERE os.valor_base <> s.valor_estimado;

-- 8.12 Status da solicitação inconsistente com o status da OS
--      Esperado: nenhuma linha
SELECT s.id_solicitacao, s.status AS status_solicitacao, os.id_os, os.status_os
FROM solicitacao s
LEFT JOIN ordem_servico os ON os.id_solicitacao = s.id_solicitacao
WHERE (os.status_os = 'FINALIZADA' AND s.status <> 'CONCLUIDA')
   OR (os.status_os = 'CANCELADA'  AND s.status <> 'CANCELADA')
   OR (os.status_os IN ('ABERTA','A_CAMINHO','EM_ATENDIMENTO') AND s.status <> 'EM_ATENDIMENTO')
   OR (os.id_os IS NULL AND s.status IN ('CONCLUIDA','EM_ATENDIMENTO'));

-- 8.13 OS finalizadas após o horário previsto (SLA)
--      Esperado: OS 2, OS 5 e OS 13
SELECT  id_os, prestador, data_previsao, data_finalizacao,
        TIMESTAMPDIFF(MINUTE, data_previsao, data_finalizacao) AS minutos_atraso
FROM vw_os_detalhada
WHERE status_os = 'FINALIZADA'
  AND data_finalizacao > data_previsao
ORDER BY minutos_atraso DESC;

-- 8.14 Avaliações de OS que não foram finalizadas
--      Esperado: nenhuma linha
SELECT a.id_avaliacao, a.id_os, os.status_os
FROM avaliacao a
JOIN ordem_servico os ON os.id_os = a.id_os
WHERE os.status_os <> 'FINALIZADA';

-- 8.15 Guincho com capacidade acima do limite do seu tipo
--      Esperado: nenhuma linha
SELECT vr.placa, vr.capacidade_kg, tg.descricao, tg.capacidade_max_kg
FROM veiculo_reboque vr
JOIN tipo_guincho tg ON tg.id_tipo_guincho = vr.id_tipo_guincho
WHERE vr.capacidade_kg > tg.capacidade_max_kg;

-- 8.16 OS em andamento com prestador não ativo ou guincho em manutenção/inativo
--      Esperado: nenhuma linha
SELECT os.id_os, p.nome, p.status AS status_prestador, vr.placa, vr.status AS status_guincho
FROM ordem_servico os
JOIN prestador p        ON p.id_prestador        = os.id_prestador
JOIN veiculo_reboque vr ON vr.id_veiculo_reboque = os.id_veiculo_reboque
WHERE os.status_os IN ('ABERTA','A_CAMINHO','EM_ATENDIMENTO')
  AND (p.status <> 'ATIVO' OR vr.status IN ('MANUTENCAO','INATIVO'));

-- 8.17 Descontos concedidos (quem autorizou consta no histórico)
SELECT os.id_os, os.valor_base + os.valor_adicionais AS valor_bruto, os.desconto,
       ROUND(100 * os.desconto / (os.valor_base + os.valor_adicionais), 2) AS desconto_pct,
       os.observacoes
FROM ordem_servico os
WHERE os.desconto > 0
ORDER BY desconto_pct DESC;


-- =====================================================================
-- 9. UPDATE — PROCESSOS EMPRESARIAIS (em transação)
-- =====================================================================
START TRANSACTION;

-- 9.1 PROCESSO: finalizar a OS 19 (solicitação 20)
UPDATE ordem_servico
   SET status_os = 'FINALIZADA',
       data_finalizacao = '2026-10-26 11:50:00'
 WHERE id_os = 19;

INSERT INTO historico_status (id_os, id_funcionario, status, data_hora, observacao)
VALUES (19, NULL, 'FINALIZADA', '2026-10-26 11:50:00', 'Serviço concluído');

UPDATE solicitacao     SET status = 'CONCLUIDA'  WHERE id_solicitacao = 20;
UPDATE veiculo_reboque SET status = 'DISPONIVEL' WHERE id_veiculo_reboque = 3;

INSERT INTO pagamento (id_os, id_forma_pagamento, valor, data_pagamento, status, comprovante)
SELECT id_os, 1, valor_final, '2026-10-26 11:55:00', 'APROVADO', 'PIX-20261026-0020'
FROM ordem_servico WHERE id_os = 19;

-- 9.2 PROCESSO: OS 20 — prestador chegou ao local
UPDATE ordem_servico SET status_os = 'EM_ATENDIMENTO' WHERE id_os = 20;
INSERT INTO historico_status (id_os, id_funcionario, status, data_hora, observacao)
VALUES (20, NULL, 'EM_ATENDIMENTO', '2026-10-27 22:50:00', 'Prestador chegou ao local');

-- 9.3 Baixa do pagamento pendente da OS 11 (setor financeiro)
UPDATE pagamento
   SET status = 'APROVADO',
       data_pagamento = '2026-10-28 09:00:00',
       comprovante = 'PIX-20261028-0013'
 WHERE id_pagamento = 13;

-- 9.4 Reajuste de tarifa com versionamento: encerra a vigência atual e cria a nova
UPDATE tarifa SET vigencia_fim = '2026-10-31' WHERE id_tarifa = 2;

INSERT INTO tarifa (id_tipo_veiculo, id_servico_reboque, valor_base, valor_km,
                    adicional_madrugada, adicional_domingo, adicional_feriado, adicional_rodovia,
                    vigencia_inicio, vigencia_fim, status)
SELECT id_tipo_veiculo, id_servico_reboque,
       ROUND(valor_base * 1.05, 2), ROUND(valor_km * 1.05, 2),
       adicional_madrugada, adicional_domingo, adicional_feriado, adicional_rodovia,
       '2026-11-01', NULL, 'ATIVA'
FROM tarifa WHERE id_tarifa = 2;

-- 9.5 Guincho 7 volta da manutenção
UPDATE veiculo_reboque SET status = 'DISPONIVEL' WHERE id_veiculo_reboque = 7;

-- 9.6 Atualização cadastral de cliente
UPDATE cliente SET email = 'juliana.r.fernandes@email.com' WHERE id_cliente = 3;

-- 9.7 UPDATE com JOIN: expira notificações sem resposta há mais de 30 min
UPDATE notificacao n
JOIN solicitacao s ON s.id_solicitacao = n.id_solicitacao
   SET n.status = 'EXPIRADA'
 WHERE n.status = 'ENVIADA'
   AND n.data_envio < NOW() - INTERVAL 30 MINUTE;

COMMIT;


-- =====================================================================
-- 10. DELETE
-- =====================================================================
START TRANSACTION;

-- 10.1 Remover telefone desativado de um cliente
DELETE FROM cliente_telefone
 WHERE id_cliente = 2 AND telefone = '11976543210';

-- 10.2 Limpeza: notificações expiradas anteriores a outubro/2026
DELETE FROM notificacao
 WHERE status = 'EXPIRADA'
   AND data_envio < '2026-10-01';

-- 10.3 Excluir tarifa antiga que nunca foi aplicada em nenhuma OS
DELETE FROM tarifa
 WHERE id_tarifa = 12
   AND NOT EXISTS (SELECT 1 FROM ordem_servico os WHERE os.id_tarifa = 12);

-- 10.4 Excluir cliente inativo sem veículos (telefones apagados em CASCADE)
DELETE FROM cliente
 WHERE id_cliente = 10
   AND NOT EXISTS (SELECT 1 FROM veiculo v WHERE v.id_cliente = 10);

COMMIT;


-- =====================================================================
-- 11. TESTES DE INTEGRIDADE
--     Descomente UM por vez: TODOS devem gerar ERRO (prova que as
--     restrições estão funcionando). Não descomente para importar o script.
-- =====================================================================

-- [PK/UNIQUE] CPF de cliente duplicado
-- INSERT INTO cliente (nome, cpf, email, senha, logradouro, numero, bairro, cidade, uf, cep)
-- VALUES ('Teste', '32165498701', 'teste@email.com', SHA2('x',256), 'Rua X', '1', 'Centro', 'São Paulo', 'SP', '01000000');

-- [FK] Veículo para cliente inexistente
-- INSERT INTO veiculo (id_cliente, id_tipo_veiculo, placa, marca, modelo, ano, cor)
-- VALUES (999, 2, 'TST1A11', 'Fiat', 'Uno', 2010, 'Branco');

-- [FK RESTRICT] Excluir cliente que possui veículos
-- DELETE FROM cliente WHERE id_cliente = 1;

-- [FK RESTRICT] Excluir prestador com OS executadas
-- DELETE FROM prestador WHERE id_prestador = 1;

-- [UNIQUE 1:1] Segunda OS para a mesma solicitação (Gera 0,1)
-- INSERT INTO ordem_servico (id_solicitacao, id_tarifa, id_prestador, id_veiculo_reboque, data_inicio, valor_base)
-- VALUES (1, 1, 1, 1, '2026-09-02 10:00:00', 100.00);

-- [UNIQUE 1:1] Segunda avaliação para a mesma OS
-- INSERT INTO avaliacao (id_os, nota) VALUES (1, 4);

-- [CHECK] Nota fora da faixa 1..5
-- INSERT INTO avaliacao (id_os, nota) VALUES (11, 6);

-- [CHECK] Desconto maior que o valor do serviço
-- UPDATE ordem_servico SET desconto = 9999 WHERE id_os = 1;

-- [CHECK] OS finalizada sem data de finalização
-- UPDATE ordem_servico SET status_os = 'FINALIZADA' WHERE id_os = 20;

-- [CHECK] Placa fora do padrão
-- INSERT INTO veiculo (id_cliente, id_tipo_veiculo, placa, marca, modelo, ano, cor)
-- VALUES (1, 2, '123ABCD', 'Fiat', 'Uno', 2010, 'Branco');

-- [CHECK] Vigência final anterior à inicial
-- INSERT INTO tarifa (id_tipo_veiculo, id_servico_reboque, valor_base, valor_km, vigencia_inicio, vigencia_fim)
-- VALUES (2, 3, 50, 1, '2026-12-01', '2026-11-01');

-- [CHECK] Vínculo encerrado sem data_fim
-- INSERT INTO opera (id_prestador, id_veiculo_reboque, data_inicio, status) VALUES (6, 1, '2026-10-01', 'ENCERRADO');

-- [CHECK] Pagamento com valor zero/negativo
-- INSERT INTO pagamento (id_os, id_forma_pagamento, valor, data_pagamento, status) VALUES (1, 1, 0, NOW(), 'APROVADO');

-- [COLUNA DERIVADA] Tentar gravar valor_final manualmente
-- UPDATE ordem_servico SET valor_final = 1.00 WHERE id_os = 1;


-- =====================================================================
-- 12. CONFERÊNCIA FINAL — quantidade de registros por tabela
-- =====================================================================
SELECT 'cliente' AS tabela, COUNT(*) AS registros FROM cliente
UNION ALL SELECT 'cliente_telefone', COUNT(*) FROM cliente_telefone
UNION ALL SELECT 'veiculo',          COUNT(*) FROM veiculo
UNION ALL SELECT 'tipo_veiculo',     COUNT(*) FROM tipo_veiculo
UNION ALL SELECT 'tipo_guincho',     COUNT(*) FROM tipo_guincho
UNION ALL SELECT 'compativel',       COUNT(*) FROM compativel
UNION ALL SELECT 'servico_reboque',  COUNT(*) FROM servico_reboque
UNION ALL SELECT 'tarifa',           COUNT(*) FROM tarifa
UNION ALL SELECT 'empresa',          COUNT(*) FROM empresa
UNION ALL SELECT 'prestador',        COUNT(*) FROM prestador
UNION ALL SELECT 'veiculo_reboque',  COUNT(*) FROM veiculo_reboque
UNION ALL SELECT 'opera',            COUNT(*) FROM opera
UNION ALL SELECT 'funcionario',      COUNT(*) FROM funcionario
UNION ALL SELECT 'solicitacao',      COUNT(*) FROM solicitacao
UNION ALL SELECT 'notificacao',      COUNT(*) FROM notificacao
UNION ALL SELECT 'ordem_servico',    COUNT(*) FROM ordem_servico
UNION ALL SELECT 'historico_status', COUNT(*) FROM historico_status
UNION ALL SELECT 'cancelamento',     COUNT(*) FROM cancelamento
UNION ALL SELECT 'pagamento',        COUNT(*) FROM pagamento
UNION ALL SELECT 'forma_pagamento',  COUNT(*) FROM forma_pagamento
UNION ALL SELECT 'avaliacao',        COUNT(*) FROM avaliacao;

-- FIM DO SCRIPT
