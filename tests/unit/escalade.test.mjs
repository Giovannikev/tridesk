// Règles d'escalade : nœud « Décision » du workflow 22.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { runCode } from '../helpers/n8n.mjs';

const ENV = { CONFIDENCE_MIN: '0.6', PUBLIC_API_URL: 'http://localhost:5679/webhook' };
const SOURCES = [{ n: 1, title: 'Connexion et mot de passe', section: 'Mot de passe oublié', similarity: 0.71 }];

// Ticket « nominal » : rien ne justifie une escalade
const ticket = over => ({
  id: 7, channel: 'webhook', customer_name: 'Marie', customer_contact: 'marie@exemple.test',
  subject: 'Mot de passe oublié', body: "J'ai oublié mon mot de passe",
  category: 'acces_connexion', priority: 'normale', confidence: 0.9, wants_human: false,
  answerable: true, suggested_answer: '1. Cliquez sur « Mot de passe oublié » [1]', sources: SOURCES,
  processing_error: null, ...over,
});
const decide = over => runCode('22_escalade.json', 'Décision', { json: ticket(over), env: ENV });

test('ticket simple et bien couvert : réponse automatique, pas d’escalade', () => {
  const d = decide({});
  assert.equal(d.escalate, false);
  assert.deepEqual(d.reasons, []);
  assert.match(d.auto_answer, /^Bonjour Marie,/);
  assert.match(d.auto_answer, /\[1\] Connexion et mot de passe › Mot de passe oublié/);
  assert.match(d.auto_answer, /ticket n°7/);
});

test('demande explicite d’un humain → demande_humain', () => {
  assert.deepEqual(decide({ wants_human: true }).reasons, ['demande_humain']);
});

for (const priority of ['haute', 'critique']) {
  test(`priorité ${priority} → priorite_haute`, () => {
    const d = decide({ priority });
    assert.ok(d.escalate);
    assert.deepEqual(d.reasons, ['priorite_haute']);
    assert.match(d.agent_subject, new RegExp(`^\\[Escalade\\]\\[${priority}\\] Ticket n°7`));
  });
}

test('confiance sous le seuil → confiance_faible', () => {
  assert.deepEqual(decide({ confidence: 0.59 }).reasons, ['confiance_faible']);
  assert.deepEqual(decide({ confidence: 0.6 }).reasons, [], 'le seuil lui-même est accepté');
});

test('le seuil de confiance se règle par CONFIDENCE_MIN', () => {
  const d = runCode('22_escalade.json', 'Décision', { json: ticket({ confidence: 0.75 }), env: { ...ENV, CONFIDENCE_MIN: '0.8' } });
  assert.deepEqual(d.reasons, ['confiance_faible']);
});

test('pas de source, pas de réponse ou LLM qui ne sait pas → hors_base', () => {
  assert.deepEqual(decide({ sources: [] }).reasons, ['hors_base']);
  assert.deepEqual(decide({ suggested_answer: null }).reasons, ['hors_base']);
  assert.deepEqual(decide({ answerable: false }).reasons, ['hors_base']);
});

test('les sources stockées en JSON texte (sortie Postgres) sont acceptées', () => {
  assert.equal(decide({ sources: JSON.stringify(SOURCES) }).escalate, false);
});

test('erreur technique → erreur_technique, le ticket n’est jamais perdu', () => {
  const d = decide({ processing_error: 'Ollama injoignable', confidence: 0, answerable: false, suggested_answer: null, sources: [] });
  assert.deepEqual(d.reasons, ['confiance_faible', 'hors_base', 'erreur_technique']);
  assert.match(d.agent_text, /Erreur : Ollama injoignable/);
});

test('plusieurs raisons sont cumulées dans l’ordre', () => {
  assert.deepEqual(decide({ wants_human: true, priority: 'critique', confidence: 0.2 }).reasons,
    ['demande_humain', 'priorite_haute', 'confiance_faible']);
});

test('l’accusé de réception annonce le délai du SLA', () => {
  assert.match(decide({ priority: 'critique' }).ack, /prise en charge sous 1 heure/);
  assert.match(decide({ priority: undefined, wants_human: true }).ack, /1 jour ouvré/);
});

test('le message à l’agent contient le message client et la commande pour clore', () => {
  const d = decide({ priority: 'haute' });
  assert.match(d.agent_text, /--- Message du client ---\nSujet : Mot de passe oublié/);
  assert.match(d.agent_text, /tickets\/resolve/);
  assert.match(d.agent_text, /"ticket_id": 7/);
});

test('client anonyme : formule de politesse neutre', () => {
  assert.match(decide({ customer_name: null }).auto_answer, /^Bonjour,/);
});
