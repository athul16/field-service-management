import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from './AuthContext';

export function ProtectedRoute() {
  const { profile } = useAuth();
  if (!profile) return <Navigate to="/login" replace />;
  return <Outlet />;
}
