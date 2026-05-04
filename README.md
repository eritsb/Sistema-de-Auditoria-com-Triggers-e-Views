# Sistema-de-Auditoria-com-Triggers-e-Views

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
- [Exemplos de Uso](#exemplos-de-uso)
- [Testes Realizados](#testes-realizados)
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
- <img width="600" height="380" alt="Diagrama ER" src="https://github.com/user-attachments/assets/6c508f82-0543-4e75-a75b-4dca67bd310e" />
<img width="600" height="380" alt="Diagrama ER" src="https://github.com/user-attachments/assets/903d3c08-ba8a-4fba-abdc-dcce3f82c05c" />
<img width="600" height="380" alt="Diagrama ER" src="https://github.com/user-attachments/assets/e3f2eb12-6762-4794-b634-7a6882b65b6b" />
 Facilitar auditorias externas e relatórios de gestão

### Recursos Aplicados

| Recurso | Descrição |
|---------|-----------|
| **Triggers** | Procedimentos armazenados executados automaticamente em resposta a eventos (INSERT, UPDATE, DELETE), registrando valores anteriores e posteriores a cada operação |
| **Views** | Consultas SQL salvas tratadas como tabelas virtuais, simplificando o acesso aos dados e ocultando a complexidade das consultas |

---

## Diagrama ER

O banco de dados `bd_auditoria` é composto por **cinco tabelas principais**, conforme o diagrama abaixo:

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

Armazena as informações dos clientes cadastrados no sistema.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_cliente` | INT, PK, AUTO_INCREMENT | Identificador único |
| `nome` | VARCHAR(100) | Nome do cliente |
| `cpf` | VARCHAR(14) | CPF do cliente |
| `email` | VARCHAR(100) | E-mail |
| `telefone` | VARCHAR(20) | Contato |
| `data_cadastro` | DATETIME | Data do cadastro (automático) |
| `status` | VARCHAR(20) | Situação (`ativo` / `inativo`) |

### Tabela `produtos`

Armazena os produtos disponíveis para venda.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_produto` | INT, PK | Identificador |
| `nome` | VARCHAR(100) | Nome do produto |
| `descricao` | TEXT | Descrição |
| `preco` | DECIMAL(10,2) | Valor |
| `estoque` | INT | Quantidade disponível |
| `data_cadastro` | DATETIME | Data de cadastro |
| `status` | VARCHAR(20) | Situação |

### Tabela `vendas`

Registra as vendas realizadas no sistema.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_venda` | INT, PK | Identificador |
| `id_cliente` | INT, FK | Cliente da compra |
| `data_venda` | DATETIME | Data da venda |
| `valor_total` | DECIMAL | Valor total |
| `status` | VARCHAR(20) | `concluída` / `cancelada` |

### Tabela `itens_venda`

Detalha os produtos de cada venda.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_item` | INT, PK | Identificador |
| `id_venda` | INT, FK | Referência à venda |
| `id_produto` | INT, FK | Referência ao produto |
| `quantidade` | INT | Quantidade vendida |
| `preco_unitario` | DECIMAL | Preço no momento da venda |

### Tabela `auditoria`

Registra automaticamente todas as alterações feitas no sistema via Triggers.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_auditoria` | INT, PK | Identificador |
| `tabela_afetada` | VARCHAR(50) | Nome da tabela modificada |
| `operacao` | VARCHAR | `INSERT`, `UPDATE` ou `DELETE` |
| `id_registro` | INT | ID do registro afetado |
| `valor_antigo` | JSON | Dados antes da operação |
| `valor_novo` | JSON | Dados após a operação |
| `usuario` | VARCHAR(100) | Usuário responsável |
| `data_operacao` | TIMESTAMP | Data e hora da operação |

---

## Triggers de Auditoria

As Triggers são executadas **automaticamente** após operações nas tabelas, sem necessidade de intervenção manual.

### `trg_clientes_insert`

Disparada após um `INSERT` em `clientes`. Registra os dados novos no campo `valor_novo`.

```sql
-- Exemplo de operação
INSERT INTO clientes (nome, cpf, email, telefone, status)
VALUES ('Mariah', '123.456.789-00', 'mariah@email.com', '99999-9999', 'ativo');
```

**Auditoria registra:** operação `INSERT` com todos os dados em `valor_novo`.

---

### `trg_clientes_update`

Disparada após `UPDATE` em `clientes`. Salva os valores **antes** (`OLD`) e **depois** (`NEW`).

```sql
-- Exemplo de operação
UPDATE clientes
SET nome = 'Maria Silva'
WHERE id_cliente = 1;
```

**Auditoria registra:**
- `valor_antigo`: `{"nome": "Maria"}`
- `valor_novo`: `{"nome": "Maria Silva"}`

---

### `trg_clientes_delete`

Disparada após `DELETE` em `clientes`. Salva apenas os dados anteriores à exclusão.

```sql
-- Exemplo de operação
DELETE FROM clientes WHERE id_cliente = 1;
```

**Auditoria registra:** todos os dados do cliente excluído em `valor_antigo`.

---

### `trg_produtos_update`

Disparada após `UPDATE` em `produtos`. Guarda os valores de antes e depois da alteração (incluindo preço, estoque e status).

---

### `trg_vendas_insert`

Disparada após `INSERT` em `vendas`. Registra os dados da nova venda criada.

---

### Resumo das Triggers

| Trigger | Tabela | Evento | O que registra |
|---------|--------|--------|----------------|
| `trg_clientes_insert` | `clientes` | INSERT | Novos dados do cliente |
| `trg_clientes_update` | `clientes` | UPDATE | Antes e depois da alteração |
| `trg_clientes_delete` | `clientes` | DELETE | Dados antes da exclusão |
| `trg_produtos_update` | `produtos` | UPDATE | Antes e depois da alteração |
| `trg_vendas_insert` | `vendas` | INSERT | Dados da nova venda |

---

## Views

As Views foram criadas para facilitar consultas, organizando os dados de forma mais simples e reutilizável.

### `vw_clientes_ativos`

Exibe apenas os clientes com status `ativo`.

```sql
CREATE VIEW vw_clientes_ativos AS
SELECT id_cliente, nome, cpf, email, telefone, data_cadastro
FROM clientes
WHERE status = 'ativo';
```

**Exemplo de resultado:**

| id_cliente | nome | email |
|------------|------|-------|
| 1 | Mariah | mariah@email.com |

---

### `vw_produtos_disponiveis`

Mostra apenas produtos ativos e com estoque maior que zero.

```sql
CREATE VIEW vw_produtos_disponiveis AS
SELECT id_produto, nome, descricao, preco, estoque
FROM produtos
WHERE status = 'ativo' AND estoque > 0;
```

**Exemplo de resultado:**

| id_produto | nome | estoque |
|------------|------|---------|
| 1 | Camiseta | 18 |
| 2 | Calça | 14 |

---

### `vw_vendas_clientes`

Exibe as vendas junto com o nome do cliente.

```sql
CREATE VIEW vw_vendas_clientes AS
SELECT v.id_venda, c.nome AS nome_cliente, v.data_venda, v.valor_total, v.status
FROM vendas v
INNER JOIN clientes c ON v.id_cliente = c.id_cliente;
```

**Exemplo de resultado:**

| id_venda | nome_cliente | valor_total | status |
|----------|-------------|-------------|--------|
| 10 | Mariah | 180.00 | finalizada |

---

### `vw_itens_venda_detalhada`

Detalha os produtos vendidos em cada venda, incluindo subtotal calculado.

```sql
CREATE VIEW vw_itens_venda_detalhada AS
SELECT iv.id_item, iv.id_venda, p.nome AS produto,
       iv.quantidade, iv.preco_unitario,
       (iv.quantidade * iv.preco_unitario) AS subtotal
FROM itens_venda iv
INNER JOIN produtos p ON iv.id_produto = p.id_produto;
```

**Exemplo de resultado:**

| id_venda | produto | quantidade | subtotal |
|----------|---------|------------|----------|
| 10 | Camiseta | 2 | 100.00 |
| 10 | Calça | 1 | 80.00 |

---

### `vw_auditoria_resumida`

Apresenta um resumo das operações registradas na auditoria, sem os campos JSON.

```sql
CREATE VIEW vw_auditoria_resumida AS
SELECT id_auditoria, tabela_afetada, operacao,
       id_registro, usuario, data_operacao
FROM auditoria;
```

**Exemplo de resultado:**

| id_auditoria | tabela_afetada | operacao | data_operacao |
|--------------|---------------|----------|---------------|
| 1 | vendas | INSERT | 2026-01-01 10:00:00 |
| 2 | produtos | UPDATE | 2026-01-01 10:05:00 |

---

## Exemplos de Uso

### Cenário: Compra em uma loja

A cliente **Mariah** realiza uma compra contendo 2 camisetas e 1 calça.

**1. Registrar a venda:**

```sql
INSERT INTO vendas (id_cliente, data_venda, valor_total, status)
VALUES (1, NOW(), 180.00, 'finalizada');
-- Trigger trg_vendas_insert é acionada automaticamente
```

**2. Registrar os itens da venda:**

```sql
INSERT INTO itens_venda (id_venda, id_produto, quantidade, preco_unitario)
VALUES (10, 1, 2, 50.00); -- camiseta

INSERT INTO itens_venda (id_venda, id_produto, quantidade, preco_unitario)
VALUES (10, 2, 1, 80.00); -- calça
```

**3. Atualizar o estoque:**

```sql
UPDATE produtos SET estoque = estoque - 2 WHERE id_produto = 1; -- camiseta
UPDATE produtos SET estoque = estoque - 1 WHERE id_produto = 2; -- calça
-- Trigger trg_produtos_update registra as alterações
```

**4. Consultar a venda:**

```sql
SELECT * FROM vw_vendas_clientes WHERE id_venda = 10;
```

**5. Consultar o histórico de auditoria:**

```sql
SELECT * FROM auditoria ORDER BY data_operacao DESC;
```

---

## Testes Realizados

Foram realizados testes práticos para validar o funcionamento das Triggers e garantir o registro correto das operações.

### Teste 1 — Cadastro de Cliente (INSERT)

```sql
INSERT INTO clientes (nome, cpf, email, telefone, status)
VALUES ('Danilo', '123.456.789-00', 'danilo@email.com', '99999-9999', 'ativo');
```

 `trg_clientes_insert` acionada — dados registrados em `valor_novo` na tabela `auditoria`.

---

### Teste 2 — Atualização de Cliente (UPDATE)

```sql
UPDATE clientes
SET nome = 'Danilo Henrique'
WHERE id_cliente = 1;
```

 `trg_clientes_update` registrou corretamente:
- `valor_antigo`: `{"nome": "Danilo"}`
- `valor_novo`: `{"nome": "Danilo Henrique"}`

---

### Teste 3 — Exclusão de Cliente (DELETE)

```sql
DELETE FROM clientes WHERE id_cliente = 1;
```

 `trg_clientes_delete` armazenou os dados antigos antes da remoção.

---

### Teste 4 — Cadastro de Produto (INSERT)

```sql
INSERT INTO produtos (nome, descricao, preco, estoque, status)
VALUES ('Camiseta', 'Camiseta preta', 50.00, 20, 'ativo');
```

 Produto inserido corretamente e disponível para vendas.

---

### Teste 5 — Atualização de Estoque (UPDATE)

```sql
UPDATE produtos SET estoque = 18 WHERE id_produto = 1;
```

 `trg_produtos_update` registrou os valores antigos e novos do estoque.

---

### Validação Final

```sql
SELECT * FROM auditoria ORDER BY data_operacao DESC;
```

Todas as operações foram registradas corretamente, validando o funcionamento do sistema de auditoria.

---

## Como Executar

### Pré-requisitos

- MySQL instalado e configurado
- MySQL Workbench (opcional, mas recomendado)

### Passo 1 — Conectar ao MySQL

```bash
mysql -u root -p
```

Informe a senha do usuário MySQL quando solicitado.

### Passo 2 — Executar o Script SQL

```sql
SOURCE bd_auditoria.sql;
```

Caso o arquivo esteja em outra pasta:

```sql
SOURCE C:/Users/Usuario/Downloads/bd_auditoria.sql;
```

> **Pelo MySQL Workbench:** Abra a conexão local → Abra o arquivo `bd_auditoria.sql` → Clique em **Execute**.

Após a execução, o banco `bd_auditoria` será criado automaticamente com todas as tabelas, Triggers e Views.

### Passo 3 — Testar o Sistema

```sql
-- Inserir um cliente
INSERT INTO clientes (nome, cpf, email, telefone, status)
VALUES ('Danilo', '123.456.789-00', 'danilo@email.com', '99999-9999', 'ativo');

-- Atualizar dados
UPDATE clientes SET nome = 'Danilo Henrique' WHERE id_cliente = 1;

-- Excluir registro
DELETE FROM clientes WHERE id_cliente = 1;

-- Consultar auditoria
SELECT * FROM auditoria ORDER BY data_operacao DESC;

-- Consultar views
SELECT * FROM vw_vendas_clientes;
SELECT * FROM vw_clientes_ativos;
SELECT * FROM vw_produtos_disponiveis;
```

---
