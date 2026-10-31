-- =====================================================================
--  FELIGUINCHOS — CONSULTAS 01: SELECT
--  Consultas simples (uma tabela). Executar depois de ddl/ e dados/
-- =====================================================================
USE feliguinchos;

-- A1. Pessoas cadastradas, em ordem alfabética
SELECT cpf, nome, email, data_cadastro
FROM pessoa
ORDER BY nome;

-- A2. Pessoas que atuam como pessoa jurídica (cnpj preenchido)
SELECT cpf, nome, cnpj
FROM pessoa
WHERE cnpj IS NOT NULL;

-- A3. Clientes ativos
SELECT cliente_id, cpf, status
FROM cliente
WHERE status = 'ATIVO';

-- A4. Veículos blindados
SELECT veiculo_id, placa, ano, cor
FROM veiculo
WHERE blindado = TRUE;

-- A5. Prestadores autônomos (sem empresa) e prestadores aguardando análise
SELECT prestador_id, cpf, cnh, status
FROM prestador_servico
WHERE empresa_id IS NULL;

SELECT prestador_id, cpf, status
FROM prestador_servico
WHERE status = 'EM_ANALISE';

-- A6. CEPs genéricos (cidades com CEP único)
SELECT cep, cidade_id
FROM cep
WHERE cep_generico = TRUE;

-- A7. Solicitações ainda sem O.S. (solicitadas ou em análise)
SELECT solicitacao_id, data_hora_solicitacao, origem_cep, status
FROM solicitacao
WHERE status IN ('SOLICITADA','EM_ANALISE')
ORDER BY data_hora_solicitacao;

-- A8. Tarifas vigentes hoje (a vigência substitui o antigo campo status)
SELECT tarifa_id, tipo_veiculo_id, servico_id, valor_base, valor_por_km, vigencia_inicio, vigencia_fim
FROM tarifa
WHERE CURDATE() BETWEEN vigencia_inicio AND COALESCE(vigencia_fim, '9999-12-31');

-- A9. Simulação de orçamento: automóvel, reboque urbano, 15 km, num domingo
SET @tipo_veiculo = 2, @servico = 1, @km = 15;
SELECT tarifa_id,
       valor_base,
       valor_por_km * @km                                  AS valor_distancia,
       adicional_domingo                                   AS adicional,
       valor_base + valor_por_km * @km + adicional_domingo AS orcamento_total
FROM tarifa
WHERE tipo_veiculo_id = @tipo_veiculo
  AND servico_id      = @servico
  AND CURDATE() BETWEEN vigencia_inicio AND COALESCE(vigencia_fim, '9999-12-31');
