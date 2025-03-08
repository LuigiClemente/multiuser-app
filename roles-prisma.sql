generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ─────────────────────────────────────────────────
// 🟢 USER MODEL (Primary Identifier: Email)
// Authentication handled externally via Keycloak
// ─────────────────────────────────────────────────
model User {
  email      String  @id @unique // Primary Key (Email as Identity)
  roleId     String  // Foreign Key to Role
  groups     UserGroup[] // Many-to-Many with Groups
  resources  Resource[] @relation("UserResources") // One-to-Many (User-Owned Resources)

  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt()

  role       Role     @relation(fields: [roleId], references: [id], onDelete: Cascade) // Enforce valid roles

  @@index([roleId]) // Optimize role-based queries
}

// ─────────────────────────────────────────────────
// 🟢 ROLE-BASED ACCESS CONTROL (RBAC)
// ─────────────────────────────────────────────────
model Role {
  id          String   @id @unique
  name        String   @unique // e.g., "MAIN_ACCOUNT_HOLDER", "DEPENDENT_USER"
  permissions RolePermission[] // Many-to-Many with Permissions

  users       User[]   @relation(fields: [id], references: [roleId]) // Assigned users
}

model Permission {
  id       String  @id @unique
  name     String  @unique // e.g., "CAN_INVITE_USERS", "CAN_MANAGE_PLANS"

  roles    RolePermission[] // Many-to-Many with Roles
}

// 🟢 Junction table for Role-Permission Many-to-Many relation
model RolePermission {
  roleId       String
  permissionId String

  role        Role       @relation(fields: [roleId], references: [id], onDelete: Cascade)
  permission  Permission @relation(fields: [permissionId], references: [id], onDelete: Cascade)

  @@id([roleId, permissionId]) // Composite key for Many-to-Many
  @@index([roleId, permissionId]) // Optimized queries
}

// ─────────────────────────────────────────────────
// 🟢 GROUP-BASED MULTI-USER MANAGEMENT
// ─────────────────────────────────────────────────
model Group {
  id        String   @id @default(uuid()) // Unique Group ID
  name      String   // Group Name (e.g., "PlanA-Group-12345")
  planId    String?  // Optional link to Vendure plan
  users     UserGroup[] // Many-to-Many with Users
  resources Resource[] // Shared resources within this Group

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt()
}

// 🟢 Junction table for User-Group Many-to-Many relation
model UserGroup {
  userEmail String // Foreign key referencing User (Email as primary key)
  groupId   String // Foreign key referencing Group

  user      User   @relation(fields: [userEmail], references: [email], onDelete: Cascade)
  group     Group  @relation(fields: [groupId], references: [id], onDelete: Cascade)

  @@id([userEmail, groupId]) // Composite Primary Key
  @@index([groupId, userEmail]) // Optimized lookups
}

// ─────────────────────────────────────────────────
// 🟢 RESOURCE MANAGEMENT
// ─────────────────────────────────────────────────
enum OwnerType {
  USER
  GROUP
}

model Resource {
  id        String   @id @default(uuid()) // Unique Resource ID
  name      String
  ownerId   String  // Generic owner reference (User Email or Group ID)
  ownerType OwnerType // Enum to distinguish between USER and GROUP ownership

  ownerUser User?   @relation("UserResources", fields: [ownerId], references: [email], onDelete: SetNull)
  ownerGroup Group? @relation(fields: [ownerId], references: [id], onDelete: SetNull)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt()

  @@index([ownerId, ownerType]) // Optimized resource queries
}
