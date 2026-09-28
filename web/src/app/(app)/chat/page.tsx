'use client';
import { useState, useEffect, useRef } from 'react';
import { account, databases } from '@/lib/appwrite';
import { appwriteConfig } from '@/lib/appwrite';
import { ID, Query } from 'appwrite';
import { v4 as uuidv4 } from 'uuid';
import ReactMarkdown from 'react-markdown';
import { Send, RefreshCw, Loader2, Bot, User } from 'lucide-react';

interface ChatMessage {
  id: string;
  role: 'user' | 'model';
  content: string;
}

export default function ChatPage() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isInitializing, setIsInitializing] = useState(true);
  const [sessionId, setSessionId] = useState('');
  const [userId, setUserId] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    initChat();
  }, []);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const initChat = async () => {
    try {
      const user = await account.get();
      setUserId(user.$id);

      // Check for existing sessions
      const sessions = await databases.listDocuments(
        appwriteConfig.databaseId,
        appwriteConfig.tableId,
        [
          Query.equal('user_id', user.$id),
          Query.equal('message_content', 'SESSION_ROOT'),
          Query.orderDesc('$createdAt'),
          Query.limit(1)
        ]
      );

      if (sessions.documents.length > 0) {
        const latestSessionId = sessions.documents[0].session_id;
        setSessionId(latestSessionId);

        // Fetch messages for this session
        const history = await databases.listDocuments(
          appwriteConfig.databaseId,
          appwriteConfig.tableId,
          [
            Query.equal('session_id', latestSessionId),
            Query.notEqual('message_content', 'SESSION_ROOT'),
            Query.orderAsc('$createdAt')
          ]
        );

        const loadedMessages = history.documents.map((doc) => ({
          id: doc.$id,
          role: doc.sender_role as 'user' | 'model',
          content: doc.message_content,
        }));
        setMessages(loadedMessages);
      } else {
        setSessionId(uuidv4());
      }
    } catch (e) {
      console.error('Failed to init chat', e);
    } finally {
      setIsInitializing(false);
    }
  };

  const clearChat = () => {
    setMessages([]);
    setSessionId(uuidv4());
  };

  const sendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;

    const userMessage: ChatMessage = {
      id: ID.unique(),
      role: 'user',
      content: input.trim(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      // 1. Save user message to Appwrite
      await databases.createDocument(
        appwriteConfig.databaseId,
        appwriteConfig.tableId,
        userMessage.id,
        {
          user_id: userId,
          session_title: 'N/A',
          session_id: sessionId,
          sender_role: 'user',
          message_content: userMessage.content,
        }
      );

      // 2. Fetch AI response from Render Backend
      const response = await fetch('https://glow-forge-ai.onrender.com/api/chat/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: userMessage.content,
          history: messages.map(m => ({ role: m.role, content: m.content })),
          session_id: sessionId,
          user_id: userId,
        }),
      });

      if (!response.ok) throw new Error('API Error');
      
      const data = await response.json();
      
      const aiMessage: ChatMessage = {
        id: ID.unique(),
        role: 'model',
        content: data.reply,
      };

      setMessages((prev) => [...prev, aiMessage]);

      // 3. Save AI message to Appwrite
      await databases.createDocument(
        appwriteConfig.databaseId,
        appwriteConfig.tableId,
        aiMessage.id,
        {
          user_id: userId,
          session_title: 'N/A',
          session_id: sessionId,
          sender_role: 'model',
          message_content: aiMessage.content,
        }
      );

    } catch (error) {
      console.error(error);
      const errorMessage: ChatMessage = {
        id: ID.unique(),
        role: 'model',
        content: '*Failed to reach GlowForge AI. Please try again later.*',
      };
      setMessages((prev) => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-full max-w-5xl mx-auto md:px-4">
      <div className="flex justify-between items-center mb-6 pt-4 px-4 md:px-0">
        <div>
          <h1 className="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-white to-purple-300 tracking-wider">GLOWFORGE CHAT</h1>
          <p className="text-sm text-purple-400/60 font-medium">Llama 3 Powered AI</p>
        </div>
        <button 
          onClick={clearChat}
          title="Clear Chat"
          className="p-2.5 rounded-full bg-white/5 hover:bg-white/10 text-gray-300 hover:text-white transition-all border border-white/10 hover:border-purple-500/50 hover:shadow-[0_0_15px_rgba(168,85,247,0.3)]"
        >
          <RefreshCw size={18} />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto bg-[#1a0f2e]/60 border border-white/5 shadow-2xl rounded-3xl p-4 md:p-8 mb-4 space-y-6">
        {isInitializing ? (
          <div className="h-full flex items-center justify-center">
            <Loader2 className="w-8 h-8 animate-spin text-purple-400" />
          </div>
        ) : messages.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center text-center px-4">
            <div className="relative">
              <div className="absolute inset-0 bg-purple-600 blur-3xl opacity-20 rounded-full"></div>
              <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-purple-500/20 to-indigo-500/20 border border-white/10 flex items-center justify-center mb-6 relative z-10 shadow-2xl">
                <Bot size={36} className="text-purple-300" strokeWidth={1.5} />
              </div>
            </div>
            <h2 className="text-2xl font-bold text-white mb-3">How can I help you forge today?</h2>
            <p className="text-gray-400 max-w-md text-sm leading-relaxed">
              Ask me to write code, brainstorm ideas, analyze data, or summarize complex topics.
            </p>
          </div>
        ) : (
          messages.map((msg) => (
            <div key={msg.id} className={`flex gap-3 md:gap-4 ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              {msg.role === 'model' && (
                <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center shrink-0 shadow-lg mt-1">
                  <Bot size={18} className="text-white" />
                </div>
              )}
              
              <div className={`max-w-[90%] md:max-w-[80%] rounded-2xl p-4 md:px-6 md:py-4 shadow-sm ${
                msg.role === 'user' 
                  ? 'bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-tr-sm' 
                  : 'bg-white/5 text-gray-200 rounded-tl-sm border border-white/10 backdrop-blur-sm'
              }`}>
                {msg.role === 'user' ? (
                  <p className="whitespace-pre-wrap leading-relaxed text-sm md:text-base">{msg.content}</p>
                ) : (
                  <div className="prose prose-sm md:prose-base prose-invert max-w-none prose-p:leading-relaxed prose-pre:bg-black/50 prose-pre:border prose-pre:border-white/10 prose-headings:text-purple-300 prose-a:text-purple-400">
                    <ReactMarkdown>{msg.content}</ReactMarkdown>
                  </div>
                )}
              </div>
            </div>
          ))
        )}
        {isLoading && (
          <div className="flex gap-4 justify-start">
            <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center shrink-0 shadow-lg mt-1">
              <Bot size={18} className="text-white" />
            </div>
            <div className="bg-white/5 rounded-2xl rounded-tl-sm p-4 px-6 border border-white/10 flex items-center gap-3 backdrop-blur-sm">
              <Loader2 size={16} className="animate-spin text-purple-400" />
              <span className="text-gray-400 text-sm font-medium tracking-wide">Forging response...</span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <form onSubmit={sendMessage} className="relative px-2 md:px-0">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          disabled={isLoading || isInitializing}
          placeholder="Ask GlowForge..."
          className="w-full bg-[#1a0f2e]/80 backdrop-blur-xl border border-white/10 rounded-2xl py-4 pl-6 pr-16 text-white placeholder-gray-500 focus:outline-none focus:border-purple-500/50 focus:ring-2 focus:ring-purple-500/20 transition-all shadow-xl"
        />
        <button
          type="submit"
          disabled={!input.trim() || isLoading || isInitializing}
          className="absolute right-4 top-2 bottom-2 aspect-square rounded-xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:opacity-90 text-white flex items-center justify-center transition-all disabled:opacity-50 disabled:from-gray-700 disabled:to-gray-700"
        >
          <Send size={18} className="ml-0.5" />
        </button>
      </form>
    </div>
  );
}
