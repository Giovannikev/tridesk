// Exécute le code JavaScript d'un nœud « Code » n8n en dehors de n8n.
// Les variables n8n ($json, $env, $input, $('Nœud')) sont simulées : on teste la logique
// métier exactement telle qu'elle est stockée dans les workflows du dépôt.
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
export const WF_DIR = path.join(ROOT, 'n8n', 'workflows');

export function loadWorkflows() {
  return readdirSync(WF_DIR).filter(f => f.endsWith('.json')).sort()
    .map(file => ({ file, ...JSON.parse(readFileSync(path.join(WF_DIR, file), 'utf8')) }));
}

export function codeOf(file, nodeName) {
  const wf = JSON.parse(readFileSync(path.join(WF_DIR, file), 'utf8'));
  const node = wf.nodes.find(n => n.name === nodeName);
  if (!node) throw new Error(`Nœud « ${nodeName} » introuvable dans ${file}`);
  return node.parameters.jsCode;
}

const wrap = json => ({ json });

/**
 * Lance le code d'un nœud.
 * @param {string} file     fichier du workflow (ex. '22_escalade.json')
 * @param {string} nodeName nom du nœud Code
 * @param {object} ctx      { json, items, env, nodes: { 'Nom': json | json[] } }
 */
export function runCode(file, nodeName, { json = {}, items, env = {}, nodes = {} } = {}) {
  const all = (items ?? [json]).map(wrap);
  const $input = { all: () => all, first: () => all[0], item: all[0] };
  const $ = name => {
    if (!(name in nodes)) throw new Error(`Nœud simulé manquant : ${name}`);
    const list = [].concat(nodes[name]).map(wrap);
    return { item: list[0], first: () => list[0], all: () => list };
  };
  const fn = new Function('$json', '$env', '$input', '$', codeOf(file, nodeName));
  const out = fn(json, env, $input, $);
  return Array.isArray(out) ? out.map(o => o.json) : out.json;
}
