import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

const MAX_BYTES = 5 * 1024 * 1024; // 5MB
const ALLOWED_TYPES: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
};

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const caller = await getCurrentStaff();
  if (!caller) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await params;
  // Owner can set anyone's photo; everyone else can only set their own.
  if (caller.role !== "owner" && caller.id !== id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  let formData: FormData;
  try {
    formData = await request.formData();
  } catch {
    return NextResponse.json({ error: "Invalid form data" }, { status: 400 });
  }

  const file = formData.get("file");
  if (!(file instanceof File)) {
    return NextResponse.json({ error: "file is required" }, { status: 400 });
  }

  const ext = ALLOWED_TYPES[file.type];
  if (!ext) {
    return NextResponse.json(
      { error: "Unsupported file type — use JPEG, PNG, or WebP" },
      { status: 400 },
    );
  }
  if (file.size > MAX_BYTES) {
    return NextResponse.json(
      { error: "File too large — max 5MB" },
      { status: 400 },
    );
  }

  const admin = createAdminClient();

  // Verify the target staff row exists.
  const { data: target, error: targetErr } = await admin
    .from("staff")
    .select("id")
    .eq("id", id)
    .maybeSingle();
  if (targetErr || !target) {
    return NextResponse.json({ error: "Staff not found" }, { status: 404 });
  }

  // Versioned filename so the CDN/public URL changes on every upload
  // (avoids a browser serving a stale cached photo after a change).
  const path = `${id}/${Date.now()}.${ext}`;
  const bytes = await file.arrayBuffer();

  const { error: uploadErr } = await admin.storage
    .from("staff-avatars")
    .upload(path, bytes, { contentType: file.type, upsert: true });

  if (uploadErr) {
    return NextResponse.json({ error: uploadErr.message }, { status: 500 });
  }

  const { data: publicUrlData } = admin.storage
    .from("staff-avatars")
    .getPublicUrl(path);
  const avatarUrl = publicUrlData.publicUrl;

  const { error: updateErr } = await admin
    .from("staff")
    .update({ avatar_url: avatarUrl })
    .eq("id", id);

  if (updateErr) {
    return NextResponse.json({ error: updateErr.message }, { status: 500 });
  }

  return NextResponse.json({ avatarUrl });
}
