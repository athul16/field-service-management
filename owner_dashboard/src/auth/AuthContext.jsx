import { createContext, useContext, useState } from 'react';
import { api } from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [profile, setProfile] = useState(() => {
    const stored = localStorage.getItem('profile');
    return stored ? JSON.parse(stored) : null;
  });

  async function login(phone, pin) {
    const response = await api.post('/api/auth/login', { phone, pin });
    if (response.profile.role !== 'OWNER') {
      throw new Error('This dashboard is for owners only. Log in with an owner account.');
    }
    localStorage.setItem('token', response.token);
    localStorage.setItem('profile', JSON.stringify(response.profile));
    setProfile(response.profile);
  }

  function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('profile');
    setProfile(null);
  }

  return <AuthContext.Provider value={{ profile, login, logout }}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
