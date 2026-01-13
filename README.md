# 🛒 Loja Virtual API

## Documentação Completa da API REST

Esta é uma API REST para gerenciamento de e-commerce com processamento assíncrono de pedidos.
O backend processa pedidos, gerencia estoque e cadeia de suprimentos usando mensageria Kafka.

> **📌 Nota para Desenvolvedores Frontend**: Esta documentação foi criada para desenvolvedores que **não conhecem Elixir**. Você só precisa saber fazer requisições HTTP (fetch, axios, etc.) para usar esta API.

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Como Usar](#como-usar)
3. [Modelos de Dados](#modelos-de-dados)
4. [Endpoints da API](#endpoints-da-api)
5. [Exemplos de Código](#exemplos-de-código)
6. [Fluxo de Processamento](#fluxo-de-processamento)
7. [Códigos de Erro](#códigos-de-erro)

---

## 🎯 Visão Geral

### O que esta API faz?

| Funcionalidade | Descrição |
|----------------|-----------|
| **Pedidos** | Criar, listar e consultar pedidos de clientes |
| **Inventário** | Consultar produtos e ingredientes disponíveis |
| **Cadeia de Suprimentos** | Gerenciar remessas de fornecedores |
| **Health Check** | Verificar status da API e serviços |

### Tecnologias (para curiosos)

- **Backend**: Elixir/Phoenix (você não precisa saber isso para usar a API)
- **Banco de Dados**: PostgreSQL
- **Mensageria**: Apache Kafka (processamento assíncrono)
- **Formato**: Todas as respostas são **JSON**

---

## 🚀 Como Usar

### URL Base

```
http://localhost:4000
```

### Headers Obrigatórios

```http
Content-Type: application/json
```

### Formato das Respostas

Todas as respostas seguem este formato:

```json
{
  "success": true,
  "data": { ... }
}
```

Ou em caso de erro:

```json
{
  "success": false,
  "error": "Mensagem de erro",
  "errors": { "campo": ["erro específico"] }
}
```

---

## 📦 Modelos de Dados

### 1. Order (Pedido)

Um pedido representa uma compra feita por um cliente.

| Campo | Tipo | Descrição | Obrigatório |
|-------|------|-----------|-------------|
| `id` | UUID | Identificador único (gerado automaticamente) | - |
| `type` | string | Tipo do pedido: `"pronto"` ou `"personalizado"` | ✅ |
| `status` | string | Status atual do pedido | - |
| `total` | number | Valor total do pedido | Calculado |
| `customer_name` | string | Nome do cliente | ✅ |
| `customer_email` | string | Email do cliente | ✅ |
| `delivery_address` | string | Endereço de entrega | ✅ |
| `items` | array | Lista de itens do pedido | ✅ |
| `paid_at` | datetime | Data/hora do pagamento | - |
| `shipped_at` | datetime | Data/hora do envio | - |
| `delivered_at` | datetime | Data/hora da entrega | - |
| `created_at` | datetime | Data/hora da criação | - |

#### Tipos de Pedido

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| `pronto` | Produtos prontos no estoque | Camiseta, livro, eletrônico |
| `personalizado` | Produtos customizados sob demanda | Pizza com ingredientes, móvel sob medida |

#### Status do Pedido (Ciclo de Vida)

```
new → paid → processing → shipped → delivered
                ↓
           cancelled
```

| Status | Descrição |
|--------|-----------|
| `new` | Pedido criado, aguardando pagamento |
| `paid` | Pagamento confirmado |
| `processing` | Em separação/produção |
| `shipped` | Enviado para entrega |
| `delivered` | Entregue ao cliente |
| `cancelled` | Cancelado |

---

### 2. Order Item (Item do Pedido)

Cada item dentro de um pedido.

| Campo | Tipo | Descrição | Obrigatório |
|-------|------|-----------|-------------|
| `id` | UUID | Identificador único | - |
| `product_id` | UUID | ID do produto (para pedidos `pronto`) | Condicional |
| `ingredient_id` | UUID | ID do ingrediente (para pedidos `personalizado`) | Condicional |
| `quantity` | integer | Quantidade | ✅ |
| `unit_price` | number | Preço unitário | ✅ |
| `subtotal` | number | Subtotal (quantity × unit_price) | Calculado |

---

### 3. Product (Produto)

Produtos prontos disponíveis no estoque.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID | Identificador único |
| `name` | string | Nome do produto |
| `description` | string | Descrição |
| `price` | number | Preço de venda |
| `stock_quantity` | integer | Quantidade em estoque |
| `min_stock_level` | integer | Nível mínimo de estoque (alerta) |
| `sku` | string | Código SKU (único) |
| `active` | boolean | Se o produto está ativo |

---

### 4. Ingredient (Ingrediente)

Ingredientes/matérias-primas para produtos personalizados.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID | Identificador único |
| `name` | string | Nome do ingrediente |
| `description` | string | Descrição |
| `unit` | string | Unidade de medida: `kg`, `g`, `l`, `ml`, `un` |
| `stock_quantity` | number | Quantidade em estoque |
| `min_stock_level` | number | Nível mínimo de estoque |
| `cost_per_unit` | number | Custo por unidade |
| `supplier_code` | string | Código do fornecedor |
| `active` | boolean | Se está ativo |

---

### 5. Supply Shipment (Remessa de Suprimentos)

Remessas enviadas por fornecedores.

| Campo | Tipo | Descrição | Obrigatório |
|-------|------|-----------|-------------|
| `id` | UUID | Identificador único | - |
| `status` | string | `pending`, `approved`, `rejected` | - |
| `supplier_name` | string | Nome do fornecedor | ✅ |
| `supplier_email` | string | Email do fornecedor | ✅ |
| `notes` | string | Observações | - |
| `items` | array | Lista de itens da remessa | ✅ |
| `approved_by` | string | Quem aprovou | - |
| `approved_at` | datetime | Data/hora da aprovação | - |
| `rejection_reason` | string | Motivo da rejeição | - |
| `created_at` | datetime | Data/hora da criação | - |

#### Status da Remessa

```
pending → approved (estoque atualizado)
    ↓
 rejected
```

---

## 🔌 Endpoints da API

### Health Check

#### `GET /health`

Verifica se a API e seus serviços estão funcionando.

**Resposta de Sucesso (200):**
```json
{
  "status": "healthy",
  "timestamp": "2026-01-13T15:30:00Z",
  "checks": {
    "database": "healthy",
    "pipelines": "healthy",
    "kafka_producer": "healthy"
  }
}
```

**Resposta de Erro (503):**
```json
{
  "status": "unhealthy",
  "timestamp": "2026-01-13T15:30:00Z",
  "checks": {
    "database": "healthy",
    "pipelines": "unhealthy",
    "kafka_producer": "unhealthy"
  }
}
```

---

### Pedidos (Orders)

#### `POST /api/orders`

Cria um novo pedido. O pedido é enviado automaticamente para processamento de pagamento.

**Request Body:**
```json
{
  "type": "pronto",
  "customer_name": "João Silva",
  "customer_email": "joao@email.com",
  "delivery_address": "Rua das Flores, 123 - São Paulo/SP",
  "items": [
    {
      "product_id": "550e8400-e29b-41d4-a716-446655440000",
      "quantity": 2,
      "unit_price": 49.90
    },
    {
      "product_id": "550e8400-e29b-41d4-a716-446655440001",
      "quantity": 1,
      "unit_price": 29.90
    }
  ]
}
```

**Para pedidos personalizados:**
```json
{
  "type": "personalizado",
  "customer_name": "Maria Santos",
  "customer_email": "maria@email.com",
  "delivery_address": "Av. Brasil, 456 - Rio de Janeiro/RJ",
  "items": [
    {
      "ingredient_id": "660e8400-e29b-41d4-a716-446655440000",
      "quantity": 500,
      "unit_price": 0.05
    }
  ]
}
```

**Resposta de Sucesso (201):**
```json
{
  "success": true,
  "order": {
    "id": "770e8400-e29b-41d4-a716-446655440000",
    "status": "new",
    "type": "pronto",
    "total": 129.70,
    "message": "Order created and sent to payment processing"
  }
}
```

**Resposta de Erro (422):**
```json
{
  "success": false,
  "errors": {
    "customer_email": ["has invalid format"],
    "type": ["can't be blank"]
  }
}
```

---

#### `GET /api/orders`

Lista todos os pedidos.

**Query Parameters:**
| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `limit` | integer | 50 | Máximo de resultados |

**Exemplo:** `GET /api/orders?limit=10`

**Resposta (200):**
```json
{
  "success": true,
  "orders": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440000",
      "status": "delivered",
      "type": "pronto",
      "total": 129.70,
      "customer_email": "joao@email.com",
      "created_at": "2026-01-13T10:30:00Z"
    },
    {
      "id": "770e8400-e29b-41d4-a716-446655440001",
      "status": "paid",
      "type": "personalizado",
      "total": 89.90,
      "customer_email": "maria@email.com",
      "created_at": "2026-01-13T11:00:00Z"
    }
  ]
}
```

---

#### `GET /api/orders/:id`

Busca um pedido específico pelo ID.

**Exemplo:** `GET /api/orders/770e8400-e29b-41d4-a716-446655440000`

**Resposta de Sucesso (200):**
```json
{
  "success": true,
  "order": {
    "id": "770e8400-e29b-41d4-a716-446655440000",
    "status": "delivered",
    "type": "pronto",
    "total": 129.70,
    "customer_name": "João Silva",
    "customer_email": "joao@email.com",
    "delivery_address": "Rua das Flores, 123 - São Paulo/SP",
    "paid_at": "2026-01-13T10:31:00Z",
    "shipped_at": "2026-01-13T10:32:00Z",
    "delivered_at": "2026-01-13T10:35:00Z",
    "created_at": "2026-01-13T10:30:00Z"
  }
}
```

**Resposta de Erro (404):**
```json
{
  "success": false,
  "error": "Order not found"
}
```

---

### Inventário (Inventory)

#### `GET /api/inventory/products`

Lista todos os produtos ativos.

**Resposta (200):**
```json
{
  "success": true,
  "products": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Camiseta Preta M",
      "description": "Camiseta 100% algodão",
      "price": 49.90,
      "stock_quantity": 150,
      "sku": "CAM-PRT-M"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Calça Jeans 42",
      "description": "Calça jeans slim fit",
      "price": 129.90,
      "stock_quantity": 45,
      "sku": "CAL-JNS-42"
    }
  ]
}
```

---

#### `GET /api/inventory/ingredients`

Lista todos os ingredientes ativos.

**Resposta (200):**
```json
{
  "success": true,
  "ingredients": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440000",
      "name": "Farinha de Trigo",
      "unit": "kg",
      "stock_quantity": 250.5,
      "cost_per_unit": 3.50
    },
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "name": "Tomate",
      "unit": "kg",
      "stock_quantity": 45.0,
      "cost_per_unit": 8.90
    }
  ]
}
```

---

#### `GET /api/inventory/low-stock`

Lista itens com estoque abaixo do nível mínimo.

**Resposta (200):**
```json
{
  "success": true,
  "low_stock": {
    "products": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "name": "Moletom Cinza GG",
        "current": 3,
        "minimum": 5
      }
    ],
    "ingredients": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440002",
        "name": "Queijo Mussarela",
        "current": 5.2,
        "minimum": 10.0,
        "unit": "kg"
      }
    ]
  }
}
```

---

### Cadeia de Suprimentos (Supply Chain)

#### `POST /api/supply/shipments`

Cria uma nova remessa de suprimentos (ação do fornecedor).

**Request Body:**
```json
{
  "supplier_name": "Fornecedor ABC Ltda",
  "supplier_email": "vendas@fornecedorabc.com",
  "notes": "Entrega programada para dia 15/01",
  "items": [
    {
      "ingredient_id": "660e8400-e29b-41d4-a716-446655440000",
      "quantity": 100
    },
    {
      "ingredient_id": "660e8400-e29b-41d4-a716-446655440001",
      "quantity": 50
    }
  ]
}
```

**Resposta de Sucesso (201):**
```json
{
  "success": true,
  "shipment": {
    "id": "880e8400-e29b-41d4-a716-446655440000",
    "status": "pending",
    "supplier_name": "Fornecedor ABC Ltda",
    "items_count": 2,
    "message": "Shipment created and sent to admin for approval"
  }
}
```

---

#### `GET /api/supply/shipments`

Lista todas as remessas.

**Query Parameters:**
| Parâmetro | Tipo | Valores | Descrição |
|-----------|------|---------|-----------|
| `status` | string | `pending`, `approved`, `rejected` | Filtrar por status |

**Exemplo:** `GET /api/supply/shipments?status=pending`

**Resposta (200):**
```json
{
  "success": true,
  "shipments": [
    {
      "id": "880e8400-e29b-41d4-a716-446655440000",
      "status": "pending",
      "supplier_name": "Fornecedor ABC Ltda",
      "supplier_email": "vendas@fornecedorabc.com",
      "items_count": 2,
      "created_at": "2026-01-13T09:00:00Z",
      "approved_at": null
    },
    {
      "id": "880e8400-e29b-41d4-a716-446655440001",
      "status": "approved",
      "supplier_name": "Distribuidora XYZ",
      "supplier_email": "contato@xyz.com",
      "items_count": 5,
      "created_at": "2026-01-12T14:00:00Z",
      "approved_at": "2026-01-12T15:30:00Z"
    }
  ]
}
```

---

#### `POST /api/supply/shipments/:id/approve`

Aprova uma remessa pendente (ação do administrador).
**Ao aprovar, o estoque dos ingredientes é atualizado automaticamente.**

**Request Body (opcional):**
```json
{
  "approved_by": "admin@loja.com"
}
```

**Resposta de Sucesso (200):**
```json
{
  "success": true,
  "message": "Shipment approved. Stock has been updated.",
  "shipment": {
    "id": "880e8400-e29b-41d4-a716-446655440000",
    "status": "approved",
    "approved_by": "admin@loja.com",
    "approved_at": "2026-01-13T10:00:00Z"
  }
}
```

**Erros Possíveis:**

| Código | Erro | Descrição |
|--------|------|-----------|
| 404 | Shipment not found | ID não encontrado |
| 422 | Cannot approve shipment with status: approved | Já foi aprovado |

---

#### `POST /api/supply/shipments/:id/reject`

Rejeita uma remessa pendente (ação do administrador).

**Request Body:**
```json
{
  "reason": "Produtos danificados na inspeção"
}
```

**Resposta de Sucesso (200):**
```json
{
  "success": true,
  "message": "Shipment rejected.",
  "shipment": {
    "id": "880e8400-e29b-41d4-a716-446655440000",
    "status": "rejected",
    "rejection_reason": "Produtos danificados na inspeção"
  }
}
```

---

## 💻 Exemplos de Código

### JavaScript (Fetch API)

```javascript
// Configuração base
const API_URL = 'http://localhost:4000';

// Função auxiliar para requisições
async function apiRequest(endpoint, options = {}) {
  const response = await fetch(`${API_URL}${endpoint}`, {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers
    },
    ...options
  });
  return response.json();
}

// Listar produtos
async function getProducts() {
  const data = await apiRequest('/api/inventory/products');
  if (data.success) {
    console.log('Produtos:', data.products);
    return data.products;
  }
}

// Criar um pedido
async function createOrder(orderData) {
  const data = await apiRequest('/api/orders', {
    method: 'POST',
    body: JSON.stringify(orderData)
  });
  
  if (data.success) {
    console.log('Pedido criado:', data.order);
    return data.order;
  } else {
    console.error('Erros:', data.errors);
    throw new Error(JSON.stringify(data.errors));
  }
}

// Consultar status de um pedido
async function getOrderStatus(orderId) {
  const data = await apiRequest(`/api/orders/${orderId}`);
  if (data.success) {
    return data.order.status;
  }
  return null;
}

// Exemplo de uso
async function main() {
  // 1. Listar produtos disponíveis
  const products = await getProducts();
  
  // 2. Criar um pedido
  const order = await createOrder({
    type: 'pronto',
    customer_name: 'Maria Silva',
    customer_email: 'maria@email.com',
    delivery_address: 'Rua ABC, 123',
    items: [
      { product_id: products[0].id, quantity: 2, unit_price: products[0].price }
    ]
  });
  
  // 3. Verificar status
  const status = await getOrderStatus(order.id);
  console.log(`Status do pedido: ${status}`);
}

main();
```

### JavaScript (Axios)

```javascript
import axios from 'axios';

// Configuração do cliente
const api = axios.create({
  baseURL: 'http://localhost:4000/api',
  headers: {
    'Content-Type': 'application/json'
  }
});

// Interceptor para tratamento de erros
api.interceptors.response.use(
  response => response.data,
  error => {
    console.error('API Error:', error.response?.data);
    return Promise.reject(error.response?.data);
  }
);

// Funções da API
export const ordersApi = {
  create: (data) => api.post('/orders', data),
  getById: (id) => api.get(`/orders/${id}`),
  list: (limit = 50) => api.get(`/orders?limit=${limit}`)
};

export const inventoryApi = {
  getProducts: () => api.get('/inventory/products'),
  getIngredients: () => api.get('/inventory/ingredients'),
  getLowStock: () => api.get('/inventory/low-stock')
};

export const supplyApi = {
  createShipment: (data) => api.post('/supply/shipments', data),
  listShipments: (status) => api.get(`/supply/shipments${status ? `?status=${status}` : ''}`),
  approve: (id, approvedBy) => api.post(`/supply/shipments/${id}/approve`, { approved_by: approvedBy }),
  reject: (id, reason) => api.post(`/supply/shipments/${id}/reject`, { reason })
};

// Exemplo de uso
async function example() {
  // Listar produtos
  const { products } = await inventoryApi.getProducts();
  
  // Criar pedido
  const { order } = await ordersApi.create({
    type: 'pronto',
    customer_name: 'João',
    customer_email: 'joao@email.com',
    delivery_address: 'Rua XYZ, 456',
    items: [{ product_id: products[0].id, quantity: 1, unit_price: products[0].price }]
  });
  
  console.log('Pedido criado:', order.id);
}
```

### React Hook Exemplo

```javascript
import { useState, useEffect } from 'react';

const API_URL = 'http://localhost:4000/api';

// Hook customizado para produtos
export function useProducts() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetch(`${API_URL}/inventory/products`)
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          setProducts(data.products);
        } else {
          setError('Erro ao carregar produtos');
        }
      })
      .catch(err => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  return { products, loading, error };
}

// Hook customizado para pedidos
export function useOrder(orderId) {
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!orderId) return;
    
    fetch(`${API_URL}/orders/${orderId}`)
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          setOrder(data.order);
        }
      })
      .finally(() => setLoading(false));
  }, [orderId]);

  return { order, loading };
}

// Componente exemplo
function ProductList() {
  const { products, loading, error } = useProducts();

  if (loading) return <div>Carregando...</div>;
  if (error) return <div>Erro: {error}</div>;

  return (
    <ul>
      {products.map(product => (
        <li key={product.id}>
          {product.name} - R$ {product.price.toFixed(2)}
        </li>
      ))}
    </ul>
  );
}
```

---

## 🔄 Fluxo de Processamento

### Fluxo de um Pedido (Visão Simplificada)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        FLUXO DO PEDIDO                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   [Frontend]                                                             │
│       │                                                                  │
│       ▼ POST /api/orders                                                 │
│   ┌─────────┐                                                            │
│   │  API    │ ──► Salva no banco com status "new"                       │
│   └────┬────┘                                                            │
│        │                                                                 │
│        ▼ (automático, via Kafka)                                         │
│   ┌──────────────┐                                                       │
│   │  Pagamento   │ ──► Processa pagamento (simulado)                    │
│   │   Worker     │ ──► Atualiza status para "paid"                      │
│   └──────┬───────┘                                                       │
│          │                                                               │
│          ▼ (automático)                                                  │
│   ┌──────────────┐                                                       │
│   │   Router     │ ──► Verifica o tipo do pedido                        │
│   │   Worker     │ ──► Direciona para verificação de estoque            │
│   └──────┬───────┘                                                       │
│          │                                                               │
│          ├──► [pronto] ──► Verifica estoque de produtos                 │
│          │                                                               │
│          └──► [personalizado] ──► Verifica estoque de ingredientes      │
│                                                                          │
│          ▼ (automático)                                                  │
│   ┌──────────────┐                                                       │
│   │   Entrega    │ ──► Atualiza status para "shipped"                   │
│   │   Worker     │ ──► Simula entrega                                   │
│   └──────┬───────┘     ──► Atualiza status para "delivered"             │
│          │                                                               │
│          ▼                                                               │
│   ┌──────────────┐                                                       │
│   │   ENTREGUE   │                                                       │
│   └──────────────┘                                                       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Para o Frontend (o que você precisa saber):

1. **Criar pedido** → Recebe ID imediatamente
2. **Consultar status** → O status muda automaticamente conforme o processamento
3. **Não precisa monitorar** → Os workers processam em background

### Polling de Status (Opcional)

Se quiser mostrar o status em tempo real:

```javascript
// Polling simples a cada 5 segundos
function pollOrderStatus(orderId, callback) {
  const interval = setInterval(async () => {
    const response = await fetch(`/api/orders/${orderId}`);
    const data = await response.json();
    
    if (data.success) {
      callback(data.order.status);
      
      // Para de fazer polling quando entregue ou cancelado
      if (['delivered', 'cancelled'].includes(data.order.status)) {
        clearInterval(interval);
      }
    }
  }, 5000);
  
  return () => clearInterval(interval); // Função para cancelar
}

// Uso
const cancel = pollOrderStatus('order-id', (status) => {
  console.log('Status atualizado:', status);
  updateUI(status);
});

// Para cancelar o polling
// cancel();
```

---

## ❌ Códigos de Erro

### HTTP Status Codes

| Código | Significado | Quando Acontece |
|--------|-------------|-----------------|
| `200` | OK | Requisição bem sucedida |
| `201` | Created | Recurso criado com sucesso |
| `400` | Bad Request | Dados inválidos ou mal formatados |
| `404` | Not Found | Recurso não encontrado |
| `422` | Unprocessable Entity | Validação falhou |
| `500` | Internal Server Error | Erro interno do servidor |
| `503` | Service Unavailable | Serviço indisponível (health check) |

### Tratamento de Erros no Frontend

```javascript
async function handleApiCall(endpoint, options) {
  try {
    const response = await fetch(endpoint, options);
    const data = await response.json();
    
    if (!response.ok) {
      // Trata diferentes tipos de erro
      switch (response.status) {
        case 404:
          throw new Error('Recurso não encontrado');
        case 422:
          // Erros de validação
          const errorMessages = Object.entries(data.errors || {})
            .map(([field, messages]) => `${field}: ${messages.join(', ')}`)
            .join('\n');
          throw new Error(errorMessages || 'Erro de validação');
        case 500:
          throw new Error('Erro interno do servidor');
        default:
          throw new Error(data.error || 'Erro desconhecido');
      }
    }
    
    return data;
  } catch (error) {
    console.error('API Error:', error);
    throw error;
  }
}
```

---

## 🔧 Configuração CORS

A API aceita requisições dos seguintes origins:

| Origin | Uso Comum |
|--------|-----------|
| `http://localhost:3000` | Create React App, Next.js dev |
| `http://localhost:5173` | Vite dev server |
| `http://127.0.0.1:3000` | Alternativo |

Se precisar de outro origin, entre em contato com a equipe de backend.

---

## 📞 Suporte

Se encontrar problemas ou tiver dúvidas:

1. Verifique o health check: `GET /health`
2. Consulte esta documentação
3. Teste os endpoints usando Postman (collection em `postman_collection.json`)

---

**Última atualização:** Janeiro 2026
