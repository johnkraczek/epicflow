# Feature Flags SOP

SOP for feature flag-based development — shipping incomplete or risky features safely behind toggles.

## When to Use

- Shipping an incomplete feature that will be built across multiple tasks or milestones
- A/B testing different implementations
- Gradual rollout to reduce blast radius
- Risky changes that need a kill switch
- Features that depend on external services not yet ready

## Concepts

### Lifecycle

1. **Create the flag** — define it with a default of OFF
2. **Wrap the feature** — guard new code paths with a flag check
3. **Deploy with flag OFF** — code ships but is not active
4. **Enable for internal users** — test in production with real data
5. **Percentage rollout** — 10% -> 25% -> 50% -> 100%
6. **Remove the flag** — after stable at 100%, delete the flag and its checks (schedule a cleanup task)

### Flag Naming

Use descriptive, consistent names:

- `enable-<feature-name>` for feature toggles (e.g., `enable-dashboard-v2`)
- `experiment-<name>` for A/B tests (e.g., `experiment-onboarding-flow`)
- `rollout-<name>` for gradual rollouts (e.g., `rollout-new-search`)

### Flag Hygiene

- Flags are temporary. Every flag should have a planned removal date.
- Never nest flags (checking flag A inside flag B). Keep flag logic flat.
- Keep the number of active flags small. More than 5-10 active flags is a smell.

---

## Provider: Vercel Flags

For projects deployed on Vercel, use `@vercel/flags` for full-featured flag management.

### Setup

1. Install the package in the app:
   ```bash
   bun add @vercel/flags
   ```

2. Create a flag definitions file (e.g., `src/flags.ts`):
   ```ts
   import { flag } from "@vercel/flags/next";

   export const showNewDashboard = flag({
     key: "show-new-dashboard",
     decide: () => false, // default OFF
   });
   ```

3. Add the flag provider to the app root if needed (see Vercel Flags docs for framework-specific setup).

4. Use flags in server or client code:
   ```ts
   import { showNewDashboard } from "@/flags";

   export default async function Page() {
     const useNewDashboard = await showNewDashboard();

     if (useNewDashboard) {
       return <NewDashboard />;
     }
     return <CurrentDashboard />;
   }
   ```

5. Manage flag state (enable/disable, percentage rollout, user targeting) in the Vercel dashboard under the Flags tab.

### Notes

- Vercel Flags supports edge evaluation, so flags resolve fast without additional API calls.
- Flags can be overridden per-environment (preview, production).
- See [Vercel Flags documentation](https://vercel.com/docs/workflow-collaboration/feature-flags) for advanced targeting and analytics.

---

## Provider: Generic / Custom

For projects not on Vercel, or for simpler needs.

### Environment Variable Flags (Simplest)

The simplest approach — no dependencies, no external services.

1. Define the flag as an environment variable:
   ```
   FEATURE_NEW_DASHBOARD=false
   ```

2. Check it in code:
   ```ts
   const showNewDashboard = process.env.FEATURE_NEW_DASHBOARD === "true";
   ```

3. Toggle by updating the environment variable and redeploying.

**Limitations**: requires a redeploy to toggle, no percentage rollout, no user targeting.

### Database-Backed Flags (Runtime Toggling)

For flags that need to be toggled without redeployment.

1. Create a `feature_flags` table:
   ```sql
   CREATE TABLE feature_flags (
     key TEXT PRIMARY KEY,
     enabled BOOLEAN DEFAULT false,
     rollout_percentage INTEGER DEFAULT 0,
     updated_at TIMESTAMP DEFAULT now()
   );
   ```

2. Create a flag resolution function:
   ```ts
   async function isEnabled(flagKey: string, userId?: string): Promise<boolean> {
     const flag = await db.query.featureFlags.findFirst({
       where: eq(featureFlags.key, flagKey),
     });
     if (!flag) return false;
     if (flag.enabled) return true;
     if (flag.rolloutPercentage > 0 && userId) {
       // Deterministic hash for consistent user experience
       const hash = simpleHash(flagKey + userId) % 100;
       return hash < flag.rolloutPercentage;
     }
     return false;
   }
   ```

3. Toggle flags by updating the database row — no redeploy needed.

**Limitations**: adds a database query per flag check (mitigate with caching), requires building the management UI yourself.

---

## Integration with EpicFlow

### During Decomposition

When decomposing a feature that should be flag-gated:

- **First task**: create the feature flag (define it, default OFF, add the flag check to the entry point)
- **Middle tasks**: implement the feature behind the flag
- **Last task in scope**: enable the flag for internal/staging environments
- **Cleanup task**: remove the flag after stable rollout — if this falls outside the current milestone, create it as a deferred/future task

### In Task Reports

When a task creates or modifies a feature flag, note in the task report:

- Flag name
- Current state (OFF, internal-only, percentage, 100%)
- Cleanup timeline if known

## Expected Output

- Feature deployed behind a flag with flag defaulting to OFF
- Rollout plan documented (even if just "enable after QA")
- Flag cleanup task created or scheduled
