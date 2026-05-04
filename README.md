#  Sistema de Auditoria com Triggers e Views

> Documentação técnica de um sistema de auditoria de banco de dados desenvolvido em MySQL, utilizando Triggers e Views para garantir rastreabilidade, integridade e transparência das operações.

---

##  Equipe de Desenvolvimento

| Integrante | Responsabilidade |
|------------|-----------------|
| Mariah | Tabelas Principais + Diagrama ER |
| Danilo | Tabela de Auditoria + Conclusão |
| Rejane | Triggers de Auditoria + Explicação |
| Kennedy | Views + Introdução do Projeto |
| Ericha | Testes / Simulação + Repositório Git |

---

##  Sumário

- [Sobre o Projeto](#sobre-o-projeto)
- [Diagrama ER](#diagrama-er)
- [Estrutura do Banco de Dados](#estrutura-do-banco-de-dados)
- [Triggers de Auditoria](#triggers-de-auditoria)
- [Views](#views)
- [Testes Realizados](#testes-realizados)
- [Exemplo de Uso Completo](#exemplo-de-uso-completo)
- [Como Executar](#como-executar)

---

## Sobre o Projeto

Este projeto tem como objetivo a criação de um **sistema de auditoria de banco de dados** utilizando MySQL, aplicando os conceitos de **Triggers** e **Views** para garantir rastreabilidade, integridade e transparência das operações realizadas sobre os dados.

A proposta central é construir um mecanismo automático capaz de registrar todas as alterações efetuadas nas principais entidades do sistema — clientes, produtos e vendas — sem necessidade de intervenção manual na aplicação. Cada inserção, atualização ou exclusão é capturada e armazenada de forma estruturada na tabela de auditoria.

### Contexto e Justificativa

Em ambientes que exigem controle rigoroso sobre os dados — como sistemas financeiros, plataformas de e-commerce e aplicações reguladas — a auditoria de banco de dados é um requisito fundamental. Essa abordagem permite:

-  Garantir conformidade com normas e regulamentações (LGPD, por exemplo)
-  Investigar incidentes de segurança ou erros operacionais
-  Manter um histórico confiável de todas as transações realizadas
-  Facilitar auditorias externas e relatórios de gestão

### Recursos Aplicados

| Recurso | Descrição |
|---------|-----------|
| **Triggers** | Procedimentos armazenados executados automaticamente em resposta a eventos (INSERT, UPDATE, DELETE), registrando valores anteriores e posteriores a cada operação |
| **Views** | Consultas SQL salvas tratadas como tabelas virtuais, simplificando o acesso aos dados e ocultando a complexidade das consultas |

---

## Diagrama ER

O banco de dados `bd_auditoria` é composto por **cinco tabelas principais**:
<img width="600" height="380" alt="Diagrama ER" src="https://github.com/user-attachments/assets/903d3c08-ba8a-4fba-abdc-dcce3f82c05c" />
```
clientes ──(1:N)──> vendas ──(1:N)──> itens_venda <──(1:N)── produtos
                                            │
                                        auditoria
                              (log automático via Triggers)
```

### Relacionamentos

- **clientes → vendas** (1:N): Um cliente pode realizar várias vendas. A tabela `vendas` possui a FK `id_cliente`.
- **vendas → itens_venda** (1:N): Uma venda pode conter vários itens. A tabela `itens_venda` possui a FK `id_venda`.
- **produtos → itens_venda** (1:N): Um produto pode aparecer em vários itens de venda. A tabela `itens_venda` possui a FK `id_produto`.
- **auditoria**: Sem FK direta — ligada às demais tabelas logicamente pelos campos `tabela_afetada` e `id_registro`, preenchidos automaticamente pelas Triggers.

---

## Estrutura do Banco de Dados

### Tabela `clientes`

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_cliente` | INT, PK, AUTO_INCREMENT | Identificador único |
| `nome` | VARCHAR(100) | Nome do cliente |
| `cpf` | VARCHAR(14) | CPF do cliente |
| `email` | VARCHAR(100) | E-mail |
| `telefone` | VARCHAR(20) | Contato |
| `data_cadastro` | DATETIME | Data do cadastro (automático) |
| `status` | VARCHAR(20) | `ativo` / `inativo` |

### Tabela `produtos`

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_produto` | INT, PK, AUTO_INCREMENT | Identificador |
| `nome` | VARCHAR(100) | Nome do produto |
| `descricao` | TEXT | Descrição |
| `preco` | DECIMAL(10,2) | Valor |
| `estoque` | INT | Quantidade disponível |
| `data_cadastro` | DATETIME | Data de cadastro (automático) |
| `status` | VARCHAR(20) | Situação |

### Tabela `vendas`

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_venda` | INT, PK, AUTO_INCREMENT | Identificador |
| `id_cliente` | INT, FK | Referência ao cliente |
| `data_venda` | DATETIME | Data da venda (automático) |
| `valor_total` | DECIMAL(10,2) | Valor total |
| `status` | VARCHAR(20) | `finalizada` / `cancelada` |

### Tabela `itens_venda`

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_item` | INT, PK, AUTO_INCREMENT | Identificador |
| `id_venda` | INT, FK | Referência à venda |
| `id_produto` | INT, FK | Referência ao produto |
| `quantidade` | INT | Quantidade vendida |
| `preco_unitario` | DECIMAL(10,2) | Preço no momento da venda |

### Tabela `auditoria`

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_auditoria` | INT, PK, AUTO_INCREMENT | Identificador |
| `tabela_afetada` | VARCHAR(50) | Nome da tabela modificada |
| `operacao` | ENUM | `INSERT`, `UPDATE` ou `DELETE` |
| `id_registro` | INT | ID do registro afetado |
| `valor_antigo` | JSON | Dados antes da operação |
| `valor_novo` | JSON | Dados após a operação |
| `usuario` | VARCHAR(100) | Usuário responsável |
| `data_operacao` | TIMESTAMP | Data e hora da operação (automático) |

---

## Triggers de Auditoria

Cobertura completa de todas as tabelas monitoradas:

| Trigger | Tabela | Evento | O que registra |
|---------|--------|--------|----------------|
| `trg_clientes_insert` | `clientes` | INSERT | Novos dados do cliente em `valor_novo` |
| `trg_clientes_update` | `clientes` | UPDATE | Antes em `valor_antigo`, depois em `valor_novo` |
| `trg_clientes_delete` | `clientes` | DELETE | Dados removidos em `valor_antigo` |
| `trg_produtos_insert` | `produtos` | INSERT | Novos dados do produto em `valor_novo` |
| `trg_produtos_update` | `produtos` | UPDATE | Antes em `valor_antigo`, depois em `valor_novo` |
| `trg_vendas_insert` | `vendas` | INSERT | Dados da nova venda em `valor_novo` |

### `trg_clientes_insert`

```sql
CREATE TRIGGER trg_clientes_insert
AFTER INSERT ON clientes
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabela_afetada, operacao, id_registro, valor_novo, usuario)
    VALUES (
        'clientes', 'INSERT', NEW.id_cliente,
        JSON_OBJECT(
            'nome', NEW.nome, 'cpf', NEW.cpf,
            'email', NEW.email, 'telefone', NEW.telefone,
            'status', NEW.status, 'data_cadastro', NEW.data_cadastro
        ),
        CURRENT_USER()
    );
END$$
```

### `trg_clientes_update`

```sql
CREATE TRIGGER trg_clientes_update
AFTER UPDATE ON clientes
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabela_afetada, operacao, id_registro, valor_antigo, valor_novo, usuario)
    VALUES (
        'clientes', 'UPDATE', NEW.id_cliente,
        JSON_OBJECT('nome', OLD.nome, 'cpf', OLD.cpf, 'email', OLD.email,
                    'telefone', OLD.telefone, 'status', OLD.status),
        JSON_OBJECT('nome', NEW.nome, 'cpf', NEW.cpf, 'email', NEW.email,
                    'telefone', NEW.telefone, 'status', NEW.status),
        CURRENT_USER()
    );
END$$
```

### `trg_clientes_delete`

```sql
CREATE TRIGGER trg_clientes_delete
AFTER DELETE ON clientes
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabela_afetada, operacao, id_registro, valor_antigo, usuario)
    VALUES (
        'clientes', 'DELETE', OLD.id_cliente,
        JSON_OBJECT('nome', OLD.nome, 'cpf', OLD.cpf, 'email', OLD.email,
                    'telefone', OLD.telefone, 'status', OLD.status),
        CURRENT_USER()
    );
END$$
```

### `trg_produtos_insert`

```sql
CREATE TRIGGER trg_produtos_insert
AFTER INSERT ON produtos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabela_afetada, operacao, id_registro, valor_novo, usuario)
    VALUES (
        'produtos', 'INSERT', NEW.id_produto,
        JSON_OBJECT(
            'nome', NEW.nome, 'descricao', NEW.descricao,
            'preco', NEW.preco, 'estoque', NEW.estoque, 'status', NEW.status
        ),
        CURRENT_USER()
    );
END$$
```

### `trg_produtos_update`

```sql
CREATE TRIGGER trg_produtos_update
AFTER UPDATE ON produtos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabela_afetada, operacao, id_registro, valor_antigo, valor_novo, usuario)
    VALUES (
        'produtos', 'UPDATE', NEW.id_produto,
        JSON_OBJECT('nome', OLD.nome, 'preco', OLD.preco,
                    'estoque', OLD.estoque, 'status', OLD.status),
        JSON_OBJECT('nome', NEW.nome, 'preco', NEW.preco,
                    'estoque', NEW.estoque, 'status', NEW.status),
        CURRENT_USER()
    );
END$$
```

### `trg_vendas_insert`

```sql
CREATE TRIGGER trg_vendas_insert
AFTER INSERT ON vendas
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabela_afetada, operacao, id_registro, valor_novo, usuario)
    VALUES (
        'vendas', 'INSERT', NEW.id_venda,
        JSON_OBJECT(
            'id_cliente', NEW.id_cliente, 'valor_total', NEW.valor_total,
            'status', NEW.status, 'data_venda', NEW.data_venda
        ),
        CURRENT_USER()
    );
END$$
```

---

## Views

| View | Descrição |
|------|-----------|
| `vw_clientes_ativos` | Lista clientes com `status = 'ativo'` |
| `vw_produtos_disponiveis` | Lista produtos ativos com estoque maior que zero |
| `vw_vendas_clientes` | Une vendas com o nome do cliente via JOIN |
| `vw_itens_venda_detalhada` | Detalha itens com nome do produto e subtotal calculado |
| `vw_auditoria_resumida` | Log de auditoria sem os campos JSON |

```sql
SELECT * FROM vw_clientes_ativos;
SELECT * FROM vw_produtos_disponiveis;
SELECT * FROM vw_vendas_clientes;
SELECT * FROM vw_itens_venda_detalhada;
SELECT * FROM vw_auditoria_resumida;
```

---

## Testes Realizados

### Tabela `clientes`

```sql
-- Inserir
INSERT INTO clientes (nome, cpf, email, telefone, status)
VALUES ('Danilo', '123.456.789-00', 'danilo@email.com', '99999-9999', 'ativo');

INSERT INTO clientes (nome, cpf, email, telefone, status)
VALUES ('Mariah', '123.456.789-00', 'mariah@email.com', '99999-9999', 'ativo');

-- Atualizar
UPDATE clientes SET nome = 'Danilo Henrique' WHERE id_cliente = 1;

-- Excluir
DELETE FROM clientes WHERE id_cliente = 1;

-- Verificar
SELECT * FROM clientes;
```

 Triggers acionadas: `trg_clientes_insert`, `trg_clientes_update`, `trg_clientes_delete`

### Tabela `produtos`

```sql
-- Inserir
INSERT INTO produtos (nome, descricao, preco, estoque, status)
VALUES ('Camiseta', 'Camiseta preta', 50.00, 18, 'ativo');

INSERT INTO produtos (nome, descricao, preco, estoque, status)
VALUES ('Short', 'Short preto', 40.00, 20, 'ativo');

-- Atualizar estoque e preço
UPDATE produtos SET estoque = 18, preco = 35.00 WHERE id_produto = 2;

-- Verificar
SELECT * FROM produtos;
```

 Triggers acionadas: `trg_produtos_insert`, `trg_produtos_update`

### Validação da Auditoria

```sql
SELECT * FROM auditoria ORDER BY data_operacao DESC;
```

---

## Exemplo de Uso Completo

Cenário: cliente **Mariah** (`id_cliente = 2`) realiza uma compra de 2 camisetas e 1 short.

>  **Importante:** respeite a ordem abaixo por conta das chaves estrangeiras. Sempre verifique o ID real gerado com `SELECT * FROM vendas` antes de inserir os itens.

### 1. Registrar a venda

```sql
INSERT INTO vendas (id_cliente, data_venda, valor_total, status)
VALUES (2, NOW(), 180.00, 'finalizada');
-- Trigger trg_vendas_insert é acionada automaticamente
```

### 2. Verificar o ID gerado

```sql
SELECT * FROM vendas;
-- Anote o id_venda antes de continuar
```

### 3. Registrar os itens

```sql
-- Use o id_venda real retornado acima
INSERT INTO itens_venda (id_venda, id_produto, quantidade, preco_unitario)
VALUES (1, 1, 2, 50.00); -- camiseta

INSERT INTO itens_venda (id_venda, id_produto, quantidade, preco_unitario)
VALUES (1, 2, 1, 35.00); -- short
```

### 4. Atualizar o estoque

```sql
UPDATE produtos SET estoque = estoque - 2 WHERE id_produto = 1; -- camiseta
UPDATE produtos SET estoque = estoque - 1 WHERE id_produto = 2; -- short
-- Trigger trg_produtos_update registra as alterações
```

### 5. Consultar os resultados

```sql
SELECT * FROM vw_vendas_clientes WHERE id_venda = 1;
SELECT * FROM itens_venda;
SELECT * FROM produtos;
SELECT * FROM auditoria ORDER BY data_operacao DESC;
```

---

## Como Executar

### Pré-requisitos

- MySQL instalado e configurado
- MySQL Workbench (opcional, mas recomendado)

### Passo 1 — Conectar ao MySQL

```bash
mysql -u root -p
```

### Passo 2 — Executar o Script

```sql
SOURCE bd_auditoria_mvp.sql;
```

Ou pelo caminho completo:

```sql
SOURCE C:/Users/Usuario/Downloads/bd_auditoria_mvp.sql;
```

> **Pelo MySQL Workbench:** Abra a conexão → Abra o arquivo `bd_auditoria_mvp.sql` → Clique em **Execute**.

Após a execução, o banco `bd_auditoria` será criado automaticamente com todas as tabelas, Triggers e Views.

### Consultas rápidas

```sql
SELECT * FROM clientes;
SELECT * FROM produtos;
SELECT * FROM vendas;
SELECT * FROM itens_venda;
SELECT * FROM auditoria ORDER BY data_operacao DESC;
```

---
