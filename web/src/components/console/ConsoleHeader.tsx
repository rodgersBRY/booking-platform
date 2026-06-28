'use client';

import { useEffect, useState } from 'react';
import { signOut } from '@/app/login/actions';

interface Props {
  staffName: string;
  staffRole: string;
}

export default function ConsoleHeader({ staffName, staffRole }: Props) {
  const [time, setTime] = useState('');

  useEffect(() => {
    function tick() {
      setTime(
        new Date().toLocaleTimeString('en-KE', {
          hour: '2-digit',
          minute: '2-digit',
        })
      );
    }
    tick();
    const id = setInterval(tick, 10_000);
    return () => clearInterval(id);
  }, []);

  return (
    <header
      className="flex items-center justify-between px-6 py-4"
      style={{ background: 'var(--navy)', color: '#fff' }}
    >
      <div className="flex items-center gap-3">
        <span className="text-xl font-semibold tracking-tight">
          Fade &amp; Sharp
        </span>
        <span
          className="text-xs font-medium px-2 py-0.5 rounded-full"
          style={{ background: 'var(--brass)', color: '#fff' }}
        >
          Reception
        </span>
      </div>

      <div className="flex items-center gap-6">
        {time && (
          <span className="text-2xl font-mono tabular-nums opacity-90">
            {time}
          </span>
        )}

        <div className="text-right">
          <p className="text-sm font-medium">{staffName}</p>
          <p className="text-xs opacity-60 capitalize">{staffRole}</p>
        </div>

        <form action={signOut}>
          <button
            type="submit"
            className="text-xs opacity-60 hover:opacity-100 underline underline-offset-2 transition-opacity"
          >
            Sign out
          </button>
        </form>
      </div>
    </header>
  );
}
