-- FELIGUINCHOS v2 — BANCO PRONTO (estrutura + gatilhos + carga), exportado do MariaDB
-- Importe direto no phpMyAdmin. Depois, se quiser, rode as consultas e os testes.
/*M!999999\- enable the sandbox mode */ 

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

/*!40000 DROP DATABASE IF EXISTS `feliguinchos_v2`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `feliguinchos_v2` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;

USE `feliguinchos_v2`;
DROP TABLE IF EXISTS `avaliacao`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `avaliacao` (
  `avaliacao_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ordem_id` int(10) unsigned NOT NULL,
  `nota` smallint(6) NOT NULL,
  `comentario` varchar(500) DEFAULT NULL,
  `data_avaliacao` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`avaliacao_id`),
  UNIQUE KEY `uq_avaliacao_ordem` (`ordem_id`),
  CONSTRAINT `fk_avaliacao_ordem` FOREIGN KEY (`ordem_id`) REFERENCES `ordem_servico` (`ordem_id`),
  CONSTRAINT `ck_avaliacao_nota` CHECK (`nota` between 1 and 5)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `avaliacao` WRITE;
/*!40000 ALTER TABLE `avaliacao` DISABLE KEYS */;
INSERT INTO `avaliacao` VALUES
(1,1,5,'Atendimento rÃ¡pido e prestador muito educado.','2026-09-02 10:00:00'),
(2,2,4,'Bom atendimento de madrugada, preÃ§o um pouco alto.','2026-09-06 09:00:00'),
(3,3,5,'Resolveram em poucos minutos, mesmo no feriado.','2026-09-07 12:00:00'),
(4,4,4,NULL,'2026-09-11 08:00:00'),
(5,5,3,'Chegou depois do horÃ¡rio previsto.','2026-09-13 10:00:00'),
(6,6,5,'Cuidado excelente com a moto.','2026-09-15 21:00:00'),
(7,7,5,'Troca de pneu impecÃ¡vel.','2026-09-18 13:00:00'),
(8,9,4,'ServiÃ§o bom, sÃ³ tive problema com o cartÃ£o.','2026-09-25 09:00:00'),
(9,10,5,'Salvou minha madrugada!','2026-09-28 08:00:00'),
(10,12,4,'Moto transportada com seguranÃ§a.','2026-10-04 14:00:00'),
(11,13,2,'Resgate demorou muito e o valor foi alto.','2026-10-07 09:00:00'),
(12,14,5,'Excelente, mesmo de madrugada na rodovia.','2026-10-09 09:30:00'),
(13,18,5,'Prestador muito atencioso na estrada.','2026-10-21 08:00:00');
/*!40000 ALTER TABLE `avaliacao` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER trg_avaliacao_bi BEFORE INSERT ON avaliacao
FOR EACH ROW
BEGIN
    IF (SELECT status_atual FROM ordem_servico WHERE ordem_id = NEW.ordem_id) <> 'FINALIZADA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R16: avaliacao permitida somente para O.S. FINALIZADA';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `cancelamento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cancelamento` (
  `cancelamento_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ordem_id` int(10) unsigned NOT NULL,
  `funcionario_id` int(10) unsigned DEFAULT NULL,
  `responsavel` varchar(10) NOT NULL,
  `motivo` varchar(255) NOT NULL,
  `data_hora` datetime NOT NULL DEFAULT current_timestamp(),
  `valor_multa` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`cancelamento_id`),
  UNIQUE KEY `uq_cancelamento_ordem` (`ordem_id`),
  KEY `fk_cancelamento_funcionario` (`funcionario_id`),
  CONSTRAINT `fk_cancelamento_funcionario` FOREIGN KEY (`funcionario_id`) REFERENCES `funcionario` (`funcionario_id`),
  CONSTRAINT `fk_cancelamento_ordem` FOREIGN KEY (`ordem_id`) REFERENCES `ordem_servico` (`ordem_id`),
  CONSTRAINT `ck_cancelamento_responsavel` CHECK (`responsavel` in ('CLIENTE','PRESTADOR','CENTRAL')),
  CONSTRAINT `ck_cancelamento_multa` CHECK (`valor_multa` >= 0)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `cancelamento` WRITE;
/*!40000 ALTER TABLE `cancelamento` DISABLE KEYS */;
INSERT INTO `cancelamento` VALUES
(1,8,2,'CLIENTE','Cliente desistiu apÃ³s o deslocamento do guincho (veÃ­culo voltou a funcionar)','2026-09-20 09:35:00',50.00),
(2,15,1,'PRESTADOR','Guincho apresentou pane mecÃ¢nica no trajeto','2026-10-12 15:40:00',0.00),
(3,16,NULL,'CENTRAL','Sem guincho compatÃ­vel disponÃ­vel na regiÃ£o no horÃ¡rio','2026-10-14 16:30:00',0.00);
/*!40000 ALTER TABLE `cancelamento` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER trg_cancelamento_bi BEFORE INSERT ON cancelamento
FOR EACH ROW
BEGIN
    IF (SELECT status_atual FROM ordem_servico WHERE ordem_id = NEW.ordem_id) <> 'CANCELADA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R16: cancelamento permitido somente para O.S. CANCELADA';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `cliente`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cliente` (
  `cliente_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `cpf` char(11) NOT NULL,
  `email` varchar(120) NOT NULL,
  `senha` varchar(255) NOT NULL,
  `data_cadastro` date NOT NULL DEFAULT curdate(),
  `status` varchar(10) NOT NULL,
  `logradouro` varchar(120) DEFAULT NULL,
  `numero` varchar(10) DEFAULT NULL,
  `complemento` varchar(60) DEFAULT NULL,
  `bairro` varchar(60) DEFAULT NULL,
  `cidade` varchar(60) DEFAULT NULL,
  `uf` char(2) DEFAULT NULL,
  `cep` char(8) DEFAULT NULL,
  PRIMARY KEY (`cliente_id`),
  UNIQUE KEY `uq_cliente_cpf` (`cpf`),
  UNIQUE KEY `uq_cliente_email` (`email`),
  CONSTRAINT `ck_cliente_cpf` CHECK (`cpf` regexp '^[0-9]{11}$'),
  CONSTRAINT `ck_cliente_cep` CHECK (`cep` is null or `cep` regexp '^[0-9]{8}$'),
  CONSTRAINT `ck_cliente_status` CHECK (`status` in ('ATIVO','PENDENTE','BLOQUEADO'))
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `cliente` WRITE;
/*!40000 ALTER TABLE `cliente` DISABLE KEYS */;
INSERT INTO `cliente` VALUES
(1,'Mariana Costa Almeida','32165498701','mariana.almeida@email.com','24a04dccaf23322b70ef432eaaa514c5db054b6297fcdad8bfc800cd01a4a684','2026-01-15','ATIVO','Rua Augusta','1500','Apto 82','ConsolaÃ§Ã£o','SÃ£o Paulo','SP','01304001'),
(2,'Rafael Souza Barbosa','45678912302','rafael.barbosa@email.com','a3a256455ada7ba684bd4446d9acb66efb8220a8f79c5b7cf57effa86f317988','2026-02-03','ATIVO','Avenida Paulista','2000',NULL,'Bela Vista','SÃ£o Paulo','SP','01310200'),
(3,'Juliana Ribeiro Fernandes','78912345603','juliana.fernandes@email.com','3c4a19cd27874d3d0844f1cdbd67cd8abcd6b289495e47bffcc6991b1567418e','2026-02-20','ATIVO','Rua Vergueiro','3185','Casa 2','Vila Mariana','SÃ£o Paulo','SP','04101300'),
(4,'Thiago Henrique Moreira','15975345604','thiago.moreira@email.com','95bdcdbf403b178987da7fb7b6058607b123c93440d6f3d85343a7a42e360d2b','2026-03-01','ATIVO','Avenida Industrial','600','GalpÃ£o 3','Jardim','Santo AndrÃ©','SP','09080510'),
(5,'PatrÃ­cia Gomes Cardoso','35715945605','patricia.cardoso@email.com','16019828a7847b7cd26df07e8eeec0466dc05539f9f0397dd1a5501b1727455c','2026-03-12','ATIVO','Rua das Flores','45',NULL,'Centro','Guarulhos','SP','07010010'),
(6,'Lucas Batista Freitas','25836914706','lucas.freitas@email.com','62025eb81b7ee10626ad1da698c725ba6644646f383ac71fe74cf51f22344005','2026-04-02','ATIVO','Avenida Brigadeiro Faria Lima','3477','Conj. 101','Itaim Bibi','SÃ£o Paulo','SP','04538133'),
(7,'Fernanda AraÃºjo Monteiro','14725836907','fernanda.monteiro@email.com','7cf8254a10fe65919f9bffe787039badd2be86037625b2090a61fbf7252f40cb','2026-04-18','ATIVO','Rua Tuiuti','1200','Apto 34','TatuapÃ©','SÃ£o Paulo','SP','03081000'),
(8,'Gustavo Correia Vieira','96385274108','gustavo.vieira@email.com','13f56f8bad9e76ca5234b770c5def5db279652949fcedd9ed39dc6605d201f57','2026-05-05','ATIVO','Rodovia Anhanguera, km 25','S/N',NULL,'Jardim JaraguÃ¡','SÃ£o Paulo','SP','05275000'),
(9,'Beatriz Nogueira Castro','74185296309','beatriz.castro@email.com','ac0bc6d941f7b569a9edfc896205b88eed7b3f8c1ce08fc4bc3413477081c0a4','2026-06-10','ATIVO','Avenida Kennedy','880',NULL,'Jardim do Mar','SÃ£o Bernardo do Campo','SP','09726253'),
(10,'Roberto Carlos Duarte','85296374110','roberto.duarte@email.com','cb2afb580490874e4c38c807bbbedfb57ded30543895a7bf471d71c309961712','2026-07-01','PENDENTE',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(11,'SÃ©rgio Lima Prado','63985214711','sergio.prado@email.com','00090a1506732cd862be37989762937d35895a3d28a354a59b1e09674fa6cb93','2026-05-20','BLOQUEADO','Rua Domingos de Morais','2200',NULL,'Vila Mariana','SÃ£o Paulo','SP','04036000');
/*!40000 ALTER TABLE `cliente` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `cliente_telefone`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cliente_telefone` (
  `cliente_id` int(10) unsigned NOT NULL,
  `telefone` varchar(15) NOT NULL,
  PRIMARY KEY (`cliente_id`,`telefone`),
  CONSTRAINT `fk_cliente_telefone_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `cliente` (`cliente_id`) ON DELETE CASCADE,
  CONSTRAINT `ck_cliente_telefone` CHECK (`telefone` regexp '^[0-9]+$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `cliente_telefone` WRITE;
/*!40000 ALTER TABLE `cliente_telefone` DISABLE KEYS */;
INSERT INTO `cliente_telefone` VALUES
(1,'1133224455'),
(1,'11987654321'),
(2,'11976543210'),
(2,'11991234567'),
(3,'11988887777'),
(4,'1144556677'),
(4,'11999990001'),
(5,'11955554444'),
(6,'11966667777'),
(7,'11977778888'),
(8,'1139990000'),
(8,'11930001000'),
(9,'11912345678'),
(10,'11900001111'),
(11,'11944443333');
/*!40000 ALTER TABLE `cliente_telefone` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `empresa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `empresa` (
  `empresa_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `razao_social` varchar(150) NOT NULL,
  `cnpj` char(14) NOT NULL,
  `telefone` varchar(15) DEFAULT NULL,
  `email` varchar(120) DEFAULT NULL,
  PRIMARY KEY (`empresa_id`),
  UNIQUE KEY `uq_empresa_cnpj` (`cnpj`),
  CONSTRAINT `ck_empresa_cnpj` CHECK (`cnpj` regexp '^[0-9]{14}$')
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `empresa` WRITE;
/*!40000 ALTER TABLE `empresa` DISABLE KEYS */;
INSERT INTO `empresa` VALUES
(1,'Guinchos RÃ¡pido Sul Ltda','12345678000101','1130001000','contato@rapidosul.com.br'),
(2,'Reboque Forte Transportes ME','23456789000102','1140002000','contato@reboqueforte.com.br'),
(3,'Auto Socorro Paulista Ltda','34567890000103',NULL,NULL);
/*!40000 ALTER TABLE `empresa` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `forma_pagamento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `forma_pagamento` (
  `forma_pagamento_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `descricao` varchar(50) NOT NULL,
  `tipo` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`forma_pagamento_id`),
  UNIQUE KEY `uq_forma_pagamento_desc` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `forma_pagamento` WRITE;
/*!40000 ALTER TABLE `forma_pagamento` DISABLE KEYS */;
INSERT INTO `forma_pagamento` VALUES
(1,'PIX','ELETRONICO'),
(2,'CartÃ£o de CrÃ©dito','CARTAO'),
(3,'CartÃ£o de DÃ©bito','CARTAO'),
(4,'Dinheiro','DINHEIRO'),
(5,'Faturado (Boleto PJ)','FATURADO');
/*!40000 ALTER TABLE `forma_pagamento` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `funcionario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `funcionario` (
  `funcionario_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `cpf` char(11) NOT NULL,
  `email` varchar(120) NOT NULL,
  `cargo` varchar(50) NOT NULL,
  `perfil_acesso` varchar(10) NOT NULL,
  `senha` varchar(255) NOT NULL,
  `status` varchar(10) NOT NULL,
  PRIMARY KEY (`funcionario_id`),
  UNIQUE KEY `uq_funcionario_cpf` (`cpf`),
  UNIQUE KEY `uq_funcionario_email` (`email`),
  CONSTRAINT `ck_funcionario_cpf` CHECK (`cpf` regexp '^[0-9]{11}$'),
  CONSTRAINT `ck_funcionario_perfil` CHECK (`perfil_acesso` in ('ATENDENTE','FINANCEIRO','GERENTE')),
  CONSTRAINT `ck_funcionario_status` CHECK (`status` in ('ATIVO','INATIVO'))
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `funcionario` WRITE;
/*!40000 ALTER TABLE `funcionario` DISABLE KEYS */;
INSERT INTO `funcionario` VALUES
(1,'Ana Paula Ferreira','10120230301','ana.ferreira@feliguinchos.com.br','Gerente de OperaÃ§Ãµes','GERENTE','b79438f1513e08c676d10a36eb8a6684fcc6bf910443da868f5fa816d6dda56b','ATIVO'),
(2,'Bruno Carvalho Dias','10120230302','bruno.dias@feliguinchos.com.br','Supervisor de Atendimento','GERENTE','656ac5222c7e4fc201a26ca9763d3504f76fe3cab02efda4086264f8b00f4d62','ATIVO'),
(3,'Camila Rocha Santos','10120230303','camila.santos@feliguinchos.com.br','Atendente','ATENDENTE','677800676dbecfa45004d979df26dd2bbe518cc3e1820e44ee37dd048ae1abf4','ATIVO'),
(4,'Diego Martins Silva','10120230304','diego.silva@feliguinchos.com.br','Atendente','ATENDENTE','f33245cc058ec7c734db30da920e149436bf07052e68c9df87c85878696eeffa','ATIVO'),
(5,'Eduarda Lopes Gomes','10120230305','eduarda.gomes@feliguinchos.com.br','Analista Financeiro','FINANCEIRO','e00f92b84f68f11deb46b5a166c5414e818d7259e539dc06e0821bcf85003f2c','ATIVO'),
(6,'Felipe Andrade Barros','10120230306','felipe.barros@feliguinchos.com.br','Administrador de Sistemas','GERENTE','49740e0f00727fb062c2479d2be77a7ef9522fd22fdb3ea68ae934826c2d13d2','ATIVO'),
(7,'Gabriela Moura Pinto','10120230307','gabriela.pinto@feliguinchos.com.br','Atendente','ATENDENTE','8bca7b145b299722a9e2302baf53d52ce69aa7c5b547a25d4c13e14e7a7441ce','INATIVO');
/*!40000 ALTER TABLE `funcionario` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `guincho_tipo_veiculo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `guincho_tipo_veiculo` (
  `tipo_guincho_id` int(10) unsigned NOT NULL,
  `tipo_veiculo_id` int(10) unsigned NOT NULL,
  `observacao` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`tipo_guincho_id`,`tipo_veiculo_id`),
  KEY `fk_gtv_tipo_veiculo` (`tipo_veiculo_id`),
  CONSTRAINT `fk_gtv_tipo_guincho` FOREIGN KEY (`tipo_guincho_id`) REFERENCES `tipo_guincho` (`tipo_guincho_id`),
  CONSTRAINT `fk_gtv_tipo_veiculo` FOREIGN KEY (`tipo_veiculo_id`) REFERENCES `tipo_veiculo` (`tipo_veiculo_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `guincho_tipo_veiculo` WRITE;
/*!40000 ALTER TABLE `guincho_tipo_veiculo` DISABLE KEYS */;
INSERT INTO `guincho_tipo_veiculo` VALUES
(1,1,'Uso preferencial para motos'),
(2,1,'Necessita cintas e calÃ§o de roda'),
(2,2,NULL),
(2,3,'Conferir peso: limite de 3.500 kg'),
(3,3,NULL),
(3,4,NULL),
(3,5,NULL),
(4,2,'Evitar em veÃ­culos rebaixados'),
(4,4,'Somente vans atÃ© 4.000 kg'),
(5,5,NULL),
(5,6,'Ãšnico tipo apto para veÃ­culos pesados');
/*!40000 ALTER TABLE `guincho_tipo_veiculo` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `historico_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `historico_status` (
  `historico_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ordem_id` int(10) unsigned NOT NULL,
  `funcionario_id` int(10) unsigned DEFAULT NULL,
  `status` varchar(15) NOT NULL,
  `data_hora_alteracao` datetime NOT NULL DEFAULT current_timestamp(),
  `observacao` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`historico_id`),
  KEY `fk_historico_status_funcionario` (`funcionario_id`),
  KEY `idx_historico_ordem_data` (`ordem_id`,`data_hora_alteracao`),
  CONSTRAINT `fk_historico_status_funcionario` FOREIGN KEY (`funcionario_id`) REFERENCES `funcionario` (`funcionario_id`),
  CONSTRAINT `fk_historico_status_ordem` FOREIGN KEY (`ordem_id`) REFERENCES `ordem_servico` (`ordem_id`),
  CONSTRAINT `ck_historico_status` CHECK (`status` in ('ACEITA','A_CAMINHO','NO_LOCAL','EM_ATENDIMENTO','FINALIZADA','CANCELADA'))
) ENGINE=InnoDB AUTO_INCREMENT=135 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `historico_status` WRITE;
/*!40000 ALTER TABLE `historico_status` DISABLE KEYS */;
INSERT INTO `historico_status` VALUES
(1,1,NULL,'ACEITA','2026-09-02 08:18:00','Aceite registrado automaticamente (R14)'),
(2,2,NULL,'ACEITA','2026-09-06 02:33:00','Aceite registrado automaticamente (R14)'),
(3,3,NULL,'ACEITA','2026-09-07 10:03:00','Aceite registrado automaticamente (R14)'),
(4,4,NULL,'ACEITA','2026-09-10 14:24:00','Aceite registrado automaticamente (R14)'),
(5,5,NULL,'ACEITA','2026-09-12 16:05:00','Aceite registrado automaticamente (R14)'),
(6,6,NULL,'ACEITA','2026-09-15 19:33:00','Aceite registrado automaticamente (R14)'),
(7,7,NULL,'ACEITA','2026-09-18 11:04:00','Aceite registrado automaticamente (R14)'),
(8,8,NULL,'ACEITA','2026-09-20 09:03:00','Aceite registrado automaticamente (R14)'),
(9,9,NULL,'ACEITA','2026-09-24 07:36:00','Aceite registrado automaticamente (R14)'),
(10,10,NULL,'ACEITA','2026-09-28 03:15:00','Aceite registrado automaticamente (R14)'),
(11,11,NULL,'ACEITA','2026-10-02 13:04:00','Aceite registrado automaticamente (R14)'),
(12,12,NULL,'ACEITA','2026-10-04 10:35:00','Aceite registrado automaticamente (R14)'),
(13,13,NULL,'ACEITA','2026-10-06 18:06:00','Aceite registrado automaticamente (R14)'),
(14,14,NULL,'ACEITA','2026-10-09 05:26:00','Aceite registrado automaticamente (R14)'),
(15,15,NULL,'ACEITA','2026-10-12 15:04:00','Aceite registrado automaticamente (R14)'),
(16,16,NULL,'ACEITA','2026-10-14 16:05:00','Aceite registrado automaticamente (R14)'),
(17,17,NULL,'ACEITA','2026-10-15 07:54:00','Aceite registrado automaticamente (R14)'),
(18,18,NULL,'ACEITA','2026-10-20 21:08:00','Aceite registrado automaticamente (R14)'),
(19,19,NULL,'ACEITA','2026-10-26 10:05:00','Aceite registrado automaticamente (R14)'),
(20,20,NULL,'ACEITA','2026-10-27 22:19:00','Aceite registrado automaticamente (R14)'),
(21,1,NULL,'A_CAMINHO','2026-09-02 08:25:00','Prestador iniciou o deslocamento (app)'),
(22,2,NULL,'A_CAMINHO','2026-09-06 02:45:00','Prestador iniciou o deslocamento (app)'),
(23,3,NULL,'A_CAMINHO','2026-09-07 10:10:00','Prestador iniciou o deslocamento (app)'),
(24,4,NULL,'A_CAMINHO','2026-09-10 14:35:00','Prestador iniciou o deslocamento (app)'),
(25,5,NULL,'A_CAMINHO','2026-09-12 16:20:00','Prestador iniciou o deslocamento (app)'),
(26,6,NULL,'A_CAMINHO','2026-09-15 19:45:00','Prestador iniciou o deslocamento (app)'),
(27,7,NULL,'A_CAMINHO','2026-09-18 11:15:00','Prestador iniciou o deslocamento (app)'),
(28,8,NULL,'A_CAMINHO','2026-09-20 09:10:00','Prestador iniciou o deslocamento (app)'),
(29,9,NULL,'A_CAMINHO','2026-09-24 07:50:00','Prestador iniciou o deslocamento (app)'),
(30,10,NULL,'A_CAMINHO','2026-09-28 03:25:00','Prestador iniciou o deslocamento (app)'),
(31,11,NULL,'A_CAMINHO','2026-10-02 13:15:00','Prestador iniciou o deslocamento (app)'),
(32,12,NULL,'A_CAMINHO','2026-10-04 10:50:00','Prestador iniciou o deslocamento (app)'),
(33,13,NULL,'A_CAMINHO','2026-10-06 18:20:00','Prestador iniciou o deslocamento (app)'),
(34,14,NULL,'A_CAMINHO','2026-10-09 05:40:00','Prestador iniciou o deslocamento (app)'),
(35,15,NULL,'A_CAMINHO','2026-10-12 15:10:00','Prestador iniciou o deslocamento (app)'),
(36,16,NULL,'A_CAMINHO','2026-10-14 16:15:00','Prestador iniciou o deslocamento (app)'),
(37,17,NULL,'A_CAMINHO','2026-10-15 08:05:00','Prestador iniciou o deslocamento (app)'),
(38,18,NULL,'A_CAMINHO','2026-10-20 21:20:00','Prestador iniciou o deslocamento (app)'),
(39,19,NULL,'A_CAMINHO','2026-10-26 10:15:00','Prestador iniciou o deslocamento (app)'),
(40,20,NULL,'A_CAMINHO','2026-10-27 22:25:00','Prestador iniciou o deslocamento (app)'),
(52,1,NULL,'NO_LOCAL','2026-09-02 08:45:00','Prestador chegou ao local (app)'),
(53,2,NULL,'NO_LOCAL','2026-09-06 03:05:00','Prestador chegou ao local (app)'),
(54,3,NULL,'NO_LOCAL','2026-09-07 10:30:00','Prestador chegou ao local (app)'),
(55,4,NULL,'NO_LOCAL','2026-09-10 14:55:00','Prestador chegou ao local (app)'),
(56,5,NULL,'NO_LOCAL','2026-09-12 16:40:00','Prestador chegou ao local (app)'),
(57,6,NULL,'NO_LOCAL','2026-09-15 20:05:00','Prestador chegou ao local (app)'),
(58,7,NULL,'NO_LOCAL','2026-09-18 11:35:00','Prestador chegou ao local (app)'),
(59,9,NULL,'NO_LOCAL','2026-09-24 08:10:00','Prestador chegou ao local (app)'),
(60,10,NULL,'NO_LOCAL','2026-09-28 03:45:00','Prestador chegou ao local (app)'),
(61,11,NULL,'NO_LOCAL','2026-10-02 13:35:00','Prestador chegou ao local (app)'),
(62,12,NULL,'NO_LOCAL','2026-10-04 11:10:00','Prestador chegou ao local (app)'),
(63,13,NULL,'NO_LOCAL','2026-10-06 18:40:00','Prestador chegou ao local (app)'),
(64,14,NULL,'NO_LOCAL','2026-10-09 06:00:00','Prestador chegou ao local (app)'),
(65,17,NULL,'NO_LOCAL','2026-10-15 08:25:00','Prestador chegou ao local (app)'),
(66,18,NULL,'NO_LOCAL','2026-10-20 21:40:00','Prestador chegou ao local (app)'),
(67,19,NULL,'NO_LOCAL','2026-10-26 10:35:00','Prestador chegou ao local (app)'),
(83,1,NULL,'EM_ATENDIMENTO','2026-09-02 08:50:00','Atendimento iniciado (app)'),
(84,2,NULL,'EM_ATENDIMENTO','2026-09-06 03:10:00','Atendimento iniciado (app)'),
(85,3,NULL,'EM_ATENDIMENTO','2026-09-07 10:35:00','Atendimento iniciado (app)'),
(86,4,NULL,'EM_ATENDIMENTO','2026-09-10 15:00:00','Atendimento iniciado (app)'),
(87,5,NULL,'EM_ATENDIMENTO','2026-09-12 16:45:00','Atendimento iniciado (app)'),
(88,6,NULL,'EM_ATENDIMENTO','2026-09-15 20:10:00','Atendimento iniciado (app)'),
(89,7,NULL,'EM_ATENDIMENTO','2026-09-18 11:40:00','Atendimento iniciado (app)'),
(90,9,NULL,'EM_ATENDIMENTO','2026-09-24 08:15:00','Atendimento iniciado (app)'),
(91,10,NULL,'EM_ATENDIMENTO','2026-09-28 03:50:00','Atendimento iniciado (app)'),
(92,11,NULL,'EM_ATENDIMENTO','2026-10-02 13:40:00','Atendimento iniciado (app)'),
(93,12,NULL,'EM_ATENDIMENTO','2026-10-04 11:15:00','Atendimento iniciado (app)'),
(94,13,NULL,'EM_ATENDIMENTO','2026-10-06 18:45:00','Atendimento iniciado (app)'),
(95,14,NULL,'EM_ATENDIMENTO','2026-10-09 06:05:00','Atendimento iniciado (app)'),
(96,17,NULL,'EM_ATENDIMENTO','2026-10-15 08:30:00','Atendimento iniciado (app)'),
(97,18,NULL,'EM_ATENDIMENTO','2026-10-20 21:45:00','Atendimento iniciado (app)'),
(98,19,NULL,'EM_ATENDIMENTO','2026-10-26 10:40:00','Atendimento iniciado (app)'),
(114,9,2,'EM_ATENDIMENTO','2026-09-24 09:00:00','Desconto de R$ 50,00 aprovado pelo supervisor'),
(115,5,2,'EM_ATENDIMENTO','2026-09-12 20:30:00','Cliente avisado do atraso: congestionamento na Rod. Anhanguera'),
(116,13,2,'EM_ATENDIMENTO','2026-10-06 21:10:00','Resgate exigiu equipamento adicional (cintas e cabo de aÃ§o)'),
(117,1,NULL,'FINALIZADA','2026-09-02 09:20:00','ServiÃ§o concluÃ­do (app)'),
(118,2,NULL,'FINALIZADA','2026-09-06 05:10:00','ServiÃ§o concluÃ­do (app)'),
(119,3,NULL,'FINALIZADA','2026-09-07 10:50:00','ServiÃ§o concluÃ­do (app)'),
(120,4,NULL,'FINALIZADA','2026-09-10 15:40:00','ServiÃ§o concluÃ­do (app)'),
(121,5,NULL,'FINALIZADA','2026-09-12 21:45:00','ServiÃ§o concluÃ­do (app)'),
(122,6,NULL,'FINALIZADA','2026-09-15 20:25:00','ServiÃ§o concluÃ­do (app)'),
(123,7,NULL,'FINALIZADA','2026-09-18 11:55:00','ServiÃ§o concluÃ­do (app)'),
(124,9,NULL,'FINALIZADA','2026-09-24 10:40:00','ServiÃ§o concluÃ­do (app)'),
(125,10,NULL,'FINALIZADA','2026-09-28 04:20:00','ServiÃ§o concluÃ­do (app)'),
(126,11,NULL,'FINALIZADA','2026-10-02 14:05:00','ServiÃ§o concluÃ­do (app)'),
(127,12,NULL,'FINALIZADA','2026-10-04 12:40:00','ServiÃ§o concluÃ­do (app)'),
(128,13,NULL,'FINALIZADA','2026-10-06 21:30:00','ServiÃ§o concluÃ­do (app)'),
(129,14,NULL,'FINALIZADA','2026-10-09 07:50:00','ServiÃ§o concluÃ­do (app)'),
(130,17,NULL,'FINALIZADA','2026-10-15 08:40:00','ServiÃ§o concluÃ­do (app)'),
(131,18,NULL,'FINALIZADA','2026-10-21 00:15:00','ServiÃ§o concluÃ­do (app)'),
(132,8,2,'CANCELADA','2026-09-20 09:35:00','Cliente desistiu apÃ³s o deslocamento'),
(133,15,1,'CANCELADA','2026-10-12 15:40:00','Guincho apresentou pane no trajeto'),
(134,16,NULL,'CANCELADA','2026-10-14 16:30:00','Sem guincho compatÃ­vel disponÃ­vel na regiÃ£o');
/*!40000 ALTER TABLE `historico_status` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER trg_historico_status_bi BEFORE INSERT ON historico_status
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `notificacao_prestador`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `notificacao_prestador` (
  `solicitacao_id` int(10) unsigned NOT NULL,
  `prestador_id` int(10) unsigned NOT NULL,
  `data_hora_envio` datetime NOT NULL DEFAULT current_timestamp(),
  `data_hora_resposta` datetime DEFAULT NULL,
  `resposta` varchar(10) DEFAULT NULL,
  `aceite_unico` int(10) unsigned GENERATED ALWAYS AS (case when `resposta` = 'ACEITA' then `solicitacao_id` end) STORED,
  PRIMARY KEY (`solicitacao_id`,`prestador_id`),
  UNIQUE KEY `uq_notificacao_um_aceite` (`aceite_unico`),
  KEY `fk_notificacao_prestador` (`prestador_id`),
  CONSTRAINT `fk_notificacao_prestador` FOREIGN KEY (`prestador_id`) REFERENCES `prestador_servico` (`prestador_id`),
  CONSTRAINT `fk_notificacao_solicitacao` FOREIGN KEY (`solicitacao_id`) REFERENCES `solicitacao` (`solicitacao_id`),
  CONSTRAINT `ck_notificacao_datas` CHECK (`data_hora_resposta` is null or `data_hora_resposta` >= `data_hora_envio`),
  CONSTRAINT `ck_notificacao_resposta` CHECK (`resposta` is null or `resposta` in ('ACEITA','RECUSADA','EXPIRADA'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `notificacao_prestador` WRITE;
/*!40000 ALTER TABLE `notificacao_prestador` DISABLE KEYS */;
INSERT INTO `notificacao_prestador` VALUES
(1,1,'2026-09-02 08:16:00','2026-09-02 08:18:00','ACEITA',1),
(1,2,'2026-09-02 08:16:00','2026-09-02 08:17:00','RECUSADA',NULL),
(2,3,'2026-09-06 02:31:00','2026-09-06 02:33:00','ACEITA',2),
(2,5,'2026-09-06 02:31:00',NULL,'EXPIRADA',NULL),
(3,4,'2026-09-07 10:01:00','2026-09-07 10:03:00','ACEITA',3),
(4,3,'2026-09-10 14:21:00','2026-09-10 14:22:00','RECUSADA',NULL),
(4,4,'2026-09-10 14:21:00','2026-09-10 14:24:00','ACEITA',4),
(5,5,'2026-09-12 16:01:00','2026-09-12 16:05:00','ACEITA',5),
(6,6,'2026-09-15 19:31:00','2026-09-15 19:33:00','ACEITA',6),
(7,1,'2026-09-18 11:01:00','2026-09-18 11:02:00','RECUSADA',NULL),
(7,2,'2026-09-18 11:01:00','2026-09-18 11:04:00','ACEITA',7),
(8,1,'2026-09-20 09:01:00','2026-09-20 09:03:00','ACEITA',8),
(9,3,'2026-09-24 07:31:00','2026-09-24 07:36:00','ACEITA',9),
(9,5,'2026-09-24 07:31:00','2026-09-24 07:33:00','RECUSADA',NULL),
(10,2,'2026-09-28 03:11:00',NULL,'EXPIRADA',NULL),
(10,7,'2026-09-28 03:11:00','2026-09-28 03:15:00','ACEITA',10),
(11,1,'2026-10-02 13:01:00','2026-10-02 13:04:00','ACEITA',11),
(12,6,'2026-10-04 10:31:00','2026-10-04 10:35:00','ACEITA',12),
(13,5,'2026-10-06 18:01:00','2026-10-06 18:06:00','ACEITA',13),
(14,3,'2026-10-09 05:21:00','2026-10-09 05:23:00','RECUSADA',NULL),
(14,5,'2026-10-09 05:21:00','2026-10-09 05:26:00','ACEITA',14),
(15,2,'2026-10-12 15:01:00','2026-10-12 15:04:00','ACEITA',15),
(16,4,'2026-10-14 16:01:00','2026-10-14 16:05:00','ACEITA',16),
(17,7,'2026-10-15 07:51:00','2026-10-15 07:54:00','ACEITA',17),
(18,1,'2026-10-20 21:01:00','2026-10-20 21:08:00','ACEITA',18),
(18,2,'2026-10-20 21:01:00','2026-10-20 21:03:00','RECUSADA',NULL),
(19,1,'2026-10-22 12:01:00',NULL,'EXPIRADA',NULL),
(19,7,'2026-10-22 12:01:00',NULL,'EXPIRADA',NULL),
(20,3,'2026-10-26 10:01:00','2026-10-26 10:05:00','ACEITA',20),
(21,2,'2026-10-27 22:16:00','2026-10-27 22:19:00','ACEITA',21),
(22,1,'2026-10-28 08:41:00',NULL,NULL,NULL),
(22,2,'2026-10-28 08:41:00',NULL,NULL,NULL);
/*!40000 ALTER TABLE `notificacao_prestador` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER trg_notificacao_prestador_bi BEFORE INSERT ON notificacao_prestador
FOR EACH ROW
BEGIN
    IF (SELECT status FROM prestador_servico WHERE prestador_id = NEW.prestador_id) <> 'ATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R8: somente prestador com status ATIVO recebe notificacao';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `ordem_servico`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ordem_servico` (
  `ordem_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `solicitacao_id` int(10) unsigned NOT NULL,
  `tarifa_id` int(10) unsigned NOT NULL,
  `prestador_id` int(10) unsigned NOT NULL,
  `veiculo_reboque_id` int(10) unsigned NOT NULL,
  `data_hora_inicio` datetime DEFAULT NULL,
  `data_previsao` datetime DEFAULT NULL,
  `data_hora_fim` datetime DEFAULT NULL,
  `status_atual` varchar(15) NOT NULL DEFAULT 'ACEITA',
  `observacao` varchar(500) DEFAULT NULL,
  `valor_base` decimal(10,2) NOT NULL,
  `valor_adicionais` decimal(10,2) NOT NULL DEFAULT 0.00,
  `desconto` decimal(10,2) NOT NULL DEFAULT 0.00,
  `valor_total` decimal(10,2) GENERATED ALWAYS AS (`valor_base` + `valor_adicionais` - `desconto`) STORED,
  PRIMARY KEY (`ordem_id`),
  UNIQUE KEY `uq_ordem_servico_solicitacao` (`solicitacao_id`),
  KEY `fk_ordem_servico_tarifa` (`tarifa_id`),
  KEY `fk_ordem_servico_prestador` (`prestador_id`),
  KEY `fk_ordem_servico_veiculo_reboque` (`veiculo_reboque_id`),
  KEY `idx_ordem_servico_status` (`status_atual`),
  CONSTRAINT `fk_ordem_servico_prestador` FOREIGN KEY (`prestador_id`) REFERENCES `prestador_servico` (`prestador_id`),
  CONSTRAINT `fk_ordem_servico_solicitacao` FOREIGN KEY (`solicitacao_id`) REFERENCES `solicitacao` (`solicitacao_id`),
  CONSTRAINT `fk_ordem_servico_tarifa` FOREIGN KEY (`tarifa_id`) REFERENCES `tarifa` (`tarifa_id`),
  CONSTRAINT `fk_ordem_servico_veiculo_reboque` FOREIGN KEY (`veiculo_reboque_id`) REFERENCES `veiculo_reboque` (`veiculo_reboque_id`),
  CONSTRAINT `ck_ordem_servico_fim` CHECK (`data_hora_fim` is null or `data_hora_fim` >= `data_hora_inicio`),
  CONSTRAINT `ck_ordem_servico_status` CHECK (`status_atual` in ('ACEITA','A_CAMINHO','NO_LOCAL','EM_ATENDIMENTO','FINALIZADA','CANCELADA')),
  CONSTRAINT `ck_ordem_servico_valores` CHECK (`valor_base` >= 0 and `valor_adicionais` >= 0 and `desconto` >= 0),
  CONSTRAINT `ck_ordem_servico_desconto` CHECK (`desconto` <= `valor_base` + `valor_adicionais`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `ordem_servico` WRITE;
/*!40000 ALTER TABLE `ordem_servico` DISABLE KEYS */;
INSERT INTO `ordem_servico` VALUES
(1,1,1,1,1,'2026-09-02 08:25:00','2026-09-02 09:30:00','2026-09-02 09:20:00','FINALIZADA',NULL,192.00,0.00,0.00,192.00),
(2,2,5,3,3,'2026-09-06 02:45:00','2026-09-06 05:00:00','2026-09-06 05:10:00','FINALIZADA','Adicionais: madrugada + domingo + rodovia',685.00,230.00,0.00,915.00),
(3,3,10,4,4,'2026-09-07 10:10:00','2026-09-07 11:00:00','2026-09-07 10:50:00','FINALIZADA','Adicional de feriado (07/09)',87.50,30.00,0.00,117.50),
(4,4,6,4,4,'2026-09-10 14:35:00','2026-09-10 16:00:00','2026-09-10 15:40:00','FINALIZADA','Desconto cliente PJ recorrente',320.00,0.00,20.00,300.00),
(5,5,8,5,5,'2026-09-12 16:20:00','2026-09-12 21:00:00','2026-09-12 21:45:00','FINALIZADA','Adicional de rodovia',2480.00,250.00,0.00,2730.00),
(6,6,3,6,6,'2026-09-15 19:45:00','2026-09-15 20:30:00','2026-09-15 20:25:00','FINALIZADA',NULL,120.00,0.00,0.00,120.00),
(7,7,9,2,2,'2026-09-18 11:15:00','2026-09-18 12:00:00','2026-09-18 11:55:00','FINALIZADA',NULL,99.00,0.00,0.00,99.00),
(8,8,4,1,1,'2026-09-20 09:10:00','2026-09-20 10:30:00',NULL,'CANCELADA','Cancelada pelo cliente',299.00,50.00,0.00,349.00),
(9,9,7,3,3,'2026-09-24 07:50:00','2026-09-24 11:00:00','2026-09-24 10:40:00','FINALIZADA','Desconto negociado pelo supervisor',930.00,150.00,50.00,1030.00),
(10,10,1,7,2,'2026-09-28 03:25:00','2026-09-28 04:30:00','2026-09-28 04:20:00','FINALIZADA','Adicional de madrugada',202.50,50.00,0.00,252.50),
(11,11,1,1,1,'2026-10-02 13:15:00','2026-10-02 14:15:00','2026-10-02 14:05:00','FINALIZADA',NULL,185.00,0.00,0.00,185.00),
(12,12,13,6,6,'2026-10-04 10:50:00','2026-10-04 13:00:00','2026-10-04 12:40:00','FINALIZADA','Adicionais: domingo + rodovia',275.00,100.00,0.00,375.00),
(13,13,11,5,3,'2026-10-06 18:20:00','2026-10-06 21:00:00','2026-10-06 21:30:00','FINALIZADA','Adicional de rodovia/Ã¡rea rural',780.00,200.00,0.00,980.00),
(14,14,5,5,3,'2026-10-09 05:40:00','2026-10-09 08:00:00','2026-10-09 07:50:00','FINALIZADA','Adicionais: madrugada + rodovia',610.00,170.00,30.00,750.00),
(15,15,1,2,2,'2026-10-12 15:10:00','2026-10-12 16:30:00',NULL,'CANCELADA','Cancelada por falha do guincho',220.00,60.00,0.00,280.00),
(16,16,6,4,4,'2026-10-14 16:15:00','2026-10-14 17:45:00',NULL,'CANCELADA','Cancelada pela central',355.00,0.00,0.00,355.00),
(17,17,10,7,2,'2026-10-15 08:05:00','2026-10-15 09:00:00','2026-10-15 08:40:00','FINALIZADA',NULL,84.50,0.00,0.00,84.50),
(18,18,2,1,1,'2026-10-20 21:20:00','2026-10-21 00:30:00','2026-10-21 00:15:00','FINALIZADA','Adicional de rodovia; pagamento dividido',680.00,80.00,0.00,760.00),
(19,20,4,3,3,'2026-10-26 10:15:00','2026-10-26 12:00:00',NULL,'EM_ATENDIMENTO',NULL,263.00,0.00,0.00,263.00),
(20,21,1,2,2,'2026-10-27 22:25:00','2026-10-27 23:30:00',NULL,'A_CAMINHO',NULL,181.50,0.00,0.00,181.50);
/*!40000 ALTER TABLE `ordem_servico` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER trg_ordem_servico_bi BEFORE INSERT ON ordem_servico
FOR EACH ROW
BEGIN
    IF NEW.status_atual <> 'ACEITA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R15: toda O.S. deve ser criada com status ACEITA';
    END IF;
    CALL sp_valida_ordem_servico(NEW.solicitacao_id, NEW.tarifa_id, NEW.prestador_id, NEW.veiculo_reboque_id);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER trg_ordem_servico_ai AFTER INSERT ON ordem_servico
FOR EACH ROW
BEGIN
    INSERT INTO historico_status (ordem_id, funcionario_id, status, data_hora_alteracao, observacao)
    VALUES (NEW.ordem_id, NULL, 'ACEITA',
            COALESCE((SELECT MAX(data_hora_resposta) FROM notificacao_prestador
                      WHERE solicitacao_id = NEW.solicitacao_id AND resposta = 'ACEITA'), NOW()),
            'Aceite registrado automaticamente (R14)');
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER trg_ordem_servico_bu BEFORE UPDATE ON ordem_servico
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `pagamento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pagamento` (
  `pagamento_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ordem_id` int(10) unsigned NOT NULL,
  `forma_pagamento_id` int(10) unsigned NOT NULL,
  `valor_pago` decimal(10,2) NOT NULL,
  `data_hora_pagamento` datetime NOT NULL DEFAULT current_timestamp(),
  `status` varchar(10) NOT NULL DEFAULT 'PENDENTE',
  `comprovante` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`pagamento_id`),
  KEY `fk_pagamento_ordem` (`ordem_id`),
  KEY `fk_pagamento_forma` (`forma_pagamento_id`),
  KEY `idx_pagamento_status` (`status`),
  CONSTRAINT `fk_pagamento_forma` FOREIGN KEY (`forma_pagamento_id`) REFERENCES `forma_pagamento` (`forma_pagamento_id`),
  CONSTRAINT `fk_pagamento_ordem` FOREIGN KEY (`ordem_id`) REFERENCES `ordem_servico` (`ordem_id`),
  CONSTRAINT `ck_pagamento_valor` CHECK (`valor_pago` > 0),
  CONSTRAINT `ck_pagamento_status` CHECK (`status` in ('PENDENTE','APROVADO','RECUSADO'))
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `pagamento` WRITE;
/*!40000 ALTER TABLE `pagamento` DISABLE KEYS */;
INSERT INTO `pagamento` VALUES
(1,1,1,192.00,'2026-09-02 09:25:00','APROVADO','PIX-20260902-0001'),
(2,2,2,915.00,'2026-09-06 05:20:00','APROVADO','CC-AUT-778812'),
(3,3,3,117.50,'2026-09-07 10:55:00','APROVADO','CD-AUT-110233'),
(4,4,5,300.00,'2026-09-25 10:00:00','APROVADO','BOL-000451'),
(5,5,5,2730.00,'2026-10-10 09:00:00','APROVADO','BOL-000467'),
(6,6,4,120.00,'2026-09-15 20:30:00','APROVADO',NULL),
(7,7,1,99.00,'2026-09-18 12:00:00','APROVADO','PIX-20260918-0007'),
(8,8,1,50.00,'2026-09-20 09:50:00','APROVADO','PIX-20260920-0008'),
(9,9,2,1030.00,'2026-09-24 10:50:00','RECUSADO','CC-NEG-990011'),
(10,9,1,1030.00,'2026-09-24 11:05:00','APROVADO','PIX-20260924-0010'),
(11,10,1,252.50,'2026-09-28 04:25:00','APROVADO','PIX-20260928-0011'),
(12,11,1,185.00,'2026-10-02 14:10:00','PENDENTE',NULL),
(13,12,2,375.00,'2026-10-04 12:45:00','APROVADO','CC-AUT-781200'),
(14,13,2,900.00,'2026-10-06 21:40:00','APROVADO','CC-AUT-781355'),
(15,14,1,750.00,'2026-10-09 08:00:00','APROVADO','PIX-20261009-0015'),
(16,17,3,84.50,'2026-10-15 08:45:00','APROVADO','CD-AUT-120044'),
(17,18,1,400.00,'2026-10-21 00:20:00','APROVADO','PIX-20261021-0017'),
(18,18,2,360.00,'2026-10-21 00:22:00','APROVADO','CC-AUT-781990');
/*!40000 ALTER TABLE `pagamento` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `prestador_servico`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `prestador_servico` (
  `prestador_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `empresa_id` int(10) unsigned DEFAULT NULL,
  `nome` varchar(100) NOT NULL,
  `cpf` char(11) NOT NULL,
  `telefone` varchar(15) NOT NULL,
  `email` varchar(120) NOT NULL,
  `cnh` varchar(11) DEFAULT NULL,
  `status` varchar(10) NOT NULL DEFAULT 'EM_ANALISE',
  `data_cadastro` date NOT NULL DEFAULT curdate(),
  PRIMARY KEY (`prestador_id`),
  UNIQUE KEY `uq_prestador_servico_cpf` (`cpf`),
  UNIQUE KEY `uq_prestador_servico_cnh` (`cnh`),
  KEY `fk_prestador_servico_empresa` (`empresa_id`),
  CONSTRAINT `fk_prestador_servico_empresa` FOREIGN KEY (`empresa_id`) REFERENCES `empresa` (`empresa_id`),
  CONSTRAINT `ck_prestador_servico_cpf` CHECK (`cpf` regexp '^[0-9]{11}$'),
  CONSTRAINT `ck_prestador_servico_status` CHECK (`status` in ('EM_ANALISE','ATIVO','RECUSADO','BLOQUEADO')),
  CONSTRAINT `ck_prestador_servico_cnh_r5` CHECK (`status` <> 'ATIVO' or `cnh` is not null)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `prestador_servico` WRITE;
/*!40000 ALTER TABLE `prestador_servico` DISABLE KEYS */;
INSERT INTO `prestador_servico` VALUES
(1,1,'Carlos Henrique Souza','11223344501','11981110001','carlos.souza@rapidosul.com.br','01234567801','ATIVO','2026-01-08'),
(2,1,'Marcos VinÃ­cius Lima','11223344502','11981110002','marcos.lima@rapidosul.com.br','01234567802','ATIVO','2026-01-08'),
(3,2,'JosÃ© Roberto Alves','11223344503','11981110003','jose.alves@reboqueforte.com.br','01234567803','ATIVO','2026-01-20'),
(4,2,'Anderson Pereira Costa','11223344504','11981110004','anderson.costa@reboqueforte.com.br','01234567804','ATIVO','2026-01-20'),
(5,3,'Ricardo Mendes Oliveira','11223344505','11981110005','ricardo.oliveira@autosocorrosp.com.br','01234567805','ATIVO','2026-02-15'),
(6,NULL,'Paulo SÃ©rgio Ramos','11223344506','11981110006','paulo.ramos.guincho@email.com','01234567806','ATIVO','2026-03-10'),
(7,NULL,'FÃ¡bio Augusto Nunes','11223344507','11981110007','fabio.nunes.reboque@email.com','01234567807','ATIVO','2026-03-28'),
(8,3,'Luiz Fernando Teixeira','11223344508','11981110008','luiz.teixeira@autosocorrosp.com.br','01234567808','BLOQUEADO','2026-01-02'),
(9,NULL,'Rodrigo Alves Pacheco','11223344509','11981110009','rodrigo.pacheco@email.com',NULL,'EM_ANALISE','2026-10-25'),
(10,NULL,'Wagner Dias Moreira','11223344510','11981110010','wagner.moreira@email.com',NULL,'RECUSADO','2026-08-14');
/*!40000 ALTER TABLE `prestador_servico` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `prestador_veiculo_reboque`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `prestador_veiculo_reboque` (
  `prestador_id` int(10) unsigned NOT NULL,
  `veiculo_reboque_id` int(10) unsigned NOT NULL,
  `data_inicio` date NOT NULL,
  `data_fim` date DEFAULT NULL,
  `status` varchar(20) NOT NULL,
  PRIMARY KEY (`prestador_id`,`veiculo_reboque_id`,`data_inicio`),
  KEY `fk_pvr_veiculo_reboque` (`veiculo_reboque_id`),
  CONSTRAINT `fk_pvr_prestador` FOREIGN KEY (`prestador_id`) REFERENCES `prestador_servico` (`prestador_id`),
  CONSTRAINT `fk_pvr_veiculo_reboque` FOREIGN KEY (`veiculo_reboque_id`) REFERENCES `veiculo_reboque` (`veiculo_reboque_id`),
  CONSTRAINT `ck_prestador_veiculo_reboque_datas` CHECK (`data_fim` is null or `data_fim` >= `data_inicio`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `prestador_veiculo_reboque` WRITE;
/*!40000 ALTER TABLE `prestador_veiculo_reboque` DISABLE KEYS */;
INSERT INTO `prestador_veiculo_reboque` VALUES
(1,1,'2025-03-01','2025-11-30','ENCERRADO'),
(1,1,'2026-01-10',NULL,'ATIVO'),
(2,2,'2026-01-10',NULL,'ATIVO'),
(2,7,'2025-06-01','2025-12-31','ENCERRADO'),
(3,3,'2026-02-01',NULL,'ATIVO'),
(4,4,'2026-02-01',NULL,'ATIVO'),
(5,3,'2026-05-01',NULL,'ATIVO'),
(5,5,'2026-03-01',NULL,'ATIVO'),
(6,6,'2026-03-15',NULL,'ATIVO'),
(7,2,'2026-04-01',NULL,'ATIVO'),
(8,7,'2026-01-05','2026-08-31','ENCERRADO');
/*!40000 ALTER TABLE `prestador_veiculo_reboque` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `servico_reboque`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `servico_reboque` (
  `servico_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `descricao` varchar(80) NOT NULL,
  `tipo_servico` varchar(50) NOT NULL,
  `status` varchar(10) NOT NULL,
  PRIMARY KEY (`servico_id`),
  UNIQUE KEY `uq_servico_reboque_desc` (`descricao`),
  CONSTRAINT `ck_servico_reboque_status` CHECK (`status` in ('ATIVO','INATIVO'))
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `servico_reboque` WRITE;
/*!40000 ALTER TABLE `servico_reboque` DISABLE KEYS */;
INSERT INTO `servico_reboque` VALUES
(1,'Reboque urbano','REBOQUE','ATIVO'),
(2,'Reboque rodoviÃ¡rio','REBOQUE','ATIVO'),
(3,'Troca de pneu','SOCORRO','ATIVO'),
(4,'Carga de bateria','SOCORRO','ATIVO'),
(5,'Resgate em vala/ribanceira','RESGATE','ATIVO'),
(6,'Pane seca','SOCORRO','INATIVO');
/*!40000 ALTER TABLE `servico_reboque` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `solicitacao`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `solicitacao` (
  `solicitacao_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `veiculo_id` int(10) unsigned NOT NULL,
  `servico_id` int(10) unsigned NOT NULL,
  `funcionario_id` int(10) unsigned DEFAULT NULL,
  `data_hora_solicitacao` datetime NOT NULL DEFAULT current_timestamp(),
  `endereco_origem` varchar(255) NOT NULL,
  `endereco_destino` varchar(255) NOT NULL,
  `distancia_km` decimal(8,2) NOT NULL,
  `observacao` varchar(500) DEFAULT NULL,
  `valor_estimado` decimal(10,2) NOT NULL,
  `status` varchar(15) NOT NULL DEFAULT 'SOLICITADA',
  PRIMARY KEY (`solicitacao_id`),
  KEY `fk_solicitacao_veiculo` (`veiculo_id`),
  KEY `fk_solicitacao_servico` (`servico_id`),
  KEY `fk_solicitacao_funcionario` (`funcionario_id`),
  KEY `idx_solicitacao_data` (`data_hora_solicitacao`),
  KEY `idx_solicitacao_status` (`status`),
  CONSTRAINT `fk_solicitacao_funcionario` FOREIGN KEY (`funcionario_id`) REFERENCES `funcionario` (`funcionario_id`),
  CONSTRAINT `fk_solicitacao_servico` FOREIGN KEY (`servico_id`) REFERENCES `servico_reboque` (`servico_id`),
  CONSTRAINT `fk_solicitacao_veiculo` FOREIGN KEY (`veiculo_id`) REFERENCES `veiculo` (`veiculo_id`),
  CONSTRAINT `ck_solicitacao_distancia` CHECK (`distancia_km` >= 0),
  CONSTRAINT `ck_solicitacao_valor` CHECK (`valor_estimado` >= 0),
  CONSTRAINT `ck_solicitacao_status` CHECK (`status` in ('SOLICITADA','EM_ANALISE','ACEITA','SEM_PRESTADOR','CANCELADA'))
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `solicitacao` WRITE;
/*!40000 ALTER TABLE `solicitacao` DISABLE KEYS */;
INSERT INTO `solicitacao` VALUES
(1,1,1,3,'2026-09-02 08:15:00','Av. RebouÃ§as, 1200 - Pinheiros, SÃ£o Paulo/SP','Oficina Pinheiros - R. dos Pinheiros, 870, SÃ£o Paulo/SP',12.00,'Carro nÃ£o liga, cÃ¢mbio travado',192.00,'ACEITA'),
(2,3,2,NULL,'2026-09-06 02:30:00','Rod. dos Bandeirantes, km 72 - JundiaÃ­/SP','Toyota ConcessionÃ¡ria - Av. RebouÃ§as, 3000, SÃ£o Paulo/SP',85.00,'Pane elÃ©trica na rodovia, veÃ­culo blindado',685.00,'ACEITA'),
(3,4,4,4,'2026-09-07 10:00:00','R. Vergueiro, 3185 - Vila Mariana, SÃ£o Paulo/SP','No local (mesmo endereÃ§o da origem)',5.00,'Bateria descarregada na garagem',87.50,'ACEITA'),
(4,5,1,3,'2026-09-10 14:20:00','Av. dos Estados, 4500 - Santo AndrÃ©/SP','Oficina Diesel ABC - R. das Figueiras, 300, Santo AndrÃ©/SP',18.00,'Van de entregas com motor fundido',320.00,'ACEITA'),
(5,10,2,2,'2026-09-12 16:00:00','Rod. Anhanguera, km 98 - Valinhos/SP','PÃ¡tio Transportadora - Rod. Anhanguera, km 25, SÃ£o Paulo/SP',140.00,'CaminhÃ£o carregado, quebra de eixo',2480.00,'ACEITA'),
(6,2,1,NULL,'2026-09-15 19:30:00','R. Augusta, 900 - ConsolaÃ§Ã£o, SÃ£o Paulo/SP','Moto Center - R. Augusta, 2200, SÃ£o Paulo/SP',8.00,'Corrente da moto arrebentou',120.00,'ACEITA'),
(7,7,3,4,'2026-09-18 11:00:00','Av. Monteiro Lobato, 1500 - Guarulhos/SP','No local (mesmo endereÃ§o da origem)',6.00,'Pneu furado, sem estepe utilizÃ¡vel',99.00,'ACEITA'),
(8,8,1,3,'2026-09-20 09:00:00','Av. Faria Lima, 3477 - Itaim Bibi, SÃ£o Paulo/SP','Jeep ConcessionÃ¡ria - Av. Europa, 500, SÃ£o Paulo/SP',22.00,'Luz de injeÃ§Ã£o acesa',299.00,'CANCELADA'),
(9,6,2,2,'2026-09-24 07:30:00','Rod. Presidente Dutra, km 210 - Guarulhos/SP','Oficina Diesel ABC - R. das Figueiras, 300, Santo AndrÃ©/SP',60.00,'Superaquecimento do motor',930.00,'ACEITA'),
(10,9,1,NULL,'2026-09-28 03:10:00','R. Tuiuti, 300 - TatuapÃ©, SÃ£o Paulo/SP','Auto Center TatuapÃ© - R. Itapura, 1000, SÃ£o Paulo/SP',15.00,'ColisÃ£o leve, roda danificada',202.50,'ACEITA'),
(11,11,1,4,'2026-10-02 13:00:00','Av. Kennedy, 1500 - SÃ£o Bernardo do Campo/SP','Fiat ConcessionÃ¡ria - Av. Senador Vergueiro, 2000, SÃ£o Bernardo do Campo/SP',10.00,'Embreagem quebrada',185.00,'ACEITA'),
(12,12,2,3,'2026-10-04 10:30:00','Rod. dos Imigrantes, km 40 - SÃ£o Bernardo do Campo/SP','Yamaha Motos - Av. Kennedy, 500, SÃ£o Bernardo do Campo/SP',45.00,'Moto parou na serra',275.00,'ACEITA'),
(13,13,5,2,'2026-10-06 18:00:00','Estrada da RoselÃ¢ndia, 2000 - Cotia/SP','Honda ConcessionÃ¡ria - Av. Brasil, 1000, SÃ£o Paulo/SP',30.00,'VeÃ­culo caiu em vala lateral',780.00,'ACEITA'),
(14,8,2,NULL,'2026-10-09 05:20:00','Rod. Castello Branco, km 70 - Itu/SP','Jeep ConcessionÃ¡ria - Av. Europa, 500, SÃ£o Paulo/SP',70.00,'Problema na transmissÃ£o',610.00,'ACEITA'),
(15,14,1,NULL,'2026-10-12 15:00:00','Av. Paulista, 2000 - Bela Vista, SÃ£o Paulo/SP','Toyota ConcessionÃ¡ria - Av. RebouÃ§as, 3000, SÃ£o Paulo/SP',20.00,'VeÃ­culo blindado, nÃ£o dÃ¡ partida',220.00,'CANCELADA'),
(16,5,1,3,'2026-10-14 16:00:00','Av. Industrial, 600 - Santo AndrÃ©/SP','Oficina Diesel ABC - R. das Figueiras, 300, Santo AndrÃ©/SP',25.00,'Van com freio travado',355.00,'CANCELADA'),
(17,1,4,3,'2026-10-15 07:50:00','R. Augusta, 1500 - ConsolaÃ§Ã£o, SÃ£o Paulo/SP','No local (mesmo endereÃ§o da origem)',3.00,'Bateria arriada',84.50,'ACEITA'),
(18,4,2,4,'2026-10-20 21:00:00','Rod. RÃ©gis Bittencourt, km 350 - Juquitiba/SP','Hyundai ConcessionÃ¡ria - R. Vergueiro, 4000, SÃ£o Paulo/SP',120.00,'Correia dentada rompida',680.00,'ACEITA'),
(19,11,1,4,'2026-10-22 12:00:00','Av. Kennedy, 880 - SÃ£o Bernardo do Campo/SP','Fiat ConcessionÃ¡ria - Av. Senador Vergueiro, 2000, SÃ£o Bernardo do Campo/SP',11.00,'Nenhum prestador respondeu',188.50,'SEM_PRESTADOR'),
(20,3,1,2,'2026-10-26 10:00:00','Av. Paulista, 1000 - Bela Vista, SÃ£o Paulo/SP','Toyota ConcessionÃ¡ria - Av. RebouÃ§as, 3000, SÃ£o Paulo/SP',14.00,'Barulho forte na suspensÃ£o',263.00,'ACEITA'),
(21,7,1,NULL,'2026-10-27 22:15:00','Av. Monteiro Lobato, 800 - Guarulhos/SP','VW ConcessionÃ¡ria - Av. Tiradentes, 1200, Guarulhos/SP',9.00,'Motor apagou e nÃ£o volta',181.50,'ACEITA'),
(22,9,3,3,'2026-10-28 08:40:00','R. Tuiuti, 1200 - TatuapÃ©, SÃ£o Paulo/SP','No local (mesmo endereÃ§o da origem)',4.00,'Dois pneus furados',96.00,'EM_ANALISE'),
(23,13,1,3,'2026-10-29 18:00:00','Rua das Flores, 45 - Centro, Guarulhos/SP','Honda ConcessionÃ¡ria - Av. Brasil, 1000, SÃ£o Paulo/SP',28.00,'RuÃ­do no motor, cliente prefere rebocar',326.00,'SOLICITADA');
/*!40000 ALTER TABLE `solicitacao` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER trg_solicitacao_bi BEFORE INSERT ON solicitacao
FOR EACH ROW
BEGIN
    IF (SELECT c.status FROM veiculo v JOIN cliente c ON c.cliente_id = v.cliente_id
        WHERE v.veiculo_id = NEW.veiculo_id) <> 'ATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R16: solicitacao permitida somente para cliente ATIVO';
    END IF;
    IF (SELECT status FROM servico_reboque WHERE servico_id = NEW.servico_id) <> 'ATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Servico INATIVO nao aceita novos pedidos';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `tarifa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tarifa` (
  `tarifa_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tipo_veiculo_id` int(10) unsigned NOT NULL,
  `servico_id` int(10) unsigned NOT NULL,
  `valor_base` decimal(10,2) NOT NULL,
  `valor_por_km` decimal(10,2) NOT NULL,
  `adicional_madrugada` decimal(10,2) NOT NULL DEFAULT 0.00,
  `adicional_domingo` decimal(10,2) NOT NULL DEFAULT 0.00,
  `adicional_feriado` decimal(10,2) NOT NULL DEFAULT 0.00,
  `adicional_rodovia` decimal(10,2) NOT NULL DEFAULT 0.00,
  `vigencia_inicio` date NOT NULL,
  `vigencia_fim` date DEFAULT NULL,
  `status` varchar(10) NOT NULL,
  PRIMARY KEY (`tarifa_id`),
  UNIQUE KEY `uq_tarifa_vigencia` (`tipo_veiculo_id`,`servico_id`,`vigencia_inicio`),
  KEY `fk_tarifa_servico` (`servico_id`),
  CONSTRAINT `fk_tarifa_servico` FOREIGN KEY (`servico_id`) REFERENCES `servico_reboque` (`servico_id`),
  CONSTRAINT `fk_tarifa_tipo_veiculo` FOREIGN KEY (`tipo_veiculo_id`) REFERENCES `tipo_veiculo` (`tipo_veiculo_id`),
  CONSTRAINT `ck_tarifa_valores` CHECK (`valor_base` >= 0 and `valor_por_km` >= 0 and `adicional_madrugada` >= 0 and `adicional_domingo` >= 0 and `adicional_feriado` >= 0 and `adicional_rodovia` >= 0),
  CONSTRAINT `ck_tarifa_vigencia` CHECK (`vigencia_fim` is null or `vigencia_fim` >= `vigencia_inicio`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `tarifa` WRITE;
/*!40000 ALTER TABLE `tarifa` DISABLE KEYS */;
INSERT INTO `tarifa` VALUES
(1,2,1,150.00,3.50,50.00,40.00,60.00,0.00,'2026-01-01',NULL,'ATIVA'),
(2,2,2,200.00,4.00,60.00,50.00,70.00,80.00,'2026-01-01',NULL,'ATIVA'),
(3,1,1,100.00,2.50,40.00,30.00,40.00,0.00,'2026-01-01',NULL,'ATIVA'),
(4,3,1,200.00,4.50,60.00,50.00,70.00,0.00,'2026-01-01',NULL,'ATIVA'),
(5,3,2,260.00,5.00,70.00,60.00,80.00,100.00,'2026-01-01',NULL,'ATIVA'),
(6,4,1,230.00,5.00,70.00,50.00,70.00,0.00,'2026-01-01',NULL,'ATIVA'),
(7,5,2,450.00,8.00,100.00,80.00,120.00,150.00,'2026-01-01',NULL,'ATIVA'),
(8,6,2,800.00,12.00,150.00,120.00,180.00,250.00,'2026-01-01',NULL,'ATIVA'),
(9,2,3,90.00,1.50,30.00,20.00,30.00,0.00,'2026-01-01',NULL,'ATIVA'),
(10,2,4,80.00,1.50,30.00,20.00,30.00,0.00,'2026-01-01',NULL,'ATIVA'),
(11,3,5,600.00,6.00,120.00,100.00,150.00,200.00,'2026-01-01',NULL,'ATIVA'),
(12,2,1,130.00,3.00,45.00,35.00,50.00,0.00,'2025-01-01','2025-12-31','INATIVA'),
(13,1,2,140.00,3.00,50.00,40.00,50.00,60.00,'2026-01-01',NULL,'ATIVA');
/*!40000 ALTER TABLE `tarifa` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER trg_tarifa_bi BEFORE INSERT ON tarifa
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM tarifa t
               WHERE t.tipo_veiculo_id = NEW.tipo_veiculo_id AND t.servico_id = NEW.servico_id
                 AND t.vigencia_inicio <= COALESCE(NEW.vigencia_fim, '9999-12-31')
                 AND COALESCE(t.vigencia_fim, '9999-12-31') >= NEW.vigencia_inicio) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R11: vigencia sobreposta a outra tarifa do mesmo veiculo e servico';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER trg_tarifa_bu BEFORE UPDATE ON tarifa
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM tarifa t
               WHERE t.tarifa_id <> NEW.tarifa_id
                 AND t.tipo_veiculo_id = NEW.tipo_veiculo_id AND t.servico_id = NEW.servico_id
                 AND t.vigencia_inicio <= COALESCE(NEW.vigencia_fim, '9999-12-31')
                 AND COALESCE(t.vigencia_fim, '9999-12-31') >= NEW.vigencia_inicio) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R11: vigencia sobreposta a outra tarifa do mesmo veiculo e servico';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `tipo_guincho`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tipo_guincho` (
  `tipo_guincho_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `descricao` varchar(50) NOT NULL,
  `capacidade_max_kg` decimal(8,2) DEFAULT NULL,
  PRIMARY KEY (`tipo_guincho_id`),
  UNIQUE KEY `uq_tipo_guincho_desc` (`descricao`),
  CONSTRAINT `ck_tipo_guincho_capacidade` CHECK (`capacidade_max_kg` is null or `capacidade_max_kg` > 0)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `tipo_guincho` WRITE;
/*!40000 ALTER TABLE `tipo_guincho` DISABLE KEYS */;
INSERT INTO `tipo_guincho` VALUES
(1,'Carretinha para motos',400.00),
(2,'Plataforma (prancha)',3500.00),
(3,'Plataforma pesada',8000.00),
(4,'Asa delta',4000.00),
(5,'LanÃ§a pesada',25000.00);
/*!40000 ALTER TABLE `tipo_guincho` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `tipo_veiculo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tipo_veiculo` (
  `tipo_veiculo_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `descricao` varchar(50) NOT NULL,
  `categoria` varchar(50) DEFAULT NULL,
  `peso_max_kg` decimal(8,2) DEFAULT NULL,
  PRIMARY KEY (`tipo_veiculo_id`),
  UNIQUE KEY `uq_tipo_veiculo_desc` (`descricao`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `tipo_veiculo` WRITE;
/*!40000 ALTER TABLE `tipo_veiculo` DISABLE KEYS */;
INSERT INTO `tipo_veiculo` VALUES
(1,'Motocicleta','LEVE',300.00),
(2,'AutomÃ³vel de passeio','LEVE',2000.00),
(3,'SUV / Picape','MEDIO',3000.00),
(4,'UtilitÃ¡rio / Van','MEDIO',3500.00),
(5,'CaminhÃ£o leve (3/4)','PESADO',8000.00),
(6,'CaminhÃ£o pesado / Ã”nibus','PESADO',25000.00);
/*!40000 ALTER TABLE `tipo_veiculo` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `veiculo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `veiculo` (
  `veiculo_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `cliente_id` int(10) unsigned NOT NULL,
  `tipo_veiculo_id` int(10) unsigned NOT NULL,
  `placa` varchar(8) NOT NULL,
  `marca` varchar(50) NOT NULL,
  `modelo` varchar(60) NOT NULL,
  `ano` smallint(6) NOT NULL,
  `cor` varchar(30) DEFAULT NULL,
  `blindado` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`veiculo_id`),
  UNIQUE KEY `uq_veiculo_placa` (`placa`),
  KEY `fk_veiculo_cliente` (`cliente_id`),
  KEY `fk_veiculo_tipo_veiculo` (`tipo_veiculo_id`),
  CONSTRAINT `fk_veiculo_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `cliente` (`cliente_id`),
  CONSTRAINT `fk_veiculo_tipo_veiculo` FOREIGN KEY (`tipo_veiculo_id`) REFERENCES `tipo_veiculo` (`tipo_veiculo_id`),
  CONSTRAINT `ck_veiculo_ano` CHECK (`ano` >= 1900),
  CONSTRAINT `ck_veiculo_blindado` CHECK (`blindado` in (0,1))
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `veiculo` WRITE;
/*!40000 ALTER TABLE `veiculo` DISABLE KEYS */;
INSERT INTO `veiculo` VALUES
(1,1,2,'BRA2E19','Chevrolet','Onix',2022,'Branco',0),
(2,1,1,'MOT1A11','Honda','CG 160',2021,'Vermelho',0),
(3,2,3,'SUV3B22','Toyota','Hilux',2023,'Prata',1),
(4,3,2,'CAR4C33','Hyundai','HB20',2020,'Preto',0),
(5,4,4,'VAN5D44','Fiat','Ducato',2019,'Branco',0),
(6,4,5,'CAM6E55','Volkswagen','Delivery Express',2021,'Branco',0),
(7,5,2,'CAR7F66','Volkswagen','Polo',2023,'Cinza',0),
(8,6,3,'SUV8G77','Jeep','Compass',2022,'Preto',1),
(9,7,2,'CAR9H88','Renault','Kwid',2019,'Laranja',0),
(10,8,6,'ONI1J99','Mercedes-Benz','Axor 2544',2017,'Azul',0),
(11,9,2,'CAR2K10','Fiat','Argo',2021,'Vermelho',0),
(12,9,1,'MOT3L21','Yamaha','Fazer 250',2022,NULL,0),
(13,5,3,'SUV4M32','Honda','HR-V',2024,'Branco',0),
(14,2,2,'CAR5N43','Toyota','Corolla',2024,'Preto',1),
(15,11,2,'CAR6P54','Chevrolet','Prisma',2015,'Prata',0);
/*!40000 ALTER TABLE `veiculo` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `veiculo_reboque`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `veiculo_reboque` (
  `veiculo_reboque_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tipo_guincho_id` int(10) unsigned NOT NULL,
  `placa` varchar(8) NOT NULL,
  `marca` varchar(50) DEFAULT NULL,
  `modelo` varchar(60) NOT NULL,
  `ano` smallint(6) NOT NULL,
  `capacidade_kg` decimal(8,2) DEFAULT NULL,
  `status` varchar(20) NOT NULL,
  PRIMARY KEY (`veiculo_reboque_id`),
  UNIQUE KEY `uq_veiculo_reboque_placa` (`placa`),
  KEY `fk_veiculo_reboque_tipo_guincho` (`tipo_guincho_id`),
  CONSTRAINT `fk_veiculo_reboque_tipo_guincho` FOREIGN KEY (`tipo_guincho_id`) REFERENCES `tipo_guincho` (`tipo_guincho_id`),
  CONSTRAINT `ck_veiculo_reboque_ano` CHECK (`ano` >= 1900)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `veiculo_reboque` WRITE;
/*!40000 ALTER TABLE `veiculo_reboque` DISABLE KEYS */;
INSERT INTO `veiculo_reboque` VALUES
(1,2,'GUI1A23','Volkswagen','Delivery 9.170',2021,3500.00,'DISPONIVEL'),
(2,2,'GUI2B34','Ford','Cargo 816',2020,3500.00,'EM_SERVICO'),
(3,3,'GUI3C45','Mercedes-Benz','Accelo 1016',2022,8000.00,'EM_SERVICO'),
(4,4,'GUI4D56','Iveco','Daily 70C17',2019,4000.00,'DISPONIVEL'),
(5,5,'GUI5E67','Volvo','VM 270',2018,25000.00,'DISPONIVEL'),
(6,1,'GUI6F78','Fiat','Strada Carretinha',2023,400.00,'DISPONIVEL'),
(7,2,'GUI7G89',NULL,'HR Plataforma',2017,NULL,'MANUTENCAO');
/*!40000 ALTER TABLE `veiculo_reboque` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER trg_veiculo_reboque_bi BEFORE INSERT ON veiculo_reboque
FOR EACH ROW
BEGIN
    IF NEW.capacidade_kg > (SELECT capacidade_max_kg FROM tipo_guincho WHERE tipo_guincho_id = NEW.tipo_guincho_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R12: capacidade do guincho acima da capacidade maxima do tipo';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER trg_veiculo_reboque_bu BEFORE UPDATE ON veiculo_reboque
FOR EACH ROW
BEGIN
    IF NEW.capacidade_kg > (SELECT capacidade_max_kg FROM tipo_guincho WHERE tipo_guincho_id = NEW.tipo_guincho_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R12: capacidade do guincho acima da capacidade maxima do tipo';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `vw_ordem_servico_detalhada`;
/*!50001 DROP VIEW IF EXISTS `vw_ordem_servico_detalhada`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vw_ordem_servico_detalhada` AS SELECT
 1 AS `ordem_id`,
  1 AS `status_atual`,
  1 AS `solicitacao_id`,
  1 AS `data_hora_solicitacao`,
  1 AS `cliente_id`,
  1 AS `cliente`,
  1 AS `placa_veiculo`,
  1 AS `veiculo`,
  1 AS `tipo_veiculo`,
  1 AS `servico`,
  1 AS `prestador_id`,
  1 AS `prestador`,
  1 AS `empresa`,
  1 AS `placa_guincho`,
  1 AS `tipo_guincho`,
  1 AS `distancia_km`,
  1 AS `data_hora_inicio`,
  1 AS `data_previsao`,
  1 AS `data_hora_fim`,
  1 AS `valor_base`,
  1 AS `valor_adicionais`,
  1 AS `desconto`,
  1 AS `valor_total` */;
SET character_set_client = @saved_cs_client;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_valida_ordem_servico` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE  PROCEDURE `sp_valida_ordem_servico`(IN p_solicitacao INT UNSIGNED, IN p_tarifa INT UNSIGNED,
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

    
    IF v_status_prest <> 'ATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R8: somente prestador com status ATIVO pode receber O.S.';
    END IF;

    
    IF NOT EXISTS (SELECT 1 FROM notificacao_prestador
                   WHERE solicitacao_id = p_solicitacao AND prestador_id = p_prestador AND resposta = 'ACEITA') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R7: o prestador da O.S. deve ser o que aceitou a solicitacao';
    END IF;

    
    IF NOT EXISTS (SELECT 1 FROM prestador_veiculo_reboque
                   WHERE prestador_id = p_prestador AND veiculo_reboque_id = p_reboque
                     AND v_data >= data_inicio AND (data_fim IS NULL OR v_data <= data_fim)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R9: o guincho nao tem vinculo vigente com o prestador';
    END IF;

    
    IF NOT EXISTS (SELECT 1 FROM guincho_tipo_veiculo
                   WHERE tipo_guincho_id = v_tipo_guincho AND tipo_veiculo_id = v_tipo_veiculo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R9: tipo de guincho incompativel com o tipo do veiculo';
    END IF;

    
    IF NOT EXISTS (SELECT 1 FROM tarifa
                   WHERE tarifa_id = p_tarifa AND tipo_veiculo_id = v_tipo_veiculo AND servico_id = v_servico
                     AND v_data >= vigencia_inicio AND (vigencia_fim IS NULL OR v_data <= vigencia_fim)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'R10: tarifa nao corresponde ao veiculo/servico ou fora da vigencia';
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

USE `feliguinchos_v2`;
/*!50001 DROP VIEW IF EXISTS `vw_ordem_servico_detalhada`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY DEFINER */
/*!50001 VIEW `vw_ordem_servico_detalhada` AS select `os`.`ordem_id` AS `ordem_id`,`os`.`status_atual` AS `status_atual`,`s`.`solicitacao_id` AS `solicitacao_id`,`s`.`data_hora_solicitacao` AS `data_hora_solicitacao`,`c`.`cliente_id` AS `cliente_id`,`c`.`nome` AS `cliente`,`v`.`placa` AS `placa_veiculo`,concat(`v`.`marca`,' ',`v`.`modelo`) AS `veiculo`,`tv`.`descricao` AS `tipo_veiculo`,`sr`.`descricao` AS `servico`,`p`.`prestador_id` AS `prestador_id`,`p`.`nome` AS `prestador`,coalesce(`e`.`razao_social`,'Autônomo') AS `empresa`,`vr`.`placa` AS `placa_guincho`,`tg`.`descricao` AS `tipo_guincho`,`s`.`distancia_km` AS `distancia_km`,`os`.`data_hora_inicio` AS `data_hora_inicio`,`os`.`data_previsao` AS `data_previsao`,`os`.`data_hora_fim` AS `data_hora_fim`,`os`.`valor_base` AS `valor_base`,`os`.`valor_adicionais` AS `valor_adicionais`,`os`.`desconto` AS `desconto`,`os`.`valor_total` AS `valor_total` from (((((((((`ordem_servico` `os` join `solicitacao` `s` on(`s`.`solicitacao_id` = `os`.`solicitacao_id`)) join `veiculo` `v` on(`v`.`veiculo_id` = `s`.`veiculo_id`)) join `cliente` `c` on(`c`.`cliente_id` = `v`.`cliente_id`)) join `tipo_veiculo` `tv` on(`tv`.`tipo_veiculo_id` = `v`.`tipo_veiculo_id`)) join `servico_reboque` `sr` on(`sr`.`servico_id` = `s`.`servico_id`)) join `prestador_servico` `p` on(`p`.`prestador_id` = `os`.`prestador_id`)) left join `empresa` `e` on(`e`.`empresa_id` = `p`.`empresa_id`)) join `veiculo_reboque` `vr` on(`vr`.`veiculo_reboque_id` = `os`.`veiculo_reboque_id`)) join `tipo_guincho` `tg` on(`tg`.`tipo_guincho_id` = `vr`.`tipo_guincho_id`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

