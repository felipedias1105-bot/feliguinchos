-- =====================================================================
--  FELIGUINCHOS — DDL 03: VIEWS
--  Views de apoio: recompõem os dados normalizados para leitura.
--  Executar depois de 02_gatilhos.sql
-- =====================================================================
USE feliguinchos;

-- ---------------------------------------------------------------------
-- Endereços de origem e destino da solicitação, montados a partir do CEP.
-- Se o CEP for genérico, usa o logradouro e o bairro informados.
-- ---------------------------------------------------------------------
CREATE VIEW vw_solicitacao_endereco AS
SELECT  s.solicitacao_id,
        s.origem_cep,
        CONCAT_WS(', ', COALESCE(co.logradouro, s.origem_logradouro_informado), s.origem_numero,
                  s.origem_complemento, COALESCE(co.bairro, s.origem_bairro_informado))   AS origem_endereco,
        CONCAT(cio.nome, '/', cio.uf)                                                      AS origem_cidade,
        s.destino_cep,
        CONCAT_WS(', ', COALESCE(cd.logradouro, s.destino_logradouro_informado), s.destino_numero,
                  s.destino_complemento, COALESCE(cd.bairro, s.destino_bairro_informado)) AS destino_endereco,
        CONCAT(cid.nome, '/', cid.uf)                                                      AS destino_cidade
FROM solicitacao s
JOIN cep    co  ON co.cep        = s.origem_cep
JOIN cidade cio ON cio.cidade_id = co.cidade_id
JOIN cep    cd  ON cd.cep        = s.destino_cep
JOIN cidade cid ON cid.cidade_id = cd.cidade_id;

-- ---------------------------------------------------------------------
-- O.S. consolidada com cliente, veículo, serviço, prestador e guincho
-- ---------------------------------------------------------------------
CREATE VIEW vw_ordem_servico_detalhada AS
SELECT  os.ordem_id,
        os.status_atual,
        s.solicitacao_id,
        s.data_hora_solicitacao,
        c.cliente_id,
        pc.nome                                AS cliente,
        v.placa                                AS placa_veiculo,
        CONCAT(mv.marca, ' ', mv.nome)         AS veiculo,
        tv.descricao                           AS tipo_veiculo,
        sr.descricao                           AS servico,
        e.origem_cidade,
        p.prestador_id,
        pp.nome                                AS prestador,
        COALESCE(emp.razao_social, 'Autônomo') AS empresa,
        vr.placa                               AS placa_guincho,
        tg.descricao                           AS tipo_guincho,
        s.distancia_km,
        os.data_hora_inicio,
        os.data_previsao,
        os.data_hora_fim,
        os.valor_base,
        os.valor_adicionais,
        os.desconto,
        os.valor_total
FROM ordem_servico os
JOIN solicitacao             s   ON s.solicitacao_id      = os.solicitacao_id
JOIN vw_solicitacao_endereco e   ON e.solicitacao_id      = s.solicitacao_id
JOIN veiculo                 v   ON v.veiculo_id          = s.veiculo_id
JOIN modelo_veiculo          mv  ON mv.modelo_id          = v.modelo_id
JOIN cliente                 c   ON c.cliente_id          = v.cliente_id
JOIN pessoa                  pc  ON pc.cpf                = c.cpf
JOIN tipo_veiculo            tv  ON tv.tipo_veiculo_id    = v.tipo_veiculo_id
JOIN servico_reboque         sr  ON sr.servico_id         = s.servico_id
JOIN prestador_servico       p   ON p.prestador_id        = os.prestador_id
JOIN pessoa                  pp  ON pp.cpf                = p.cpf
LEFT JOIN empresa            emp ON emp.empresa_id        = p.empresa_id
JOIN veiculo_reboque         vr  ON vr.veiculo_reboque_id = os.veiculo_reboque_id
JOIN tipo_guincho            tg  ON tg.tipo_guincho_id    = vr.tipo_guincho_id;
