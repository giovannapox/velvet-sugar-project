# 🚀 GUIA RÁPIDO - Setup com WSL

## Passo 1: Abrir Terminal WSL

Abra o PowerShell e digite:
```powershell
wsl
```

## Passo 2: Copiar Projeto para WSL

```bash
# Copiar projeto do Windows para home do WSL
cp -r /mnt/c/Users/jpedr/OneDrive/Documentos/ESTUDOS/elixir/elixir_estudando/loja_virtual ~/
cd ~/loja_virtual
```

## Passo 3: Instalar Elixir/Erlang (primeira vez apenas)

```bash
# Tornar script executável
chmod +x wsl-install-elixir.sh

# Executar instalação
./wsl-install-elixir.sh
```

**Isso vai instalar:**
- ✅ Erlang
- ✅ Elixir  
- ✅ Hex & Rebar
- ✅ Phoenix
- ✅ Build tools (gcc, make, etc)

**Tempo estimado:** 5-10 minutos

## Passo 4: Setup do Projeto

```bash
# Tornar script executável
chmod +x wsl-setup-project.sh

# Executar setup
./wsl-setup-project.sh
```

**Isso vai:**
- ✅ Instalar dependências (mix deps.get)
- ✅ Compilar snappyer e crc32cer (com gcc - sem erros!)
- ✅ Iniciar Kafka e PostgreSQL (Docker)
- ✅ Criar e migrar banco de dados
- ✅ Popular seeds

**Tempo estimado:** 3-5 minutos

## Passo 5: Iniciar Servidor

```bash
mix phx.server
```

**Pronto! 🎉**

Acesse no browser do Windows:
- 🌐 API: http://localhost:4000
- 📊 Kafka UI: http://localhost:8080
- ✅ Health: http://localhost:4000/health

---

## 🧪 Testar a API

### Health Check
```bash
curl http://localhost:4000/health
```

### Criar Pedido de Teste

Primeiro, pegue um ID de produto:
```bash
curl http://localhost:4000/api/inventory/products | jq '.[0].id'
```

Depois crie um pedido:
```bash
curl -X POST http://localhost:4000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "type": "pronto",
    "customer_name": "João Teste",
    "customer_email": "joao@test.com",
    "delivery_address": "Rua Teste, 123",
    "items": [
      {"product_id": "COLE_AQUI_O_ID", "quantity": 1, "unit_price": 45.0}
    ]
  }'
```

Vai retornar um ID de pedido. Use-o para consultar:
```bash
curl http://localhost:4000/api/orders/ORDER_ID
```

Você verá o pedido passar pelos stages:
1. `new` → Criado
2. `paid` → Pagamento processado (Worker Pagamento)
3. `processing` → Estoque verificado (Worker Estoque)
4. `shipped` → Enviado (Worker Entrega)
5. `delivered` → Entregue!

**Veja os logs em tempo real** no terminal onde `mix phx.server` está rodando!

---

## 📊 Monitorar Kafka

Abra http://localhost:8080 no browser do Windows para ver:
- Tópicos criados
- Mensagens sendo publicadas
- Consumer groups ativos
- Lag dos consumers

---

## 🔄 Workflow de Desenvolvimento

### Editar código no Windows
Use VS Code normalmente no Windows editando os arquivos.

### Rodar no WSL
```bash
# No WSL, recompilar quando mudar código
mix compile

# Ou reiniciar servidor (Ctrl+C e mix phx.server novamente)
```

### Ver logs
Os logs aparecem em tempo real no terminal WSL onde o servidor está rodando.

---

## 🛑 Parar Tudo

```bash
# Parar servidor Phoenix (Ctrl+C no terminal)

# Parar Docker
docker-compose down

# Sair do WSL
exit
```

---

## ✨ Próximos Passos

Agora que está tudo funcionando com Kafka real:

1. **Experimente a arquitetura event-driven:**
   - Crie pedidos e veja o fluxo nos logs
   - Veja as mensagens no Kafka UI
   - Teste pedidos personalizados que pedem ingredientes

2. **Explore o código:**
   - `lib/loja_virtual/pipelines/` - Workers Broadway
   - `lib/loja_virtual/kafka/producer.ex` - Produtor Kafka
   - `lib/loja_virtual_web/controllers/api/` - API REST

3. **Adicione features:**
   - Mais workers/pipelines
   - Novos endpoints
   - Testes automatizados

---

Qualquer dúvida, veja o `README.md` completo!
