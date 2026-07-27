import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { HomeIcon, ProjectIcon, ReportIcon, SiteIcon, WorkerIcon } from '../components/Icons';

const TABS = [
  { to: '/', label: 'Home', Icon: HomeIcon, end: true },
  { to: '/sites', label: 'Sites', Icon: SiteIcon },
  { to: '/projects', label: 'Projects', Icon: ProjectIcon },
  { to: '/workers', label: 'Workers', Icon: WorkerIcon },
  { to: '/reports', label: 'Reports', Icon: ReportIcon },
];

export function AppLayout() {
  const { profile, logout } = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate('/login', { replace: true });
  }

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="topbar-row">
          <div className="brand">
            <span className="brand-mark">FS</span>
            <span className="brand-name">Field Service</span>
          </div>
          <div className="topbar-user">
            <span className="user-name">{profile?.fullName}</span>
            <button className="btn btn-secondary" onClick={handleLogout}>
              Log out
            </button>
          </div>
        </div>
        <nav className="tabbar">
          {TABS.map(({ to, label, Icon, end }) => (
            <NavLink key={to} to={to} end={end} className={({ isActive }) => (isActive ? 'tab tab-active' : 'tab')}>
              <Icon width={20} height={20} />
              <span>{label}</span>
            </NavLink>
          ))}
        </nav>
      </header>
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
