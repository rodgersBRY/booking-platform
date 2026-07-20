// Compile-time pin only — see staffDay.test.ts / staffAuth.test.ts for why
// this repo pins JSON shapes at the type level instead of executing tests.
// Pins GET /api/v1/staff/services — the token-authed sibling of
// /v1/public/services, filtered to services eligible for the caller's own
// role via the service_roles table (not rolesForCategory()'s heuristic).

// No cross-module identifiers needed, but an empty export forces this file
// to be treated as a module rather than a global script — without it, its
// top-level type/const names collide with same-named ones in other .test.ts
// files under a global scope.
export {};

type StaffServicesResponse = {
  services: {
    id: string;
    name: string;
    category: string | null;
    durationMinutes: number;
    price: number;
  }[];
};

const withServices: StaffServicesResponse = {
  services: [
    {
      id: "service-1",
      name: "Skin Fade",
      category: "haircut",
      durationMinutes: 45,
      price: 500,
    },
    {
      id: "service-2",
      name: "Beard Trim",
      category: null,
      durationMinutes: 15,
      price: 200,
    },
  ],
};

const noEligibleServices: StaffServicesResponse = { services: [] };

type ServerError = { error: string };
const serverError: ServerError = {
  error: "Something went wrong. Please try again.",
};

void withServices;
void noEligibleServices;
void serverError;
