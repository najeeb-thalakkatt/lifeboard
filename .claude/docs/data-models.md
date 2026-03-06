# Lifeboard — Data Models (Firestore)

> Reference file for Firestore schema and security rules. Loaded on demand from CLAUDE.md.

---

## `users/{userId}`
```
displayName: string
email: string
photoUrl: string?
moodEmoji: string?
spaceIds: string[]
notificationPrefs: { pushEnabled: bool, emailEnabled: bool }
createdAt: timestamp
```

## `spaces/{spaceId}`
```
name: string (default: "Our Home")
members: map<userId, { role: 'owner' | 'member', joinedAt: timestamp }>
inviteCode: string (6-char alphanumeric, unique)
themes: string[] (e.g., ["Home", "Kids", "Finances"])
createdAt: timestamp
```

## `spaces/{spaceId}/boards/{boardId}`
```
name: string
theme: string
columns: ["To Do", "In Progress", "Done"]
createdBy: userId
createdAt: timestamp
```

## `spaces/{spaceId}/tasks/{taskId}`
```
title: string
description: string?
status: 'todo' | 'in_progress' | 'done'
boardId: string
assignees: string[] (userIds)
dueDate: timestamp?
emojiTag: string? (💰🏡❤️🧠💪☀️)
subtasks: [{ id: string, title: string, completed: bool }]
attachments: [{ url: string, type: string, name: string }]
isWeeklyTask: bool
weekStart: timestamp?
order: int
completedAt: timestamp?
createdBy: userId
createdAt: timestamp
updatedAt: timestamp
```

## `spaces/{spaceId}/tasks/{taskId}/comments/{commentId}`
```
text: string
authorId: userId
reactions: map<emoji, userId[]>
createdAt: timestamp
```

## `spaces/{spaceId}/activity/{activityId}`
```
type: 'task_moved' | 'task_created' | 'task_completed' | 'comment_added' | 'member_joined'
actorId: userId
taskId: string?
message: string
createdAt: timestamp
```

---

## Firestore Security Rules (Summary)

- Users read/write only spaces where they are a member.
- Tasks scoped to spaces — only members can CRUD.
- Users can only update their own `users/{userId}` doc.
- `inviteCode` field on spaces is readable by any authenticated user (for join flow).
- Activity collection: read by members, write only via Cloud Functions (admin SDK).
