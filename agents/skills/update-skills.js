#!/usr/bin/env node
/**
 * update-skills.js
 *
 * 1. Runs `npx skills update -g` to pull latest skill versions.
 * 2. Reads global.txt to get the set of "global" skill names.
 * 3. For every SKILL.md under this directory, sets disable-model-invocation
 *    front-matter to false if the skill name is in global.txt, true otherwise.
 *
 *    Global skills (in global.txt) are model-invoked — disable-model-invocation: false
 *    Other skills are user-explicit only — disable-model-invocation: true
 */

import { readFileSync, writeFileSync, readdirSync, statSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));

// ---- Step 1: update skills ----
console.log('Updating skills...');
try {
  execSync('npx skills update -g', { stdio: 'inherit', cwd: __dirname });
} catch {
  console.warn('Warning: `npx skills update -g` failed, continuing...');
}

// ---- Step 2: read global.txt ----
const globalPath = join(__dirname, 'global.txt');
let globalNames = new Set();
try {
  const raw = readFileSync(globalPath, 'utf-8');
  for (const line of raw.split('\n')) {
    const name = line.trim();
    if (name) globalNames.add(name);
  }
} catch {
  console.warn('global.txt not found, treating all skills as non-global.');
}

console.log(`Global skills (${globalNames.size}): ${[...globalNames].join(', ') || '(none)'}`);

// ---- Step 3: find all SKILL.md files and update front-matter ----
const entries = readdirSync(__dirname, { withFileTypes: true });

for (const entry of entries) {
  if (!entry.isDirectory()) continue;
  const skillDir = join(__dirname, entry.name);
  const skillFile = join(skillDir, 'SKILL.md');
  try {
    if (!statSync(skillFile).isFile()) continue;
  } catch {
    continue;
  }

  const content = readFileSync(skillFile, 'utf-8');
  const updated = updateFrontMatter(content, globalNames);
  if (updated !== content) {
    writeFileSync(skillFile, updated, 'utf-8');
    console.log(`  ✓ ${entry.name}/SKILL.md`);
  } else {
    console.log(`  - ${entry.name}/SKILL.md (unchanged)`);
  }
}

console.log('Done.');

// ---- Helpers ----

/**
 * Replace/insert disable-model-invocation in front-matter YAML.
 * Insertion point: after the last single-line key but before any block key
 * with indented children.
 */
function updateFrontMatter(content, globalNames) {
  const fmMatch = content.match(/^---\n([\s\S]*?)\n---\n/);
  if (!fmMatch) {
    console.warn('  ⚠ No front-matter found, skipping');
    return content;
  }

  const fmRaw = fmMatch[1];
  const fmLines = fmRaw.split('\n');

  // Extract skill name
  const nameMatch = fmRaw.match(/^name:\s*(.+)$/m);
  if (!nameMatch) {
    console.warn('  ⚠ No name in front-matter, skipping');
    return content;
  }
  const skillName = nameMatch[1].trim();

  // Desired value: global=true → model-invoked → disable-model-invocation: false
  //               global=false → user-explicit only → disable-model-invocation: true
  const desiredValue = globalNames.has(skillName) ? 'false' : 'true';

  // Check if already correct
  const dmiMatch = fmRaw.match(/^disable-model-invocation:\s*(true|false)$/m);
  if (dmiMatch && dmiMatch[1] === desiredValue) {
    return content;
  }

  // Build new lines, replacing disable-model-invocation if present
  const newLines = [];
  let dmiFound = false;
  for (const line of fmLines) {
    if (/^disable-model-invocation:\s*(true|false)$/.test(line)) {
      newLines.push(`disable-model-invocation: ${desiredValue}`);
      dmiFound = true;
    } else {
      newLines.push(line);
    }
  }

  if (!dmiFound) {
    // Insert right after the `name:` line — safest spot.
    // description can use YAML block scalars (>-), which look like
    // multi-line content; putting disable-model-invocation there would
    // get swallowed into the scalar. name: is always a single line.
    const nameLineIdx = newLines.findIndex(l => /^name:/.test(l));
    const insertIdx = nameLineIdx >= 0 ? nameLineIdx + 1 : newLines.length;
    newLines.splice(insertIdx, 0, `disable-model-invocation: ${desiredValue}`);
  }

  // Rebuild
  const newFm = `---\n${newLines.join('\n')}\n---`;
  const rest = content.slice(fmMatch[0].length);
  return `${newFm}\n${rest}`;
}