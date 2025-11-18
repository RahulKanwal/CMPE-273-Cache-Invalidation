package com.eds.order.model;

import java.util.List;

public class CreateOrderRequest {
    private String customerId;
    private List<Order.OrderItem> items;

    public String getCustomerId() {
        return customerId;
    }

    public void setCustomerId(String customerId) {
        this.customerId = customerId;
    }

    public List<Order.OrderItem> getItems() {
        return items;
    }

    public void setItems(List<Order.OrderItem> items) {
        this.items = items;
    }
}

