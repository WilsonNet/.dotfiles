# ts-pattern - Pattern Matching for TypeScript

## Overview
`ts-pattern` is a powerful pattern matching library for TypeScript that makes complex conditionals cleaner, more readable, and type-safe. It's especially useful for handling different states, union types, and complex business logic.

## Installation
```bash
bun add ts-pattern
```

## Basic Usage

### Simple Value Matching
```typescript
import { match } from "ts-pattern";

const result = match(value)
  .with("PENDING", () => "Waiting for review")
  .with("APPROVED", () => "Application approved")
  .with("REJECTED", () => "Application rejected")
  .otherwise(() => "Unknown status");
```

### Object Pattern Matching
```typescript
interface Application {
  status: "PENDING" | "APPROVED" | "REJECTED";
  stage: "TECHNICAL" | "PSYCHOLOGICAL";
}

const message = match(application)
  .with({ status: "PENDING", stage: "TECHNICAL" }, () => 
    "Waiting for technical interview"
  )
  .with({ status: "PENDING", stage: "PSYCHOLOGICAL" }, () => 
    "Waiting for psych interview"
  )
  .with({ status: "APPROVED" }, () => 
    "Application approved!"
  )
  .with({ status: "REJECTED" }, () => 
    "Application rejected"
  )
  .exhaustive(); // Ensures all cases are handled
```

## Common Patterns in This Project

### 1. Status Badge Rendering
```typescript
import { match } from "ts-pattern";
import { Badge } from "@/components/ui/badge";

const StatusBadge = ({ status }: { status: ApplicationStatus }) => {
  return match(status)
    .with("PENDING", () => (
      <Badge variant="secondary">Pending</Badge>
    ))
    .with("APPROVED", () => (
      <Badge variant="success">Approved</Badge>
    ))
    .with("REJECTED", () => (
      <Badge variant="destructive">Rejected</Badge>
    ))
    .with("AVAILABILITY_SUBMITTED", () => (
      <Badge variant="warning">Availability Submitted</Badge>
    ))
    .with("SCHEDULED", () => (
      <Badge variant="info">Scheduled</Badge>
    ))
    .exhaustive();
};
```

### 2. Interview Stage Flow
```typescript
const getNextStage = (currentStage: InterviewStage) => {
  return match(currentStage)
    .with("INITIAL_SCREENING", () => "TECHNICAL_AVAILABILITY")
    .with("TECHNICAL_AVAILABILITY", () => "TECHNICAL_INTERVIEW")
    .with("TECHNICAL_INTERVIEW", () => "PSYCH_AVAILABILITY")
    .with("PSYCH_AVAILABILITY", () => "PSYCH_INTERVIEW")
    .with("PSYCH_INTERVIEW", () => "PROPOSAL")
    .with("PROPOSAL", () => "COMPLETE")
    .exhaustive();
};
```

### 3. Permission-Based UI
```typescript
const canPerformAction = (
  permission: Permission, 
  action: "view" | "edit" | "delete"
) => {
  return match({ permission, action })
    .with({ permission: "ADMIN", action: "delete" }, () => true)
    .with({ permission: "ADMIN", action: "edit" }, () => true)
    .with({ permission: "ADMIN", action: "view" }, () => true)
    .with({ permission: "HIRING_MANAGER", action: "view" }, () => true)
    .with({ permission: "HIRING_MANAGER", action: "edit" }, () => true)
    .with({ permission: "TECHNICAL", action: "view" }, () => true)
    .otherwise(() => false);
};
```

### 4. Auto-Assignment Logic
```typescript
const getAssignmentMessage = (status: AutoAssignmentStatus) => {
  return match(status)
    .with("PENDING", () => ({
      title: "Awaiting Assignment",
      description: "Candidate submitted availability",
      color: "yellow"
    }))
    .with("AUTO_ASSIGNED", () => ({
      title: "Auto-Assigned",
      description: "System assigned an interviewer",
      color: "blue"
    }))
    .with("CONFIRMED", () => ({
      title: "Confirmed",
      description: "Interview scheduled",
      color: "green"
    }))
    .with("OVERRIDDEN", () => ({
      title: "Manually Assigned",
      description: "HR overrode the assignment",
      color: "purple"
    }))
    .with("FAILED", () => ({
      title: "Assignment Failed",
      description: "No interviewers available",
      color: "red"
    }))
    .exhaustive();
};
```

### 5. Calendar Availability
```typescript
const getSlotColor = (slot: TimeSlot) => {
  return match(slot.availableInterviewers)
    .when((count) => count >= 5, () => "bg-emerald-500")
    .when((count) => count >= 3, () => "bg-emerald-400")
    .when((count) => count >= 1, () => "bg-emerald-300")
    .otherwise(() => "bg-gray-200");
};
```

## Advanced Features

### Wildcards (`__`)
Match any value in a specific position:
```typescript
match(user)
  .with({ role: "admin", permissions: __ }, () => "Admin user")
  .with({ role: "user", permissions: __ }, () => "Regular user")
  .exhaustive();
```

### When Clauses
Add custom conditions:
```typescript
match(application)
  .with({ status: "PENDING" }, () => "Pending")
  .when(
    (app) => app.status === "APPROVED" && app.interview !== null,
    () => "Approved with interview"
  )
  .otherwise(() => "Other");
```

### Union Types
Handle union types elegantly:
```typescript
type Result = 
  | { type: "success"; data: string }
  | { type: "error"; message: string }
  | { type: "loading" };

const content = match(result)
  .with({ type: "success" }, ({ data }) => <div>{data}</div>)
  .with({ type: "error" }, ({ message }) => <Error message={message} />)
  .with({ type: "loading" }, () => <Spinner />)
  .exhaustive();
```

### Optionals and Nullables
```typescript
match(maybeInterview)
  .with(undefined, () => "No interview scheduled")
  .with({ status: "PENDING" }, () => "Interview pending")
  .with({ status: "APPROVED" }, () => "Interview passed")
  .exhaustive();
```

## Benefits Over Traditional Conditionals

### 1. Exhaustiveness Checking
```typescript
// ❌ Traditional: Easy to miss cases
if (status === "PENDING") return "Pending";
if (status === "APPROVED") return "Approved";
// Oops, forgot REJECTED!

// ✅ ts-pattern: Compile-time exhaustiveness check
match(status)
  .with("PENDING", () => "Pending")
  .with("APPROVED", () => "Approved")
  .exhaustive(); // Type error! REJECTED not handled
```

### 2. Type Inference
```typescript
// ❌ Traditional: Manual type narrowing
if (result.type === "success") {
  // TypeScript knows result.data exists here
}

// ✅ ts-pattern: Automatic type narrowing
match(result)
  .with({ type: "success" }, ({ data }) => {
    // data is automatically typed as string
  })
  .exhaustive();
```

### 3. Readability
```typescript
// ❌ Traditional: Nested if-else hell
if (user.role === "admin") {
  if (user.permissions.includes("delete")) {
    return "Can delete";
  }
  return "Can edit";
} else if (user.role === "user") {
  return "Can view";
}

// ✅ ts-pattern: Flat, readable
match(user)
  .with({ role: "admin", permissions: P.array(P.string).includes("delete") }, () => 
    "Can delete"
  )
  .with({ role: "admin" }, () => "Can edit")
  .with({ role: "user" }, () => "Can view")
  .exhaustive();
```

## When to Use

### Use ts-pattern when:
- You have complex conditional logic with many branches
- You're working with union types or discriminated unions
- You need exhaustiveness checking (ensure all cases handled)
- State machines or workflow logic
- Rendering different UI based on multiple conditions

### Use traditional conditionals when:
- Simple if/else with 2-3 branches
- Boolean logic only
- Performance-critical code (ts-pattern has small overhead)

## Common Anti-Patterns

### ❌ Don't: Over-engineer simple cases
```typescript
// Overkill for simple boolean
const result = match(isLoading)
  .with(true, () => "Loading...")
  .with(false, () => "Done")
  .exhaustive();

// Better
const result = isLoading ? "Loading..." : "Done";
```

### ✅ Do: Use for complex state machines
```typescript
// Good: Complex state matching
const canEdit = match({ status, userRole, isOwner })
  .with({ status: "DRAFT", userRole: "ADMIN" }, () => true)
  .with({ status: "DRAFT", userRole: "EDITOR", isOwner: true }, () => true)
  .with({ status: "PUBLISHED" }, () => false)
  .otherwise(() => false);
```

## Resources

- [ts-pattern GitHub](https://github.com/gvergnaud/ts-pattern)
- [Documentation](https://github.com/gvergnaud/ts-pattern#readme)
- [Pattern Matching in TypeScript](https://dev.to/gvergnaud/bringing-pattern-matching-to-typescript-introducing-ts-pattern-v3-0-oob)

## Example: Complete Interview Status Logic

```typescript
import { match, P } from "ts-pattern";

const getInterviewStatusDisplay = (application: Application) => {
  return match({
    status: application.status,
    hasInterview: !!application.interview,
    hasPsychInterview: !!application.psychInterview,
  })
    .with({ status: "PENDING" }, () => ({
      message: "Application under review",
      action: null,
    }))
    .with({ status: "AVAILABILITY_SUBMITTED", hasInterview: false }, () => ({
      message: "We're scheduling your technical interview",
      action: "wait",
    }))
    .with({ status: "SCHEDULED", hasInterview: true }, (ctx) => ({
      message: `Interview scheduled with ${ctx.hasInterview.interviewer}`,
      action: "view_details",
    }))
    .with({ status: "APPROVED", hasInterview: true, hasPsychInterview: false }, () => ({
      message: "Technical interview passed! Select psych interview availability",
      action: "select_availability",
    }))
    .otherwise(() => ({
      message: "Unknown status",
      action: null,
    }));
};
```

This skill should be loaded when working with complex conditional logic, state machines, or union types in the codebase.
