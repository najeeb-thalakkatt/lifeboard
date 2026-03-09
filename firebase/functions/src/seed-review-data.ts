#!/usr/bin/env npx ts-node
/**
 * Seed realistic demo data for Apple App Store review.
 *
 * Creates two users (a couple) sharing a space with boards, tasks,
 * chores, shopping list items, comments, and activity feed entries.
 *
 * Usage (from firebase/functions/):
 *   npm run seed            # seed data
 *   npm run seed:clean      # remove all seed data
 *
 * All IDs are prefixed with "seed_" for easy cleanup.
 * Script is idempotent — safe to run multiple times.
 */

import * as admin from "firebase-admin";

// ── Initialise Firebase Admin ────────────────────────────────
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "lifeboard-8cd26" });
}

const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;

// ── Date Helpers ─────────────────────────────────────────────

const now = new Date();

function daysAgo(n: number): Date {
  const d = new Date(now);
  d.setDate(d.getDate() - n);
  return d;
}

function daysFromNow(n: number): Date {
  const d = new Date(now);
  d.setDate(d.getDate() + n);
  return d;
}

function hoursAgo(n: number): Date {
  const d = new Date(now);
  d.setHours(d.getHours() - n);
  return d;
}

function toTs(d: Date): admin.firestore.Timestamp {
  return Timestamp.fromDate(d);
}

function dateStr(d: Date): string {
  return d.toISOString().split("T")[0]; // YYYY-MM-DD
}

// ── Constants ────────────────────────────────────────────────

const SARAH_ID = "seed_sarah_001";
const JAMES_ID = "seed_james_002";
const SPACE_ID = "seed_space_home";

const BOARD_HOME = "seed_board_home_projects";
const BOARD_WEEKEND = "seed_board_weekend";
const BOARD_GOALS = "seed_board_goals";

// ── Users ────────────────────────────────────────────────────

const users = [
  {
    id: SARAH_ID,
    displayName: "Sarah Mitchell",
    email: "sarah.review@lifeboard.app",
    photoUrl: "",
    moodEmoji: "☀️",
    spaceIds: [SPACE_ID],
    notificationPrefs: { pushEnabled: true, emailEnabled: false },
    createdAt: toTs(daysAgo(21)),
  },
  {
    id: JAMES_ID,
    displayName: "James Mitchell",
    email: "james.review@lifeboard.app",
    photoUrl: "",
    moodEmoji: "💪",
    spaceIds: [SPACE_ID],
    notificationPrefs: { pushEnabled: true, emailEnabled: false },
    createdAt: toTs(daysAgo(20)),
  },
];

// ── Space ────────────────────────────────────────────────────

const space = {
  name: "Our Home",
  members: {
    [SARAH_ID]: { role: "owner", joinedAt: toTs(daysAgo(21)) },
    [JAMES_ID]: { role: "member", joinedAt: toTs(daysAgo(20)) },
  },
  inviteCode: "SEED42",
  themes: ["Home", "Family", "Finances"],
  createdAt: toTs(daysAgo(21)),
};

// ── Boards ───────────────────────────────────────────────────

const boards = [
  {
    id: BOARD_HOME,
    name: "Home Projects",
    theme: "Home",
    columns: ["To Do", "In Progress", "Done"],
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(18)),
  },
  {
    id: BOARD_WEEKEND,
    name: "Weekend Plans",
    theme: "Family",
    columns: ["To Do", "In Progress", "Done"],
    createdBy: JAMES_ID,
    createdAt: toTs(daysAgo(16)),
  },
  {
    id: BOARD_GOALS,
    name: "Family Goals",
    theme: "Finances",
    columns: ["To Do", "In Progress", "Done"],
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(14)),
  },
];

// ── Tasks ────────────────────────────────────────────────────

const tasks = [
  // ── Home Projects (7 tasks) ──
  {
    id: "seed_task_faucet",
    title: "Fix leaking kitchen faucet",
    description: "The kitchen faucet has been dripping. Need to replace the washer or the whole cartridge.",
    status: "done",
    boardId: BOARD_HOME,
    assignees: [JAMES_ID],
    dueDate: toTs(daysAgo(5)),
    emojiTag: "🏡",
    subtasks: [
      { id: "st1", title: "Buy replacement cartridge", completed: true },
      { id: "st2", title: "Turn off water supply", completed: true },
      { id: "st3", title: "Replace and test", completed: true },
    ],
    attachments: [],
    isWeeklyTask: false,
    order: 0,
    completedAt: toTs(daysAgo(3)),
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(15)),
    updatedAt: toTs(daysAgo(3)),
  },
  {
    id: "seed_task_garage",
    title: "Organize the garage",
    description: "Sort through boxes, set up shelving, donate what we don't need.",
    status: "in_progress",
    boardId: BOARD_HOME,
    assignees: [JAMES_ID, SARAH_ID],
    dueDate: toTs(daysFromNow(3)),
    emojiTag: "🏡",
    subtasks: [
      { id: "st1", title: "Sort through storage boxes", completed: true },
      { id: "st2", title: "Install wall shelving", completed: false },
      { id: "st3", title: "Donate old items", completed: false },
    ],
    attachments: [],
    isWeeklyTask: false,
    order: 0,
    createdBy: JAMES_ID,
    createdAt: toTs(daysAgo(10)),
    updatedAt: toTs(daysAgo(1)),
  },
  {
    id: "seed_task_bedroom",
    title: "Repaint bedroom accent wall",
    description: "We picked out 'Sage Mist' from the paint store. Need painter's tape and drop cloths.",
    status: "todo",
    boardId: BOARD_HOME,
    assignees: [SARAH_ID],
    dueDate: toTs(daysFromNow(10)),
    emojiTag: "🏡",
    subtasks: [
      { id: "st1", title: "Buy paint + supplies", completed: false },
      { id: "st2", title: "Prep the wall", completed: false },
      { id: "st3", title: "Paint!", completed: false },
    ],
    attachments: [],
    isWeeklyTask: false,
    order: 1,
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(7)),
    updatedAt: toTs(daysAgo(7)),
  },
  {
    id: "seed_task_smoke",
    title: "Replace smoke detector batteries",
    description: "All 4 detectors need fresh 9V batteries. Check expiry dates too.",
    status: "done",
    boardId: BOARD_HOME,
    assignees: [JAMES_ID],
    emojiTag: "🏡",
    subtasks: [],
    attachments: [],
    isWeeklyTask: false,
    order: 1,
    completedAt: toTs(daysAgo(8)),
    createdBy: JAMES_ID,
    createdAt: toTs(daysAgo(12)),
    updatedAt: toTs(daysAgo(8)),
  },
  {
    id: "seed_task_dishwasher",
    title: "Research new dishwasher options",
    description: "Current one is on its last legs. Compare Bosch, LG, and Samsung models.",
    status: "todo",
    boardId: BOARD_HOME,
    assignees: [SARAH_ID],
    emojiTag: "🏡",
    subtasks: [
      { id: "st1", title: "Check Consumer Reports reviews", completed: false },
      { id: "st2", title: "Compare prices at Home Depot vs Lowe's", completed: false },
    ],
    attachments: [],
    isWeeklyTask: false,
    order: 2,
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(5)),
    updatedAt: toTs(daysAgo(5)),
  },
  {
    id: "seed_task_gutters",
    title: "Clean out gutters",
    description: "Lots of leaves from last fall. Grab the ladder and gloves.",
    status: "todo",
    boardId: BOARD_HOME,
    assignees: [JAMES_ID],
    dueDate: toTs(daysFromNow(7)),
    emojiTag: "🏡",
    subtasks: [],
    attachments: [],
    isWeeklyTask: false,
    order: 3,
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(4)),
    updatedAt: toTs(daysAgo(4)),
  },
  {
    id: "seed_task_hinge",
    title: "Fix squeaky door hinge",
    description: "The bedroom door hinge squeaks every time. WD-40 or replace.",
    status: "done",
    boardId: BOARD_HOME,
    assignees: [JAMES_ID],
    emojiTag: "🏡",
    subtasks: [],
    attachments: [],
    isWeeklyTask: false,
    order: 2,
    completedAt: toTs(daysAgo(6)),
    createdBy: JAMES_ID,
    createdAt: toTs(daysAgo(9)),
    updatedAt: toTs(daysAgo(6)),
  },

  // ── Weekend Plans (4 tasks) ──
  {
    id: "seed_task_datenight",
    title: "Plan date night this Friday",
    description: "Try that new Italian place downtown. Make a reservation for 7:30.",
    status: "done",
    boardId: BOARD_WEEKEND,
    assignees: [SARAH_ID],
    dueDate: toTs(daysAgo(2)),
    emojiTag: "❤️",
    subtasks: [
      { id: "st1", title: "Pick restaurant", completed: true },
      { id: "st2", title: "Make reservation", completed: true },
      { id: "st3", title: "Arrange babysitter", completed: true },
    ],
    attachments: [],
    isWeeklyTask: false,
    order: 0,
    completedAt: toTs(daysAgo(2)),
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(8)),
    updatedAt: toTs(daysAgo(2)),
  },
  {
    id: "seed_task_farmers",
    title: "Farmers market Saturday morning",
    description: "Get fresh veggies, that honey we liked, and flowers for the table.",
    status: "in_progress",
    boardId: BOARD_WEEKEND,
    assignees: [SARAH_ID, JAMES_ID],
    dueDate: toTs(daysFromNow(2)),
    emojiTag: "☀️",
    subtasks: [
      { id: "st1", title: "Make list of what we need", completed: true },
      { id: "st2", title: "Bring reusable bags", completed: false },
    ],
    attachments: [],
    isWeeklyTask: false,
    order: 0,
    createdBy: JAMES_ID,
    createdAt: toTs(daysAgo(4)),
    updatedAt: toTs(hoursAgo(6)),
  },
  {
    id: "seed_task_camping",
    title: "Book camping trip for next month",
    description: "Check availability at Lake Tahoe campgrounds. Need 2 nights.",
    status: "todo",
    boardId: BOARD_WEEKEND,
    assignees: [JAMES_ID],
    dueDate: toTs(daysFromNow(14)),
    emojiTag: "☀️",
    subtasks: [
      { id: "st1", title: "Research campgrounds", completed: false },
      { id: "st2", title: "Check gear condition", completed: false },
      { id: "st3", title: "Book site", completed: false },
    ],
    attachments: [],
    isWeeklyTask: false,
    order: 1,
    createdBy: JAMES_ID,
    createdAt: toTs(daysAgo(3)),
    updatedAt: toTs(daysAgo(3)),
  },
  {
    id: "seed_task_movie",
    title: "Movie night picks",
    description: "Each pick 2 movies for this weekend. Winner gets to skip dishes 😄",
    status: "todo",
    boardId: BOARD_WEEKEND,
    assignees: [SARAH_ID, JAMES_ID],
    dueDate: toTs(daysFromNow(1)),
    emojiTag: "❤️",
    subtasks: [
      { id: "st1", title: "Sarah's picks", completed: false },
      { id: "st2", title: "James's picks", completed: false },
    ],
    attachments: [],
    isWeeklyTask: false,
    order: 2,
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(1)),
    updatedAt: toTs(daysAgo(1)),
  },

  // ── Family Goals (4 tasks) ──
  {
    id: "seed_task_savings",
    title: "Set up joint savings goal",
    description: "Open a high-yield savings account. Target: $5,000 emergency fund.",
    status: "done",
    boardId: BOARD_GOALS,
    assignees: [SARAH_ID, JAMES_ID],
    emojiTag: "💰",
    subtasks: [
      { id: "st1", title: "Compare savings accounts", completed: true },
      { id: "st2", title: "Open account", completed: true },
      { id: "st3", title: "Set up auto-transfer", completed: true },
    ],
    attachments: [],
    isWeeklyTask: false,
    order: 0,
    completedAt: toTs(daysAgo(5)),
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(14)),
    updatedAt: toTs(daysAgo(5)),
  },
  {
    id: "seed_task_budget",
    title: "Review monthly budget together",
    description: "Go through last month's spending. Check subscriptions we can cancel.",
    status: "in_progress",
    boardId: BOARD_GOALS,
    assignees: [SARAH_ID],
    dueDate: toTs(daysFromNow(2)),
    emojiTag: "💰",
    subtasks: [
      { id: "st1", title: "Export bank statements", completed: true },
      { id: "st2", title: "Categorize expenses", completed: false },
      { id: "st3", title: "Identify savings opportunities", completed: false },
    ],
    attachments: [],
    isWeeklyTask: false,
    order: 0,
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(6)),
    updatedAt: toTs(daysAgo(1)),
  },
  {
    id: "seed_task_mealprep",
    title: "Start meal prep Sundays",
    description: "Plan and prep meals for the week every Sunday afternoon. Saves money and time!",
    status: "todo",
    boardId: BOARD_GOALS,
    assignees: [SARAH_ID, JAMES_ID],
    dueDate: toTs(daysFromNow(4)),
    emojiTag: "🧠",
    subtasks: [
      { id: "st1", title: "Find 5 easy recipes", completed: false },
      { id: "st2", title: "Buy meal prep containers", completed: false },
    ],
    attachments: [],
    isWeeklyTask: false,
    order: 1,
    createdBy: JAMES_ID,
    createdAt: toTs(daysAgo(3)),
    updatedAt: toTs(daysAgo(3)),
  },
  {
    id: "seed_task_jog",
    title: "Morning jog routine — 3x/week",
    description: "Start with 20-minute jogs Mon/Wed/Fri. Build up to 30 min by next month.",
    status: "in_progress",
    boardId: BOARD_GOALS,
    assignees: [JAMES_ID],
    emojiTag: "💪",
    subtasks: [
      { id: "st1", title: "Get new running shoes", completed: true },
      { id: "st2", title: "Map a 2-mile route", completed: true },
      { id: "st3", title: "Complete first full week", completed: false },
    ],
    attachments: [],
    isWeeklyTask: false,
    order: 1,
    createdBy: JAMES_ID,
    createdAt: toTs(daysAgo(7)),
    updatedAt: toTs(daysAgo(1)),
  },
];

// ── Chores ───────────────────────────────────────────────────

const chores = [
  {
    id: "seed_chore_vacuum",
    name: "Vacuum living room",
    emoji: "🧹",
    recurrenceType: "weekly",
    recurrenceInterval: 1,
    recurrenceDaysOfWeek: [6], // Saturday
    recurrenceDayOfMonth: 1,
    recurrenceMode: "fixed",
    assigneeId: JAMES_ID,
    nextDueDate: toTs(daysFromNow(2)),
    lastCompletedAt: toTs(daysAgo(5)),
    lastCompletedBy: JAMES_ID,
    priority: "regular",
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(18)),
    order: 0,
    isArchived: false,
  },
  {
    id: "seed_chore_trash",
    name: "Take out trash & recycling",
    emoji: "🗑️",
    recurrenceType: "biweekly",
    recurrenceInterval: 1,
    recurrenceDaysOfWeek: [3], // Wednesday
    recurrenceDayOfMonth: 1,
    recurrenceMode: "fixed",
    assigneeId: JAMES_ID,
    nextDueDate: toTs(daysFromNow(4)),
    lastCompletedAt: toTs(daysAgo(3)),
    lastCompletedBy: JAMES_ID,
    priority: "regular",
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(18)),
    order: 1,
    isArchived: false,
  },
  {
    id: "seed_chore_laundry",
    name: "Do laundry",
    emoji: "👕",
    recurrenceType: "every_n_days",
    recurrenceInterval: 3,
    recurrenceDaysOfWeek: [],
    recurrenceDayOfMonth: 1,
    recurrenceMode: "floating",
    assigneeId: SARAH_ID,
    nextDueDate: toTs(daysFromNow(1)),
    lastCompletedAt: toTs(daysAgo(2)),
    lastCompletedBy: SARAH_ID,
    priority: "regular",
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(18)),
    order: 2,
    isArchived: false,
  },
  {
    id: "seed_chore_plants",
    name: "Water indoor plants",
    emoji: "🌿",
    recurrenceType: "weekly",
    recurrenceInterval: 1,
    recurrenceDaysOfWeek: [1, 4], // Mon & Thu
    recurrenceDayOfMonth: 1,
    recurrenceMode: "fixed",
    assigneeId: SARAH_ID,
    nextDueDate: toTs(daysFromNow(1)),
    lastCompletedAt: toTs(daysAgo(1)),
    lastCompletedBy: SARAH_ID,
    priority: "regular",
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(18)),
    order: 3,
    isArchived: false,
  },
  {
    id: "seed_chore_bathrooms",
    name: "Clean bathrooms",
    emoji: "🚿",
    recurrenceType: "weekly",
    recurrenceInterval: 1,
    recurrenceDaysOfWeek: [7], // Sunday
    recurrenceDayOfMonth: 1,
    recurrenceMode: "fixed",
    assigneeId: null,
    nextDueDate: toTs(daysFromNow(3)),
    lastCompletedAt: toTs(daysAgo(4)),
    lastCompletedBy: JAMES_ID,
    priority: "regular",
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(18)),
    order: 4,
    isArchived: false,
  },
  {
    id: "seed_chore_mop",
    name: "Mop kitchen floor",
    emoji: "🧽",
    recurrenceType: "weekly",
    recurrenceInterval: 1,
    recurrenceDaysOfWeek: [5], // Friday
    recurrenceDayOfMonth: 1,
    recurrenceMode: "fixed",
    assigneeId: JAMES_ID,
    nextDueDate: toTs(daysAgo(2)), // OVERDUE!
    lastCompletedAt: toTs(daysAgo(9)),
    lastCompletedBy: JAMES_ID,
    priority: "now",
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(18)),
    order: 5,
    isArchived: false,
  },
  {
    id: "seed_chore_grocery",
    name: "Weekly grocery run",
    emoji: "🛒",
    recurrenceType: "weekly",
    recurrenceInterval: 1,
    recurrenceDaysOfWeek: [6], // Saturday
    recurrenceDayOfMonth: 1,
    recurrenceMode: "fixed",
    assigneeId: null,
    nextDueDate: toTs(daysFromNow(2)),
    lastCompletedAt: toTs(daysAgo(5)),
    lastCompletedBy: SARAH_ID,
    priority: "regular",
    createdBy: JAMES_ID,
    createdAt: toTs(daysAgo(18)),
    order: 6,
    isArchived: false,
  },
  {
    id: "seed_chore_sheets",
    name: "Change bed sheets",
    emoji: "🛏️",
    recurrenceType: "biweekly",
    recurrenceInterval: 1,
    recurrenceDaysOfWeek: [7], // Sunday
    recurrenceDayOfMonth: 1,
    recurrenceMode: "fixed",
    assigneeId: null,
    nextDueDate: toTs(daysFromNow(5)),
    lastCompletedAt: toTs(daysAgo(9)),
    lastCompletedBy: SARAH_ID,
    priority: "whenever",
    createdBy: SARAH_ID,
    createdAt: toTs(daysAgo(18)),
    order: 7,
    isArchived: false,
  },
];

// ── Chore Completions (~20 over last 2-3 weeks) ─────────────

const choreCompletions = [
  // Vacuum completions
  { id: "seed_cc_01", choreId: "seed_chore_vacuum", choreName: "Vacuum living room", choreEmoji: "🧹", completedBy: JAMES_ID, completedAt: toTs(daysAgo(19)), date: dateStr(daysAgo(19)) },
  { id: "seed_cc_02", choreId: "seed_chore_vacuum", choreName: "Vacuum living room", choreEmoji: "🧹", completedBy: JAMES_ID, completedAt: toTs(daysAgo(12)), date: dateStr(daysAgo(12)) },
  { id: "seed_cc_03", choreId: "seed_chore_vacuum", choreName: "Vacuum living room", choreEmoji: "🧹", completedBy: JAMES_ID, completedAt: toTs(daysAgo(5)), date: dateStr(daysAgo(5)), hatTipBy: SARAH_ID },
  // Trash completions
  { id: "seed_cc_04", choreId: "seed_chore_trash", choreName: "Take out trash & recycling", choreEmoji: "🗑️", completedBy: JAMES_ID, completedAt: toTs(daysAgo(17)), date: dateStr(daysAgo(17)) },
  { id: "seed_cc_05", choreId: "seed_chore_trash", choreName: "Take out trash & recycling", choreEmoji: "🗑️", completedBy: JAMES_ID, completedAt: toTs(daysAgo(3)), date: dateStr(daysAgo(3)) },
  // Laundry completions
  { id: "seed_cc_06", choreId: "seed_chore_laundry", choreName: "Do laundry", choreEmoji: "👕", completedBy: SARAH_ID, completedAt: toTs(daysAgo(14)), date: dateStr(daysAgo(14)) },
  { id: "seed_cc_07", choreId: "seed_chore_laundry", choreName: "Do laundry", choreEmoji: "👕", completedBy: SARAH_ID, completedAt: toTs(daysAgo(11)), date: dateStr(daysAgo(11)) },
  { id: "seed_cc_08", choreId: "seed_chore_laundry", choreName: "Do laundry", choreEmoji: "👕", completedBy: SARAH_ID, completedAt: toTs(daysAgo(8)), date: dateStr(daysAgo(8)) },
  { id: "seed_cc_09", choreId: "seed_chore_laundry", choreName: "Do laundry", choreEmoji: "👕", completedBy: JAMES_ID, completedAt: toTs(daysAgo(5)), date: dateStr(daysAgo(5)) },
  { id: "seed_cc_10", choreId: "seed_chore_laundry", choreName: "Do laundry", choreEmoji: "👕", completedBy: SARAH_ID, completedAt: toTs(daysAgo(2)), date: dateStr(daysAgo(2)), hatTipBy: JAMES_ID },
  // Water plants
  { id: "seed_cc_11", choreId: "seed_chore_plants", choreName: "Water indoor plants", choreEmoji: "🌿", completedBy: SARAH_ID, completedAt: toTs(daysAgo(4)), date: dateStr(daysAgo(4)) },
  { id: "seed_cc_12", choreId: "seed_chore_plants", choreName: "Water indoor plants", choreEmoji: "🌿", completedBy: SARAH_ID, completedAt: toTs(daysAgo(1)), date: dateStr(daysAgo(1)) },
  // Clean bathrooms
  { id: "seed_cc_13", choreId: "seed_chore_bathrooms", choreName: "Clean bathrooms", choreEmoji: "🚿", completedBy: JAMES_ID, completedAt: toTs(daysAgo(11)), date: dateStr(daysAgo(11)), hatTipBy: SARAH_ID },
  { id: "seed_cc_14", choreId: "seed_chore_bathrooms", choreName: "Clean bathrooms", choreEmoji: "🚿", completedBy: SARAH_ID, completedAt: toTs(daysAgo(4)), date: dateStr(daysAgo(4)) },
  // Mop kitchen (last done 9 days ago — overdue!)
  { id: "seed_cc_15", choreId: "seed_chore_mop", choreName: "Mop kitchen floor", choreEmoji: "🧽", completedBy: JAMES_ID, completedAt: toTs(daysAgo(16)), date: dateStr(daysAgo(16)) },
  { id: "seed_cc_16", choreId: "seed_chore_mop", choreName: "Mop kitchen floor", choreEmoji: "🧽", completedBy: JAMES_ID, completedAt: toTs(daysAgo(9)), date: dateStr(daysAgo(9)) },
  // Grocery run
  { id: "seed_cc_17", choreId: "seed_chore_grocery", choreName: "Weekly grocery run", choreEmoji: "🛒", completedBy: SARAH_ID, completedAt: toTs(daysAgo(12)), date: dateStr(daysAgo(12)) },
  { id: "seed_cc_18", choreId: "seed_chore_grocery", choreName: "Weekly grocery run", choreEmoji: "🛒", completedBy: JAMES_ID, completedAt: toTs(daysAgo(5)), date: dateStr(daysAgo(5)), hatTipBy: SARAH_ID },
  // Change sheets
  { id: "seed_cc_19", choreId: "seed_chore_sheets", choreName: "Change bed sheets", choreEmoji: "🛏️", completedBy: SARAH_ID, completedAt: toTs(daysAgo(9)), date: dateStr(daysAgo(9)) },
  { id: "seed_cc_20", choreId: "seed_chore_sheets", choreName: "Change bed sheets", choreEmoji: "🛏️", completedBy: SARAH_ID, completedAt: toTs(daysAgo(16)), date: dateStr(daysAgo(16)) },
];

// ── HomePad Items (Shopping List) ────────────────────────────

const homePadItems = [
  // ── to_buy (8 items) ──
  { id: "seed_hp_milk", name: "Milk (whole)", emoji: "🥛", category: "Groceries", subcategory: "Dairy", status: "to_buy", frequency: "weekly", isCustom: false, isHidden: false, addedBy: SARAH_ID, addedAt: toTs(daysAgo(1)), quantity: 1, order: 0, createdAt: toTs(daysAgo(1)) },
  { id: "seed_hp_eggs", name: "Eggs (dozen)", emoji: "🥚", category: "Groceries", subcategory: "Dairy", status: "to_buy", frequency: "weekly", isCustom: false, isHidden: false, addedBy: SARAH_ID, addedAt: toTs(daysAgo(1)), quantity: 2, order: 1, createdAt: toTs(daysAgo(1)) },
  { id: "seed_hp_chicken", name: "Chicken breast", emoji: "🍗", category: "Groceries", subcategory: "Meat", status: "to_buy", frequency: "weekly", isCustom: false, isHidden: false, addedBy: JAMES_ID, addedAt: toTs(hoursAgo(8)), quantity: 1, note: "Get the organic ones", order: 2, createdAt: toTs(hoursAgo(8)) },
  { id: "seed_hp_avocados", name: "Avocados", emoji: "🥑", category: "Groceries", subcategory: "Produce", status: "to_buy", frequency: "weekly", isCustom: false, isHidden: false, addedBy: SARAH_ID, addedAt: toTs(hoursAgo(6)), quantity: 4, order: 3, createdAt: toTs(hoursAgo(6)) },
  { id: "seed_hp_bread", name: "Sourdough bread", emoji: "🍞", category: "Groceries", subcategory: "Bakery", status: "to_buy", frequency: "weekly", isCustom: false, isHidden: false, addedBy: JAMES_ID, addedAt: toTs(daysAgo(1)), quantity: 1, order: 4, createdAt: toTs(daysAgo(1)) },
  { id: "seed_hp_oliveoil", name: "Extra virgin olive oil", emoji: "🫒", category: "Groceries", subcategory: "Pantry", status: "to_buy", frequency: "monthly", isCustom: false, isHidden: false, addedBy: SARAH_ID, addedAt: toTs(daysAgo(2)), quantity: 1, order: 5, createdAt: toTs(daysAgo(2)) },
  { id: "seed_hp_papertowels", name: "Paper towels", emoji: "🧻", category: "Home Essentials", subcategory: "", status: "to_buy", frequency: "monthly", isCustom: false, isHidden: false, addedBy: JAMES_ID, addedAt: toTs(daysAgo(2)), quantity: 1, note: "Bounty brand if on sale", order: 6, createdAt: toTs(daysAgo(2)) },
  { id: "seed_hp_dogfood", name: "Dog food (Blue Buffalo)", emoji: "🐾", category: "Pet Supplies", subcategory: "", status: "to_buy", frequency: "monthly", isCustom: false, isHidden: false, addedBy: JAMES_ID, addedAt: toTs(daysAgo(3)), quantity: 1, order: 7, createdAt: toTs(daysAgo(3)) },

  // ── purchased (7 items) ──
  { id: "seed_hp_bananas", name: "Bananas", emoji: "🍌", category: "Groceries", subcategory: "Produce", status: "purchased", frequency: "weekly", isCustom: false, isHidden: false, addedBy: SARAH_ID, addedAt: toTs(daysAgo(3)), purchasedBy: SARAH_ID, purchasedAt: toTs(daysAgo(1)), quantity: 1, purchaseCount: 3, order: 0, createdAt: toTs(daysAgo(3)) },
  { id: "seed_hp_yogurt", name: "Greek yogurt", emoji: "🥛", category: "Groceries", subcategory: "Dairy", status: "purchased", frequency: "weekly", isCustom: false, isHidden: false, addedBy: SARAH_ID, addedAt: toTs(daysAgo(4)), purchasedBy: SARAH_ID, purchasedAt: toTs(daysAgo(1)), quantity: 2, purchaseCount: 4, order: 1, createdAt: toTs(daysAgo(4)) },
  { id: "seed_hp_detergent", name: "Laundry detergent", emoji: "🧴", category: "Cleaning", subcategory: "", status: "purchased", frequency: "monthly", isCustom: false, isHidden: false, addedBy: JAMES_ID, addedAt: toTs(daysAgo(5)), purchasedBy: JAMES_ID, purchasedAt: toTs(daysAgo(2)), quantity: 1, purchaseCount: 1, order: 2, createdAt: toTs(daysAgo(5)) },
  { id: "seed_hp_pasta", name: "Pasta sauce (marinara)", emoji: "🍝", category: "Groceries", subcategory: "Pantry", status: "purchased", frequency: "biweekly", isCustom: false, isHidden: false, addedBy: SARAH_ID, addedAt: toTs(daysAgo(4)), purchasedBy: JAMES_ID, purchasedAt: toTs(daysAgo(1)), quantity: 2, purchaseCount: 2, order: 3, createdAt: toTs(daysAgo(4)) },
  { id: "seed_hp_apples", name: "Apples (Honeycrisp)", emoji: "🍎", category: "Groceries", subcategory: "Produce", status: "purchased", frequency: "weekly", isCustom: false, isHidden: false, addedBy: SARAH_ID, addedAt: toTs(daysAgo(3)), purchasedBy: SARAH_ID, purchasedAt: toTs(daysAgo(1)), quantity: 6, purchaseCount: 3, order: 4, createdAt: toTs(daysAgo(3)) },
  { id: "seed_hp_beef", name: "Ground beef", emoji: "🥩", category: "Groceries", subcategory: "Meat", status: "purchased", frequency: "weekly", isCustom: false, isHidden: false, addedBy: JAMES_ID, addedAt: toTs(daysAgo(4)), purchasedBy: JAMES_ID, purchasedAt: toTs(daysAgo(2)), quantity: 1, purchaseCount: 2, order: 5, createdAt: toTs(daysAgo(4)) },
  { id: "seed_hp_dishsoap", name: "Dish soap", emoji: "🧹", category: "Cleaning", subcategory: "", status: "purchased", frequency: "monthly", isCustom: false, isHidden: false, addedBy: SARAH_ID, addedAt: toTs(daysAgo(6)), purchasedBy: SARAH_ID, purchasedAt: toTs(daysAgo(2)), quantity: 1, purchaseCount: 1, order: 6, createdAt: toTs(daysAgo(6)) },

  // ── custom items (5) ──
  { id: "seed_hp_vitamins", name: "Daily multivitamins", emoji: "💊", category: "Personal Care", subcategory: "", status: "to_buy", frequency: "monthly", isCustom: true, isHidden: false, addedBy: SARAH_ID, addedAt: toTs(daysAgo(2)), quantity: 1, order: 8, createdAt: toTs(daysAgo(2)) },
  { id: "seed_hp_protein", name: "Protein powder (vanilla)", emoji: "💪", category: "Personal Care", subcategory: "", status: "to_buy", frequency: "monthly", isCustom: true, isHidden: false, addedBy: JAMES_ID, addedAt: toTs(daysAgo(1)), quantity: 1, note: "Optimum Nutrition brand", order: 9, createdAt: toTs(daysAgo(1)) },
  { id: "seed_hp_candles", name: "Birthday candles", emoji: "🎂", category: "Home Essentials", subcategory: "", status: "to_buy", frequency: "as_needed", isCustom: true, isHidden: false, addedBy: SARAH_ID, addedAt: toTs(hoursAgo(3)), quantity: 1, note: "Mom's birthday next week!", order: 10, createdAt: toTs(hoursAgo(3)) },
  { id: "seed_hp_led", name: "LED light bulbs (60W)", emoji: "💡", category: "Home Essentials", subcategory: "", status: "to_buy", frequency: "as_needed", isCustom: true, isHidden: false, addedBy: JAMES_ID, addedAt: toTs(daysAgo(3)), quantity: 4, note: "For hallway and bathroom", order: 11, createdAt: toTs(daysAgo(3)) },
  { id: "seed_hp_campfuel", name: "Camping fuel canisters", emoji: "⛺", category: "Home Essentials", subcategory: "", status: "to_buy", frequency: "as_needed", isCustom: true, isHidden: false, addedBy: JAMES_ID, addedAt: toTs(daysAgo(2)), quantity: 2, note: "For the camping trip", order: 12, createdAt: toTs(daysAgo(2)) },
];

// ── Comments on tasks ────────────────────────────────────────

const comments = [
  {
    taskId: "seed_task_faucet",
    comment: { id: "seed_comment_01", text: "I watched a YouTube tutorial — looks doable! Just need a basin wrench.", authorId: JAMES_ID, reactions: { "👍": [SARAH_ID] }, createdAt: toTs(daysAgo(10)) },
  },
  {
    taskId: "seed_task_faucet",
    comment: { id: "seed_comment_02", text: "Nice work babe! No more dripping 🎉", authorId: SARAH_ID, reactions: { "❤️": [JAMES_ID] }, createdAt: toTs(daysAgo(3)) },
  },
  {
    taskId: "seed_task_garage",
    comment: { id: "seed_comment_03", text: "Found the holiday decorations! Let's keep those. Everything else can probably go.", authorId: SARAH_ID, reactions: {}, createdAt: toTs(daysAgo(5)) },
  },
  {
    taskId: "seed_task_datenight",
    comment: { id: "seed_comment_04", text: "The Italian place has great reviews! I'll call for a reservation.", authorId: SARAH_ID, reactions: { "😍": [JAMES_ID] }, createdAt: toTs(daysAgo(5)) },
  },
  {
    taskId: "seed_task_savings",
    comment: { id: "seed_comment_05", text: "Auto-transfer is set up — $200/month. We'll hit $5K in no time 💰", authorId: SARAH_ID, reactions: { "🎉": [JAMES_ID] }, createdAt: toTs(daysAgo(5)) },
  },
  {
    taskId: "seed_task_jog",
    comment: { id: "seed_comment_06", text: "Did my first 20-min jog today! Feeling good 💪", authorId: JAMES_ID, reactions: { "🔥": [SARAH_ID] }, createdAt: toTs(daysAgo(2)) },
  },
];

// ── Activity Feed ────────────────────────────────────────────

const activities = [
  { id: "seed_act_01", type: "member_joined", actorId: SARAH_ID, message: "Sarah Mitchell created the space", createdAt: toTs(daysAgo(21)) },
  { id: "seed_act_02", type: "member_joined", actorId: JAMES_ID, message: "James Mitchell joined the space", createdAt: toTs(daysAgo(20)) },
  { id: "seed_act_03", type: "task_created", actorId: SARAH_ID, taskId: "seed_task_faucet", message: "Sarah created \"Fix leaking kitchen faucet\"", createdAt: toTs(daysAgo(15)) },
  { id: "seed_act_04", type: "task_created", actorId: JAMES_ID, taskId: "seed_task_garage", message: "James created \"Organize the garage\"", createdAt: toTs(daysAgo(10)) },
  { id: "seed_act_05", type: "task_completed", actorId: JAMES_ID, taskId: "seed_task_smoke", message: "James completed \"Replace smoke detector batteries\"", createdAt: toTs(daysAgo(8)) },
  { id: "seed_act_06", type: "task_completed", actorId: JAMES_ID, taskId: "seed_task_hinge", message: "James completed \"Fix squeaky door hinge\"", createdAt: toTs(daysAgo(6)) },
  { id: "seed_act_07", type: "task_completed", actorId: SARAH_ID, taskId: "seed_task_savings", message: "Sarah completed \"Set up joint savings goal\" 🎉", createdAt: toTs(daysAgo(5)) },
  { id: "seed_act_08", type: "comment_added", actorId: SARAH_ID, taskId: "seed_task_savings", message: "Sarah commented on \"Set up joint savings goal\"", createdAt: toTs(daysAgo(5)) },
  { id: "seed_act_09", type: "task_completed", actorId: JAMES_ID, taskId: "seed_task_faucet", message: "James completed \"Fix leaking kitchen faucet\" 🎉", createdAt: toTs(daysAgo(3)) },
  { id: "seed_act_10", type: "task_completed", actorId: SARAH_ID, taskId: "seed_task_datenight", message: "Sarah completed \"Plan date night this Friday\" ❤️", createdAt: toTs(daysAgo(2)) },
  { id: "seed_act_11", type: "task_moved", actorId: JAMES_ID, taskId: "seed_task_jog", message: "James moved \"Morning jog routine\" to In Progress", createdAt: toTs(daysAgo(1)) },
  { id: "seed_act_12", type: "comment_added", actorId: JAMES_ID, taskId: "seed_task_jog", message: "James commented on \"Morning jog routine\"", createdAt: toTs(daysAgo(1)) },
];

// ── Seed Logic ───────────────────────────────────────────────

async function createAuthUsers(): Promise<void> {
  const authUsers = [
    { uid: SARAH_ID, email: "sarah.review@lifeboard.app", password: "Review2024!", displayName: "Sarah Mitchell" },
    { uid: JAMES_ID, email: "james.review@lifeboard.app", password: "Review2024!", displayName: "James Mitchell" },
  ];

  for (const u of authUsers) {
    try {
      await admin.auth().createUser({
        uid: u.uid,
        email: u.email,
        password: u.password,
        displayName: u.displayName,
        emailVerified: true,
      });
      console.log(`  ✅ Auth user created: ${u.displayName} (${u.email})`);
    } catch (err: any) {
      if (err.code === "auth/uid-already-exists" || err.code === "auth/email-already-exists") {
        console.log(`  ⏭️  Auth user already exists: ${u.displayName}`);
      } else {
        throw err;
      }
    }
  }
}

async function seedData(): Promise<void> {
  console.log("\n🌱 Seeding Lifeboard review data...\n");

  // 1. Create Auth users
  console.log("👤 Creating Auth users...");
  await createAuthUsers();

  // 2. Create Firestore user docs
  console.log("\n📄 Writing user documents...");
  const batch1 = db.batch();
  for (const u of users) {
    const { id, ...data } = u;
    batch1.set(db.collection("users").doc(id), data);
  }
  await batch1.commit();
  console.log(`  ✅ ${users.length} users written`);

  // 3. Create space
  console.log("\n🏠 Creating space...");
  const batch2 = db.batch();
  batch2.set(db.collection("spaces").doc(SPACE_ID), space);

  // 4. Create boards
  for (const b of boards) {
    const { id, ...data } = b;
    batch2.set(db.collection("spaces").doc(SPACE_ID).collection("boards").doc(id), data);
  }
  await batch2.commit();
  console.log(`  ✅ Space + ${boards.length} boards created`);

  // 5. Create tasks
  console.log("\n📋 Creating tasks...");
  const batch3 = db.batch();
  for (const t of tasks) {
    const { id, ...data } = t;
    batch3.set(db.collection("spaces").doc(SPACE_ID).collection("tasks").doc(id), data);
  }
  await batch3.commit();
  console.log(`  ✅ ${tasks.length} tasks created`);

  // 6. Create comments
  console.log("\n💬 Creating comments...");
  const batch4 = db.batch();
  for (const c of comments) {
    const { id, ...commentData } = c.comment;
    batch4.set(
      db.collection("spaces").doc(SPACE_ID).collection("tasks").doc(c.taskId).collection("comments").doc(id),
      commentData
    );
  }
  await batch4.commit();
  console.log(`  ✅ ${comments.length} comments created`);

  // 7. Create chores
  console.log("\n🧹 Creating chores...");
  const batch5 = db.batch();
  for (const ch of chores) {
    const { id, ...data } = ch;
    batch5.set(db.collection("spaces").doc(SPACE_ID).collection("chores").doc(id), data);
  }
  await batch5.commit();
  console.log(`  ✅ ${chores.length} chores created`);

  // 8. Create chore completions
  console.log("\n✅ Creating chore completions...");
  // Firestore batch limit is 500, we have 20 — fine in one batch
  const batch6 = db.batch();
  for (const cc of choreCompletions) {
    const { id, ...data } = cc;
    batch6.set(db.collection("spaces").doc(SPACE_ID).collection("chore_completions").doc(id), data);
  }
  await batch6.commit();
  console.log(`  ✅ ${choreCompletions.length} chore completions created`);

  // 9. Create shopping list items
  console.log("\n🛒 Creating shopping list items...");
  const batch7 = db.batch();
  for (const item of homePadItems) {
    const { id, ...data } = item;
    batch7.set(db.collection("spaces").doc(SPACE_ID).collection("homepad_items").doc(id), data);
  }
  await batch7.commit();
  console.log(`  ✅ ${homePadItems.length} shopping list items created`);

  // 10. Create activity feed
  console.log("\n📢 Creating activity feed...");
  const batch8 = db.batch();
  for (const a of activities) {
    const { id, ...data } = a;
    batch8.set(db.collection("spaces").doc(SPACE_ID).collection("activity").doc(id), data);
  }
  await batch8.commit();
  console.log(`  ✅ ${activities.length} activity entries created`);

  // Summary
  console.log("\n" + "═".repeat(50));
  console.log("🎉 Seed complete! Summary:");
  console.log(`   👤 Users:             ${users.length}`);
  console.log(`   🏠 Spaces:            1`);
  console.log(`   📋 Boards:            ${boards.length}`);
  console.log(`   📝 Tasks:             ${tasks.length}`);
  console.log(`   💬 Comments:          ${comments.length}`);
  console.log(`   🧹 Chores:            ${chores.length}`);
  console.log(`   ✅ Chore completions: ${choreCompletions.length}`);
  console.log(`   🛒 Shopping items:    ${homePadItems.length}`);
  console.log(`   📢 Activity entries:  ${activities.length}`);
  console.log("═".repeat(50));
  console.log("\n🔑 Review credentials:");
  console.log("   Sarah: sarah.review@lifeboard.app / Review2024!");
  console.log("   James: james.review@lifeboard.app / Review2024!");
  console.log("");
}

// ── Cleanup Logic ────────────────────────────────────────────

async function cleanSeedData(): Promise<void> {
  console.log("\n🧹 Cleaning all seed data...\n");

  // Helper to delete all docs in a collection matching seed_ prefix
  async function deleteCollection(ref: admin.firestore.CollectionReference): Promise<number> {
    const snapshot = await ref.where(admin.firestore.FieldPath.documentId(), ">=", "seed_")
      .where(admin.firestore.FieldPath.documentId(), "<", "seed`") // lexicographic range
      .get();

    if (snapshot.empty) return 0;

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    return snapshot.size;
  }

  // Delete subcollections under space
  const spaceRef = db.collection("spaces").doc(SPACE_ID);

  // Delete comments (nested under tasks)
  for (const taskId of tasks.map((t) => t.id)) {
    const commentsSnap = await spaceRef.collection("tasks").doc(taskId).collection("comments").get();
    if (!commentsSnap.empty) {
      const batch = db.batch();
      commentsSnap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  }
  console.log("  🗑️  Comments deleted");

  const collections = ["tasks", "boards", "chores", "chore_completions", "homepad_items", "activity"];
  for (const col of collections) {
    const count = await deleteCollection(spaceRef.collection(col));
    console.log(`  🗑️  ${col}: ${count} docs deleted`);
  }

  // Delete the space itself
  await spaceRef.delete();
  console.log("  🗑️  Space deleted");

  // Delete user docs
  for (const u of users) {
    await db.collection("users").doc(u.id).delete();
  }
  console.log(`  🗑️  ${users.length} user docs deleted`);

  // Delete Auth users
  for (const uid of [SARAH_ID, JAMES_ID]) {
    try {
      await admin.auth().deleteUser(uid);
      console.log(`  🗑️  Auth user deleted: ${uid}`);
    } catch (err: any) {
      if (err.code === "auth/user-not-found") {
        console.log(`  ⏭️  Auth user not found: ${uid}`);
      } else {
        throw err;
      }
    }
  }

  console.log("\n✅ All seed data cleaned up!\n");
}

// ── Main ─────────────────────────────────────────────────────

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  if (args.includes("--clean")) {
    await cleanSeedData();
  } else {
    // Clean first (idempotent), then seed
    await cleanSeedData();
    await seedData();
  }

  process.exit(0);
}

main().catch((err) => {
  console.error("❌ Fatal error:", err);
  process.exit(1);
});
