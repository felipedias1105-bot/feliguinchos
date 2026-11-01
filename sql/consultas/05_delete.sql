-- =====================================================================
--  FELIGUINCHOS — CONSULTAS 05: DELETE
--  Pela regra do modelo (RN12/RNF09), cadastros saem de uso por status;
--  exclusão física só onde não há histórico a preservar. Notificações,
--  status, pagamentos e cancelamentos nunca são apagados (RF14).
-- =====================================================================
USE feliguinchos;

START TRANSACTION;

-- F1. Remover telefone desativado de uma pessoa (cliente 2)
DELETE pt FROM pessoa_telefone pt
JOIN cliente c ON c.cpf = pt.cpf
WHERE c.cliente_id = 2 AND pt.telefone = '11976543210';

-- F2. Excluir tarifa antiga que nunca foi aplicada
DELETE FROM tarifa
 WHERE tarifa_id = 12
   AND NOT EXISTS (SELECT 1 FROM ordem_servico WHERE tarifa_id = 12);

-- F3. Excluir cadastro PENDENTE nunca concluído (sem veículos):
--     primeiro o papel de cliente, depois a pessoa, se ela não tiver outro papel.
--     Os telefones da pessoa são apagados em CASCADE.
DELETE FROM cliente
 WHERE cliente_id = 10 AND status = 'PENDENTE'
   AND NOT EXISTS (SELECT 1 FROM veiculo WHERE cliente_id = 10);

DELETE FROM pessoa
 WHERE cpf = '85296374110'
   AND NOT EXISTS (SELECT 1 FROM cliente           WHERE cpf = '85296374110')
   AND NOT EXISTS (SELECT 1 FROM funcionario       WHERE cpf = '85296374110')
   AND NOT EXISTS (SELECT 1 FROM prestador_servico WHERE cpf = '85296374110');

-- F4. Excluir CEP cadastrado que não é usado por nenhuma pessoa ou solicitação
DELETE FROM cep
 WHERE cep = '01001000'
   AND NOT EXISTS (SELECT 1 FROM pessoa      WHERE cep = '01001000')
   AND NOT EXISTS (SELECT 1 FROM solicitacao WHERE origem_cep = '01001000' OR destino_cep = '01001000');

COMMIT;
