import dotenv from 'dotenv';
dotenv.config();

import express, { type Request, Response, NextFunction } from "express";
import { registerRoutes } from "./routes";
import { setupVite, serveStatic, log } from "./vite";

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Trust proxy for proper IP forwarding in containers
app.set('trust proxy', true);

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  const path = req.path;
  let capturedJsonResponse: Record<string, any> | undefined = undefined;

  const originalResJson = res.json;
  res.json = function (bodyJson, ...args) {
    capturedJsonResponse = bodyJson;
    return originalResJson.apply(res, [bodyJson, ...args]);
  };

  res.on("finish", () => {
    const duration = Date.now() - start;
    if (path.startsWith("/api")) {
      let logLine = `${req.method} ${path} ${res.statusCode} in ${duration}ms`;
      if (capturedJsonResponse) {
        logLine += ` :: ${JSON.stringify(capturedJsonResponse)}`;
      }

      if (logLine.length > 80) {
        logLine = logLine.slice(0, 79) + "…";
      }

      log(logLine);
    }
  });

  next();
});

(async () => {
  try {
    const server = await registerRoutes(app);

    // Error handling middleware
    app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
      const status = err.status || err.statusCode || 500;
      const message = err.message || "Internal Server Error";
      
      log(`Error: ${message}`, "error");
      res.status(status).json({ message });
    });

    // Setup static serving or Vite based on environment
    if (process.env.NODE_ENV === "production") {
      log("Setting up static file serving for production");
      serveStatic(app);
    } else {
      log("Setting up Vite development server");
      await setupVite(app, server);
    }

    // Get port from environment variable, default to 5000
    const port = parseInt(process.env.PORT || '5000', 10);
    
    server.listen(port, '0.0.0.0', () => {
      log(`Server running on http://0.0.0.0:${port}`);
      log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });

    // Graceful shutdown handling
    process.on('SIGTERM', () => {
      log('SIGTERM received, shutting down gracefully');
      server.close(() => {
        log('Server closed');
        process.exit(0);
      });
    });

  } catch (error) {
    log(`Failed to start server: ${error}`, "error");
    process.exit(1);
  }
})();