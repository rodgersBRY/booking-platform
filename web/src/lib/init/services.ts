import servicesJson from "./services.json";

type SeedItem = {
  service: string;
  price: number;
  currency?: string;
};

type ServiceSeed = Record<string, SeedItem[]>;

export type ServiceInsertRow = {
  name: string;
  category: string;
  description: null;
  duration_minutes: number;
  price: number;
  active: true;
};

const CATEGORY_DEFAULT_DURATIONS: Record<string, number> = {
  haircuts: 45,
  beards: 30,
  hair_dyes: 60,
  hair_relaxing: 45,
  hair_treatments: 45,
  nail_care: 45,
  facials: 45,
  massage: 60,
  body_treatments: 45,
  waxing: 30,
  spa_packages: 90,
};

function durationFor(category: string, name: string): number {
  const explicitDuration = name.match(/\((\d+)\s*mins?\)/i);
  if (explicitDuration) return Number(explicitDuration[1]);
  return CATEGORY_DEFAULT_DURATIONS[category] ?? 45;
}

export function flattenServiceSeed(seed: ServiceSeed): ServiceInsertRow[] {
  return Object.entries(seed).flatMap(([category, items]) =>
    items.map((item) => ({
      name: item.service,
      category,
      description: null,
      duration_minutes: durationFor(category, item.service),
      price: item.price,
      active: true,
    })),
  );
}

export const initialServices = flattenServiceSeed(servicesJson);
