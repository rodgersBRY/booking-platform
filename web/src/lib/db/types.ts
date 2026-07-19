// Hand-written types mirroring supabase/migrations/0001_init.sql.
// Replaceable later with generated types: `supabase gen types typescript`.

export type StaffRole =
  | "owner"
  | "receptionist"
  | "barber"
  | "beautician"
  | "masseuse";
export type ClientStatus = "active" | "inactive" | "blocked";
export type StaffPresence = "available" | "busy" | "on_break" | "off_duty";
export type AcquisitionSource =
  | "social"
  | "website"
  | "referral"
  | "walkby"
  | "whatsapp"
  | "other";
export type BookingChannel = "walkin" | "online" | "whatsapp" | "phone";
export type BookingStatus =
  | "booked"
  | "arrived"
  | "in_chair"
  | "completed"
  | "late"
  | "no_show"
  | "cancelled";
export type QueueChoice = "waiting" | "switched" | "notify";
export type QueueStatus =
  | "waiting"
  | "notified"
  | "in_chair"
  | "served"
  | "left";
export type PaymentMethod = "cash" | "mpesa" | "card";
export type LoyaltyTxnType = "earn" | "redeem" | "referral_bonus" | "adjust";
export type MessageType =
  | "reminder_24h"
  | "reminder_2h"
  | "review_request"
  | "reengagement"
  | "queue_notify"
  | "owner_alert";
export type MessageStatus = "sent" | "failed";
export type NotificationType =
  | "booking_confirmed"
  | "booking_cancelled"
  | "booking_completed"
  | "appointment_reminder"
  | "promotion"
  | "new_service"
  | "loyalty_reward";

export interface Staff {
  id: string;
  name: string;
  role: StaffRole;
  phone: string | null;
  email: string | null;
  telegram_chat_id: string | null;
  password_hash: string | null;
  auth_user_id: string | null;
  avatar_url: string | null;
  status: ClientStatus;
  presence: StaffPresence;
  presence_updated_at: string | null;
  created_at: string;
}

export interface Service {
  id: string;
  name: string;
  category: string | null;
  description: string | null;
  duration_minutes: number;
  price: number;
  active: boolean;
  created_at: string;
}

export interface ServiceRole {
  service_id: string;
  role: StaffRole;
}

export interface Client {
  id: string;
  name: string;
  phone: string;
  email: string | null;
  preferred_staff_id: string | null;
  acquisition_source: AcquisitionSource | null;
  referred_by_client_id: string | null;
  loyalty_points: number;
  total_visits: number;
  last_visit_at: string | null;
  status: ClientStatus;
  created_at: string;
}

export interface Booking {
  id: string;
  client_id: string;
  staff_id: string | null;
  service_id: string;
  scheduled_start: string;
  scheduled_end: string;
  channel: BookingChannel;
  status: BookingStatus;
  created_by_staff_id: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface QueueEntry {
  id: string;
  client_id: string;
  staff_id: string | null;
  booking_id: string | null;
  joined_at: string;
  estimated_wait_minutes: number | null;
  choice: QueueChoice;
  status: QueueStatus;
  notified_at: string | null;
}

export interface Notification {
  id: string;
  client_id: string;
  type: NotificationType;
  title: string;
  body: string;
  booking_id: string | null;
  read: boolean;
  created_at: string;
}

export interface Visit {
  id: string;
  booking_id: string | null;
  client_id: string;
  staff_id: string | null;
  service_id: string | null;
  completed_at: string;
  amount_charged: number;
  payment_method: PaymentMethod | null;
  loyalty_points_earned: number;
  review_requested: boolean;
  created_at: string;
}
