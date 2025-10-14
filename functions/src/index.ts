import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import {
  GoogleGenerativeAI,
  GenerativeModel,
  SchemaType,
} from '@google/generative-ai';
import type {
  DocumentData,
  DocumentReference,
  Timestamp,
  UpdateData,
} from 'firebase-admin/firestore';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

const MODEL_NAME = 'gemini-1.5-pro';
const REFUSAL_MESSAGE =
  'Sorry, I can only help with educational topics. Try questions about math, science, history, languages, programming, exam prep, study skills, etc.';
const RATE_LIMIT_WINDOW_MS = 5 * 60 * 1000;
const RATE_LIMIT_MAX_REQUESTS = 20;
const HISTORY_LIMIT = 12;
const SYSTEM_INSTRUCTION = `You are an Educational Assistant. Only answer academic topics (math, science, programming, history, languages, study skills). If the user asks about non-educational topics (e.g., celebrities, sports like Messi, entertainment, gossip, politics, adult topics), politely refuse with: "Sorry, I can only help with educational topics. Try questions about math, science, history, languages, programming, exam prep, study skills, etc." Keep answers concise, well-structured, and cite concepts, not URLs.`;

const KEYWORD_DENY_LIST = [
  'messi',
  'ronaldo',
  'league',
  'celebrity',
  'celebrities',
  'gossip',
  'movie',
  'movies',
  'series',
  'tiktok',
  'instagram',
  'facebook',
  'twitter',
  'politic',
  'election',
  'politics',
  'government',
  'adult',
  'nsfw',
  'sex',
  'violence',
  'gambling',
  'casino',
  'lottery',
  'betting',
  'celebs',
  'hollywood',
  'bollywood',
  'nba',
  'nfl',
  'soccer',
  'football',
  'baseball',
  'hockey',
  'premier league',
  'transfer news',
  'crime',
  'illegal',
  'hack',
  'hacking',
  'cheat code',
  'cheats',
  'leak',
  'rumor',
];

const KEYWORD_ALLOW_LIST = [
  'math',
  'mathematics',
  'algebra',
  'geometry',
  'calculus',
  'statistics',
  'probability',
  'physics',
  'chemistry',
  'biology',
  'science',
  'medicine',
  'anatomy',
  'programming',
  'coding',
  'computer',
  'technology',
  'algorithm',
  'data structure',
  'data structures',
  'software',
  'engineering',
  'history',
  'geography',
  'economics',
  'finance',
  'accounting',
  'language',
  'grammar',
  'vocabulary',
  'literature',
  'poetry',
  'essay',
  'study',
  'studying',
  'education',
  'exam',
  'homework',
  'revision',
  'practice',
  'recursion',
  'loop',
  'dart',
  'flutter',
  'java',
  'python',
  'chemical',
  'equation',
  'balance',
];

const apiKey = functions.config().genai?.key as string | undefined;

const genAI = apiKey ? new GoogleGenerativeAI(apiKey) : undefined;
const chatModel: GenerativeModel | undefined = genAI
  ? genAI.getGenerativeModel({
      model: MODEL_NAME,
      systemInstruction: SYSTEM_INSTRUCTION,
    })
  : undefined;
const classificationModel: GenerativeModel | undefined = genAI
  ? genAI.getGenerativeModel({ model: MODEL_NAME })
  : undefined;

type MessageRole = 'user' | 'model' | 'system';

type CallableResponse = {
  text: string;
  refused?: boolean;
  throttled?: boolean;
  tokens?: number;
  model?: string;
  persisted?: boolean;
};

type MessageRecord = {
  role?: string;
  content?: string;
};

type ClassificationResult = {
  isEducational: boolean;
  category: string;
};

const RATE_LIMIT_MESSAGE =
  "You're sending messages too quickly. Please wait a few minutes.";
const AUTH_REQUIRED_MESSAGE =
  'Please sign in to use the educational assistant.';
const MISSING_KEY_MESSAGE =
  'Educational assistant is temporarily unavailable. Please try again soon.';

function containsKeyword(message: string, keywords: string[]): boolean {
  return keywords.some((keyword) => message.includes(keyword));
}

async function ensureChatDocument(
  chatRef: DocumentReference,
  now: Timestamp,
): Promise<void> {
  const snapshot = await chatRef.get();
  if (!snapshot.exists) {
    await chatRef.set({
      createdAt: now,
      lastMessageAt: now,
      title: 'Educational Assistant',
    });
    return;
  }
  const data = snapshot.data() ?? {};
  const update: UpdateData = {
    lastMessageAt: now,
  };
  if (!data.title) {
    update.title = 'Educational Assistant';
  }
  await chatRef.set(update, { merge: true });
}

async function enforceRateLimit(uid: string): Promise<boolean> {
  const rateRef = firestore
    .collection('users')
    .doc(uid)
    .collection('eduChatMeta')
    .doc('rateLimit');
  const nowMs = Date.now();
  return firestore.runTransaction(async (tx) => {
    const snapshot = await tx.get(rateRef);
    if (!snapshot.exists) {
      tx.set(rateRef, {
        windowStart: admin.firestore.Timestamp.fromMillis(nowMs),
        count: 1,
      });
      return true;
    }
    const data = snapshot.data() ?? {};
    const windowStart = data.windowStart as Timestamp | undefined;
    const count = typeof data.count === 'number' ? data.count : 0;
    if (!windowStart || nowMs - windowStart.toMillis() >= RATE_LIMIT_WINDOW_MS) {
      tx.set(rateRef, {
        windowStart: admin.firestore.Timestamp.fromMillis(nowMs),
        count: 1,
      });
      return true;
    }
    if (count >= RATE_LIMIT_MAX_REQUESTS) {
      return false;
    }
    tx.update(rateRef, {
      count: count + 1,
    });
    return true;
  });
}

async function addMessage(
  chatRef: DocumentReference,
  role: MessageRole,
  content: string,
  options?: { model?: string; tokens?: number; timestamp?: Timestamp },
): Promise<void> {
  const createdAt = options?.timestamp ?? admin.firestore.Timestamp.now();
  const sanitizedContent = content.length > 4000 ? content.slice(0, 4000) : content;
  const payload: DocumentData = {
    role,
    content: sanitizedContent,
    createdAt,
  };
  if (options?.model) {
    payload.model = options.model;
  }
  if (typeof options?.tokens === 'number') {
    payload.tokens = options.tokens;
  }
  await chatRef.collection('messages').add(payload);
  await chatRef.set(
    {
      lastMessageAt: createdAt,
    },
    { merge: true },
  );
}

async function classifyMessage(message: string): Promise<ClassificationResult> {
  if (!classificationModel) {
    throw new Error('Classification model not available');
  }
  const response = await classificationModel.generateContent({
    contents: [
      {
        role: 'user',
        parts: [
          {
            text: `Classify the following user question. Respond strictly in JSON with fields isEducational (boolean) and category (string). Consider a topic educational only if it is clearly academic (math, science, programming, history, languages, economics, study skills). Question: """${message}"""`,
          },
        ],
      },
    ],
    generationConfig: {
      responseMimeType: 'application/json',
      responseSchema: {
        type: SchemaType.OBJECT,
        properties: {
          isEducational: { type: SchemaType.BOOLEAN },
          category: { type: SchemaType.STRING },
        },
        required: ['isEducational', 'category'],
      },
      maxOutputTokens: 256,
      temperature: 0,
    },
  });
  const text = response.response?.text();
  if (!text) {
    throw new Error('Empty classification response');
  }
  try {
    const parsed = JSON.parse(text) as ClassificationResult;
    return {
      isEducational: Boolean(parsed.isEducational),
      category: typeof parsed.category === 'string' ? parsed.category : 'unknown',
    };
  } catch (error) {
    functions.logger.error('Failed to parse classification response', error, text);
    throw new Error('Failed to classify topic');
  }
}

async function loadHistory(
  chatRef: DocumentReference,
): Promise<MessageRecord[]> {
  const snapshot = await chatRef
    .collection('messages')
    .orderBy('createdAt', 'desc')
    .limit(HISTORY_LIMIT)
    .get();
  return snapshot.docs
    .map((doc) => doc.data() as MessageRecord)
    .filter((doc) => typeof doc.content === 'string' && typeof doc.role === 'string')
    .reverse();
}

function buildContents(history: MessageRecord[], latest: string) {
  const contents = history
    .filter((item) => item.role === 'user' || item.role === 'model')
    .map((item) => ({
      role: item.role === 'model' ? 'model' : 'user',
      parts: [{ text: item.content ?? '' }],
    }));
  contents.push({
    role: 'user',
    parts: [{ text: latest }],
  });
  return contents;
}

async function respondWithRefusal(
  chatRef: DocumentReference,
  message: string,
): Promise<void> {
  await addMessage(chatRef, 'model', message);
}

export const generateEducationalReply = functions
  .runWith({ timeoutSeconds: 60, memory: '1GiB' })
  .https.onCall(async (data, context): Promise<CallableResponse> => {
    const uid = context.auth?.uid;
    if (!uid) {
      return { text: AUTH_REQUIRED_MESSAGE, refused: true, persisted: false };
    }

    const chatId = typeof data?.chatId === 'string' ? data.chatId.trim() : '';
    const incomingMessage =
      typeof data?.message === 'string' ? data.message.trim() : '';

    if (!chatId) {
      return {
        text: 'Missing chat reference. Please reopen the assistant.',
        refused: true,
        persisted: false,
      };
    }
    if (!incomingMessage) {
      return {
        text: 'Please enter a question before sending.',
        refused: true,
        persisted: false,
      };
    }

    const lowerMessage = incomingMessage.toLowerCase();
    const chatRef = firestore
      .collection('users')
      .doc(uid)
      .collection('eduChats')
      .doc(chatId);

    try {
      const now = admin.firestore.Timestamp.now();
      await ensureChatDocument(chatRef, now);

      const allowed = await enforceRateLimit(uid);
      if (!allowed) {
        await addMessage(chatRef, 'user', incomingMessage, { timestamp: now });
        await respondWithRefusal(chatRef, RATE_LIMIT_MESSAGE);
        return {
          text: RATE_LIMIT_MESSAGE,
          refused: true,
          throttled: true,
          persisted: true,
        };
      }

      await addMessage(chatRef, 'user', incomingMessage, { timestamp: now });

      if (containsKeyword(lowerMessage, KEYWORD_DENY_LIST)) {
        await respondWithRefusal(chatRef, REFUSAL_MESSAGE);
        return { text: REFUSAL_MESSAGE, refused: true, persisted: true };
      }

      if (!chatModel || !classificationModel) {
        functions.logger.error('Gemini model not configured.');
        await respondWithRefusal(chatRef, MISSING_KEY_MESSAGE);
        return { text: MISSING_KEY_MESSAGE, refused: true, persisted: true };
      }

      const classification = await classifyMessage(incomingMessage);
      const categoryLower = (classification.category || 'unknown').toLowerCase();
      if (!classification.isEducational) {
        functions.logger.info('Refused by classification', {
          uid,
          category: classification.category,
        });
        await respondWithRefusal(chatRef, REFUSAL_MESSAGE);
        return { text: REFUSAL_MESSAGE, refused: true, persisted: true };
      }

      if (
        containsKeyword(categoryLower, KEYWORD_DENY_LIST) ||
        (!containsKeyword(categoryLower, KEYWORD_ALLOW_LIST) &&
          !containsKeyword(lowerMessage, KEYWORD_ALLOW_LIST))
      ) {
        await respondWithRefusal(chatRef, REFUSAL_MESSAGE);
        return { text: REFUSAL_MESSAGE, refused: true, persisted: true };
      }

      const history = await loadHistory(chatRef);
      const contents = buildContents(history, incomingMessage);
      const response = await chatModel.generateContent({
        contents,
        generationConfig: {
          temperature: 0.4,
          maxOutputTokens: 1024,
        },
      });

      const replyText = response.response?.text()?.trim();
      if (!replyText) {
        const fallback = _safeFallback(replyText);
        await respondWithRefusal(chatRef, fallback);
        return {
          text: fallback,
          refused: true,
          persisted: true,
        };
      }

      const usage = response.response?.usageMetadata;
      const tokens = typeof usage?.totalTokens === 'number'
        ? usage.totalTokens
        : undefined;

      await addMessage(chatRef, 'model', replyText, {
        model: MODEL_NAME,
        tokens,
      });

      return {
        text: replyText,
        model: MODEL_NAME,
        tokens,
        persisted: true,
      };
    } catch (error) {
      functions.logger.error('generateEducationalReply error', error, {
        uid,
        chatId,
      });
      await respondWithRefusal(chatRef, MISSING_KEY_MESSAGE);
      return { text: MISSING_KEY_MESSAGE, refused: true, persisted: true };
    }
  });

function _safeFallback(previous?: string | null): string {
  return previous && previous.length > 3
    ? previous
    : 'Educational assistant is unavailable right now. Please try again later.';
}
