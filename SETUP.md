# Repo setup — 5 minutes

## M1 does this once

```bash
cd urbanride-architecture
git init
git add .
git commit -m "Scaffold: ADD sections, diagram slots, build script"
git branch -M main
```

Create an **empty private repo** on GitHub (no README, no .gitignore — this folder has both),
then:

```bash
git remote add origin https://github.com/<user>/urbanride-architecture.git
git push -u origin main
```

Settings → Collaborators → add the other four.

## Everyone else

```bash
git clone https://github.com/<user>/urbanride-architecture.git
cd urbanride-architecture
```

## Working loop

```bash
git pull --rebase          # ALWAYS first
# edit only your own file
git add add/0X-your-file.md
git commit -m "Section X: draft"
git push
```

**Push often — every 30–45 minutes.** Frequent small commits mean a crashed laptop costs
minutes instead of hours.

## If you hit a conflict

You shouldn't — everyone owns a separate file. If you do, it means two people edited the same
file, so stop and talk rather than resolving blind. The likely cause is someone editing a file
they don't own.

## If Git becomes a time sink

Abandon it. Move to a shared Google Drive folder and have M5 assemble manually. **Git is here to
save you time, not to be learned tonight.** If more than 20 minutes go into Git problems, the
tool is costing more than it returns.
