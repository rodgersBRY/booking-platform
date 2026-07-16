import "server-only";
import { NextRequest, NextResponse } from "next/server";
import { timingSafeEqual, createHash } from "crypto";

export function assertAutomationKey(request: NextRequest): NextResponse | null {
  const key = process.env.AUTOMATION_API_KEY;
  if (!key)
    return NextResponse.json(
      { error: "Automation key not configured" },
      { status: 500 },
    );

  const provided = request.headers.get("x-automation-key") ?? "";
  if (!provided)
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  // Constant-time comparison to prevent timing attacks.
  const a = createHash("sha256").update(provided).digest();
  const b = createHash("sha256").update(key).digest();
  if (a.length !== b.length || !timingSafeEqual(a, b))
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  return null; // authorized
}
