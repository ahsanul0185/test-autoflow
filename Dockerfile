# Use an official Node.js runtime as a base image
FROM node:18 AS base

# Set working directory
WORKDIR /app

# Copy dependency files first for better caching
COPY package*.json ./

# Install only production dependencies (if your build script needs devDeps, remove --only=production)
RUN npm install

# Copy all source code
COPY . .

# Build both frontend and backend
RUN npm run build

# Set environment variables
ENV NODE_ENV=production
ENV PORT=5000

# Expose app port
EXPOSE 5000

# Start the app
CMD ["npm", "start"]
