// Entrées : validation de l'API (workflow 02) et normalisation des e-mails (workflow 03).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { runCode } from '../helpers/n8n.mjs';

const validate = body => runCode('02_canal_webhook_api.json', 'Validation', { json: { body } })[0];

test('API : ticket valide', () => {
  const v = validate({ subject: ' Avoir ', message: 'Comment créer un avoir ?',
                       customer: { name: 'Marie', email: 'marie@exemple.test' } });
  assert.equal(v.valid, true);
  assert.deepEqual(v.errors, []);
  assert.equal(v.subject, 'Avoir', 'espaces retirés');
  assert.equal(v.customer_email, 'marie@exemple.test');
});

test('API : message absent ou trop court → 400', () => {
  assert.equal(validate({}).valid, false);
  assert.equal(validate(undefined).valid, false);
  assert.match(validate({ message: 'abc' }).errors[0], /^message/);
});

test('API : e-mail invalide refusé', () => {
  const v = validate({ message: 'Bonjour à tous', customer: { email: 'pas-un-email' } });
  assert.equal(v.valid, false);
  assert.match(v.errors[0], /^customer\.email/);
});

test('API : champs tronqués pour éviter les entrées géantes', () => {
  const v = validate({ message: 'x'.repeat(20000), subject: 's'.repeat(500) });
  assert.equal(v.message.length, 10000);
  assert.equal(v.subject.length, 200);
});

test('API : customer qui n’est pas un objet est ignoré', () => {
  const v = validate({ message: 'Bonjour à tous', customer: 'Marie' });
  assert.equal(v.valid, true);
  assert.equal(v.customer_name, null);
});

// --- E-mail ------------------------------------------------------------------
const ENV = { SUPPORT_FROM_EMAIL: 'support@support.local' };
const mail = over => ({ from: { value: [{ address: 'Client@Exemple.test', name: 'Client' }] },
                        subject: 'Facture', text: 'Ma facture est fausse.', messageId: '<m1@x>', headers: {}, ...over });
const normalise = (...mails) => runCode('03_canal_email.json', 'Normaliser', { items: mails, env: ENV });

test('e-mail : normalisé en ticket', () => {
  const [t] = normalise(mail());
  assert.deepEqual(t, { external_id: '<m1@x>', customer_name: 'Client', customer_email: 'client@exemple.test',
                        subject: 'Facture', message: 'Ma facture est fausse.' });
});

test('e-mail : l’historique cité et la signature sont retirés', () => {
  const [t] = normalise(mail({ text: 'Toujours bloqué.\n\nLe lun. 3 nov. 2026, Support a écrit :\n> ancien message' }));
  assert.equal(t.message, 'Toujours bloqué.');
  const [t2] = normalise(mail({ text: 'Merci\n-- \nJean, société X' }));
  assert.equal(t2.message, 'Merci');
});

test('e-mail : pas de boucle sur nos propres messages ni sur les réponses automatiques', () => {
  assert.equal(normalise(mail({ from: { value: [{ address: 'SUPPORT@support.local' }] } })).length, 0);
  assert.equal(normalise(mail({ headers: { 'auto-submitted': 'auto-replied' } })).length, 0);
});

test('e-mail : HTML seul converti en texte, message vide ignoré', () => {
  const [t] = normalise(mail({ text: undefined, html: '<p>Bonjour <b>support</b></p>' }));
  assert.equal(t.message, 'Bonjour  support');
  assert.equal(normalise(mail({ text: '   ' })).length, 0);
});

test('e-mail : expéditeur au format texte et sans objet', () => {
  const [t] = normalise(mail({ from: 'Paul <paul@exemple.test>', subject: undefined, messageId: undefined, date: 'd' }));
  assert.equal(t.customer_email, 'paul@exemple.test');
  assert.equal(t.subject, '(sans objet)');
  assert.match(t.external_id, /^paul@exemple\.test\|d\|/, 'identifiant de repli pour le dédoublonnage');
});
