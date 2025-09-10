# Use an official Node.js runtime as a base image
FROM node:18 AS base

# Set working directory
WORKDIR /app

# Copy dependency files first for better caching
COPY package*.json ./

# Install dependencies (including devDependencies for build process)
RUN npm ci

# Copy all source code
COPY . .

# Build both frontend and backend
RUN npm run build

# Production stage
FROM node:18-slim AS production

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files and install only production dependencies
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy built application from build stage
COPY --from=base /app/dist ./dist
COPY --from=base /app/client/dist ./client/dist

# Set environment variables
ENV NODE_ENV=production
ENV PORT=5000

# Expose app port
EXPOSE 5000

# Create non-root user for security
RUN groupadd -g 1001 -r nodejs && useradd -r -g nodejs -u 1001 nodejs
RUN chown -R nodejs:nodejs /app
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/ || exit 1

# Start the app
CMD ["node", "dist/index.js"]