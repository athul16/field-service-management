const BASE_URL = import.meta.env.VITE_API_BASE_URL;

class ApiError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

function authHeaders() {
  const token = localStorage.getItem('token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function handle(response) {
  if (response.status === 204) return null;

  const text = await response.text();
  const body = text ? safeJsonParse(text) : null;

  if (!response.ok) {
    // Not every error path returns the same shape (see agents.md) — fall
    // back to a generic message rather than assume body.error exists.
    const message = body?.error || `Request failed (${response.status})`;
    throw new ApiError(message, response.status);
  }

  return body;
}

function safeJsonParse(text) {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function withQuery(path, query) {
  if (!query) return path;
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value !== undefined && value !== null && value !== '') params.set(key, value);
  }
  const qs = params.toString();
  return qs ? `${path}?${qs}` : path;
}

export const api = {
  get(path, query) {
    return fetch(`${BASE_URL}${withQuery(path, query)}`, {
      headers: { ...authHeaders() },
    }).then(handle);
  },
  post(path, body) {
    return fetch(`${BASE_URL}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...authHeaders() },
      body: JSON.stringify(body ?? {}),
    }).then(handle);
  },
  patch(path, body) {
    return fetch(`${BASE_URL}${path}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', ...authHeaders() },
      body: JSON.stringify(body ?? {}),
    }).then(handle);
  },
  del(path) {
    return fetch(`${BASE_URL}${path}`, {
      method: 'DELETE',
      headers: { ...authHeaders() },
    }).then(handle);
  },
};

export { ApiError };
