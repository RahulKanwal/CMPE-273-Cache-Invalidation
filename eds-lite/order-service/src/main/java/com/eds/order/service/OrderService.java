package com.eds.order.service;

import com.eds.order.model.CreateOrderRequest;
import com.eds.order.model.Order;
import com.eds.order.model.OrderEvent;
import com.eds.order.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Service
public class OrderService {
    private final OrderRepository orderRepository;
    
    @Autowired(required = false)
    private KafkaTemplate<String, OrderEvent> kafkaTemplate;

    public OrderService(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }

    @Transactional
    public Order createOrder(CreateOrderRequest request) {
        Order order = new Order();
        order.setId(UUID.randomUUID().toString());
        order.setCustomerId(request.getCustomerId());
        order.setItems(request.getItems());
        
        BigDecimal total = request.getItems().stream()
                .map(item -> item.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        order.setTotal(total);

        Order saved = orderRepository.save(order);

        // Publish order event asynchronously (don't block response)
        if (kafkaTemplate != null) {
            try {
                OrderEvent event = new OrderEvent(
                        saved.getId(),
                        OrderEvent.OrderEventType.Created,
                        saved.getCustomerId(),
                        saved.getTotal(),
                        Instant.now()
                );
                kafkaTemplate.send("order.events", saved.getId(), event);
            } catch (Exception e) {
                // Log error but don't fail the order creation
                System.err.println("Failed to publish order event: " + e.getMessage());
            }
        }

        return saved;
    }

    public Order getOrder(String id) {
        return orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found: " + id));
    }

    public java.util.List<Order> getOrdersByCustomer(String customerId) {
        return orderRepository.findByCustomerId(customerId);
    }
}

