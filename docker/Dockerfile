# Uptime Monitor Pro - Dockerfile
# Multi-stage build for optimized production image

# Stage 1: Build stage
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    curl \
    python3 \
    make \
    g++

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Stage 2: Production stage
FROM node:18-alpine AS production

# Create app user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S uptime-monitor -u 1001

# Set working directory
WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache \
    curl \
    dumb-init

# Copy built application from builder stage
COPY --from=builder /app/node_modules ./node_modules

# Copy application files
COPY uptime-monitor-api.js ./
COPY index.html ./
COPY recovery.html ./
COPY package.json ./

# Create data directories
RUN mkdir -p /app/secure-data /app/logs && \
    chown -R uptime-monitor:nodejs /app

# Switch to non-root user
USER uptime-monitor

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "uptime-monitor-api.js"]
