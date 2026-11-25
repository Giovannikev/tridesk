// Post-traitement de la sortie du LLM : nœud « Analyse » du workflow 20.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { runCode } from '../helpers/n8n.mjs';

const analyse = (llm, { subject = 'Question', body = 'Comment créer un avoir ?', raw } = {}) =>
  runCode('20_classification.json', 'Analyse', {
    json: raw ?? { model: 'qwen2.5:1.5b', message: { content: JSON.stringify(llm) } },
    nodes: { Prompt: { ticket_id: 3, subject, body } },
  });

const OK = { summary: 'Créer un avoir', category: 'facturation_comptabilite', reason: 'question',
             priority: 'basse', wants_human: false, confidence: 0.92 };

test('une sortie valide est reprise telle quelle', () => {
  const r = analyse(OK);
  assert.equal(r.ticket_id, 3);
  assert.equal(r.category, 'facturation_comptabilite');
  assert.equal(r.priority, 'basse');
  assert.equal(r.confidence, 0.92);
  assert.equal(r.wants_human, false);
  assert.equal(r.error, null);
  assert.equal(r.model, 'qwen2.5:1.5b');
});

test('catégorie ou priorité inconnue → valeurs par défaut sûres', () => {
  const r = analyse({ ...OK, category: 'cuisine', priority: 'urgentissime' });
  assert.equal(r.category, 'autre');
  assert.equal(r.priority, 'normale');
});

test('la confiance est bornée entre 0 et 1 et arrondie', () => {
  assert.equal(analyse({ ...OK, confidence: 7 }).confidence, 1);
  assert.equal(analyse({ ...OK, confidence: -2 }).confidence, 0);
  assert.equal(analyse({ ...OK, confidence: 'beaucoup' }).confidence, 0);
  assert.equal(analyse({ ...OK, confidence: 0.12345 }).confidence, 0.123);
});

test('JSON invalide du LLM → confiance 0 et erreur, donc escalade en aval', () => {
  const r = analyse(null, { raw: { message: { content: 'pas du json' } } });
  assert.equal(r.confidence, 0);
  assert.match(r.error, /^classification : /);
  assert.equal(r.category, 'autre');
});

test('erreur HTTP d’Ollama → erreur remontée', () => {
  const r = analyse(null, { raw: { error: { message: 'connect ECONNREFUSED' } } });
  assert.match(r.error, /ECONNREFUSED/);
  assert.equal(r.confidence, 0);
});

for (const body of [
  'Je voudrais parler à un conseiller au sujet de ma facture.',
  'Merci de me rappeler rapidement.',
  'Rappelez-moi svp',
  'Est-ce que je peux discuter avec un humain ?',
]) {
  test(`demande d’humain détectée par mots-clés : « ${body} »`, () => {
    assert.equal(analyse({ ...OK, wants_human: false }, { body }).wants_human, true);
  });
}

test('le LLM ne peut pas inventer une demande d’humain absente du texte', () => {
  assert.equal(analyse({ ...OK, wants_human: true }, { body: 'Comment créer un avoir ?' }).wants_human, false);
});

test('résumé et justification tronqués à 500 caractères', () => {
  const r = analyse({ ...OK, summary: 'x'.repeat(900), reason: '' });
  assert.equal(r.summary.length, 500);
  assert.equal(r.reason, null);
});
