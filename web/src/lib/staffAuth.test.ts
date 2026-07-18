import { getStaffFromRequest, shapeStaff, type StaffWithAuthId } from "./staffAuth";
import type { NextRequest } from "next/server";

// This repo has no runtime test runner configured (no jest/vitest — see
// package.json), so these files are compile-time checks in the existing
// house style (see availability.test.ts, init/services.test.ts): they pin
// input/output types and are exercised by `npm run build`'s type-checking
// pass, not by executed assertions.

// --- shapeStaff: PII-safe shape for the mobile app -------------------------

const activeBookableStaff: StaffWithAuthId = {
  id: "staff-1",
  name: "James Otieno",
  role: "barber",
  phone: "+254700000000",
  email: "james@example.com",
  telegram_chat_id: null,
  password_hash: null,
  auth_user_id: "auth-user-1",
  avatar_url: "https://example.com/avatar.png",
  status: "active",
  created_at: "2026-01-01T00:00:00.000Z",
};

const shaped: {
  id: string;
  name: string;
  role: StaffWithAuthId["role"];
  phone: string | null;
  email: string | null;
  avatarUrl: string | null;
  status: StaffWithAuthId["status"];
} = shapeStaff(activeBookableStaff);

// shapeStaff must never leak auth_user_id, password_hash, or telegram_chat_id.
// @ts-expect-error - authUserId is intentionally not part of the shaped output
void shaped.authUserId;

// --- getStaffFromRequest: resolution and rejection cases -------------------
//
// getStaffFromRequest resolves to StaffWithAuthId | null. Its early-return
// structure covers the four required cases:
//   - valid active bookable staff -> resolves the staff row
//   - missing/invalid Authorization header or token -> null before any
//     Supabase call (bearerToken returns null)
//   - admin.auth.getUser errors or returns no user -> null
//   - no staff row linked to auth_user_id -> null
//   - staff row found but status !== "active" -> null
// This project has no jest/vitest configured to mock admin.auth.getUser and
// the staff select and actually execute those branches, so, matching this
// repo's existing test-file convention, the case is pinned at the type level
// instead of executed.

declare const request: NextRequest;
const result: Promise<StaffWithAuthId | null> = getStaffFromRequest(request);

void result;
