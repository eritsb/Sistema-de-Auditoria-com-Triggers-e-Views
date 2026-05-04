CREATE DATABASE bd_auditoria;

USE bd_auditoria;

CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100),
    cpf VARCHAR(14),
    email VARCHAR(100),
    telefone VARCHAR(20),
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) -- ativo, inativo
);

CREATE TABLE produtos (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100),
    descricao TEXT,
    preco DECIMAL(10,2),
    estoque INT,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20)
);

CREATE TABLE vendas (
    id_venda INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    data_venda DATETIME DEFAULT CURRENT_TIMESTAMP,
    valor_total DECIMAL(10,2),
    status VARCHAR(20), -- concluída, cancelada
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE itens_venda (
    id_item INT AUTO_INCREMENT PRIMARY KEY,
    id_venda INT,
    id_produto INT,
    quantidade INT,
    preco_unitario DECIMAL(10,2),
    FOREIGN KEY (id_venda) REFERENCES vendas(id_venda),
    FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);

CREATE TABLE auditoria (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    tabela_afetada VARCHAR(50) NOT NULL,
    operacao ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    id_registro INT NOT NULL,
    valor_antigo JSON,
    valor_novo JSON,
    usuario VARCHAR(100),
    data_operacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TRIGGERS 

DELIMITER $$

CREATE TRIGGER trg_produtos_insert
AFTER INSERT ON produtos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (
        tabela_afetada, operacao, id_registro, valor_novo, usuario
    )
    VALUES (
        'produtos',
        'INSERT',
        NEW.id_produto,
        JSON_OBJECT(
            'nome', NEW.nome,
            'descricao', NEW.descricao,
            'preco', NEW.preco,
            'estoque', NEW.estoque,
            'status', NEW.status
        ),
        CURRENT_USER()
    );
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_clientes_insert
AFTER INSERT ON clientes
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (
        tabela_afetada, operacao, id_registro, valor_novo, usuario
    )
    VALUES (
        'clientes',
        'INSERT',
        NEW.id_cliente,
        JSON_OBJECT(
            'nome', NEW.nome,
            'cpf', NEW.cpf,
            'email', NEW.email,
            'telefone', NEW.telefone,
            'status', NEW.status,
            'data_cadastro', NEW.data_cadastro
        ),
        CURRENT_USER()
    );
END$$

CREATE TRIGGER trg_clientes_update
AFTER UPDATE ON clientes
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (
        tabela_afetada, operacao, id_registro, valor_antigo, valor_novo, usuario
    )
    VALUES (
        'clientes',
        'UPDATE',
        NEW.id_cliente,
        JSON_OBJECT(
            'nome', OLD.nome,
            'cpf', OLD.cpf,
            'email', OLD.email,
            'telefone', OLD.telefone,
            'status', OLD.status,
            'data_cadastro', OLD.data_cadastro
        ),
        JSON_OBJECT(
            'nome', NEW.nome,
            'cpf', NEW.cpf,
            'email', NEW.email,
            'telefone', NEW.telefone,
            'status', NEW.status,
            'data_cadastro', NEW.data_cadastro
        ),
        CURRENT_USER()
    );
END$$

CREATE TRIGGER trg_clientes_delete
AFTER DELETE ON clientes
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (
        tabela_afetada, operacao, id_registro, valor_antigo, usuario
    )
    VALUES (
        'clientes',
        'DELETE',
        OLD.id_cliente,
        JSON_OBJECT(
            'nome', OLD.nome,
            'cpf', OLD.cpf,
            'email', OLD.email,
            'telefone', OLD.telefone,
            'status', OLD.status,
            'data_cadastro', OLD.data_cadastro
        ),
        CURRENT_USER()
    );
END$$

CREATE TRIGGER trg_produtos_update
AFTER UPDATE ON produtos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (
        tabela_afetada, operacao, id_registro, valor_antigo, valor_novo, usuario
    )
    VALUES (
        'produtos',
        'UPDATE',
        NEW.id_produto,
        JSON_OBJECT(
            'nome', OLD.nome,
            'descricao', OLD.descricao,
            'preco', OLD.preco,
            'estoque', OLD.estoque,
            'status', OLD.status
        ),
        JSON_OBJECT(
            'nome', NEW.nome,
            'descricao', NEW.descricao,
            'preco', NEW.preco,
            'estoque', NEW.estoque,
            'status', NEW.status
        ),
        CURRENT_USER()
    );
END$$

CREATE TRIGGER trg_vendas_insert
AFTER INSERT ON vendas
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (
        tabela_afetada, operacao, id_registro, valor_novo, usuario
    )
    VALUES (
        'vendas',
        'INSERT',
        NEW.id_venda,
        JSON_OBJECT(
            'id_cliente', NEW.id_cliente,
            'valor_total', NEW.valor_total,
            'status', NEW.status,
            'data_venda', NEW.data_venda
        ),
        CURRENT_USER()
    );
END$$

DELIMITER ;


-- VIEWS

-- Clientes ativos
CREATE VIEW vw_clientes_ativos AS
SELECT 
    id_cliente,
    nome,
    cpf,
    email,
    telefone,
    data_cadastro
FROM clientes
WHERE status = 'ativo';

-- Produtos disponiveis
CREATE VIEW vw_produtos_disponiveis AS
SELECT 
    id_produto,
    nome,
    descricao,
    preco,
    estoque,
    status
FROM produtos
WHERE status = 'ativo' AND estoque > 0;

-- Vendas com nome do cliente
CREATE VIEW vw_vendas_clientes AS
SELECT 
    v.id_venda,
    c.nome AS nome_cliente,
    v.data_venda,
    v.valor_total,
    v.status
FROM vendas v
INNER JOIN clientes c 
    ON v.id_cliente = c.id_cliente;
    
-- Itens vendidos com produto
CREATE VIEW vw_itens_venda_detalhada AS
SELECT 
    iv.id_item,
    iv.id_venda,
    p.nome AS produto,
    iv.quantidade,
    iv.preco_unitario,
    (iv.quantidade * iv.preco_unitario) AS subtotal
FROM itens_venda iv
INNER JOIN produtos p 
    ON iv.id_produto = p.id_produto;
    
-- Auditoria resumo
CREATE VIEW vw_auditoria_resumida AS
SELECT 
    id_auditoria,
    tabela_afetada,
    operacao,
    id_registro,
    usuario,
    data_operacao
FROM auditoria;

-- Teste Cliente

-- Inserir cadastro do cliente:
INSERT INTO clientes (nome, cpf, email, telefone, status)
VALUES ('Danilo', '123.456.789-00', 'danilo@email.com', '99999-9999', 'ativo');

INSERT INTO clientes (nome, cpf, email, telefone, status)
VALUES ('Mariah', '123.456.789-00', 'mariah@email.com', '99999-9999', 'ativo');  -- Exibir 1

-- Atualizar cadastro do cliente:
UPDATE clientes
SET nome = 'Danilo Henrique'
WHERE id_cliente = 1; -- Exibir 1
-- Exibir 3

-- Excluir cadastro do cliente:
DELETE FROM clientes WHERE id_cliente = 1; -- Exibir 1

-- Teste produto

-- Cadastro do produto:
INSERT INTO produtos (nome, descricao, preco, estoque, status)
VALUES ('Camiseta', 'Camiseta preta', 50.00, 18, 'ativo');

INSERT INTO produtos (nome, descricao, preco, estoque, status)
VALUES ('Short', 'Short preto', 40.00, 20, 'ativo'); -- Exibir 2

-- Atualização do estoque e valor:
UPDATE produtos SET estoque = 18, preco = 35.00 WHERE id_produto = 2; -- Exibir 2

-- Validação final:
SELECT * FROM auditoria ORDER BY data_operacao DESC; -- Exibir 3

-- Exemplo de uso

-- Registro de venda:
INSERT INTO vendas (id_cliente, data_venda, valor_total, status)
VALUES (2, NOW(), 180.00, 'finalizada'); -- Exibir 4
-- Trigger trg_vendas_insert é acionada automaticamente

-- Registrar os itens da venda
INSERT INTO itens_venda (id_venda, id_produto, quantidade, preco_unitario)
VALUES (1, 1, 2, 50.00); -- camiseta

INSERT INTO itens_venda (id_venda, id_produto, quantidade, preco_unitario)
VALUES (1, 2, 1, 35.00); -- Short -- Exibir 5

-- Atualizar o estoque
UPDATE produtos SET estoque = estoque - 2 WHERE id_produto = 1; -- camiseta
UPDATE produtos SET estoque = estoque - 1 WHERE id_produto = 2; -- Short  -- Exibir 2
-- Trigger trg_produtos_update registra as alterações

-- Consultar a venda
SELECT * FROM vw_vendas_clientes WHERE id_venda = 1;

-- Exibição 
-- 1
SELECT * FROM clientes;

-- 2
SELECT * FROM produtos;

-- 3
SELECT * FROM auditoria ORDER BY data_operacao DESC;

-- 4
SELECT * FROM vendas;

-- 5
SELECT * FROM itens_venda;
