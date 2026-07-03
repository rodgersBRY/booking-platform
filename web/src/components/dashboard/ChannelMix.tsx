"use client";

interface ChannelRow {
  channel: string;
  count: number;
}

interface ChannelMixProps {
  channels: ChannelRow[];
}

const CHANNEL_LABELS: Record<string, string> = {
  walkin: "Walk-in",
  online: "Online",
  whatsapp: "WhatsApp",
  phone: "Phone",
  unknown: "Other",
};

export function ChannelMix({ channels }: ChannelMixProps) {
  if (channels.length === 0) {
    return <p className="text-sm text-zinc-400">No bookings this week yet.</p>;
  }

  const total = channels.reduce((s, c) => s + c.count, 0);
  const sorted = [...channels].sort((a, b) => b.count - a.count);

  return (
    <ul className="space-y-2">
      {sorted.map((c) => {
        const pct = total > 0 ? Math.round((c.count / total) * 100) : 0;
        const label = CHANNEL_LABELS[c.channel] ?? c.channel;
        return (
          <li key={c.channel} className="flex items-center gap-3 text-sm">
            <span className="w-20 shrink-0 text-zinc-600 font-medium">{label}</span>
            <div className="flex-1 h-2 rounded-full bg-zinc-100">
              <div
                className="h-2 rounded-full bg-(--navy)"
                style={{ width: `${pct}%` }}
              />
            </div>
            <span className="w-8 text-right text-zinc-500 shrink-0">{c.count}</span>
            <span className="w-8 text-right text-zinc-400 shrink-0 text-xs">{pct}%</span>
          </li>
        );
      })}
    </ul>
  );
}
