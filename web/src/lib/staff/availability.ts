export type AvailabilityInsertRow = {
  staff_id: string;
  weekday: number;
  start_time: string;
  end_time: string;
};

const DEFAULT_WEEKLY_HOURS = [
  { weekday: 1, start_time: "09:00", end_time: "19:00" },
  { weekday: 2, start_time: "09:00", end_time: "19:00" },
  { weekday: 3, start_time: "09:00", end_time: "19:00" },
  { weekday: 4, start_time: "09:00", end_time: "19:00" },
  { weekday: 5, start_time: "09:00", end_time: "19:00" },
  { weekday: 6, start_time: "13:00", end_time: "21:00" },
  { weekday: 0, start_time: "13:00", end_time: "21:00" },
] as const;

export function defaultAvailabilityForBarber(
  staffId: string,
): AvailabilityInsertRow[] {
  return DEFAULT_WEEKLY_HOURS.map((hours) => ({
    staff_id: staffId,
    ...hours,
  }));
}
