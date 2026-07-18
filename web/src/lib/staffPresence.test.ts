import type { StaffPresence } from "./db/types";

// Compile-time pin only — see staffDay.test.ts / staffAuth.test.ts for why
// this repo pins JSON shapes at the type level instead of executing tests.

type StaffPresenceResponse = {
  presence: StaffPresence;
  presenceUpdatedAt: string;
};

const example: StaffPresenceResponse = {
  presence: "busy",
  presenceUpdatedAt: "2026-07-18T06:00:00.000Z",
};

// The PATCH body accepts exactly the four enum values — anything else must
// 400. Pin the enum here so a drift between db/types.ts and the route's
// validation list fails the build instead of shipping silently.
const allValues: StaffPresence[] = ["available", "busy", "on_break", "off_duty"];

void example;
void allValues;
