FROM vectorized/redpanda:latest

# Create data directory
RUN mkdir -p /var/lib/redpanda/data

# Expose Kafka port
EXPOSE 9092

# Start Redpanda (Kafka-compatible)
CMD ["redpanda", "start", "--smp", "1", "--memory", "1G", "--reserve-memory", "0M", "--overprovisioned", "--node-id", "0", "--check=false", "--kafka-addr", "0.0.0.0:9092", "--advertise-kafka-addr", "0.0.0.0:9092", "--pandaproxy-addr", "0.0.0.0:8082", "--advertise-pandaproxy-addr", "0.0.0.0:8082"]