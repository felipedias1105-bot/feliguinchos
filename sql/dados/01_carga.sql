-- =====================================================================
--  FELIGUINCHOS — DADOS 01: CARGA DE DADOS (MASSA DE TESTE)
--  Executar depois dos 3 arquivos de ddl/
--  Período simulado: set/2026 a out/2026 (feriados: 07/09 e 12/10)
--
--  A carga passa pelos gatilhos, então ela própria comprova as regras.
--  Casos que o modelo normalizado permite e que estão na carga:
--   * a mesma pessoa com dois papéis (Paulo Sérgio: prestador e cliente)
--   * o mesmo modelo usado por veículo e por guincho (Fiat Strada)
--   * CEP genérico com logradouro e bairro informados (Juquitiba e
--     Pirapora do Bom Jesus)
--   * pessoa atuando como pessoa jurídica (cnpj preenchido)
-- =====================================================================
USE feliguinchos;

-- =====================================================================
-- ENDEREÇOS
-- =====================================================================
INSERT INTO cidade (cidade_id, nome, uf) VALUES
( 1, 'São Paulo',             'SP'),
( 2, 'Santo André',           'SP'),
( 3, 'Guarulhos',             'SP'),
( 4, 'São Bernardo do Campo', 'SP'),
( 5, 'Jundiaí',               'SP'),
( 6, 'Valinhos',              'SP'),
( 7, 'Cotia',                 'SP'),
( 8, 'Itu',                   'SP'),
( 9, 'Juquitiba',             'SP'),
(10, 'Pirapora do Bom Jesus', 'SP');

-- CEP genérico: cidade com CEP único, sem logradouro próprio
INSERT INTO cep (cep, cidade_id, logradouro, bairro, cep_generico) VALUES
('01001000',  1, 'Praça da Sé',                   'Sé',                  FALSE),
('01304001',  1, 'Rua Augusta',                   'Consolação',          FALSE),
('01310200',  1, 'Avenida Paulista',              'Bela Vista',          FALSE),
('01412000',  1, 'Rua Augusta',                   'Cerqueira César',     FALSE),
('01430000',  1, 'Avenida Brasil',                'Jardim América',      FALSE),
('01449000',  1, 'Avenida Europa',                'Jardim Europa',       FALSE),
('03081000',  1, 'Rua Tuiuti',                    'Tatuapé',             FALSE),
('03310000',  1, 'Rua Itapura',                   'Tatuapé',             FALSE),
('04101300',  1, 'Rua Vergueiro',                 'Vila Mariana',        FALSE),
('04538133',  1, 'Avenida Brigadeiro Faria Lima', 'Itaim Bibi',          FALSE),
('05275000',  1, 'Rodovia Anhanguera',            'Jardim Jaraguá',      FALSE),
('05402000',  1, 'Avenida Rebouças',              'Pinheiros',           FALSE),
('05422001',  1, 'Rua dos Pinheiros',             'Pinheiros',           FALSE),
('09080510',  2, 'Avenida Industrial',            'Jardim',              FALSE),
('09080300',  2, 'Rua das Figueiras',             'Jardim',              FALSE),
('09210580',  2, 'Avenida dos Estados',           'Santa Terezinha',     FALSE),
('07010010',  3, 'Rua das Flores',                'Centro',              FALSE),
('07112000',  3, 'Avenida Monteiro Lobato',       'Macedo',              FALSE),
('07034000',  3, 'Rodovia Presidente Dutra',      'Vila Endres',         FALSE),
('07090000',  3, 'Avenida Tiradentes',            'Centro',              FALSE),
('09726253',  4, 'Avenida Kennedy',               'Jardim do Mar',       FALSE),
('09750000',  4, 'Avenida Senador Vergueiro',     'Centro',              FALSE),
('09845000',  4, 'Rodovia dos Imigrantes',        'Riacho Grande',       FALSE),
('13213000',  5, 'Rodovia dos Bandeirantes',      'Distrito Industrial', FALSE),
('13278000',  6, 'Rodovia Anhanguera',            'Macuco',              FALSE),
('06705000',  7, 'Estrada da Roselândia',         'Roselândia',          FALSE),
('13312500',  8, 'Rodovia Castello Branco',       'Pirapitingui',        FALSE),
('06950000',  9, NULL,                            NULL,                  TRUE),
('06550000', 10, NULL,                            NULL,                  TRUE);


-- =====================================================================
-- PESSOAS (clientes, funcionários e prestadores)
-- =====================================================================
INSERT INTO pessoa (cpf, nome, email, senha, cnpj, data_cadastro, cep, numero, complemento, logradouro_informado, bairro_informado) VALUES
-- clientes
('32165498701', 'Mariana Costa Almeida',     'mariana.almeida@email.com',   SHA2('cli001',256), NULL,             '2026-01-15', '01304001', '1500', 'Apto 82',   NULL, NULL),
('45678912302', 'Rafael Souza Barbosa',      'rafael.barbosa@email.com',    SHA2('cli002',256), NULL,             '2026-02-03', '01310200', '2000', NULL,        NULL, NULL),
('78912345603', 'Juliana Ribeiro Fernandes', 'juliana.fernandes@email.com', SHA2('cli003',256), NULL,             '2026-02-20', '04101300', '3185', 'Casa 2',    NULL, NULL),
('15975345604', 'Thiago Henrique Moreira',   'thiago.moreira@email.com',    SHA2('cli004',256), '45678901000104', '2026-03-01', '09080510', '600',  'Galpão 3',  NULL, NULL),
('35715945605', 'Patrícia Gomes Cardoso',    'patricia.cardoso@email.com',  SHA2('cli005',256), NULL,             '2026-03-12', '07010010', '45',   NULL,        NULL, NULL),
('25836914706', 'Lucas Batista Freitas',     'lucas.freitas@email.com',     SHA2('cli006',256), NULL,             '2026-04-02', '04538133', '3477', 'Conj. 101', NULL, NULL),
('14725836907', 'Fernanda Araújo Monteiro',  'fernanda.monteiro@email.com', SHA2('cli007',256), NULL,             '2026-04-18', '03081000', '1200', 'Apto 34',   NULL, NULL),
('96385274108', 'Gustavo Correia Vieira',    'gustavo.vieira@email.com',    SHA2('cli008',256), '56789012000105', '2026-05-05', '05275000', 'km 25',NULL,        NULL, NULL),
('74185296309', 'Beatriz Nogueira Castro',   'beatriz.castro@email.com',    SHA2('cli009',256), NULL,             '2026-06-10', '09726253', '880',  NULL,        NULL, NULL),
('85296374110', 'Roberto Carlos Duarte',     'roberto.duarte@email.com',    SHA2('cli010',256), NULL,             '2026-07-01', NULL,       NULL,   NULL,        NULL, NULL),
('63985214711', 'Sérgio Lima Prado',         'sergio.prado@email.com',      SHA2('cli011',256), NULL,             '2026-05-20', '06550000', '120',  NULL,        'Rua São José', 'Centro'),
-- funcionários
('10120230301', 'Ana Paula Ferreira',    'ana.ferreira@feliguinchos.com.br',   SHA2('Ana@2026',256),     NULL, '2025-11-03', '04101300', '1020', 'Apto 51', NULL, NULL),
('10120230302', 'Bruno Carvalho Dias',   'bruno.dias@feliguinchos.com.br',     SHA2('Bruno@2026',256),   NULL, '2025-11-03', NULL, NULL, NULL, NULL, NULL),
('10120230303', 'Camila Rocha Santos',   'camila.santos@feliguinchos.com.br',  SHA2('Camila@2026',256),  NULL, '2025-12-01', NULL, NULL, NULL, NULL, NULL),
('10120230304', 'Diego Martins Silva',   'diego.silva@feliguinchos.com.br',    SHA2('Diego@2026',256),   NULL, '2025-12-01', NULL, NULL, NULL, NULL, NULL),
('10120230305', 'Eduarda Lopes Gomes',   'eduarda.gomes@feliguinchos.com.br',  SHA2('Eduarda@2026',256), NULL, '2026-01-05', NULL, NULL, NULL, NULL, NULL),
('10120230306', 'Felipe Andrade Barros', 'felipe.barros@feliguinchos.com.br',  SHA2('Felipe@2026',256),  NULL, '2025-11-03', NULL, NULL, NULL, NULL, NULL),
('10120230307', 'Gabriela Moura Pinto',  'gabriela.pinto@feliguinchos.com.br', SHA2('Gabi@2026',256),    NULL, '2025-12-01', NULL, NULL, NULL, NULL, NULL),
-- prestadores
('11223344501', 'Carlos Henrique Souza',   'carlos.souza@rapidosul.com.br',         SHA2('prest01',256), NULL, '2025-02-20', NULL, NULL, NULL, NULL, NULL),
('11223344502', 'Marcos Vinícius Lima',    'marcos.lima@rapidosul.com.br',          SHA2('prest02',256), NULL, '2025-02-20', NULL, NULL, NULL, NULL, NULL),
('11223344503', 'José Roberto Alves',      'jose.alves@reboqueforte.com.br',        SHA2('prest03',256), NULL, '2026-01-20', NULL, NULL, NULL, NULL, NULL),
('11223344504', 'Anderson Pereira Costa',  'anderson.costa@reboqueforte.com.br',    SHA2('prest04',256), NULL, '2026-01-20', NULL, NULL, NULL, NULL, NULL),
('11223344505', 'Ricardo Mendes Oliveira', 'ricardo.oliveira@autosocorrosp.com.br', SHA2('prest05',256), NULL, '2026-02-15', NULL, NULL, NULL, NULL, NULL),
('11223344506', 'Paulo Sérgio Ramos',      'paulo.ramos.guincho@email.com',         SHA2('prest06',256), NULL, '2026-03-10', '06950000', '310', NULL, 'Estrada do Paiol', 'Barnabés'),
('11223344507', 'Fábio Augusto Nunes',     'fabio.nunes.reboque@email.com',         SHA2('prest07',256), NULL, '2026-03-28', NULL, NULL, NULL, NULL, NULL),
('11223344508', 'Luiz Fernando Teixeira',  'luiz.teixeira@autosocorrosp.com.br',    SHA2('prest08',256), NULL, '2026-01-02', NULL, NULL, NULL, NULL, NULL),
('11223344509', 'Rodrigo Alves Pacheco',   'rodrigo.pacheco@email.com',             SHA2('prest09',256), NULL, '2026-10-25', NULL, NULL, NULL, NULL, NULL),
('11223344510', 'Wagner Dias Moreira',     'wagner.moreira@email.com',              SHA2('prest10',256), NULL, '2026-08-14', NULL, NULL, NULL, NULL, NULL);

INSERT INTO pessoa_telefone (cpf, telefone) VALUES
('32165498701', '11987654321'), ('32165498701', '1133224455'),
('45678912302', '11991234567'), ('45678912302', '11976543210'),
('78912345603', '11988887777'),
('15975345604', '11999990001'), ('15975345604', '1144556677'),
('35715945605', '11955554444'),
('25836914706', '11966667777'),
('14725836907', '11977778888'),
('96385274108', '11930001000'), ('96385274108', '1139990000'),
('74185296309', '11912345678'),
('85296374110', '11900001111'),
('63985214711', '11944443333'),
('10120230301', '11940000001'), ('10120230302', '11940000002'), ('10120230303', '11940000003'),
('10120230304', '11940000004'), ('10120230305', '11940000005'), ('10120230306', '11940000006'),
('10120230307', '11940000007'),
('11223344501', '11981110001'), ('11223344502', '11981110002'), ('11223344503', '11981110003'),
('11223344504', '11981110004'), ('11223344505', '11981110005'), ('11223344506', '11981110006'),
('11223344506', '11981110016'), ('11223344507', '11981110007'), ('11223344508', '11981110008'),
('11223344509', '11981110009'), ('11223344510', '11981110010');

INSERT INTO empresa (empresa_id, razao_social, cnpj, telefone, email) VALUES
(1, 'Guinchos Rápido Sul Ltda',     '12345678000101', '1130001000', 'contato@rapidosul.com.br'),
(2, 'Reboque Forte Transportes ME', '23456789000102', '1140002000', 'contato@reboqueforte.com.br'),
(3, 'Auto Socorro Paulista Ltda',   '34567890000103', NULL,         NULL);

-- Papéis de cada pessoa ------------------------------------------------
INSERT INTO cliente (cliente_id, cpf, status) VALUES
( 1, '32165498701', 'ATIVO'),
( 2, '45678912302', 'ATIVO'),
( 3, '78912345603', 'ATIVO'),
( 4, '15975345604', 'ATIVO'),
( 5, '35715945605', 'ATIVO'),
( 6, '25836914706', 'ATIVO'),
( 7, '14725836907', 'ATIVO'),
( 8, '96385274108', 'ATIVO'),
( 9, '74185296309', 'ATIVO'),
(10, '85296374110', 'PENDENTE'),
(11, '63985214711', 'BLOQUEADO'),
(12, '11223344506', 'ATIVO');      -- Paulo Sérgio: também é prestador

INSERT INTO funcionario (funcionario_id, cpf, cargo, perfil_acesso, status) VALUES
(1, '10120230301', 'Gerente de Operações',      'GERENTE',    'ATIVO'),
(2, '10120230302', 'Supervisor de Atendimento', 'GERENTE',    'ATIVO'),
(3, '10120230303', 'Atendente',                 'ATENDENTE',  'ATIVO'),
(4, '10120230304', 'Atendente',                 'ATENDENTE',  'ATIVO'),
(5, '10120230305', 'Analista Financeiro',       'FINANCEIRO', 'ATIVO'),
(6, '10120230306', 'Administrador de Sistemas', 'GERENTE',    'ATIVO'),
(7, '10120230307', 'Atendente',                 'ATENDENTE',  'INATIVO');

INSERT INTO prestador_servico (prestador_id, cpf, empresa_id, cnh, status) VALUES
( 1, '11223344501', 1,    '01234567801', 'ATIVO'),
( 2, '11223344502', 1,    '01234567802', 'ATIVO'),
( 3, '11223344503', 2,    '01234567803', 'ATIVO'),
( 4, '11223344504', 2,    '01234567804', 'ATIVO'),
( 5, '11223344505', 3,    '01234567805', 'ATIVO'),
( 6, '11223344506', NULL, '01234567806', 'ATIVO'),
( 7, '11223344507', NULL, '01234567807', 'ATIVO'),
( 8, '11223344508', 3,    '01234567808', 'BLOQUEADO'),
( 9, '11223344509', NULL, NULL,          'EM_ANALISE'),
(10, '11223344510', NULL, NULL,          'RECUSADO');


-- =====================================================================
-- VEÍCULOS E GUINCHOS
-- =====================================================================
INSERT INTO modelo_veiculo (modelo_id, marca, nome) VALUES
( 1, 'Chevrolet',     'Onix'),
( 2, 'Honda',         'CG 160'),
( 3, 'Toyota',        'Hilux'),
( 4, 'Hyundai',       'HB20'),
( 5, 'Fiat',          'Ducato'),
( 6, 'Volkswagen',    'Delivery Express'),
( 7, 'Volkswagen',    'Polo'),
( 8, 'Jeep',          'Compass'),
( 9, 'Renault',       'Kwid'),
(10, 'Mercedes-Benz', 'Axor 2544'),
(11, 'Fiat',          'Argo'),
(12, 'Yamaha',        'Fazer 250'),
(13, 'Honda',         'HR-V'),
(14, 'Toyota',        'Corolla'),
(15, 'Chevrolet',     'Prisma'),
(16, 'Volkswagen',    'Delivery 9.170'),
(17, 'Ford',          'Cargo 816'),
(18, 'Mercedes-Benz', 'Accelo 1016'),
(19, 'Iveco',         'Daily 70C17'),
(20, 'Volvo',         'VM 270'),
(21, 'Fiat',          'Strada'),
(22, 'Hyundai',       'HR');

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
(2, 2, 'Prancha obrigatória para elétricos, rebaixados e blindados'),
(4, 2, 'Evitar em veículos rebaixados'),
(2, 3, 'Conferir peso: limite de 3.500 kg'),
(3, 3, NULL),
(3, 4, NULL),
(4, 4, 'Somente vans até 4.000 kg'),
(3, 5, NULL),
(5, 5, NULL),
(5, 6, 'Único tipo apto para veículos pesados');

-- Veículos dos clientes (cliente 10 sem veículo: cardinalidade 0,N)
INSERT INTO veiculo (veiculo_id, cliente_id, tipo_veiculo_id, modelo_id, placa, ano, cor, blindado) VALUES
( 1,  1, 2,  1, 'BRA2E19', 2022, 'Branco',   FALSE),
( 2,  1, 1,  2, 'MOT1A11', 2021, 'Vermelho', FALSE),
( 3,  2, 3,  3, 'SUV3B22', 2023, 'Prata',    TRUE),
( 4,  3, 2,  4, 'CAR4C33', 2020, 'Preto',    FALSE),
( 5,  4, 4,  5, 'VAN5D44', 2019, 'Branco',   FALSE),
( 6,  4, 5,  6, 'CAM6E55', 2021, 'Branco',   FALSE),
( 7,  5, 2,  7, 'CAR7F66', 2023, 'Cinza',    FALSE),
( 8,  6, 3,  8, 'SUV8G77', 2022, 'Preto',    TRUE),
( 9,  7, 2,  9, 'CAR9H88', 2019, 'Laranja',  FALSE),
(10,  8, 6, 10, 'ONI1J99', 2017, 'Azul',     FALSE),
(11,  9, 2, 11, 'CAR2K10', 2021, 'Vermelho', FALSE),
(12,  9, 1, 12, 'MOT3L21', 2022, NULL,       FALSE),
(13,  5, 3, 13, 'SUV4M32', 2024, 'Branco',   FALSE),
(14,  2, 2, 14, 'CAR5N43', 2024, 'Preto',    TRUE),
(15, 11, 2, 15, 'CAR6P54', 2015, 'Prata',    FALSE),
(16, 12, 3, 21, 'STR7Q65', 2023, 'Branco',   FALSE);   -- mesmo modelo do guincho 6

INSERT INTO veiculo_reboque (veiculo_reboque_id, tipo_guincho_id, modelo_id, placa, ano, capacidade_kg, status) VALUES
(1, 2, 16, 'GUI1A23', 2021,  3500.00, 'DISPONIVEL'),
(2, 2, 17, 'GUI2B34', 2020,  3500.00, 'EM_SERVICO'),
(3, 3, 18, 'GUI3C45', 2022,  8000.00, 'EM_SERVICO'),
(4, 4, 19, 'GUI4D56', 2019,  4000.00, 'DISPONIVEL'),
(5, 5, 20, 'GUI5E67', 2018, 25000.00, 'DISPONIVEL'),
(6, 1, 21, 'GUI6F78', 2023,   400.00, 'DISPONIVEL'),
(7, 2, 22, 'GUI7G89', 2017,  NULL,    'MANUTENCAO');

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
(1, 1, '2025-03-01', '2025-11-30', 'ENCERRADO');   -- mesmo par em outro período


-- =====================================================================
-- SERVIÇOS E TARIFAS
-- =====================================================================
INSERT INTO servico_reboque (servico_id, descricao, tipo_servico, status) VALUES
(1, 'Reboque urbano',             'REBOQUE', 'ATIVO'),
(2, 'Reboque rodoviário',         'REBOQUE', 'ATIVO'),
(3, 'Troca de pneu',              'SOCORRO', 'ATIVO'),
(4, 'Carga de bateria',           'SOCORRO', 'ATIVO'),
(5, 'Resgate em vala/ribanceira', 'RESGATE', 'ATIVO'),
(6, 'Pane seca',                  'SOCORRO', 'INATIVO');

-- Tarifa vigente = vigencia_fim nula ou futura (o status foi removido na normalização)
INSERT INTO tarifa (tarifa_id, tipo_veiculo_id, servico_id, valor_base, valor_por_km,
                    adicional_madrugada, adicional_domingo, adicional_feriado, adicional_rodovia,
                    vigencia_inicio, vigencia_fim) VALUES
( 1, 2, 1, 150.00,  3.50,  50.00,  40.00,  60.00,   0.00, '2026-01-01', NULL),
( 2, 2, 2, 200.00,  4.00,  60.00,  50.00,  70.00,  80.00, '2026-01-01', NULL),
( 3, 1, 1, 100.00,  2.50,  40.00,  30.00,  40.00,   0.00, '2026-01-01', NULL),
( 4, 3, 1, 200.00,  4.50,  60.00,  50.00,  70.00,   0.00, '2026-01-01', NULL),
( 5, 3, 2, 260.00,  5.00,  70.00,  60.00,  80.00, 100.00, '2026-01-01', NULL),
( 6, 4, 1, 230.00,  5.00,  70.00,  50.00,  70.00,   0.00, '2026-01-01', NULL),
( 7, 5, 2, 450.00,  8.00, 100.00,  80.00, 120.00, 150.00, '2026-01-01', NULL),
( 8, 6, 2, 800.00, 12.00, 150.00, 120.00, 180.00, 250.00, '2026-01-01', NULL),
( 9, 2, 3,  90.00,  1.50,  30.00,  20.00,  30.00,   0.00, '2026-01-01', NULL),
(10, 2, 4,  80.00,  1.50,  30.00,  20.00,  30.00,   0.00, '2026-01-01', NULL),
(11, 3, 5, 600.00,  6.00, 120.00, 100.00, 150.00, 200.00, '2026-01-01', NULL),
(12, 2, 1, 130.00,  3.00,  45.00,  35.00,  50.00,   0.00, '2025-01-01', '2025-12-31'),
(13, 1, 2, 140.00,  3.00,  50.00,  40.00,  50.00,  60.00, '2026-01-01', NULL);

INSERT INTO forma_pagamento (forma_pagamento_id, descricao, tipo) VALUES
(1, 'PIX',                  'ELETRONICO'),
(2, 'Cartão de Crédito',    'CARTAO'),
(3, 'Cartão de Débito',     'CARTAO'),
(4, 'Dinheiro',             'DINHEIRO'),
(5, 'Faturado (Boleto PJ)', 'FATURADO');


-- =====================================================================
-- SOLICITAÇÕES
--   Socorro no local (bateria, pneu): destino = mesmo endereço da origem.
--   Solicitação 18: origem em CEP genérico (Juquitiba), com logradouro e
--   bairro informados.
--   valor_estimado = tarifa.valor_base + tarifa.valor_por_km * distancia_km
-- =====================================================================
INSERT INTO solicitacao (solicitacao_id, veiculo_id, servico_id, funcionario_id, data_hora_solicitacao,
       origem_cep, origem_numero, origem_complemento, origem_logradouro_informado, origem_bairro_informado,
       destino_cep, destino_numero, destino_complemento, destino_logradouro_informado, destino_bairro_informado,
       distancia_km, observacao, valor_estimado, status) VALUES
( 1,  1, 1, 3,    '2026-09-02 08:15:00', '05402000', '1200',   NULL,      NULL, NULL, '05422001', '870',   'Oficina Pinheiros',       NULL, NULL,  12.00, 'Carro não liga, câmbio travado',               192.00, 'ACEITA'),
( 2,  3, 2, NULL, '2026-09-06 02:30:00', '13213000', 'km 72',  NULL,      NULL, NULL, '05402000', '3000',  'Toyota Concessionária',   NULL, NULL,  85.00, 'Pane elétrica na rodovia, veículo blindado',   685.00, 'ACEITA'),
( 3,  4, 4, 4,    '2026-09-07 10:00:00', '04101300', '3185',   'Casa 2',  NULL, NULL, '04101300', '3185',  'Casa 2',                  NULL, NULL,   5.00, 'Bateria descarregada (atendimento no local)',   87.50, 'ACEITA'),
( 4,  5, 1, 3,    '2026-09-10 14:20:00', '09210580', '4500',   NULL,      NULL, NULL, '09080300', '300',   'Oficina Diesel ABC',      NULL, NULL,  18.00, 'Van de entregas com motor fundido',            320.00, 'ACEITA'),
( 5, 10, 2, 2,    '2026-09-12 16:00:00', '13278000', 'km 98',  NULL,      NULL, NULL, '05275000', 'km 25', 'Pátio da transportadora', NULL, NULL, 140.00, 'Caminhão carregado, quebra de eixo',          2480.00, 'ACEITA'),
( 6,  2, 1, NULL, '2026-09-15 19:30:00', '01304001', '900',    NULL,      NULL, NULL, '01412000', '2200',  'Moto Center',             NULL, NULL,   8.00, 'Corrente da moto arrebentou',                  120.00, 'ACEITA'),
( 7,  7, 3, 4,    '2026-09-18 11:00:00', '07112000', '1500',   NULL,      NULL, NULL, '07112000', '1500',  NULL,                      NULL, NULL,   6.00, 'Pneu furado, sem estepe (atendimento no local)', 99.00, 'ACEITA'),
( 8,  8, 1, 3,    '2026-09-20 09:00:00', '04538133', '3477',   NULL,      NULL, NULL, '01449000', '500',   'Jeep Concessionária',     NULL, NULL,  22.00, 'Luz de injeção acesa',                         299.00, 'CANCELADA'),
( 9,  6, 2, 2,    '2026-09-24 07:30:00', '07034000', 'km 210', NULL,      NULL, NULL, '09080300', '300',   'Oficina Diesel ABC',      NULL, NULL,  60.00, 'Superaquecimento do motor',                    930.00, 'ACEITA'),
(10,  9, 1, NULL, '2026-09-28 03:10:00', '03081000', '300',    NULL,      NULL, NULL, '03310000', '1000',  'Auto Center Tatuapé',     NULL, NULL,  15.00, 'Colisão leve, roda danificada',                202.50, 'ACEITA'),
(11, 11, 1, 4,    '2026-10-02 13:00:00', '09726253', '1500',   NULL,      NULL, NULL, '09750000', '2000',  'Fiat Concessionária',     NULL, NULL,  10.00, 'Embreagem quebrada',                           185.00, 'ACEITA'),
(12, 12, 2, 3,    '2026-10-04 10:30:00', '09845000', 'km 40',  NULL,      NULL, NULL, '09726253', '500',   'Yamaha Motos',            NULL, NULL,  45.00, 'Moto parou na serra',                          275.00, 'ACEITA'),
(13, 13, 5, 2,    '2026-10-06 18:00:00', '06705000', '2000',   NULL,      NULL, NULL, '01430000', '1000',  'Honda Concessionária',    NULL, NULL,  30.00, 'Veículo caiu em vala lateral',                 780.00, 'ACEITA'),
(14,  8, 2, NULL, '2026-10-09 05:20:00', '13312500', 'km 70',  NULL,      NULL, NULL, '01449000', '500',   'Jeep Concessionária',     NULL, NULL,  70.00, 'Problema na transmissão',                      610.00, 'ACEITA'),
(15, 14, 1, NULL, '2026-10-12 15:00:00', '01310200', '2000',   NULL,      NULL, NULL, '05402000', '3000',  'Toyota Concessionária',   NULL, NULL,  20.00, 'Veículo blindado, não dá partida',             220.00, 'CANCELADA'),
(16,  5, 1, 3,    '2026-10-14 16:00:00', '09080510', '600',    'Galpão 3',NULL, NULL, '09080300', '300',   'Oficina Diesel ABC',      NULL, NULL,  25.00, 'Van com freio travado',                        355.00, 'CANCELADA'),
(17,  1, 4, 3,    '2026-10-15 07:50:00', '01304001', '1500',   'Apto 82', NULL, NULL, '01304001', '1500',  'Apto 82',                 NULL, NULL,   3.00, 'Bateria arriada (atendimento no local)',        84.50, 'ACEITA'),
(18,  4, 2, 4,    '2026-10-20 21:00:00', '06950000', 'km 350', NULL,      'Rodovia Régis Bittencourt', 'Zona rural',
                                                                                     '04101300', '4000',  'Hyundai Concessionária',  NULL, NULL, 120.00, 'Correia dentada rompida',                      680.00, 'ACEITA'),
(19, 11, 1, 4,    '2026-10-22 12:00:00', '09726253', '880',    NULL,      NULL, NULL, '09750000', '2000',  'Fiat Concessionária',     NULL, NULL,  11.00, 'Nenhum prestador respondeu',                   188.50, 'SEM_PRESTADOR'),
(20,  3, 1, 2,    '2026-10-26 10:00:00', '01310200', '1000',   NULL,      NULL, NULL, '05402000', '3000',  'Toyota Concessionária',   NULL, NULL,  14.00, 'Barulho forte na suspensão',                   263.00, 'ACEITA'),
(21,  7, 1, NULL, '2026-10-27 22:15:00', '07112000', '800',    NULL,      NULL, NULL, '07090000', '1200',  'VW Concessionária',       NULL, NULL,   9.00, 'Motor apagou e não volta',                     181.50, 'ACEITA'),
(22,  9, 3, 3,    '2026-10-28 08:40:00', '03081000', '1200',   'Apto 34', NULL, NULL, '03081000', '1200',  'Apto 34',                 NULL, NULL,   4.00, 'Dois pneus furados (atendimento no local)',     96.00, 'EM_ANALISE'),
(23, 13, 1, 3,    '2026-10-29 18:00:00', '07010010', '45',     NULL,      NULL, NULL, '01430000', '1000',  'Honda Concessionária',    NULL, NULL,  28.00, 'Ruído no motor, cliente prefere rebocar',      326.00, 'SOLICITADA');

-- Notificações (resposta NULL = ainda sem resposta)
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

-- Ordens de serviço: nascem ACEITA (R15); o gatilho grava o histórico de aceite (R14)
INSERT INTO ordem_servico (ordem_id, solicitacao_id, tarifa_id, prestador_id, veiculo_reboque_id,
                           data_hora_inicio, data_previsao, data_hora_fim, observacao,
                           valor_base, valor_adicionais, desconto) VALUES
( 1,  1,  1, 1, 1, '2026-09-02 08:25:00', '2026-09-02 09:30:00', '2026-09-02 09:20:00', NULL,                                         192.00,   0.00,  0.00),
( 2,  2,  5, 3, 3, '2026-09-06 02:45:00', '2026-09-06 05:00:00', '2026-09-06 05:10:00', 'Adicionais: madrugada + domingo + rodovia',  685.00, 230.00,  0.00),
( 3,  3, 10, 4, 4, '2026-09-07 10:10:00', '2026-09-07 11:00:00', '2026-09-07 10:50:00', 'Adicional de feriado (07/09)',                87.50,  30.00,  0.00),
( 4,  4,  6, 4, 4, '2026-09-10 14:35:00', '2026-09-10 16:00:00', '2026-09-10 15:40:00', 'Desconto para cliente PJ (frota)',           320.00,   0.00, 20.00),
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
(20, 21,  1, 2, 2, '2026-10-27 22:25:00', '2026-10-27 23:30:00', NULL,                  'Adicional de madrugada',                     181.50,  50.00,  0.00);

-- Histórico de status, em ordem cronológica (exigência do gatilho R15)
INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao)
SELECT ordem_id, NULL, 'A_CAMINHO', data_hora_inicio, 'Prestador iniciou o deslocamento (app)'
FROM ordem_servico ORDER BY ordem_id;

INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao)
SELECT ordem_id, NULL, 'NO_LOCAL', data_hora_inicio + INTERVAL 20 MINUTE, 'Prestador chegou ao local (app)'
FROM ordem_servico WHERE data_hora_fim IS NOT NULL OR ordem_id = 19 ORDER BY ordem_id;

INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao)
SELECT ordem_id, NULL, 'EM_ATENDIMENTO', data_hora_inicio + INTERVAL 25 MINUTE, 'Atendimento iniciado (app)'
FROM ordem_servico WHERE data_hora_fim IS NOT NULL OR ordem_id = 19 ORDER BY ordem_id;

INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao) VALUES
( 9, 2, 'EM_ATENDIMENTO', '2026-09-24 09:00:00', 'Desconto de R$ 50,00 aprovado pelo supervisor'),
( 5, 2, 'EM_ATENDIMENTO', '2026-09-12 20:30:00', 'Cliente avisado do atraso: congestionamento na Rod. Anhanguera'),
(13, 2, 'EM_ATENDIMENTO', '2026-10-06 21:10:00', 'Resgate exigiu equipamento adicional (cintas e cabo de aço)');

INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao)
SELECT ordem_id, NULL, 'FINALIZADA', data_hora_fim, 'Serviço concluído (app)'
FROM ordem_servico WHERE data_hora_fim IS NOT NULL ORDER BY ordem_id;

INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao) VALUES
( 8, 2,    'CANCELADA', '2026-09-20 09:35:00', 'Cliente desistiu após o deslocamento'),
(15, 1,    'CANCELADA', '2026-10-12 15:40:00', 'Guincho apresentou pane no trajeto'),
(16, NULL, 'CANCELADA', '2026-10-14 16:30:00', 'Endereço de origem informado errado');

-- status_atual = último registro do histórico (R15)
UPDATE ordem_servico os
   SET os.status_atual = (SELECT h.status FROM historico_status h
                          WHERE h.ordem_id = os.ordem_id
                          ORDER BY h.data_hora_alteracao DESC, h.historico_id DESC LIMIT 1);

-- Cancelamentos (o nº 3 sem funcionário autorizador -> auditoria)
INSERT INTO cancelamento (cancelamento_id, ordem_id, funcionario_id, responsavel, motivo, data_hora, valor_multa) VALUES
(1,  8, 2,    'CLIENTE',   'Cliente desistiu após o deslocamento do guincho (veículo voltou a funcionar)', '2026-09-20 09:35:00', 50.00),
(2, 15, 1,    'PRESTADOR', 'Guincho apresentou pane mecânica no trajeto',                                 '2026-10-12 15:40:00',  0.00),
(3, 16, NULL, 'CENTRAL',   'Endereço de origem informado errado; o cliente foi orientado a abrir novo pedido', '2026-10-14 16:30:00',  0.00);

-- Pagamentos
--  O.S. 9 -> 1ª tentativa recusada | O.S. 11 -> PENDENTE (auditoria)
--  O.S. 13 -> pago a menor (auditoria) | O.S. 18 -> pagamento dividido
--  O.S. 8 -> multa do cancelamento
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

-- Avaliações (O.S. 11 e 17 finalizadas sem avaliação: cardinalidade 0,1)
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
