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
