import { createServerClient } from "@supabase/ssr";
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// Paths that do NOT require authentication.
const PUBLIC_PATHS = ["/login", "/auth/callback"];

function isPublic(pathname: string): boolean {
  return PUBLIC_PATHS.some(
    (p) => pathname === p || pathname.startsWith(p + "/"),
  );
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Always allow static assets and Next.js internals through.
  if (
    pathname.startsWith("/_next/") ||
    pathname.startsWith("/api/") ||
    pathname.match(/\.(?:ico|png|svg|jpg|jpeg|webp|woff2?)$/)
  ) {
    return NextResponse.next();
  }

  // Build a response we can attach refreshed cookies to.
  let response = NextResponse.next({
    request,
  });

  // Create a Supabase client that reads/writes cookies on the request/response.
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          // Re-create response so the refreshed cookies propagate to the browser.
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  // Refresh the session — this is the primary purpose of the proxy.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // If the user is not signed in and is hitting a protected route, redirect.
  if (!user && !isPublic(pathname)) {
    const loginUrl = new URL("/login", request.url);
    return NextResponse.redirect(loginUrl);
  }

  // If already signed in and hitting /login, let the login page itself redirect
  // to the role home (it reads the session server-side). No redirect here to
  // avoid a round-trip before the page has a chance to do it cleanly.

  return response;
}

export const config = {
  matcher: [
    /*
     * Match every path except static files, image optimisation routes, and
     * the Next.js internal _next prefix.  The proxy.md docs note that proxy
     * still runs for _next/data even when excluded, so we only need to guard
     * against accidentally blocking real static assets.
     */
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|webp|woff2?)).*)",
  ],
};
