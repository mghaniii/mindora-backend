import express from 'express';
import cors from 'cors';
import routes from './routes/index.js';
import { notFound, errorHandler } from './middlewares/error.middleware.js';

const app = express();

// CORS + preflight OPTIONS otomatis ditangani middleware cors
// (preflight dipicu header Authorization dari frontend).
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());

app.use('/api', routes);

app.use(notFound);
app.use(errorHandler);

export default app;
