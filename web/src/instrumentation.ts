export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    const { seedOwner } = await import("@/lib/init/owner");
    await seedOwner();
  }
}
