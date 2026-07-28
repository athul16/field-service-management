import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { HomeIcon, ProjectIcon, ReportIcon, SiteIcon, WorkerIcon } from '../components/Icons';

const NAV_ITEMS = [
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
      <aside className="sidebar">
        <div className="brand">
          <span className="brand-mark">FS</span>
          <span className="brand-name">Field Service</span>
        </div>
        <nav>
          {NAV_ITEMS.map(({ to, label, Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) => (isActive ? 'navitem navitem-active' : 'navitem')}
            >
              <Icon width={17} height={17} />
              <span>{label}</span>
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-foot">
          <span className="user-name">{profile?.fullName}</span>
          <button className="btn btn-secondary" onClick={handleLogout}>
            Log out
          </button>
        </div>
      </aside>
      <div className="main-col">
        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
