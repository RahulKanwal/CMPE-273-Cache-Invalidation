FROM mongo:7.0

# Create data directory
RUN mkdir -p /data/db

# Expose MongoDB port
EXPOSE 27017

# Start MongoDB
CMD ["mongod", "--bind_ip_all"]