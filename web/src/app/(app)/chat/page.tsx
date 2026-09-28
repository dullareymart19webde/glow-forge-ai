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
      const response = await fetch('https://glow-forge-ai.onrender.com/api/chat/ask', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          prompt: userMessage.content,
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
    <div className="flex flex-col h-full max-w-4xl mx-auto">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-white tracking-widest">GLOWFORGE CHAT</h1>
        <button 
          onClick={clearChat}
          title="Clear Chat"
          className="p-2 rounded-full bg-white/5 hover:bg-white/10 text-white transition-colors"
        >
          <RefreshCw size={20} />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto glass-panel rounded-3xl p-4 md:p-6 mb-4 space-y-6">
        {isInitializing ? (
          <div className="h-full flex items-center justify-center">
            <Loader2 className="w-8 h-8 animate-spin text-purple-400" />
          </div>
        ) : messages.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center text-center px-4">
            <div className="w-16 h-16 rounded-full glow-effect bg-purple-900/50 flex items-center justify-center mb-4">
              <Bot size={32} className="text-purple-300" />
            </div>
            <h2 className="text-xl font-bold text-white mb-2">How can I help you forge today?</h2>
            <p className="text-purple-300/70 max-w-md">
              Ask me to write code, brainstorm ideas, analyze data, or summarize complex topics.
            </p>
          </div>
        ) : (
          messages.map((msg) => (
            <div key={msg.id} className={`flex gap-4 ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              {msg.role === 'model' && (
                <div className="w-8 h-8 rounded-full bg-purple-600 flex items-center justify-center shrink-0 mt-1">
                  <Bot size={18} className="text-white" />
                </div>
              )}
              
              <div className={`max-w-[85%] rounded-2xl p-4 ${
                msg.role === 'user' 
                  ? 'bg-purple-600 text-white rounded-tr-sm' 
                  : 'bg-white/10 text-gray-100 rounded-tl-sm border border-white/5'
              }`}>
                {msg.role === 'user' ? (
                  <p className="whitespace-pre-wrap">{msg.content}</p>
                ) : (
                  <div className="prose prose-invert max-w-none prose-p:leading-relaxed prose-pre:bg-black/50 prose-pre:border prose-pre:border-white/10">
                    <ReactMarkdown>{msg.content}</ReactMarkdown>
                  </div>
                )}
              </div>

              {msg.role === 'user' && (
                <div className="w-8 h-8 rounded-full bg-purple-900 flex items-center justify-center shrink-0 mt-1 border border-purple-500/30">
                  <User size={18} className="text-white" />
                </div>
              )}
            </div>
          ))
        )}
        {isLoading && (
          <div className="flex gap-4 justify-start">
            <div className="w-8 h-8 rounded-full bg-purple-600 flex items-center justify-center shrink-0 mt-1">
              <Bot size={18} className="text-white" />
            </div>
            <div className="bg-white/10 rounded-2xl rounded-tl-sm p-4 border border-white/5 flex items-center gap-2">
              <Loader2 size={16} className="animate-spin text-purple-400" />
              <span className="text-purple-300 text-sm">Forging response...</span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <form onSubmit={sendMessage} className="relative">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          disabled={isLoading || isInitializing}
          placeholder="Ask GlowForge..."
          className="w-full bg-black/40 border border-purple-500/30 rounded-full py-4 pl-6 pr-16 text-white placeholder-purple-300/50 focus:outline-none focus:border-purple-500 focus:ring-1 focus:ring-purple-500 transition-all shadow-[0_0_20px_rgba(168,85,247,0.1)]"
        />
        <button
          type="submit"
          disabled={!input.trim() || isLoading || isInitializing}
          className="absolute right-2 top-2 bottom-2 aspect-square rounded-full bg-purple-600 hover:bg-purple-500 text-white flex items-center justify-center transition-colors disabled:opacity-50 disabled:bg-purple-900"
        >
          <Send size={18} className="ml-1" />
        </button>
      </form>
    </div>
  );
}
