// Cohérence des workflows n8n du dépôt et de la base de connaissances.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';
import { ROOT, loadWorkflows, runCode } from '../helpers/n8n.mjs';

const workflows = loadWorkflows();
const ids = new Set(workflows.map(w => w.id));
const bootstrap = readFileSync(path.join(ROOT, 'n8n', 'bootstrap.sh'), 'utf8');

test('9 workflows avec des identifiants uniques', () => {
  assert.equal(workflows.length, 9);
  assert.equal(ids.size, 9);
});

for (const wf of workflows) {
  test(`${wf.file} : connexions et noms de nœuds cohérents`, () => {
    const names = wf.nodes.map(n => n.name);
    assert.equal(new Set(names).size, names.length, 'noms de nœuds en double');
    for (const [from, outputs] of Object.entries(wf.connections)) {
      assert.ok(names.includes(from), `connexion depuis un nœud inconnu : ${from}`);
      for (const branch of outputs.main ?? []) for (const c of branch ?? [])
        assert.ok(names.includes(c.node), `connexion vers un nœud inconnu : ${c.node}`);
    }
  });

  test(`${wf.file} : les sous-workflows appelés existent dans le dépôt`, () => {
    for (const n of wf.nodes.filter(n => n.type === 'n8n-nodes-base.executeWorkflow'))
      assert.ok(ids.has(n.parameters.workflowId?.value), `${n.name} appelle ${n.parameters.workflowId?.value}`);
  });

  test(`${wf.file} : credentials créés par bootstrap.sh, aucun secret dans le workflow`, () => {
    for (const n of wf.nodes) for (const c of Object.values(n.credentials ?? {}))
      assert.ok(bootstrap.includes(`id: "${c.id}"`), `${n.name} utilise un credential inconnu ${c.id}`);
    const raw = JSON.stringify(wf);
    assert.doesNotMatch(raw, /password"\s*:\s*"[^"$={]/i, 'mot de passe en clair');
    assert.doesNotMatch(raw, /\b\d{8,10}:[A-Za-z0-9_-]{35}\b/, 'jeton Telegram en clair');
    assert.doesNotMatch(raw, /\bsk-[A-Za-z0-9]{20,}/, 'clé d’API en clair');
  });

  test(`${wf.file} : chaque webhook exige la clé d’API (X-API-Key)`, () => {
    for (const n of wf.nodes.filter(n => n.type === 'n8n-nodes-base.webhook')) {
      assert.equal(n.parameters.authentication, 'headerAuth', `${n.name} n’est pas protégé`);
      assert.equal(n.credentials?.httpHeaderAuth?.id, 'p04CredApiKey001');
    }
  });
}

// --- Base de connaissances -----------------------------------------------------
const KB_DIR = path.join(ROOT, 'knowledge-base');
const kbItems = readdirSync(KB_DIR).filter(f => f.endsWith('.md')).sort()
  .map(fileName => ({ fileName, text: readFileSync(path.join(KB_DIR, fileName), 'utf8') }));

test('base de connaissances : chaque fiche a un titre « # » et des sections « ## »', () => {
  assert.ok(kbItems.length >= 10);
  for (const { fileName, text } of kbItems) {
    assert.match(text, /^#\s+\S/m, `${fileName} sans titre`);
    assert.match(text, /^##\s+\S/m, `${fileName} sans section`);
  }
});

test('découpage (workflow 01) : extraits bornés, index uniques par fiche comme l’exige la base', () => {
  const [{ chunks, inputs }] = runCode('01_ingestion_base_connaissances.json', 'Découpage', { items: kbItems });
  assert.equal(inputs.length, chunks.length);
  assert.ok(chunks.length >= kbItems.length * 2);
  const keys = new Set(chunks.map(c => `${c.doc_path}#${c.chunk_index}`));
  assert.equal(keys.size, chunks.length, 'contrainte UNIQUE (doc_path, chunk_index) violée');
  for (const c of chunks) {
    assert.ok(c.content.startsWith(`${c.doc_title} — ${c.section}\n`), 'titre et section en tête de l’extrait');
    // 1200 caractères max, sauf un paragraphe seul plus long (non coupé)
    const body = c.content.slice(c.content.indexOf('\n') + 1);
    assert.ok(body.length <= 1200 || !body.includes('\n\n'), `${c.doc_path}#${c.chunk_index} trop long`);
  }
});

test('découpage : une fiche sans section « ## » est refusée', () => {
  assert.throws(() => runCode('01_ingestion_base_connaissances.json', 'Découpage',
    { items: [{ fileName: 'x.md', text: '# Titre\nTexte sans section' }] }), /Aucune section/);
});
