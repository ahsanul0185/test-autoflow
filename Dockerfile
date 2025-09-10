# Use an official Node.js runtime as a base image
FROM node:18 AS base

WORKDIR /app

# Copy dependency files first for caching
COPY package*.json ./

# Install all dependencies
RUN npm install

# Copy all source code
COPY . .

# Build both frontend and backend (uses your build script)
RUN npm run build

# Set environment variables
ENV NODE_ENV=production
ENV PORT=5000

# Expose port
EXPOSE 5000

# Start the app
CMD ["npm", "start"]
