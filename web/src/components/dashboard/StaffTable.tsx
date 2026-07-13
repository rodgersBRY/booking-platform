"use client";

interface StaffRow {
  staffId: string;
  staffName: string;
  visits: number;
  revenue: number;
}

interface StaffTableProps {
  rows: StaffRow[];
}

export function StaffTable({ rows }: StaffTableProps) {
  if (rows.length === 0) {
    return <p className="text-sm text-zinc-400">No visits this week yet.</p>;
  }

  return (
    <table className="w-full text-sm">
      <thead>
        <tr className="text-left text-xs uppercase tracking-wide text-zinc-400 border-b border-zinc-100">
          <th className="pb-2 font-medium">Barber</th>
          <th className="pb-2 font-medium text-right">Visits</th>
          <th className="pb-2 font-medium text-right">Revenue (KES)</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((row) => (
          <tr key={row.staffId} className="border-b border-zinc-50 last:border-0">
            <td className="py-2 font-medium text-(--navy)">{row.staffName}</td>
            <td className="py-2 text-right text-zinc-700">{row.visits}</td>
            <td className="py-2 text-right text-zinc-700">{row.revenue.toLocaleString()}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
