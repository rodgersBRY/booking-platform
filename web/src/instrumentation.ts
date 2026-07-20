export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    const [{ seedOwner }, { seedServices }] = await Promise.all([
      import("@/lib/init/owner"),
      import("@/lib/init/serviceSeed"),
    ]);
    
    await seedOwner();
    await seedServices();
  }
}
