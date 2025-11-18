#!/bin/bash

# Port Management Script for EDS-Lite
# Helps diagnose and resolve port conflicts

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Port definitions
declare -A PORTS=(
    ["8080"]="API Gateway"
    ["8081"]="Catalog Service"
    ["8082"]="Order Service"
    ["9092"]="Kafka"
    ["6379"]="Redis"
    ["27017"]="MongoDB"
)

# Function to check port status
check_port() {
    local port=$1
    local service_name=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        local pid=$(lsof -ti:$port)
        local process=$(ps -p $pid -o comm= 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓${NC} Port $port ($service_name): Running (PID: $pid, Process: $process)"
        return 0
    else
        echo -e "${RED}✗${NC} Port $port ($service_name): Not running"
        return 1
    fi
}

# Function to kill process on port
kill_port() {
    local port=$1
    local service_name=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        local pid=$(lsof -ti:$port)
        echo -e "${YELLOW}Stopping $service_name on port $port (PID: $pid)...${NC}"
        
        # Try graceful shutdown first
        kill -TERM $pid 2>/dev/null || true
        sleep 3
        
        # Check if still running
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${YELLOW}Graceful shutdown failed, force killing...${NC}"
            kill -9 $pid 2>/dev/null || true
            sleep 2
        fi
        
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${RED}✗${NC} Failed to stop $service_name on port $port"
            return 1
        else
            echo -e "${GREEN}✓${NC} $service_name stopped successfully"
            return 0
        fi
    else
        echo -e "${YELLOW}Port $port is already free${NC}"
        return 0
    fi
}

# Function to show detailed port info
show_port_details() {
    local port=$1
    echo ""
    echo "=== Detailed info for port $port ==="
    lsof -i :$port || echo "No processes on port $port"
    echo ""
}

# Main menu
show_menu() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}EDS-Lite Port Management${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "1. Check all ports status"
    echo "2. Stop specific service"
    echo "3. Stop all services"
    echo "4. Show detailed port info"
    echo "5. Kill all Java processes (nuclear option)"
    echo "6. Start services helper"
    echo "7. Exit"
    echo ""
}

# Function to check all ports
check_all_ports() {
    echo ""
    echo -e "${BLUE}=== Port Status Check ===${NC}"
    echo ""
    
    for port in "${!PORTS[@]}"; do
        check_port "$port" "${PORTS[$port]}"
    done
    
    echo ""
    echo -e "${BLUE}=== Summary ===${NC}"
    local running=0
    local total=${#PORTS[@]}
    
    for port in "${!PORTS[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            ((running++))
        fi
    done
    
    echo "Services running: $running/$total"
    
    if [ $running -eq $total ]; then
        echo -e "${GREEN}✓ All services are running!${NC}"
    elif [ $running -eq 0 ]; then
        echo -e "${RED}✗ No services are running${NC}"
    else
        echo -e "${YELLOW}⚠ Some services are missing${NC}"
    fi
}

# Function to stop specific service
stop_specific_service() {
    echo ""
    echo "Which service would you like to stop?"
    echo ""
    local i=1
    local port_array=()
    
    for port in $(echo "${!PORTS[@]}" | tr ' ' '\n' | sort -n); do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo "$i. ${PORTS[$port]} (port $port)"
            port_array+=($port)
            ((i++))
        fi
    done
    
    if [ ${#port_array[@]} -eq 0 ]; then
        echo "No services are currently running."
        return
    fi
    
    echo ""
    read -p "Enter number (1-$((i-1))): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((i-1)) ]; then
        local selected_port=${port_array[$((choice-1))]}
        kill_port "$selected_port" "${PORTS[$selected_port]}"
    else
        echo "Invalid choice."
    fi
}

# Function to stop all services
stop_all_services() {
    echo ""
    echo -e "${YELLOW}Stopping all EDS-Lite services...${NC}"
    echo ""
    
    # Stop in reverse order (applications first, then infrastructure)
    for port in 8082 8081 8080 9092 6379 27017; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            kill_port "$port" "${PORTS[$port]}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}All services stopped.${NC}"
}

# Function to kill all Java processes (nuclear option)
kill_all_java() {
    echo ""
    echo -e "${RED}WARNING: This will kill ALL Java processes on your system!${NC}"
    echo "This includes IDEs, other applications, etc."
    echo ""
    read -p "Are you sure? (type 'yes' to confirm): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo "Killing all Java processes..."
        pkill -f java || echo "No Java processes found"
        sleep 2
        echo "Done."
    else
        echo "Cancelled."
    fi
}

# Function to show start services helper
show_start_helper() {
    echo ""
    echo -e "${BLUE}=== How to Start Services ===${NC}"
    echo ""
    echo "Infrastructure services:"
    echo "  ./scripts/start-kafka.sh"
    echo "  ./scripts/start-redis.sh"
    echo "  ./scripts/start-mongo.sh"
    echo ""
    echo "Application services (in separate terminals):"
    echo "  Terminal 1: cd api-gateway && mvn spring-boot:run"
    echo "  Terminal 2: cd order-service && mvn spring-boot:run"
    echo "  Terminal 3: cd catalog-service && export CACHE_MODE=ttl_invalidate && mvn spring-boot:run"
    echo ""
    echo "Or use the automated script:"
    echo "  ./scripts/start-all-services.sh"
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Choose an option (1-7): " choice
    
    case $choice in
        1)
            check_all_ports
            ;;
        2)
            stop_specific_service
            ;;
        3)
            stop_all_services
            ;;
        4)
            echo ""
            read -p "Enter port number to inspect: " port
            show_port_details "$port"
            ;;
        5)
            kill_all_java
            ;;
        6)
            show_start_helper
            ;;
        7)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose 1-7."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done