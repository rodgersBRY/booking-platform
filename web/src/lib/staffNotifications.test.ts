// Compile-time pin only — see staffDay.test.ts / staffAuth.test.ts for why
// this repo pins JSON shapes at the type level instead of executing tests.
// Pins GET /api/v1/staff/notifications.

export {};

type StaffNotificationType =
  | "booking_created"
  | "booking_cancelled"
  | "booking_rescheduled"
  | "customer_checked_in";

type StaffNotificationEntry = {
  id: string;
  type: StaffNotificationType;
  title: string;
  body: string;
  bookingId: string | null;
  readAt: string | null;
  createdAt: string;
};

type StaffNotificationsResponse = {
  notifications: StaffNotificationEntry[];
  unreadCount: number;
};

const withUnread: StaffNotificationsResponse = {
  notifications: [
    {
      id: "notif-1",
      type: "booking_created",
      title: "New booking",
      body: "Brian Mwangi booked Haircut for Sat, Jul 25, 10:00 AM.",
      bookingId: "booking-1",
      readAt: null,
      createdAt: "2026-07-19T07:00:00.000Z",
    },
    {
      id: "notif-2",
      type: "customer_checked_in",
      title: "Customer checked in",
      body: "Faith Wanjiru has checked in.",
      bookingId: "booking-2",
      readAt: "2026-07-19T07:05:00.000Z",
      createdAt: "2026-07-19T06:50:00.000Z",
    },
  ],
  unreadCount: 1,
};

const empty: StaffNotificationsResponse = {
  notifications: [],
  unreadCount: 0,
};

void withUnread;
void empty;
