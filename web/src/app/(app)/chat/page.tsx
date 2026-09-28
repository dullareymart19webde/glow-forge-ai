'use client';
import { useState, useEffect, useRef } from 'react';
import { account, databases } from '@/lib/appwrite';
import { appwriteConfig } from '@/lib/appwrite';
import { ID, Query } from 'appwrite';
import { v4 as uuidv4 } from 'uuid';
import ReactMarkdown from 'react-markdown';
import { Send, RefreshCw, Loader2, Bot, User, History, X, MessageSquare } from 'lucide-react';

interface ChatMessage {
  id: string;
  role: 'user' | 'model';
  content: string;
}

interface ChatSession {
  id: string;
  title: string;
  updatedAt: string;
}

export default function ChatPage() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isInitializing, setIsInitializing] = useState(true);
  const [sessionId, setSessionId] = useState('');
  const [userId, setUserId] = useState('');
  
  // History state
  const [sessions, setSessions] = useState<ChatSession[]>([]);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const [isLoadingHistory, setIsLoadingHistory] = useState(false);

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

  const loadHistory = async () => {
    setIsHistoryOpen(true);
    if (sessions.length > 0 || !userId) return;
    setIsLoadingHistory(true);
    
    try {
      const historyRes = await databases.listDocuments(
        appwriteConfig.databaseId,
        appwriteConfig.tableId,
        [
          Query.equal('user_id', userId),
          Query.orderDesc('$createdAt'),
          Query.limit(100)
        ]
      );
      
      const sessionMap = new Map<string, ChatSession>();
      historyRes.documents.forEach(doc => {
        if (!sessionMap.has(doc.session_id)) {
          // Find the first user message for the title if possible
          // But since it's desc, we just use whatever message is first in desc order
          // which is the last message. To find the true title, we'd need to fetch ascending,
          // but just using the first 30 chars of this doc is fine for a quick title.
          const isUser = doc.sender_role === 'user';
          let title = doc.message_content.substring(0, 30) + '...';
          
          sessionMap.set(doc.session_id, {
            id: doc.session_id,
            title: title,
            updatedAt: new Date(doc.$createdAt).toLocaleDateString()
          });
        } else {
          // If we find an older user message, update the title to the FIRST user message
          if (doc.sender_role === 'user') {
            const current = sessionMap.get(doc.session_id)!;
            current.title = doc.message_content.substring(0, 30) + '...';
          }
        }
      });
      
      setSessions(Array.from(sessionMap.values()));
    } catch (error) {
      console.error('Failed to load history', error);
    } finally {
      setIsLoadingHistory(false);
    }
  };

  const loadSession = async (sid: string) => {
    setIsHistoryOpen(false);
    setIsInitializing(true);
    try {
      setSessionId(sid);
      const historyRes = await databases.listDocuments(
        appwriteConfig.databaseId,
        appwriteConfig.tableId,
        [
          Query.equal('session_id', sid),
          Query.orderAsc('$createdAt')
        ]
      );

      const loadedMessages = historyRes.documents.map((doc) => ({
        id: doc.$id,
        role: doc.sender_role as 'user' | 'model',
        content: doc.message_content,
      }));
      setMessages(loadedMessages);
    } catch (e) {
      console.error('Failed to load session', e);
    } finally {
      setIsInitializing(false);
    }
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
        content: data.response, // Fixed from data.reply
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

  const handleSuggestionClick = (suggestion: string) => {
    setInput(suggestion);
    // Optionally auto-send:
    // const formEvent = new Event('submit') as unknown as React.FormEvent;
    // sendMessage(formEvent); // Actually, we'll just populate the input for now.
  };

  const suggestions = [
    "Write a python script to scrape a website",
    "Explain quantum computing to a 5 year old",
    "How do I center a div in Tailwind CSS?",
    "Give me 5 creative ideas for a tech startup"
  ];

  return (
    <div className="flex flex-col h-full max-w-5xl mx-auto md:px-4">
      <div className="flex justify-between items-center mb-6 pt-4 px-4 md:px-0">
        <div>
          <h1 className="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-white to-purple-300 tracking-wider">GLOWFORGE CHAT</h1>
          <p className="text-sm text-purple-400/60 font-medium">Llama 3 Powered AI</p>
        </div>
        <div className="flex gap-2">
          {/* History button */}
          <button 
            onClick={loadHistory}
            title="Chat History"
            className="p-2.5 rounded-full bg-white/5 hover:bg-white/10 text-gray-300 hover:text-white transition-all border border-white/10 hover:border-purple-500/50 hover:shadow-[0_0_15px_rgba(168,85,247,0.3)] flex items-center gap-2 px-4"
          >
            <span className="text-sm font-medium hidden md:block">History</span>
            <History size={18} />
          </button>
          <button 
            onClick={clearChat}
            title="New Chat"
            className="p-2.5 rounded-full bg-white/5 hover:bg-white/10 text-gray-300 hover:text-white transition-all border border-white/10 hover:border-purple-500/50 hover:shadow-[0_0_15px_rgba(168,85,247,0.3)] flex items-center gap-2 px-4"
          >
            <span className="text-sm font-medium hidden md:block">New Chat</span>
            <RefreshCw size={18} />
          </button>
        </div>
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
            <p className="text-gray-400 max-w-md text-sm leading-relaxed mb-8">
              Ask me to write code, brainstorm ideas, analyze data, or summarize complex topics.
            </p>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 w-full max-w-2xl">
              {suggestions.map((suggestion, idx) => (
                <button
                  key={idx}
                  onClick={() => handleSuggestionClick(suggestion)}
                  className="bg-white/5 hover:bg-white/10 border border-white/10 hover:border-purple-500/50 rounded-xl p-4 text-sm text-gray-300 hover:text-white transition-all text-left flex items-center gap-3 group"
                >
                  <div className="p-2 rounded-lg bg-purple-500/20 text-purple-400 group-hover:bg-purple-500 group-hover:text-white transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m9 18 6-6-6-6"/></svg>
                  </div>
                  {suggestion}
                </button>
              ))}
            </div>
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

      {/* History Modal */}
      {isHistoryOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div className="bg-[#1a0f2e] border border-white/10 shadow-2xl rounded-3xl w-full max-w-md max-h-[80vh] flex flex-col relative overflow-hidden">
            <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-purple-600 to-indigo-600"></div>
            <div className="flex justify-between items-center p-6 border-b border-white/5">
              <h2 className="text-xl font-bold text-white flex items-center gap-2">
                <History className="text-purple-400" size={20} />
                Chat History
              </h2>
              <button 
                onClick={() => setIsHistoryOpen(false)}
                className="text-gray-400 hover:text-white transition-colors"
              >
                <X size={20} />
              </button>
            </div>
            
            <div className="flex-1 overflow-y-auto p-4 space-y-2">
              {isLoadingHistory ? (
                <div className="flex flex-col items-center justify-center h-40 text-purple-400">
                  <Loader2 className="animate-spin mb-2" size={24} />
                  <p className="text-sm">Loading sessions...</p>
                </div>
              ) : sessions.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-40 text-gray-400 text-center">
                  <MessageSquare size={32} className="mb-2 opacity-20" />
                  <p className="text-sm">No chat history found.</p>
                </div>
              ) : (
                sessions.map((session) => (
                  <button
                    key={session.id}
                    onClick={() => loadSession(session.id)}
                    className="w-full text-left p-4 rounded-xl bg-white/5 hover:bg-white/10 border border-transparent hover:border-purple-500/30 transition-all group flex flex-col gap-1"
                  >
                    <span className="text-sm font-medium text-gray-200 group-hover:text-purple-300 line-clamp-1">
                      {session.title}
                    </span>
                    <span className="text-xs text-gray-500 font-mono">
                      {session.updatedAt}
                    </span>
                  </button>
                ))
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
