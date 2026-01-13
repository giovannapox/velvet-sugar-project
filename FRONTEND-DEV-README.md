# 🚀 Guia Rápido para Desenvolvedores Frontend

Olá! Este guia vai te ajudar a rodar a API da Loja Virtual no seu computador.

## ✅ Pré-requisitos

1. **Docker Desktop** - [Download aqui](https://www.docker.com/products/docker-desktop)
   - Baixe, instale e abra o Docker Desktop
   - Aguarde ele iniciar completamente (ícone fica verde)

## 🏃 Como Rodar a API

### Opção 1: Duplo-clique (mais fácil)
1. Dê **duplo-clique** no arquivo `INICIAR-API.bat`
2. Aguarde aparecer as mensagens de inicialização
3. Quando ver "API rodando", está pronto!

### Opção 2: Terminal
```bash
docker-compose up
```

## 🌐 URLs Importantes

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **API** | http://localhost:4000 | Sua API principal |
| **Health Check** | http://localhost:4000/health | Verifica se está rodando |
| **Kafka UI** | http://localhost:8080 | Interface para ver mensagens Kafka |

## 🧪 Testando se Funciona

Abra o navegador e acesse:
```
http://localhost:4000/health
```

Deve aparecer algo como:
```json
{
  "status": "healthy",
  "checks": {
    "database": "healthy",
    "pipelines": "healthy"
  }
}
```

## 📡 Endpoints da API

### Produtos
```
GET  http://localhost:4000/api/inventory/products
```

### Pedidos
```
GET  http://localhost:4000/api/orders
POST http://localhost:4000/api/orders
```

### Exemplo de Requisição (JavaScript)
```javascript
// Listar produtos
fetch('http://localhost:4000/api/inventory/products')
  .then(res => res.json())
  .then(data => console.log(data));

// Criar pedido
fetch('http://localhost:4000/api/orders', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    type: 'pronto',
    customer_name: 'Teste',
    customer_email: 'teste@email.com',
    delivery_address: 'Rua Teste, 123',
    items: []
  })
})
.then(res => res.json())
.then(data => console.log(data));
```

## 🛑 Como Parar a API

### Opção 1: Duplo-clique
Dê **duplo-clique** no arquivo `PARAR-API.bat`

### Opção 2: Terminal
```bash
docker-compose down
```

### Opção 3: No terminal que está rodando
Pressione `Ctrl + C`

## ❓ Problemas Comuns

### "Docker não está rodando"
- Abra o Docker Desktop e espere ele iniciar (ícone verde na bandeja)

### "Porta já está em uso"
- Outra aplicação está usando a porta 4000
- Feche essa aplicação ou mude a porta no docker-compose.yml

### "Demora muito para iniciar"
- Na primeira vez, o Docker precisa baixar as imagens (pode levar 5-10 min)
- Nas próximas vezes será muito mais rápido

## 📖 Documentação Completa

Para ver todos os endpoints e modelos de dados, leia o arquivo `README.md`

---

**Bom desenvolvimento! 🎉**
