"use client";

import { useRef, useState } from "react";
import { uploadStaffAvatar } from "@/lib/api/staff";

const MAX_AVATAR_BYTES = 5 * 1024 * 1024;

function initials(name: string): string {
  return name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]!.toUpperCase())
    .join("");
}

type Props = {
  staffId: string;
  name: string;
  avatarUrl: string | null;
};

/** Your own photo in the nav header — click to change it. */
export function HeaderAvatar({ staffId, name, avatarUrl }: Props) {
  const [url, setUrl] = useState(avatarUrl);
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  async function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    if (file.size > MAX_AVATAR_BYTES) {
      alert("File too large — max 5MB.");
      return;
    }
    setUploading(true);
    try {
      const newUrl = await uploadStaffAvatar(staffId, file);
      setUrl(newUrl);
    } catch (err) {
      alert((err as Error).message);
    } finally {
      setUploading(false);
    }
  }

  return (
    <>
      <input
        ref={fileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        onChange={handleChange}
      />
      <button
        type="button"
        onClick={() => fileInputRef.current?.click()}
        disabled={uploading}
        title="Change your photo"
        className="w-9 h-9 rounded-full overflow-hidden flex items-center justify-center text-xs font-semibold shrink-0 border border-white/20 transition-opacity hover:opacity-80 disabled:opacity-50"
        style={url ? undefined : { background: "var(--brass)", color: "#fff" }}
      >
        {uploading ? (
          "…"
        ) : url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={url} alt={name} className="w-full h-full object-cover" />
        ) : (
          initials(name)
        )}
      </button>
    </>
  );
}
