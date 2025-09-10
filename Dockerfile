# Use Node.js
FROM node:18

WORKDIR /app

# Install deps first
COPY package*.json ./
RUN npm install

# Copy all source
COPY . .

# Build client + server
RUN npm run build

# Env
ENV NODE_ENV=production
ENV PORT=5000

# Expose port
EXPOSE 5000

# Start server
CMD ["node", "dist/server/index.js"]
