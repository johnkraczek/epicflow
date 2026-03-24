# Dependency Upgrade SOP

Procedure for major dependency upgrades and security advisories.

## When to Use

- A dependency has a new major version with breaking changes
- A security advisory requires updating a dependency
- A dependency is deprecated and must be replaced
- A transitive dependency conflict requires version alignment

## Steps

### 1. Assess
Read the changelog and migration guide for the new version. Identify:
- Breaking changes that affect this project
- Deprecated APIs being removed
- New peer dependency requirements
- Known issues or caveats in the migration guide

If the upgrade is security-driven, note the CVE and affected versions.

### 2. Branch
```bash
git checkout -b chore/upgrade-{package}
```

### 3. Update
Change the version in the package manifest (e.g., `package.json`, `pyproject.toml`, `Cargo.toml`). Install dependencies to update the lockfile.

### 4. Fix breaking changes
Address all breaking changes systematically:
- Update import paths
- Fix type errors and API signature changes
- Update configuration files if the package's config format changed
- Replace calls to removed/renamed APIs

Work through compiler/type-checker errors first, then runtime issues.

### 5. Test
Run the full test suite (`{testCommand}`) and the check command (`{checkCommand}`). Pay special attention to:
- Areas of the codebase that heavily use the upgraded dependency
- Edge cases mentioned in the migration guide
- Manual smoke testing of critical user flows that touch the dependency

### 6. PR
Create a pull request with migration notes in the description:
- What was upgraded and to which version
- Why (major release, security advisory, deprecation)
- What breaking changes were encountered and how they were resolved
- What to watch for after merge (known behavioral changes, performance differences)

### 7. Monitor
After merge, watch for regressions:
- Check error tracking for new exceptions
- Review performance metrics if the dependency touches hot paths
- Keep the old version noted so rollback is straightforward if needed

## Expected Output

- Dependency updated to target version
- All breaking changes resolved
- Full test suite passes
- PR includes migration notes for team awareness
