import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

export function AppLayout() {
  const { profile, logout } = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate('/login', { replace: true });
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <h2 className="sidebar-title">Field Service</h2>
        <nav>
          <NavLink to="/sites" className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}>
            Sites
          </NavLink>
          <NavLink to="/projects" className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}>
            Projects
          </NavLink>
          <NavLink to="/workers" className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}>
            Workers
          </NavLink>
          <NavLink to="/reports" className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}>
            Reports
          </NavLink>
        </nav>
      </aside>
      <div className="main-column">
        <header className="topbar">
          <span>{profile?.fullName}</span>
          <button className="btn btn-secondary" onClick={handleLogout}>
            Log out
          </button>
        </header>
        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
