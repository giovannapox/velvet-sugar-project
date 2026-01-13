defmodule LojaVirtual.Kafka.Topics do
  @moduledoc """
  Kafka topic constants for the event-driven architecture.

  Topics follow the pattern: domain.action
  """

  # Order lifecycle
  def orders_new, do: "orders.new"
  def orders_paid, do: "orders.paid"

  # Stock checking
  def stock_product_check, do: "stock.product.check"
  def stock_ingredient_check, do: "stock.ingredient.check"

  # Supply chain
  def supply_needed, do: "supply.needed"
  def supply_shipment_created, do: "supply.shipment.created"
  def stock_replenished, do: "stock.replenished"

  # Production & Delivery
  def production_queue, do: "production.queue"
  def shipping_ready, do: "shipping.ready"

  @doc "Returns all topic names for initialization"
  def all do
    [
      orders_new(),
      orders_paid(),
      stock_product_check(),
      stock_ingredient_check(),
      supply_needed(),
      supply_shipment_created(),
      stock_replenished(),
      production_queue(),
      shipping_ready()
    ]
  end
end
