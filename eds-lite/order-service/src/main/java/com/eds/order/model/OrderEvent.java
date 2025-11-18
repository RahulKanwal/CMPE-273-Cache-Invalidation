package com.eds.order.model;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.math.BigDecimal;
import java.time.Instant;

public class OrderEvent {
    private String orderId;
    private OrderEventType type;
    private String customerId;
    private BigDecimal total;
    private Instant timestamp;

    @JsonCreator
    public OrderEvent(
            @JsonProperty("orderId") String orderId,
            @JsonProperty("type") OrderEventType type,
            @JsonProperty("customerId") String customerId,
            @JsonProperty("total") BigDecimal total,
            @JsonProperty("timestamp") Instant timestamp) {
        this.orderId = orderId;
        this.type = type;
        this.customerId = customerId;
        this.total = total;
        this.timestamp = timestamp;
    }

    public String getOrderId() {
        return orderId;
    }

    public void setOrderId(String orderId) {
        this.orderId = orderId;
    }

    public OrderEventType getType() {
        return type;
    }

    public void setType(OrderEventType type) {
        this.type = type;
    }

    public String getCustomerId() {
        return customerId;
    }

    public void setCustomerId(String customerId) {
        this.customerId = customerId;
    }

    public BigDecimal getTotal() {
        return total;
    }

    public void setTotal(BigDecimal total) {
        this.total = total;
    }

    public Instant getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Instant timestamp) {
        this.timestamp = timestamp;
    }

    public enum OrderEventType {
        Created, Paid, Canceled
    }
}

