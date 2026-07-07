import { defaultAvailabilityForBarber } from "./availability";

const rows = defaultAvailabilityForBarber("barber-1");

const first: {
  barber_id: string;
  weekday: number;
  start_time: string;
  end_time: string;
} = rows[0];

const rowCount: 7 = rows.length as 7;

void first;
void rowCount;
