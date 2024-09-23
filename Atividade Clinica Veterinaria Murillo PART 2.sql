create schema clinicavet;
use clinicavet;

create table paciente(
id_paciente int auto_increment primary key,
nome  varchar (100),
especie varchar (50),
idade int);

insert into paciente (nome, especie, idade)
values ('Maya','Cachorro',1);

select * from paciente;


create table veterinario (
id_veterinario int auto_increment primary key,
nome varchar (100),
especialidade VARCHAR (50));

insert into veterinario (nome, especialidade)
values ('Thiago', 'Aves');

SELECT * FROM veterinario;


create table consultas (
id_consulta int auto_increment primary key,
id_pacientefk int,
id_veterinariofk int,
data_consulta date,
custo decimal (10,2),
constraint id_pacientefkk Foreign key (id_pacientefk) references paciente (id_paciente),
constraint id_veterinariofkk Foreign key (id_veterinariofk)  references veterinario (id_veterinario));

insert into consultas (id_pacientefk, id_veterinariofk, data_consulta, custo)
values (1,1,'2024-09-22', 110.90);

SELECT * FROM consultas;


DELIMITER //
CREATE PROCEDURE agendar_consulta (
    IN id_paciente INT,
    IN id_veterinario INT,
    IN data_consulta DATE,
    IN custo DECIMAL(10, 2)
)
BEGIN
    INSERT INTO consultas (id_pacientefk, id_veterinariofk, data_consulta, custo)
    VALUES (id_pacientefk, id_veterinariofk, data_consulta, custo);
    
    SELECT 'Consulta agendada com sucesso.' AS Mensagem;
END //
DELIMITER ;

CALL agendar_consulta(1, 1, '2024-09-30', 150.00);





DELIMITER //
CREATE PROCEDURE atualizar_paciente (
    IN id_paciente INT,
    IN novo_nome VARCHAR(100),
    IN nova_especie VARCHAR(50),
    IN nova_idade INT
)
BEGIN
    UPDATE paciente
    SET nome = novo_nome,
        especie = nova_especie,
        idade = nova_idade
    WHERE id_paciente = id_paciente;
    IF ROW_COUNT() > 0 THEN
        SELECT 'Paciente atualizado com sucesso.' AS Mensagem;
    ELSE
        SELECT 'Nenhum paciente encontrado com o ID fornecido.' AS Mensagem;
    END IF;
END //
DELIMITER ;
drop procedure atualizar_paciente;
call atualizar_paciente (1,'Golias','Macaco',12);




DELIMITER //
CREATE PROCEDURE remover_consulta (
    IN id_consulta INT
)
BEGIN
    DELETE FROM consultas
    WHERE id_consulta = id_consulta;
    IF ROW_COUNT() > 0 THEN
        SELECT 'Consulta removida com sucesso.' AS Mensagem;
    ELSE
        SELECT 'Nenhuma consulta encontrada com o ID fornecido.' AS Mensagem;
    END IF;
END //
DELIMITER ;
drop procedure remover_consulta;
CALL remover_consulta(1);





DELIMITER //
CREATE FUNCTION total_gasto_paciente (
 id_paciente INT
) 
RETURNS DECIMAL(10, 2)
BEGIN
    DECLARE total DECIMAL(10, 2);
    SELECT SUM(custo) INTO total
    FROM consultas
    WHERE id_pacientefk = id_paciente;
    RETURN IFNULL(total, 0.00);
END //
DELIMITER ;
SELECT total_gasto_paciente(1) AS total_gasto;




DELIMITER //
CREATE TRIGGER verificar_idade_paciente
BEFORE INSERT ON paciente
FOR EACH ROW
BEGIN
    IF NEW.idade < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Idade inválida: deve ser um número positivo.';
    END IF;
END //
DELIMITER ;







CREATE TABLE Log_Consultas (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_consulta INT,
    custo_antigo DECIMAL(10, 2),
    custo_novo DECIMAL(10, 2),
    data_alteracao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER atualizar_custo_consulta
AFTER UPDATE ON consultas
FOR EACH ROW
BEGIN
    IF OLD.custo <> NEW.custo THEN
        INSERT INTO Log_Consultas (id_consulta, custo_antigo, custo_novo)
        VALUES (NEW.id_consulta, OLD.custo, NEW.custo);
    END IF;
END //
DELIMITER ;

UPDATE consultas SET Custo = 100.00 WHERE id_consulta = 1;



CREATE TABLE tratamentos (
    id_tratamento INT AUTO_INCREMENT PRIMARY KEY,
    id_consulta INT,
    descricao VARCHAR(255),
    custo DECIMAL(10, 2),
    FOREIGN KEY (id_consulta) REFERENCES consultas(id_consulta) ON DELETE CASCADE
);
insert into tratamentos(id_tratamento,id_consulta,descricao,custo)
Values (1,1,"doença no estomago", 100);
select * from tratamentos;

CREATE TABLE medicamentos (
    id_medicamento INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    dosagem VARCHAR(50),
    descricaom VARCHAR(255)
);
insert into medicamentos(id_medicamento,nome,dosagem,descricaom)
Values (1,"TROTATINA","100ml", "Para virus de estomago");

Select * from medicamentos;


CREATE TABLE historico_vacinas (
    id_vacina INT AUTO_INCREMENT PRIMARY KEY,
    id_pacientehv INT,
    nome_vacina VARCHAR(100) NOT NULL,
    data_aplicacao DATE,
    proxima_vacina DATE,
    FOREIGN KEY (id_pacientehv) REFERENCES paciente(id_paciente));
drop table historico_vacinas;

insert into historico_vacinas(id_pacientehv, nome_vacina,data_aplicacao,proxima_vacina)
Values (1,"H13V",20240922,20250122);
select * from historico_vacinas;





DELIMITER //
CREATE TRIGGER registrar_alteracoes_tratamento
AFTER UPDATE ON Tratamentos
FOR EACH ROW
BEGIN
    INSERT INTO Log_Tratamentos (id_tratamento, custo_antigo, custo_novo, data_alteracao)
    VALUES (OLD.id_tratamento, OLD.custo, NEW.custo, NOW());
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER prevenir_exclusao_medicamento
BEFORE DELETE ON Medicamentos
FOR EACH ROW
BEGIN
    DECLARE num_tratamentos INT;
    SELECT COUNT(*) INTO num_tratamentos FROM Tratamentos WHERE id_medicamento = OLD.id_medicamento;

    IF num_tratamentos > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Não é possível excluir o medicamento: está relacionado a tratamentos.';
    END IF;
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER normalizar_nome_medicamento
BEFORE INSERT ON Medicamentos
FOR EACH ROW
BEGIN
    SET NEW.nome = UPPER(NEW.nome);
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER atualizar_proxima_vacina
AFTER INSERT ON historico_vacinas
FOR EACH ROW
BEGIN
    UPDATE historico_vacinas
    SET proxima_vacina = DATE_ADD(NEW.data_aplicacao, INTERVAL 1 YEAR)
    WHERE id_pacientehv = NEW.id_pacientehv AND nome_vacina = NEW.nome_vacina;
END //
DELIMITER ;




CREATE TABLE Log_Avisos_Vacinas (
    id_aviso INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente INT,
    nome_vacina VARCHAR(100),
    dias_restantes INT,
    data_aviso TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
DELIMITER //
CREATE TRIGGER verificar_vacinas_em_dia
AFTER INSERT ON historico_vacinas
FOR EACH ROW
BEGIN
    DECLARE dias_restantes INT;

    SET dias_restantes = DATEDIFF(NEW.proxima_vacina, NOW());
    
    IF dias_restantes BETWEEN 0 AND 30 THEN
        INSERT INTO Log_Avisos_Vacinas (id_pacientehv, nome_vacina, dias_restantes, data_aviso)
        VALUES (NEW.id_pacientehv, NEW.nome_vacina, dias_restantes, NOW());
    END IF;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE adicionar_medicamento (
    IN p_nome VARCHAR(100),
    IN p_dosagem VARCHAR(50),
    IN p_descricaom VARCHAR(255)
)
BEGIN
    INSERT INTO Medicamentos (nome, dosagem, descricaom)
    VALUES (p_nome, p_dosagem, p_descricaom);
END //
DELIMITER ;
CALL adicionar_medicamento('Dewormer', '10mg', 'Medicamento para vermes.');


DELIMITER //
CREATE PROCEDURE adicionar_veterinario (
    IN p_nome VARCHAR(100),
    IN p_especialidade VARCHAR(50)
)
BEGIN
    INSERT INTO veterinario (nome, especialidade)
    VALUES (p_nome, p_especialidade);
END //
DELIMITER ;
CALL adicionar_veterinario('Maria', 'Dermatologia');



DELIMITER //
CREATE PROCEDURE buscar_paciente_por_nome (
    IN p_nome VARCHAR(100)
)
BEGIN
    SELECT * FROM paciente WHERE nome LIKE CONCAT('%', p_nome, '%');
END //
DELIMITER ;
CALL buscar_paciente_por_nome('Maya');


DELIMITER //
CREATE PROCEDURE contar_consultas_paciente (
    IN p_id_paciente INT,
    OUT p_contagem INT
)
BEGIN
    SELECT COUNT(*) INTO p_contagem FROM consultas WHERE id_pacientefk = p_id_paciente;
END //
DELIMITER ;

CALL contar_consultas_paciente(1, @contagem);
SELECT @contagem;




DELIMITER //
CREATE PROCEDURE remover_vacina (
    IN p_id_vacina INT
)
BEGIN
    DELETE FROM Historico_Vacinas WHERE id_vacina = p_id_vacina;
END //
DELIMITER ;
CALL remover_vacina(1);