import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { GoogleGenAI } from '@google/genai';
import dotenv from 'dotenv';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function startServer() {
  const app = express();
  const PORT = 3000;

  app.use(express.json());

  // API Routes
  app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', app: 'FarmaJá Angola' });
  });

  // ZIP Download Endpoint
  app.get('/api/download-zip', (req, res) => {
    const zipPath = path.join(process.cwd(), 'public', 'farmaja_flutter_project.zip');
    res.download(zipPath, 'farmaja_flutter_project.zip');
  });

  // Gemini AI Assistant Endpoint for FarmaJá Angola
  app.post('/api/ai-assistant', async (req, res) => {
    try {
      const { query, context } = req.body;
      if (!query) {
        return res.status(400).json({ error: 'Query is required' });
      }

      const apiKey = process.env.GEMINI_API_KEY;
      if (apiKey && apiKey !== 'MY_GEMINI_API_KEY') {
        const ai = new GoogleGenAI({ apiKey });
        const response = await ai.models.generateContent({
          model: 'gemini-2.5-flash',
          contents: `Você é o assistente virtual de saúde e medicamentos do FarmaJá, a aplicação líder em Angola para localização de medicamentos em farmácias (Luanda, Benguela, Huambo, Lubango, etc.).
          
Instruções:
- Responda de forma clara, empática e profissional em português de Angola.
- Forneça informações gerais sobre princípios ativos, dosagens típicas, precauções e se o medicamento requer receita médica em Angola.
- Recomende sempre a consulta com um médico ou farmacêutico.
- Se o utilizador perguntar sobre disponibilidade de preços em Kwanza (AOA), ajude-o a procurar nas farmácias parceiras da rede FarmaJá.
- Contexto atual do utilizador: ${context || 'Nenhum contexto fornecido'}.

Pergunta do Utilizador: ${query}`,
        });

        return res.json({ text: response.text });
      } else {
        // Fallback response if GEMINI_API_KEY is not configured
        return res.json({
          text: `[Assistente FarmaJá - Modo Local]
Aviso: Para consultas personalizadas via Inteligência Artificial Gemini, configure a chave GEMINI_API_KEY no painel do AI Studio.

Resposta para "${query}":
Em Angola, a maioria dos medicamentos para dor (como Paracetamol ou Ibuprofeno) pode ser adquirida sem receita médica em farmácias de serviço em Luanda, Benguela ou Huambo. No entanto, antibióticos (como Amoxicilina ou Azitromicina) e antimaláricos (como Coartem) requerem prescrição médica.

Consulte o estoque em tempo real na aba "Home" para ver farmácias com estoque disponível e preços em Kwanza (AOA)!`
        });
      }
    } catch (error: any) {
      console.error('Error in AI Assistant endpoint:', error);
      res.status(500).json({ error: 'Erro ao processar consulta com AI', details: error?.message });
    }
  });

  // Vite middleware in dev or static files in production
  if (process.env.NODE_ENV !== 'production') {
    const { createServer: createViteServer } = await import('vite');
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`FarmaJá server running on http://0.0.0.0:${PORT}`);
  });
}

startServer();
