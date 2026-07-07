import { flattenServiceSeed } from "./services";

const rows = flattenServiceSeed({
  haircuts: [{ service: "Platinum Haircut", price: 1500, currency: "KES" }],
  beards: [{ service: "Royal Shave (30 mins)", price: 2000, currency: "KES" }],
});

const first: {
  name: string;
  category: string;
  description: null;
  duration_minutes: number;
  price: number;
  active: true;
} = rows[0];

const secondDuration: number = rows[1].duration_minutes;

void first;
void secondDuration;
