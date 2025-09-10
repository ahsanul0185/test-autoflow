# Stage 1: Build frontend and backend
FROM node:18 AS builder

WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install all dependencies (needed for building frontend)
RUN npm install

# Copy source code
COPY . .

# Build frontend
RUN npm run build

# Stage 2: Production image
FROM node:18 AS production

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5000

# Copy only the built output and needed files
COPY package*.json ./
RUN npm install --only=production

# Copy built backend and frontend
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/client/dist ./client/dist

EXPOSE 5000

CMD ["node", "dist/index.js"]
