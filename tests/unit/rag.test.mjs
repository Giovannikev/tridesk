// Réponse RAG : filtrage des sources (« Prompt RAG ») et mise en forme des citations (« Mise en forme »).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { runCode } from '../helpers/n8n.mjs';

const TICKET = { id: 5, subject: 'Avoir', body: 'Comment créer un avoir ?' };
const row = (similarity, n) => ({ doc_title: `Fiche ${n}`, section: `Section ${n}`, doc_path: `${n}.md`,
                                  content: `Contenu ${n}`, similarity });

const prompt = (rows, env = { SIMILARITY_MIN: '0.5' }, emb = { embeddings: [[0.1]] }) =>
  runCode('21_reponse_rag.json', 'Prompt RAG', {
    items: rows, env, nodes: { 'Lire ticket': TICKET, 'Ollama · embedding': emb },
  })[0];

test('seuls les extraits au-dessus du seuil de similarité deviennent des sources', () => {
  const p = prompt([row(0.8, 'a'), row(0.55, 'b'), row(0.3, 'c')]);
  assert.equal(p.has_sources, true);
  assert.deepEqual(p.sources.map(s => s.title), ['Fiche a', 'Fiche b']);
  assert.deepEqual(p.sources.map(s => s.n), [1, 2]);
  assert.equal(p.best_similarity, 0.8);
  assert.match(p.request.messages[1].content, /\[1\] Contenu a\n\n\[2\] Contenu b$/);
  assert.doesNotMatch(p.request.messages[1].content, /Contenu c/);
});

test('aucun extrait assez proche → pas de source (le ticket sera escaladé hors_base)', () => {
  const p = prompt([row(0.2, 'a')]);
  assert.equal(p.has_sources, false);
  assert.deepEqual(p.sources, []);
});

test('le seuil se règle par SIMILARITY_MIN', () => {
  assert.equal(prompt([row(0.55, 'a')], { SIMILARITY_MIN: '0.6' }).has_sources, false);
});

test('erreur d’embedding remontée', () => {
  const p = prompt([{ error: 'vide' }], undefined, { error: { message: 'model not found' } });
  assert.match(p.error, /embedding : model not found/);
});

test('la requête impose une sortie JSON structurée (étapes + numéro de source)', () => {
  const f = prompt([row(0.9, 'a')]).request.format;
  assert.deepEqual(f.required, ['steps', 'answerable']);
  assert.deepEqual(f.properties.steps.items.required, ['text', 'source']);
});

// --- Mise en forme -----------------------------------------------------------
const PROMPT = { ticket_id: 5, error: null, sources: [
  { n: 1, title: 'Factures et avoirs', section: 'Créer un avoir' },
  { n: 2, title: 'Paiements', section: 'Rapprochement' },
] };
const format = (llm, p = PROMPT) => runCode('21_reponse_rag.json', 'Mise en forme', {
  json: { message: { content: JSON.stringify(llm) } }, nodes: { 'Prompt RAG': p },
})[0];

test('les étapes sont numérotées et citent leur source ; seules les sources utilisées sont gardées', () => {
  const r = format({ answerable: true, steps: [
    { text: 'Ouvrez la facture.', source: 1 }, { text: 'Cliquez sur « Avoir ».', source: 1 } ] });
  assert.equal(r.answer, '1. Ouvrez la facture. [1]\n2. Cliquez sur « Avoir ». [1]');
  assert.deepEqual(r.sources.map(s => s.n), [1]);
  assert.equal(r.answerable, true);
});

test('un numéro de source inventé par le LLM n’est pas cité', () => {
  const r = format({ answerable: true, steps: [{ text: 'Étape.', source: 9 }] });
  assert.equal(r.answer, '1. Étape.');
  assert.deepEqual(r.sources.map(s => s.n), [1], 'repli sur la meilleure source');
});

test('les formules de politesse ajoutées par le LLM sont retirées', () => {
  const r = format({ answerable: true, steps: [{ text: 'Bonjour Madame, ouvrez la facture.', source: 1 }] });
  assert.equal(r.answer, '1. ouvrez la facture. [1]');
});

test('le LLM ne sait pas répondre → answerable false, pas de réponse', () => {
  const r = format({ answerable: false, steps: [] });
  assert.equal(r.answer, null);
  assert.equal(r.answerable, false);
  assert.deepEqual(r.sources, []);
});

test('answerable true mais aucune étape → considéré comme non répondable', () => {
  assert.equal(format({ answerable: true, steps: [{ text: '  ', source: 1 }] }).answerable, false);
});
