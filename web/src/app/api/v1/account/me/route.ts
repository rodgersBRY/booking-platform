import { getClientFromRequest, shapeClient } from "@/lib/clientAuth";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const client = await getClientFromRequest(request);
  if (!client) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  return NextResponse.json({ client: shapeClient(client) });
}
